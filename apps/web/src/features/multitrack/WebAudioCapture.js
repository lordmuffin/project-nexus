import React, { useState, useEffect, useRef, useCallback } from 'react';
import './WebAudioCapture.css';

const WebAudioCapture = () => {
  const [isSupported, setIsSupported] = useState(false);
  const [availableSources, setAvailableSources] = useState([]);
  const [selectedSources, setSelectedSources] = useState(new Set());
  const [isRecording, setIsRecording] = useState(false);
  const [recordings, setRecordings] = useState([]);
  const [audioLevels, setAudioLevels] = useState({});
  const [permissions, setPermissions] = useState({
    microphone: false,
    screen: false
  });

  const mediaRecordersRef = useRef({});
  const audioContextRef = useRef(null);
  const analyserNodesRef = useRef({});
  const animationFrameRef = useRef(null);
  const recordedChunksRef = useRef({});

  // Check browser support
  useEffect(() => {
    checkBrowserSupport();
    initializeAudioContext();
  }, []);

  const checkBrowserSupport = () => {
    const hasGetUserMedia = !!(navigator.mediaDevices && navigator.mediaDevices.getUserMedia);
    const hasGetDisplayMedia = !!(navigator.mediaDevices && navigator.mediaDevices.getDisplayMedia);
    const hasMediaRecorder = !!(window.MediaRecorder);
    const hasAudioContext = !!(window.AudioContext || window.webkitAudioContext);

    const supported = hasGetUserMedia && hasGetDisplayMedia && hasMediaRecorder && hasAudioContext;
    setIsSupported(supported);

    if (supported) {
      discoverAudioSources();
    }

    console.log('Browser support check:', {
      getUserMedia: hasGetUserMedia,
      getDisplayMedia: hasGetDisplayMedia,
      MediaRecorder: hasMediaRecorder,
      AudioContext: hasAudioContext,
      supported
    });
  };

  const initializeAudioContext = () => {
    try {
      audioContextRef.current = new (window.AudioContext || window.webkitAudioContext)();
      console.log('Audio context initialized');
    } catch (error) {
      console.error('Error initializing audio context:', error);
    }
  };

  const discoverAudioSources = async () => {
    try {
      // Check microphone permission
      try {
        const micStream = await navigator.mediaDevices.getUserMedia({ audio: true });
        micStream.getTracks().forEach(track => track.stop());
        setPermissions(prev => ({ ...prev, microphone: true }));
      } catch (error) {
        console.log('Microphone permission not granted');
      }

      // Get available audio input devices
      const devices = await navigator.mediaDevices.enumerateDevices();
      const audioInputs = devices.filter(device => device.kind === 'audioinput');

      const sources = [
        ...audioInputs.map((device, index) => ({
          id: `microphone_${device.deviceId}`,
          type: 'microphone',
          name: device.label || `Microphone ${index + 1}`,
          deviceId: device.deviceId,
          isDefault: device.deviceId === 'default'
        })),
        {
          id: 'screen_audio',
          type: 'screen_audio',
          name: 'System Audio (Screen Capture)',
          description: 'Capture system audio via screen sharing'
        }
      ];

      setAvailableSources(sources);
      console.log('Discovered audio sources:', sources);

    } catch (error) {
      console.error('Error discovering audio sources:', error);
    }
  };

  const requestMicrophoneAccess = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      stream.getTracks().forEach(track => track.stop());
      setPermissions(prev => ({ ...prev, microphone: true }));
      
      // Refresh device list with labels
      await discoverAudioSources();
      return true;
    } catch (error) {
      console.error('Error requesting microphone access:', error);
      return false;
    }
  };

  const requestScreenAudioAccess = async () => {
    try {
      const stream = await navigator.mediaDevices.getDisplayMedia({ 
        audio: true,
        video: true // Required for screen capture
      });
      
      // Stop the stream immediately, we just wanted to check permission
      stream.getTracks().forEach(track => track.stop());
      setPermissions(prev => ({ ...prev, screen: true }));
      return true;
    } catch (error) {
      console.error('Error requesting screen audio access:', error);
      return false;
    }
  };

  const toggleSource = (sourceId) => {
    setSelectedSources(prev => {
      const newSet = new Set(prev);
      if (newSet.has(sourceId)) {
        newSet.delete(sourceId);
      } else {
        newSet.add(sourceId);
      }
      return newSet;
    });
  };

  const startRecording = async () => {
    if (selectedSources.size === 0) {
      alert('Please select at least one audio source');
      return;
    }

    try {
      setIsRecording(true);
      recordedChunksRef.current = {};

      // Start recording for each selected source
      for (const sourceId of selectedSources) {
        await startSourceRecording(sourceId);
      }

      // Start audio level monitoring
      startAudioLevelMonitoring();

    } catch (error) {
      console.error('Error starting recording:', error);
      setIsRecording(false);
    }
  };

  const startSourceRecording = async (sourceId) => {
    try {
      const source = availableSources.find(s => s.id === sourceId);
      if (!source) return;

      let stream;

      if (source.type === 'microphone') {
        // Get microphone stream
        stream = await navigator.mediaDevices.getUserMedia({
          audio: {
            deviceId: source.deviceId !== 'default' ? { exact: source.deviceId } : undefined,
            sampleRate: 48000,
            channelCount: 1,
            echoCancellation: false,
            noiseSuppression: false,
            autoGainControl: false
          }
        });
      } else if (source.type === 'screen_audio') {
        // Get screen capture stream with audio
        stream = await navigator.mediaDevices.getDisplayMedia({
          audio: {
            sampleRate: 48000,
            channelCount: 2,
            echoCancellation: false,
            noiseSuppression: false
          },
          video: {
            width: 1,
            height: 1,
            frameRate: 1
          }
        });

        // We only want the audio track
        const videoTracks = stream.getVideoTracks();
        videoTracks.forEach(track => {
          track.stop();
          stream.removeTrack(track);
        });
      }

      if (!stream || stream.getAudioTracks().length === 0) {
        throw new Error('No audio track available');
      }

      // Create MediaRecorder
      const mediaRecorder = new MediaRecorder(stream, {
        mimeType: 'audio/webm;codecs=opus'
      });

      recordedChunksRef.current[sourceId] = [];

      mediaRecorder.ondataavailable = (event) => {
        if (event.data.size > 0) {
          recordedChunksRef.current[sourceId].push(event.data);
        }
      };

      mediaRecorder.onstop = () => {
        const blob = new Blob(recordedChunksRef.current[sourceId], {
          type: 'audio/webm;codecs=opus'
        });
        
        const recording = {
          id: `${sourceId}_${Date.now()}`,
          sourceId,
          sourceName: source.name,
          sourceType: source.type,
          blob,
          url: URL.createObjectURL(blob),
          duration: 0, // Would be calculated in production
          timestamp: new Date()
        };

        setRecordings(prev => [...prev, recording]);
      };

      mediaRecorder.start(1000); // Collect data every second
      mediaRecordersRef.current[sourceId] = {
        mediaRecorder,
        stream,
        source
      };

      // Set up audio analysis
      setupAudioAnalysis(sourceId, stream);

      console.log(`Started recording for ${source.name}`);

    } catch (error) {
      console.error(`Error starting recording for ${sourceId}:`, error);
      throw error;
    }
  };

  const setupAudioAnalysis = (sourceId, stream) => {
    try {
      if (!audioContextRef.current) return;

      const audioContext = audioContextRef.current;
      const source = audioContext.createMediaStreamSource(stream);
      const analyser = audioContext.createAnalyser();
      
      analyser.fftSize = 256;
      analyser.smoothingTimeConstant = 0.8;
      
      source.connect(analyser);
      analyserNodesRef.current[sourceId] = analyser;

    } catch (error) {
      console.error('Error setting up audio analysis:', error);
    }
  };

  const startAudioLevelMonitoring = () => {
    const updateLevels = () => {
      if (!isRecording) return;

      const levels = {};
      
      for (const [sourceId, analyser] of Object.entries(analyserNodesRef.current)) {
        const dataArray = new Uint8Array(analyser.frequencyBinCount);
        analyser.getByteFrequencyData(dataArray);
        
        // Calculate RMS level
        let sum = 0;
        for (let i = 0; i < dataArray.length; i++) {
          sum += dataArray[i] * dataArray[i];
        }
        const rms = Math.sqrt(sum / dataArray.length);
        
        // Convert to dB (roughly)
        const db = rms > 0 ? 20 * Math.log10(rms / 255) : -Infinity;
        
        levels[sourceId] = {
          rms: db,
          peak: Math.max(...dataArray) > 0 ? 20 * Math.log10(Math.max(...dataArray) / 255) : -Infinity
        };
      }
      
      setAudioLevels(levels);
      animationFrameRef.current = requestAnimationFrame(updateLevels);
    };

    updateLevels();
  };

  const stopRecording = async () => {
    setIsRecording(false);

    // Stop audio level monitoring
    if (animationFrameRef.current) {
      cancelAnimationFrame(animationFrameRef.current);
    }

    // Stop all media recorders and streams
    for (const [sourceId, { mediaRecorder, stream }] of Object.entries(mediaRecordersRef.current)) {
      try {
        if (mediaRecorder.state !== 'inactive') {
          mediaRecorder.stop();
        }
        stream.getTracks().forEach(track => track.stop());
      } catch (error) {
        console.error(`Error stopping recording for ${sourceId}:`, error);
      }
    }

    // Clear references
    mediaRecordersRef.current = {};
    analyserNodesRef.current = {};
    setAudioLevels({});

    console.log('Recording stopped');
  };

  const downloadRecording = (recording) => {
    const link = document.createElement('a');
    link.href = recording.url;
    link.download = `${recording.sourceName}_${recording.timestamp.toISOString()}.webm`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const deleteRecording = (recordingId) => {
    setRecordings(prev => {
      const recording = prev.find(r => r.id === recordingId);
      if (recording) {
        URL.revokeObjectURL(recording.url);
      }
      return prev.filter(r => r.id !== recordingId);
    });
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

  if (!isSupported) {
    return (
      <div className="web-audio-capture">
        <div className="error-message">
          <h3>Browser Not Supported</h3>
          <p>Your browser doesn't support the required Web APIs for multi-track audio recording.</p>
          <p>Please use a modern browser like Chrome, Firefox, or Edge.</p>
          <div className="required-apis">
            <h4>Required APIs:</h4>
            <ul>
              <li>MediaDevices.getUserMedia()</li>
              <li>MediaDevices.getDisplayMedia()</li>
              <li>MediaRecorder</li>
              <li>Web Audio API</li>
            </ul>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="web-audio-capture">
      <div className="capture-header">
        <h2>Web Audio Recording</h2>
        <p>Record multiple audio sources simultaneously using web browser APIs</p>
      </div>

      {/* Permissions Section */}
      <div className="permissions-section">
        <h3>Permissions</h3>
        <div className="permission-grid">
          <div className="permission-item">
            <div className="permission-info">
              <span className="permission-name">Microphone Access</span>
              <span className={`permission-status ${permissions.microphone ? 'granted' : 'denied'}`}>
                {permissions.microphone ? '✅ Granted' : '❌ Not Granted'}
              </span>
            </div>
            {!permissions.microphone && (
              <button onClick={requestMicrophoneAccess} className="permission-button">
                Request Access
              </button>
            )}
          </div>
          
          <div className="permission-item">
            <div className="permission-info">
              <span className="permission-name">Screen Audio Access</span>
              <span className={`permission-status ${permissions.screen ? 'granted' : 'not-requested'}`}>
                {permissions.screen ? '✅ Granted' : '⚠️ Click to test'}
              </span>
            </div>
            <button onClick={requestScreenAudioAccess} className="permission-button">
              Test Access
            </button>
          </div>
        </div>
      </div>

      {/* Audio Sources */}
      <div className="sources-section">
        <h3>Audio Sources</h3>
        <div className="sources-grid">
          {availableSources.map(source => (
            <div key={source.id} className={`source-card ${selectedSources.has(source.id) ? 'selected' : ''}`}>
              <div className="source-info">
                <div className="source-name">{source.name}</div>
                <div className="source-type">{source.type}</div>
                {source.description && (
                  <div className="source-description">{source.description}</div>
                )}
                {source.isDefault && <span className="default-badge">Default</span>}
              </div>
              
              <div className="source-controls">
                <button
                  onClick={() => toggleSource(source.id)}
                  className={`select-button ${selectedSources.has(source.id) ? 'selected' : ''}`}
                  disabled={isRecording}
                >
                  {selectedSources.has(source.id) ? 'Selected' : 'Select'}
                </button>
                
                {isRecording && selectedSources.has(source.id) && (
                  <div className="audio-levels">
                    <div className="level-display">
                      <span className="level-label">Peak:</span>
                      <span 
                        className="level-value"
                        style={{ color: getLevelColor(audioLevels[source.id]?.peak) }}
                      >
                        {formatAudioLevel(audioLevels[source.id]?.peak)}
                      </span>
                    </div>
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Recording Controls */}
      <div className="recording-controls">
        {!isRecording ? (
          <button 
            onClick={startRecording}
            className="record-button"
            disabled={selectedSources.size === 0}
          >
            ● Start Recording
          </button>
        ) : (
          <button onClick={stopRecording} className="stop-button">
            ⏹ Stop Recording
          </button>
        )}
        
        {isRecording && (
          <div className="recording-status">
            <span className="recording-indicator">🔴 Recording {selectedSources.size} source(s)</span>
          </div>
        )}
      </div>

      {/* Recordings List */}
      {recordings.length > 0 && (
        <div className="recordings-section">
          <h3>Recorded Audio</h3>
          <div className="recordings-list">
            {recordings.map(recording => (
              <div key={recording.id} className="recording-item">
                <div className="recording-info">
                  <div className="recording-name">{recording.sourceName}</div>
                  <div className="recording-details">
                    <span className="recording-type">{recording.sourceType}</span>
                    <span className="recording-time">
                      {recording.timestamp.toLocaleTimeString()}
                    </span>
                  </div>
                </div>
                
                <div className="recording-controls">
                  <audio controls src={recording.url} />
                  <button 
                    onClick={() => downloadRecording(recording)}
                    className="download-button"
                  >
                    ⬇️ Download
                  </button>
                  <button 
                    onClick={() => deleteRecording(recording.id)}
                    className="delete-button"
                  >
                    🗑️ Delete
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Browser Limitations Notice */}
      <div className="limitations-notice">
        <h4>Browser Limitations</h4>
        <ul>
          <li>System audio capture requires screen sharing permission</li>
          <li>Recording quality depends on browser implementation</li>
          <li>Some browsers may not support all features</li>
          <li>For professional recording, use the desktop application</li>
        </ul>
      </div>
    </div>
  );
};

export default WebAudioCapture;