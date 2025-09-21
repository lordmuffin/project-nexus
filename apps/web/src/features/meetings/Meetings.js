import React, { useState, useEffect } from 'react';
import { io } from 'socket.io-client';
import './Meetings.css';

// Dynamic API base URL that works with actual host IP
const getApiBase = () => {
  if (process.env.REACT_APP_API_URL) {
    return process.env.REACT_APP_API_URL;
  }
  
  // Use current hostname with port 3001 for backend
  const protocol = window.location.protocol;
  const hostname = window.location.hostname;
  return `${protocol}//${hostname}:3001`;
};

const API_BASE = getApiBase();

function Meetings() {
  const [meetings, setMeetings] = useState([]);
  const [selectedMeeting, setSelectedMeeting] = useState(null);
  const [activeTab, setActiveTab] = useState('summary');
  const [isLoading, setIsLoading] = useState(true);
  const [liveTranscription, setLiveTranscription] = useState('');
  const [isRecording, setIsRecording] = useState(false);

  useEffect(() => {
    fetchMeetings();
    setupWebSocketListeners();
  }, []);

  const fetchMeetings = async () => {
    try {
      const response = await fetch(`${API_BASE}/api/meetings`);
      const data = await response.json();
      if (data.success) {
        setMeetings(data.data || []);
      }
    } catch (error) {
      console.error('Error fetching meetings:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const setupWebSocketListeners = () => {
    // Set up Socket.IO connection for live updates
    const protocol = window.location.protocol;
    const hostname = window.location.hostname;
    const socketUrl = process.env.REACT_APP_WS_URL || `${protocol}//${hostname}:3001`;
    
    console.log('Connecting to Socket.IO server:', socketUrl);
    const socket = io(socketUrl, {
      autoConnect: true,
      reconnection: true,
      reconnectionDelay: 1000,
      reconnectionAttempts: 5,
      timeout: 20000,
    });

    // Connection events
    socket.on('connect', () => {
      console.log('Socket.IO connected:', socket.id);
    });

    socket.on('disconnect', (reason) => {
      console.log('Socket.IO disconnected:', reason);
    });

    socket.on('connect_error', (error) => {
      console.error('Socket.IO connection error:', error);
    });

    // Meeting/transcription events
    socket.on('transcription_started', (message) => {
      console.log('Transcription started:', message);
      setIsRecording(true);
      setLiveTranscription('Starting transcription...');
    });

    socket.on('transcription_progress', (message) => {
      console.log('Transcription progress:', message);
      setLiveTranscription(prev => prev + ' ' + (message.text || ''));
    });

    socket.on('transcription_completed', (message) => {
      console.log('Transcription completed:', message);
      setIsRecording(false);
      if (message.transcriptionId) {
        fetchTranscriptionResult(message.transcriptionId);
      }
    });

    socket.on('recording_started', (message) => {
      console.log('Recording started:', message);
      setIsRecording(true);
      setLiveTranscription('Recording started...');
    });

    socket.on('recording_stopped', (message) => {
      console.log('Recording stopped:', message);
      setIsRecording(false);
    });

    // Device pairing events
    socket.on('device_paired', (message) => {
      console.log('Device paired:', message);
    });

    socket.on('device_unpaired', (message) => {
      console.log('Device unpaired:', message);
    });

    return () => {
      socket.disconnect();
    };
  };

  const fetchTranscriptionResult = async (transcriptionId) => {
    try {
      const response = await fetch(`${API_BASE}/api/transcription/jobs/${transcriptionId}/result`);
      const data = await response.json();
      
      if (data.success && data.data) {
        const newMeeting = {
          id: transcriptionId,
          title: `Meeting ${new Date().toLocaleDateString()}`,
          transcript: data.data.text,
          segments: data.data.segments || [],
          duration: data.data.duration || 0,
          createdAt: new Date().toISOString(),
          language: data.data.language || 'auto'
        };
        
        setMeetings(prev => [newMeeting, ...prev]);
        setSelectedMeeting(newMeeting);
        
        // Generate AI summary
        generateMeetingSummary(transcriptionId, data.data.text);
      }
    } catch (error) {
      console.error('Error fetching transcription result:', error);
    }
  };

  const generateMeetingSummary = async (meetingId, transcript) => {
    try {
      const response = await fetch(`${API_BASE}/api/meetings/${meetingId}/analyze`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ transcript }),
      });
      
      const data = await response.json();
      if (data.success) {
        setMeetings(prev => prev.map(meeting => 
          meeting.id === meetingId 
            ? { ...meeting, summary: data.data.summary, actionItems: data.data.actionItems }
            : meeting
        ));
      }
    } catch (error) {
      console.error('Error generating meeting summary:', error);
    }
  };

  const formatTime = (seconds) => {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  const renderMeetingList = () => (
    <div className="meetings-list">
      <div className="meetings-list-header">
        <h3>Recent Meetings</h3>
        {isRecording && (
          <div className="recording-indicator">
            <span className="recording-dot"></span>
            Recording...
          </div>
        )}
      </div>
      
      {liveTranscription && isRecording && (
        <div className="live-transcription">
          <h4>Live Transcription</h4>
          <div className="live-text">{liveTranscription}</div>
        </div>
      )}
      
      {meetings.length === 0 ? (
        <div className="empty-state">
          <div className="empty-icon">🎙️</div>
          <h4>No meetings yet</h4>
          <p>Start recording with your mobile device to see transcriptions here.</p>
        </div>
      ) : (
        <div className="meetings-items">
          {meetings.map(meeting => (
            <div 
              key={meeting.id}
              className={`meeting-item ${selectedMeeting?.id === meeting.id ? 'selected' : ''}`}
              onClick={() => setSelectedMeeting(meeting)}
            >
              <div className="meeting-title">{meeting.title}</div>
              <div className="meeting-meta">
                <span className="meeting-date">
                  {new Date(meeting.createdAt).toLocaleDateString()}
                </span>
                {meeting.duration > 0 && (
                  <span className="meeting-duration">
                    {formatTime(meeting.duration)}
                  </span>
                )}
              </div>
              <div className="meeting-preview">
                {meeting.transcript?.substring(0, 100)}...
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );

  const renderMeetingDetails = () => {
    if (!selectedMeeting) {
      return (
        <div className="meeting-details-empty">
          <div className="empty-icon">📝</div>
          <h3>Select a meeting</h3>
          <p>Choose a meeting from the list to view its details and transcript.</p>
        </div>
      );
    }

    return (
      <div className="meeting-details">
        <div className="meeting-header">
          <h2>{selectedMeeting.title}</h2>
          <div className="meeting-info">
            <span>📅 {new Date(selectedMeeting.createdAt).toLocaleString()}</span>
            {selectedMeeting.duration > 0 && (
              <span>⏱️ {formatTime(selectedMeeting.duration)}</span>
            )}
            {selectedMeeting.language && (
              <span>🌍 {selectedMeeting.language}</span>
            )}
          </div>
        </div>

        <div className="meeting-tabs">
          <button 
            className={`tab ${activeTab === 'summary' ? 'active' : ''}`}
            onClick={() => setActiveTab('summary')}
          >
            Summary
          </button>
          <button 
            className={`tab ${activeTab === 'transcript' ? 'active' : ''}`}
            onClick={() => setActiveTab('transcript')}
          >
            Transcript
          </button>
          <button 
            className={`tab ${activeTab === 'actions' ? 'active' : ''}`}
            onClick={() => setActiveTab('actions')}
          >
            Action Items
          </button>
        </div>

        <div className="meeting-content">
          {activeTab === 'summary' && (
            <div className="summary-content">
              {selectedMeeting.summary ? (
                <div className="summary-text">{selectedMeeting.summary}</div>
              ) : (
                <div className="summary-placeholder">
                  <p>AI summary will appear here once generated...</p>
                  <button 
                    className="btn-secondary"
                    onClick={() => generateMeetingSummary(selectedMeeting.id, selectedMeeting.transcript)}
                  >
                    Generate Summary
                  </button>
                </div>
              )}
            </div>
          )}

          {activeTab === 'transcript' && (
            <div className="transcript-content">
              {selectedMeeting.segments && selectedMeeting.segments.length > 0 ? (
                <div className="transcript-segments">
                  {selectedMeeting.segments.map((segment, index) => (
                    <div key={index} className="transcript-segment">
                      <span className="segment-time">
                        {formatTime(segment.start)}
                      </span>
                      <span className="segment-text">{segment.text}</span>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="transcript-full">
                  <pre>{selectedMeeting.transcript}</pre>
                </div>
              )}
            </div>
          )}

          {activeTab === 'actions' && (
            <div className="actions-content">
              {selectedMeeting.actionItems && selectedMeeting.actionItems.length > 0 ? (
                <div className="action-items">
                  {selectedMeeting.actionItems.map((item, index) => (
                    <div key={index} className="action-item">
                      <input type="checkbox" />
                      <span>{item}</span>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="actions-placeholder">
                  <p>Action items will appear here once extracted from the transcript...</p>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    );
  };

  if (isLoading) {
    return (
      <div className="meetings">
        <div className="loading">Loading meetings...</div>
      </div>
    );
  }

  return (
    <div className="meetings">
      <div className="meetings-layout">
        {renderMeetingList()}
        {renderMeetingDetails()}
      </div>
    </div>
  );
}

export default Meetings;