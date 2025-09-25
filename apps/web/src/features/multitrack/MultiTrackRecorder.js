import React, { useState, useEffect, useCallback } from 'react';
import WebAudioCapture from './WebAudioCapture';
import './MultiTrackRecorder.css';

const MultiTrackRecorder = () => {
  const [isElectron, setIsElectron] = useState(false);
  const [audioSources, setAudioSources] = useState([]);
  const [currentSession, setCurrentSession] = useState(null);
  const [tracks, setTracks] = useState([]);
  const [isRecording, setIsRecording] = useState(false);
  const [systemPermissions, setSystemPermissions] = useState({});
  const [audioLevels, setAudioLevels] = useState({});

  // Check if running in Electron
  useEffect(() => {
    const electronAPI = window.electronAPI;
    setIsElectron(!!electronAPI);
    
    if (electronAPI) {
      initializeAudio();
      setupEventListeners();
    }
  }, []);

  const initializeAudio = useCallback(async () => {
    try {
      // Get available audio sources
      const sources = await window.electronAPI.audio.getAvailableSources();
      setAudioSources(sources);

      // Check system audio permissions
      const permissions = await window.electronAPI.audio.getSystemAudioPermission();
      setSystemPermissions(permissions);
      
      console.log('Audio sources:', sources);
      console.log('System permissions:', permissions);
    } catch (error) {
      console.error('Error initializing audio:', error);
    }
  }, []);

  const setupEventListeners = useCallback(() => {
    const electronAPI = window.electronAPI;
    
    // Audio level updates
    electronAPI.audio.onAudioLevels((event, sessionId, trackNumber, levels) => {
      setAudioLevels(prev => ({
        ...prev,
        [`${sessionId}_${trackNumber}`]: levels
      }));
    });

    // Session events
    electronAPI.audio.onSessionCreated((event, session) => {
      console.log('Session created:', session);
    });

    electronAPI.audio.onRecordingStarted((event, sessionId) => {
      console.log('Recording started:', sessionId);
      setIsRecording(true);
    });

    electronAPI.audio.onRecordingStopped((event, sessionId) => {
      console.log('Recording stopped:', sessionId);
      setIsRecording(false);
    });

    // Track events
    electronAPI.audio.onTrackAdded((event, sessionId, track) => {
      console.log('Track added:', track);
      updateSessionStatus();
    });

    return () => {
      // Cleanup listeners
      electronAPI.audio.removeAllListeners('audioLevels');
      electronAPI.audio.removeAllListeners('sessionCreated');
      electronAPI.audio.removeAllListeners('recordingStarted');
      electronAPI.audio.removeAllListeners('recordingStopped');
      electronAPI.audio.removeAllListeners('trackAdded');
    };
  }, []);

  const updateSessionStatus = useCallback(async () => {
    if (!currentSession) return;
    
    try {
      const status = await window.electronAPI.audio.getSessionStatus(currentSession.sessionId);
      if (status) {
        setTracks(status.tracks || []);
        setIsRecording(status.isRecording);
      }
    } catch (error) {
      console.error('Error updating session status:', error);
    }
  }, [currentSession]);

  const createSession = async () => {
    try {
      const sessionData = await window.electronAPI.audio.startSession({
        sessionName: `Multi-track Recording ${new Date().toLocaleString()}`,
        outputFormat: 'multitrack',
        sampleRate: 48000,
        bitDepth: 16
      });
      
      setCurrentSession(sessionData);
      console.log('Session created:', sessionData);
    } catch (error) {
      console.error('Error creating session:', error);
    }
  };

  const addTrack = async (sourceId) => {
    if (!currentSession) {
      await createSession();
      return;
    }

    try {
      const source = audioSources.find(s => s.id === sourceId);
      if (!source) return;

      const trackNumber = tracks.length + 1;
      
      await window.electronAPI.audio.addTrack(currentSession.sessionId, {
        trackNumber,
        sourceId,
        sourceType: source.type,
        sourceName: source.name,
        isEnabled: true,
        gainDb: 0.0
      });

      await updateSessionStatus();
    } catch (error) {
      console.error('Error adding track:', error);
    }
  };

  const removeTrack = async (trackNumber) => {
    if (!currentSession) return;

    try {
      await window.electronAPI.audio.removeTrack(currentSession.sessionId, trackNumber);
      await updateSessionStatus();
    } catch (error) {
      console.error('Error removing track:', error);
    }
  };

  const updateTrackSettings = async (trackNumber, settings) => {
    if (!currentSession) return;

    try {
      await window.electronAPI.audio.updateTrackSettings(currentSession.sessionId, trackNumber, settings);
      await updateSessionStatus();
    } catch (error) {
      console.error('Error updating track settings:', error);
    }
  };

  const startRecording = async () => {
    if (!currentSession || tracks.length === 0) {
      alert('Please add at least one track before recording');
      return;
    }

    try {
      await window.electronAPI.audio.startRecording(currentSession.sessionId);
    } catch (error) {
      console.error('Error starting recording:', error);
    }
  };

  const stopRecording = async () => {
    if (!currentSession) return;

    try {
      await window.electronAPI.audio.stopRecording(currentSession.sessionId);
    } catch (error) {
      console.error('Error stopping recording:', error);
    }
  };

  const requestSystemPermissions = async () => {
    try {
      const result = await window.electronAPI.audio.requestSystemAudioPermission();
      setSystemPermissions(result);
      
      if (result.granted) {
        // Refresh audio sources after permission granted
        await initializeAudio();
      }
    } catch (error) {
      console.error('Error requesting permissions:', error);
    }
  };

  const formatAudioLevel = (level) => {
    if (level === -Infinity || level === undefined) return '-∞';
    return `${level.toFixed(1)}dB`;
  };

  const getLevelColor = (level) => {
    if (level === -Infinity || level === undefined) return '#666';
    if (level > -6) return '#ef4444'; // Red (clipping)
    if (level > -12) return '#f59e0b'; // Orange (hot)
    if (level > -24) return '#10b981'; // Green (good)
    return '#6b7280'; // Gray (quiet)
  };

  if (!isElectron) {
    return (
      <div className="multitrack-recorder">
        <div className="web-fallback-header">
          <h2>Multi-Track Audio Recording</h2>
          <div className="platform-notice">
            <p>🖥️ <strong>Desktop App:</strong> Full multi-track recording with system audio capture</p>
            <p>🌐 <strong>Web Version:</strong> Browser-based recording with limited capabilities</p>
          </div>
        </div>
        <WebAudioCapture />
      </div>
    );
  }

  return (
    <div className="multitrack-recorder">
      <div className="recorder-header">
        <h2>Multi-Track Audio Recording</h2>
        <div className="session-info">
          {currentSession ? (
            <span className="session-status">
              Session: {currentSession.sessionId?.substring(0, 8)}...
              {isRecording && <span className="recording-indicator">● REC</span>}
            </span>
          ) : (
            <span className="no-session">No active session</span>
          )}
        </div>
      </div>

      {/* System Permissions */}
      {!systemPermissions.granted && systemPermissions.required && (
        <div className="permission-notice">
          <div className="permission-content">
            <h4>System Audio Permission Required</h4>
            <p>To record system audio, additional permissions are needed.</p>
            <button onClick={requestSystemPermissions} className="permission-button">
              Grant Permissions
            </button>
          </div>
        </div>
      )}

      {/* Audio Sources */}
      <div className="audio-sources-section">
        <h3>Available Audio Sources</h3>
        <div className="sources-grid">
          {audioSources.map(source => (
            <div key={source.id} className="source-card">
              <div className="source-info">
                <div className="source-name">{source.name}</div>
                <div className="source-type">{source.type}</div>
                {source.isDefault && <span className="default-badge">Default</span>}
              </div>
              <button 
                onClick={() => addTrack(source.id)}
                className="add-track-button"
                disabled={tracks.some(t => t.sourceId === source.id)}
              >
                {tracks.some(t => t.sourceId === source.id) ? 'Added' : 'Add Track'}
              </button>
            </div>
          ))}
        </div>
      </div>

      {/* Recording Tracks */}
      {tracks.length > 0 && (
        <div className="tracks-section">
          <h3>Recording Tracks</h3>
          <div className="tracks-container">
            {tracks.map(track => {
              const levelKey = `${currentSession?.sessionId}_${track.trackNumber}`;
              const levels = audioLevels[levelKey] || {};
              
              return (
                <div key={track.trackNumber} className="track-row">
                  <div className="track-number">{track.trackNumber}</div>
                  
                  <div className="track-info">
                    <div className="track-name">{track.sourceName}</div>
                    <div className="track-type">{track.sourceType}</div>
                  </div>

                  <div className="track-controls">
                    <button 
                      className={`control-button ${track.isEnabled ? 'enabled' : 'disabled'}`}
                      onClick={() => updateTrackSettings(track.trackNumber, { isEnabled: !track.isEnabled })}
                      title={track.isEnabled ? 'Disable Track' : 'Enable Track'}
                    >
                      {track.isEnabled ? '🔊' : '🔇'}
                    </button>
                    
                    <button 
                      className={`control-button ${track.isMuted ? 'muted' : ''}`}
                      onClick={() => updateTrackSettings(track.trackNumber, { isMuted: !track.isMuted })}
                      title={track.isMuted ? 'Unmute' : 'Mute'}
                    >
                      {track.isMuted ? '🔇' : '🔊'}
                    </button>
                    
                    <button 
                      className={`control-button ${track.isSolo ? 'solo' : ''}`}
                      onClick={() => updateTrackSettings(track.trackNumber, { isSolo: !track.isSolo })}
                      title={track.isSolo ? 'Unsolo' : 'Solo'}
                    >
                      S
                    </button>
                  </div>

                  <div className="track-levels">
                    <div className="level-meters">
                      <div className="level-meter">
                        <div className="level-label">Peak</div>
                        <div 
                          className="level-value"
                          style={{ color: getLevelColor(levels.peak) }}
                        >
                          {formatAudioLevel(levels.peak)}
                        </div>
                        <div 
                          className="level-bar"
                          style={{ 
                            width: `${Math.max(0, Math.min(100, (levels.peak + 60) * 100 / 60))}%`,
                            backgroundColor: getLevelColor(levels.peak)
                          }}
                        />
                      </div>
                      <div className="level-meter">
                        <div className="level-label">RMS</div>
                        <div 
                          className="level-value"
                          style={{ color: getLevelColor(levels.rms) }}
                        >
                          {formatAudioLevel(levels.rms)}
                        </div>
                        <div 
                          className="level-bar"
                          style={{ 
                            width: `${Math.max(0, Math.min(100, (levels.rms + 60) * 100 / 60))}%`,
                            backgroundColor: getLevelColor(levels.rms)
                          }}
                        />
                      </div>
                    </div>
                  </div>

                  <div className="track-actions">
                    <button 
                      onClick={() => removeTrack(track.trackNumber)}
                      className="remove-track-button"
                      disabled={isRecording}
                    >
                      ✕
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Recording Controls */}
      <div className="recording-controls">
        {!currentSession ? (
          <button onClick={createSession} className="session-button">
            Create Session
          </button>
        ) : (
          <div className="recording-buttons">
            {!isRecording ? (
              <button 
                onClick={startRecording} 
                className="record-button"
                disabled={tracks.length === 0}
              >
                ● Start Recording
              </button>
            ) : (
              <button onClick={stopRecording} className="stop-button">
                ⏹ Stop Recording
              </button>
            )}
          </div>
        )}
      </div>

      {/* Session Status */}
      {currentSession && (
        <div className="session-status-section">
          <h4>Session Status</h4>
          <div className="status-grid">
            <div className="status-item">
              <span className="status-label">Tracks:</span>
              <span className="status-value">{tracks.length}</span>
            </div>
            <div className="status-item">
              <span className="status-label">Recording:</span>
              <span className="status-value">{isRecording ? 'Yes' : 'No'}</span>
            </div>
            <div className="status-item">
              <span className="status-label">Session ID:</span>
              <span className="status-value">{currentSession.sessionId?.substring(0, 16)}...</span>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default MultiTrackRecorder;