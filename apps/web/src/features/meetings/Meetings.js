import React, { useState, useEffect } from 'react';
import { io } from 'socket.io-client';
import MultiTrackPlayback from '../multitrack/MultiTrackPlayback';
import AIProcesses from './AIProcesses';
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
  const [showPlayback, setShowPlayback] = useState(false);
  const [socket, setSocket] = useState(null);

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
    const socketInstance = io(socketUrl, {
      autoConnect: true,
      reconnection: true,
      reconnectionDelay: 1000,
      reconnectionAttempts: 5,
      timeout: 20000,
    });

    // Store socket instance in state
    setSocket(socketInstance);

    // Connection events
    socketInstance.on('connect', () => {
      console.log('Socket.IO connected:', socketInstance.id);
    });

    socketInstance.on('disconnect', (reason) => {
      console.log('Socket.IO disconnected:', reason);
    });

    socketInstance.on('connect_error', (error) => {
      console.error('Socket.IO connection error:', error);
    });

    // Meeting/transcription events
    socketInstance.on('transcription_started', (message) => {
      console.log('Transcription started:', message);
      setIsRecording(true);
      setLiveTranscription('Starting transcription...');
    });

    socketInstance.on('transcription_progress', (message) => {
      console.log('Transcription progress:', message);
      setLiveTranscription(prev => prev + ' ' + (message.text || ''));
    });

    socketInstance.on('transcription_completed', (message) => {
      console.log('Transcription completed:', message);
      setIsRecording(false);
      if (message.transcriptionId) {
        fetchTranscriptionResult(message.transcriptionId);
      }
    });

    socketInstance.on('recording_started', (message) => {
      console.log('Recording started:', message);
      setIsRecording(true);
      setLiveTranscription('Recording started...');
    });

    socketInstance.on('recording_stopped', (message) => {
      console.log('Recording stopped:', message);
      setIsRecording(false);
    });

    // Device pairing events
    socketInstance.on('device_paired', (message) => {
      console.log('Device paired:', message);
    });

    socketInstance.on('device_unpaired', (message) => {
      console.log('Device unpaired:', message);
    });

    // Analysis progress events
    socketInstance.on('meeting:analysis_progress', (message) => {
      console.log('Meeting analysis progress:', message);
      const { meetingId, phase, message: progressMessage, progress, estimatedTimeRemaining } = message;
      
      setMeetings(prev => prev.map(meeting => 
        meeting.id === meetingId 
          ? { 
              ...meeting, 
              analysisProgress: {
                phase,
                message: progressMessage,
                progress,
                estimatedTimeRemaining
              }
            }
          : meeting
      ));
    });

    // Analysis completion events
    socketInstance.on('meeting:analysis_complete', (message) => {
      console.log('Meeting analysis completed:', message);
      const { meetingId, analysis, processingTime, parseError } = message;
      
      setMeetings(prev => prev.map(meeting => 
        meeting.id === meetingId 
          ? { 
              ...meeting, 
              summary: analysis.summary, 
              actionItems: analysis.actionItems || [],
              keyPoints: analysis.keyPoints || [],
              decisions: analysis.decisions || [],
              processingTime: processingTime,
              parseError: parseError,
              isAnalyzing: false,
              analysisError: null,
              analysisProgress: null
            }
          : meeting
      ));
    });

    // AI Process events
    socketInstance.on('process:started', (data) => {
      console.log('Process started:', data);
      // Additional handling for process start if needed
    });

    socketInstance.on('process:progress', (data) => {
      console.log('Process progress:', data);
      // Additional handling for process progress if needed
    });

    socketInstance.on('process:completed', (data) => {
      console.log('Process completed:', data);
      // Additional handling for process completion if needed
    });

    socketInstance.on('process:failed', (data) => {
      console.log('Process failed:', data);
      // Additional handling for process failure if needed
    });

    socketInstance.on('process:cancelled', (data) => {
      console.log('Process cancelled:', data);
      // Additional handling for process cancellation if needed
    });

    return () => {
      socketInstance.disconnect();
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
        
        // Auto-generate AI summary for longer transcripts
        if (data.data.text && data.data.text.length > 100) {
          setTimeout(() => {
            generateMeetingSummary(transcriptionId, data.data.text);
          }, 1000); // Small delay to ensure UI is ready
        }
      }
    } catch (error) {
      console.error('Error fetching transcription result:', error);
    }
  };

  const generateMeetingSummary = async (meetingId, transcript) => {
    const startTime = Date.now();
    try {
      setMeetings(prev => prev.map(meeting => 
        meeting.id === meetingId 
          ? { ...meeting, isAnalyzing: true, analysisError: null }
          : meeting
      ));

      const response = await fetch(`${API_BASE}/api/meetings/${meetingId}/analyze`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ transcript }),
      });
      
      const data = await response.json();
      const processingTime = ((Date.now() - startTime) / 1000).toFixed(1);
      
      if (data.success) {
        setMeetings(prev => prev.map(meeting => 
          meeting.id === meetingId 
            ? { 
                ...meeting, 
                summary: data.data.summary, 
                actionItems: data.data.actionItems,
                keyPoints: data.data.keyPoints,
                decisions: data.data.decisions,
                processingTime: data.data.processingTime || processingTime,
                parseError: data.data.parseError,
                isAnalyzing: false,
                analysisError: null
              }
            : meeting
        ));
      } else {
        throw new Error(data.error || 'Analysis failed');
      }
    } catch (error) {
      console.error('Error generating meeting summary:', error);
      const processingTime = ((Date.now() - startTime) / 1000).toFixed(1);
      setMeetings(prev => prev.map(meeting => 
        meeting.id === meetingId 
          ? { 
              ...meeting, 
              isAnalyzing: false, 
              analysisError: error.message,
              processingTime
            }
          : meeting
      ));
    }
  };

  const regenerateSummary = async (meetingId, transcript, style = 'standard') => {
    const startTime = Date.now();
    try {
      setMeetings(prev => prev.map(meeting => 
        meeting.id === meetingId 
          ? { ...meeting, isAnalyzing: true, analysisError: null }
          : meeting
      ));

      const response = await fetch(`${API_BASE}/api/meetings/${meetingId}/analyze`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ transcript, style }),
      });
      
      const data = await response.json();
      const processingTime = ((Date.now() - startTime) / 1000).toFixed(1);
      
      if (data.success) {
        console.log('=== API RESPONSE DATA ===');
        console.log('data.data:', data.data);
        console.log('========================');
        
        setMeetings(prev => prev.map(meeting => 
          meeting.id === meetingId 
            ? { 
                ...meeting, 
                summary: data.data.summary, 
                actionItems: data.data.actionItems,
                keyPoints: data.data.keyPoints,
                decisions: data.data.decisions,
                processingTime: data.data.processingTime || processingTime,
                parseError: data.data.parseError,
                isAnalyzing: false,
                analysisError: null,
                lastStyle: style
              }
            : meeting
        ));
      } else {
        throw new Error(data.error || 'Analysis failed');
      }
    } catch (error) {
      console.error('Error regenerating meeting summary:', error);
      const processingTime = ((Date.now() - startTime) / 1000).toFixed(1);
      setMeetings(prev => prev.map(meeting => 
        meeting.id === meetingId 
          ? { 
              ...meeting, 
              isAnalyzing: false, 
              analysisError: error.message,
              processingTime
            }
          : meeting
      ));
    }
  };

  const formatTime = (seconds) => {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  const parseJSONSummary = (jsonString) => {
    try {
      // Handle multi-line JSON by removing newlines and extra spaces
      const cleanedJson = jsonString
        .replace(/\n\s*/g, ' ') // Replace newlines with spaces
        .replace(/\s+/g, ' ')   // Replace multiple spaces with single space
        .trim();
      
      const parsed = JSON.parse(cleanedJson);
      
      return {
        summary: parsed.summary || '',
        keyPoints: Array.isArray(parsed.keyPoints) ? parsed.keyPoints : [],
        actionItems: Array.isArray(parsed.actionItems) ? parsed.actionItems : [],
        decisions: Array.isArray(parsed.decisions) ? parsed.decisions : []
      };
    } catch (e) {
      console.warn('JSON parsing failed:', e);
      
      // Fallback: try to extract just the summary text
      const summaryMatch = jsonString.match(/"summary"\s*:\s*"([^"]+)"/);
      const keyPointsMatch = jsonString.match(/"keyPoints"\s*:\s*\[(.*?)\]/s);
      const actionItemsMatch = jsonString.match(/"actionItems"\s*:\s*\[(.*?)\]/s);
      const decisionsMatch = jsonString.match(/"decisions"\s*:\s*\[(.*?)\]/s);
      
      const extractArray = (match) => {
        if (!match) return [];
        try {
          return JSON.parse(`[${match[1]}]`);
        } catch (e) {
          return match[1].split(',').map(item => item.replace(/"/g, '').trim()).filter(item => item);
        }
      };
      
      return {
        summary: summaryMatch ? summaryMatch[1] : jsonString.substring(0, 200) + '...',
        keyPoints: extractArray(keyPointsMatch),
        actionItems: extractArray(actionItemsMatch),
        decisions: extractArray(decisionsMatch)
      };
    }
  };

  const renderStructuredSummary = (meeting) => {
    console.log('=== DEBUGGING SUMMARY ===');
    console.log('Meeting summary:', meeting.summary);
    console.log('Meeting keyPoints:', meeting.keyPoints);
    console.log('Meeting actionItems:', meeting.actionItems);
    console.log('Meeting decisions:', meeting.decisions);
    
    // Parse summary if it's JSON string, otherwise use as text
    let parsedSummary;
    
    // Priority 1: Use structured data if available from API response
    if (meeting.keyPoints || meeting.actionItems || meeting.decisions) {
      console.log('USING STRUCTURED DATA FROM MEETING OBJECT');
      parsedSummary = {
        summary: meeting.summary,
        keyPoints: meeting.keyPoints || [],
        actionItems: meeting.actionItems || [],
        decisions: meeting.decisions || []
      };
    }
    // Priority 2: Parse JSON string if summary looks like JSON
    else if (typeof meeting.summary === 'string' && meeting.summary.trim().startsWith('{')) {
      console.log('PARSING JSON SUMMARY STRING');
      parsedSummary = parseJSONSummary(meeting.summary);
    }
    // Priority 3: Use plain text summary
    else {
      console.log('USING PLAIN TEXT SUMMARY');
      parsedSummary = {
        summary: meeting.summary,
        keyPoints: [],
        actionItems: [],
        decisions: []
      };
    }
    
    console.log('FINAL PARSED SUMMARY:', parsedSummary);
    console.log('========================');

    return (
      <div className="summary-sections">
        {meeting.processingTime && (
          <div className="processing-info">
            <span className="processing-time">⏱️ Generated in {meeting.processingTime}s</span>
            {meeting.parseError && (
              <span className="parse-warning">⚠️ Fallback parsing used</span>
            )}
          </div>
        )}
        
        {meeting.isAnalyzing && (
          <div className="analyzing-indicator">
            <div className="analysis-header">
              <span className="analyzing-spinner">🔄</span> 
              <span>{meeting.analysisProgress?.message || 'Generating AI summary...'}</span>
            </div>
            {meeting.analysisProgress && (
              <div className="progress-container">
                <div className="progress-bar">
                  <div 
                    className="progress-fill" 
                    style={{ width: `${meeting.analysisProgress.progress}%` }}
                  ></div>
                </div>
                <div className="progress-info">
                  <span className="progress-percentage">{meeting.analysisProgress.progress}%</span>
                  <span className="progress-phase">{meeting.analysisProgress.phase}</span>
                  {meeting.analysisProgress.estimatedTimeRemaining && (
                    <span className="time-remaining">
                      ~{meeting.analysisProgress.estimatedTimeRemaining}s remaining
                    </span>
                  )}
                </div>
              </div>
            )}
          </div>
        )}

        {meeting.analysisError && (
          <div className="analysis-error">
            <span className="error-icon">⚠️</span> 
            <span>Analysis failed: {meeting.analysisError}</span>
            <button 
              className="retry-btn"
              onClick={() => generateMeetingSummary(meeting.id, meeting.transcript)}
            >
              Retry
            </button>
          </div>
        )}

        {parsedSummary.summary && (
          <div className="summary-section">
            <div className="section-header">
              <h4>📝 Summary</h4>
              <div className="summary-actions">
                <button 
                  className="regenerate-btn"
                  onClick={() => regenerateSummary(meeting.id, meeting.transcript, 'detailed')}
                  title="Generate a more detailed summary"
                >
                  🔄 Detailed
                </button>
                <button 
                  className="regenerate-btn"
                  onClick={() => regenerateSummary(meeting.id, meeting.transcript, 'brief')}
                  title="Generate a brief summary"
                >
                  🔄 Brief
                </button>
                <button 
                  className="regenerate-btn"
                  onClick={() => regenerateSummary(meeting.id, meeting.transcript, 'action-focused')}
                  title="Focus on action items and decisions"
                >
                  🔄 Action-focused
                </button>
              </div>
            </div>
            <div className="summary-text">
              {parsedSummary.summary}
            </div>
          </div>
        )}

        {parsedSummary.keyPoints && parsedSummary.keyPoints.length > 0 && (
          <div className="summary-section">
            <h4>🔑 Key Points</h4>
            <ul className="key-points-list">
              {parsedSummary.keyPoints.map((point, index) => (
                <li key={index}>{point}</li>
              ))}
            </ul>
          </div>
        )}

        {parsedSummary.actionItems && parsedSummary.actionItems.length > 0 && (
          <div className="summary-section">
            <h4>✅ Action Items</h4>
            <ul className="action-items-list">
              {parsedSummary.actionItems.map((item, index) => (
                <li key={index}>
                  <input type="checkbox" id={`action-${index}`} />
                  <label htmlFor={`action-${index}`}>{item}</label>
                </li>
              ))}
            </ul>
          </div>
        )}

        {parsedSummary.decisions && parsedSummary.decisions.length > 0 && (
          <div className="summary-section">
            <h4>⚖️ Decisions Made</h4>
            <ul className="decisions-list">
              {parsedSummary.decisions.map((decision, index) => (
                <li key={index}>{decision}</li>
              ))}
            </ul>
          </div>
        )}
      </div>
    );
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
          <div className="meeting-title-section">
            <h2>{selectedMeeting.title}</h2>
            <div className="meeting-info">
              <span>📅 {new Date(selectedMeeting.createdAt).toLocaleString()}</span>
              {selectedMeeting.duration > 0 && (
                <span>⏱️ {formatTime(selectedMeeting.duration)}</span>
              )}
              {selectedMeeting.language && (
                <span>🌍 {selectedMeeting.language}</span>
              )}
              {selectedMeeting.recording_format === 'multitrack' && (
                <span className="multitrack-badge">🎵 Multi-Track</span>
              )}
            </div>
          </div>
          
          <div className="meeting-actions">
            {selectedMeeting.recording_format === 'multitrack' && (
              <button 
                onClick={() => setShowPlayback(true)}
                className="playback-button"
              >
                🎵 Multi-Track Player
              </button>
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
          <button 
            className={`tab ${activeTab === 'processes' ? 'active' : ''}`}
            onClick={() => setActiveTab('processes')}
          >
            AI Processes
          </button>
        </div>

        <div className="meeting-content">
          {activeTab === 'summary' && (
            <div className="summary-content">
              {selectedMeeting.summary || (selectedMeeting.keyPoints && selectedMeeting.keyPoints.length > 0) || (selectedMeeting.actionItems && selectedMeeting.actionItems.length > 0) || (selectedMeeting.decisions && selectedMeeting.decisions.length > 0) ? (
                <div className="structured-summary">
                  {renderStructuredSummary(selectedMeeting)}
                </div>
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

          {activeTab === 'processes' && (
            <div className="processes-content">
              <AIProcesses 
                meetingId={selectedMeeting.id} 
                socket={socket}
              />
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
      {showPlayback && selectedMeeting ? (
        <MultiTrackPlayback 
          recording={selectedMeeting}
          onClose={() => setShowPlayback(false)}
        />
      ) : (
        <div className="meetings-layout">
          {renderMeetingList()}
          {renderMeetingDetails()}
        </div>
      )}
    </div>
  );
}

export default Meetings;