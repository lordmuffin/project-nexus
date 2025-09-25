import React, { useState, useEffect, useRef, useCallback } from 'react';
import './MultiTrackPlayback.css';

const MultiTrackPlayback = ({ recording, onClose }) => {
  const [tracks, setTracks] = useState([]);
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(0);
  const [playbackSpeed, setPlaybackSpeed] = useState(1.0);
  const [volume, setVolume] = useState(1.0);
  const [trackSettings, setTrackSettings] = useState({});
  
  const audioContextRef = useRef(null);
  const trackBuffersRef = useRef({});
  const trackSourcesRef = useRef({});
  const trackGainsRef = useRef({});
  const masterGainRef = useRef(null);
  const playStartTimeRef = useRef(0);
  const playStartPositionRef = useRef(0);
  const animationFrameRef = useRef(null);

  // Initialize audio context and load tracks
  useEffect(() => {
    initializeAudio();
    loadTracks();
    
    return () => {
      cleanup();
    };
  }, [recording]);

  const initializeAudio = useCallback(() => {
    try {
      audioContextRef.current = new (window.AudioContext || window.webkitAudioContext)();
      masterGainRef.current = audioContextRef.current.createGain();
      masterGainRef.current.connect(audioContextRef.current.destination);
      
      console.log('Audio context initialized');
    } catch (error) {
      console.error('Error initializing audio context:', error);
    }
  }, []);

  const loadTracks = useCallback(async () => {
    if (!recording?.tracks) return;

    try {
      console.log('Loading tracks for recording:', recording.id);
      
      // Simulate track data (in production, this would come from the backend)
      const simulatedTracks = [
        {
          id: '1',
          trackNumber: 1,
          sourceName: 'Microphone',
          sourceType: 'microphone',
          filePath: '/recordings/track_1.wav',
          duration: 120, // 2 minutes
          isEnabled: true,
          volume: 1.0,
          isMuted: false,
          isSolo: false
        },
        {
          id: '2',
          trackNumber: 2,
          sourceName: 'System Audio',
          sourceType: 'system_output',
          filePath: '/recordings/track_2.wav',
          duration: 120,
          isEnabled: true,
          volume: 0.8,
          isMuted: false,
          isSolo: false
        }
      ];

      setTracks(simulatedTracks);
      setDuration(Math.max(...simulatedTracks.map(t => t.duration)));

      // Initialize track settings
      const settings = {};
      simulatedTracks.forEach(track => {
        settings[track.id] = {
          volume: track.volume,
          isMuted: track.isMuted,
          isSolo: track.isSolo,
          isEnabled: track.isEnabled
        };
      });
      setTrackSettings(settings);

      // In production, load actual audio files
      await loadAudioFiles(simulatedTracks);
      
    } catch (error) {
      console.error('Error loading tracks:', error);
    }
  }, [recording]);

  const loadAudioFiles = async (trackList) => {
    // In production, this would load actual audio files
    // For now, we'll simulate the loading process
    
    try {
      for (const track of trackList) {
        console.log(`Loading audio file for track ${track.trackNumber}: ${track.filePath}`);
        
        // Create gain node for each track
        const gainNode = audioContextRef.current.createGain();
        gainNode.connect(masterGainRef.current);
        trackGainsRef.current[track.id] = gainNode;
        
        // In production, fetch and decode the actual audio file:
        // const response = await fetch(track.filePath);
        // const arrayBuffer = await response.arrayBuffer();
        // const audioBuffer = await audioContextRef.current.decodeAudioData(arrayBuffer);
        // trackBuffersRef.current[track.id] = audioBuffer;
        
        // For demo, create silent buffer
        const buffer = audioContextRef.current.createBuffer(
          2, // stereo
          audioContextRef.current.sampleRate * track.duration,
          audioContextRef.current.sampleRate
        );
        trackBuffersRef.current[track.id] = buffer;
      }
      
      console.log('All audio files loaded');
    } catch (error) {
      console.error('Error loading audio files:', error);
    }
  };

  const play = useCallback(() => {
    if (!audioContextRef.current) return;

    try {
      // Resume audio context if suspended
      if (audioContextRef.current.state === 'suspended') {
        audioContextRef.current.resume();
      }

      setIsPlaying(true);
      playStartTimeRef.current = audioContextRef.current.currentTime;
      playStartPositionRef.current = currentTime;

      // Start playback for each enabled track
      tracks.forEach(track => {
        const settings = trackSettings[track.id];
        if (!settings || !settings.isEnabled || settings.isMuted) return;

        const source = audioContextRef.current.createBufferSource();
        source.buffer = trackBuffersRef.current[track.id];
        source.playbackRate.value = playbackSpeed;
        
        const gainNode = trackGainsRef.current[track.id];
        if (gainNode) {
          source.connect(gainNode);
          gainNode.gain.value = settings.volume;
        }

        source.start(0, currentTime);
        trackSourcesRef.current[track.id] = source;
      });

      // Update current time
      updatePlaybackPosition();
      
    } catch (error) {
      console.error('Error starting playback:', error);
    }
  }, [tracks, trackSettings, currentTime, playbackSpeed]);

  const pause = useCallback(() => {
    setIsPlaying(false);
    
    // Stop all playing sources
    Object.values(trackSourcesRef.current).forEach(source => {
      try {
        source.stop();
      } catch (error) {
        // Source may already be stopped
      }
    });
    trackSourcesRef.current = {};

    // Cancel animation frame
    if (animationFrameRef.current) {
      cancelAnimationFrame(animationFrameRef.current);
    }
  }, []);

  const stop = useCallback(() => {
    pause();
    setCurrentTime(0);
    playStartPositionRef.current = 0;
  }, [pause]);

  const seek = useCallback((time) => {
    const wasPlaying = isPlaying;
    
    if (isPlaying) {
      pause();
    }
    
    setCurrentTime(Math.max(0, Math.min(duration, time)));
    
    if (wasPlaying) {
      // Restart playback from new position
      setTimeout(() => play(), 50);
    }
  }, [isPlaying, duration, pause, play]);

  const updatePlaybackPosition = useCallback(() => {
    if (!isPlaying || !audioContextRef.current) return;

    const elapsed = (audioContextRef.current.currentTime - playStartTimeRef.current) * playbackSpeed;
    const newTime = playStartPositionRef.current + elapsed;

    if (newTime >= duration) {
      stop();
      return;
    }

    setCurrentTime(newTime);
    animationFrameRef.current = requestAnimationFrame(updatePlaybackPosition);
  }, [isPlaying, playbackSpeed, duration, stop]);

  const updateTrackSetting = useCallback((trackId, setting, value) => {
    setTrackSettings(prev => ({
      ...prev,
      [trackId]: {
        ...prev[trackId],
        [setting]: value
      }
    }));

    // Apply setting immediately if playing
    if (setting === 'volume' && trackGainsRef.current[trackId]) {
      trackGainsRef.current[trackId].gain.value = value;
    }
  }, []);

  const updateMasterVolume = useCallback((newVolume) => {
    setVolume(newVolume);
    if (masterGainRef.current) {
      masterGainRef.current.gain.value = newVolume;
    }
  }, []);

  const updatePlaybackSpeed = useCallback((speed) => {
    setPlaybackSpeed(speed);
    
    // If playing, restart with new speed
    if (isPlaying) {
      const wasPlaying = isPlaying;
      pause();
      if (wasPlaying) {
        setTimeout(() => play(), 50);
      }
    }
  }, [isPlaying, pause, play]);

  const cleanup = useCallback(() => {
    pause();
    
    if (audioContextRef.current) {
      audioContextRef.current.close();
    }
    
    trackBuffersRef.current = {};
    trackSourcesRef.current = {};
    trackGainsRef.current = {};
  }, [pause]);

  const formatTime = (seconds) => {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  const getTrackWaveformData = (track) => {
    // In production, this would generate actual waveform data from the audio buffer
    // For demo, generate fake waveform data
    const points = 100;
    const data = [];
    for (let i = 0; i < points; i++) {
      data.push(Math.random() * 0.8 + 0.1);
    }
    return data;
  };

  return (
    <div className="multitrack-playback">
      <div className="playback-header">
        <div className="playback-title">
          <h2>{recording?.title || 'Multi-Track Recording'}</h2>
          <button onClick={onClose} className="close-button">✕</button>
        </div>
        
        <div className="playback-info">
          <span className="track-count">{tracks.length} tracks</span>
          <span className="duration">{formatTime(duration)}</span>
        </div>
      </div>

      {/* Master Controls */}
      <div className="master-controls">
        <div className="transport-controls">
          <button onClick={stop} className="transport-button">
            ⏹
          </button>
          <button 
            onClick={isPlaying ? pause : play} 
            className="transport-button primary"
          >
            {isPlaying ? '⏸' : '▶'}
          </button>
        </div>

        <div className="time-display">
          <span className="current-time">{formatTime(currentTime)}</span>
          <span className="separator">/</span>
          <span className="total-time">{formatTime(duration)}</span>
        </div>

        <div className="master-volume">
          <label>Master</label>
          <input
            type="range"
            min="0"
            max="1"
            step="0.01"
            value={volume}
            onChange={(e) => updateMasterVolume(parseFloat(e.target.value))}
            className="volume-slider"
          />
          <span className="volume-value">{Math.round(volume * 100)}%</span>
        </div>

        <div className="playback-speed">
          <label>Speed</label>
          <select 
            value={playbackSpeed} 
            onChange={(e) => updatePlaybackSpeed(parseFloat(e.target.value))}
            className="speed-select"
          >
            <option value="0.5">0.5x</option>
            <option value="0.75">0.75x</option>
            <option value="1.0">1.0x</option>
            <option value="1.25">1.25x</option>
            <option value="1.5">1.5x</option>
            <option value="2.0">2.0x</option>
          </select>
        </div>
      </div>

      {/* Timeline */}
      <div className="timeline-container">
        <div className="timeline-markers">
          {Array.from({ length: Math.ceil(duration / 10) + 1 }, (_, i) => (
            <div key={i} className="timeline-marker">
              <span className="marker-time">{formatTime(i * 10)}</span>
            </div>
          ))}
        </div>
        
        <div 
          className="timeline-track"
          onClick={(e) => {
            const rect = e.currentTarget.getBoundingClientRect();
            const percent = (e.clientX - rect.left) / rect.width;
            seek(percent * duration);
          }}
        >
          <div 
            className="timeline-progress"
            style={{ width: `${(currentTime / duration) * 100}%` }}
          />
          <div 
            className="timeline-playhead"
            style={{ left: `${(currentTime / duration) * 100}%` }}
          />
        </div>
      </div>

      {/* Track List */}
      <div className="tracks-list">
        {tracks.map(track => {
          const settings = trackSettings[track.id] || {};
          const waveformData = getTrackWaveformData(track);
          
          return (
            <div key={track.id} className="track-item">
              <div className="track-header">
                <div className="track-info">
                  <div className="track-number">{track.trackNumber}</div>
                  <div className="track-details">
                    <div className="track-name">{track.sourceName}</div>
                    <div className="track-type">{track.sourceType}</div>
                  </div>
                </div>

                <div className="track-controls">
                  <button 
                    className={`control-btn ${settings.isMuted ? 'muted' : ''}`}
                    onClick={() => updateTrackSetting(track.id, 'isMuted', !settings.isMuted)}
                    title={settings.isMuted ? 'Unmute' : 'Mute'}
                  >
                    {settings.isMuted ? '🔇' : '🔊'}
                  </button>
                  
                  <button 
                    className={`control-btn ${settings.isSolo ? 'solo' : ''}`}
                    onClick={() => updateTrackSetting(track.id, 'isSolo', !settings.isSolo)}
                    title={settings.isSolo ? 'Unsolo' : 'Solo'}
                  >
                    S
                  </button>

                  <div className="volume-control">
                    <input
                      type="range"
                      min="0"
                      max="1"
                      step="0.01"
                      value={settings.volume || 1}
                      onChange={(e) => updateTrackSetting(track.id, 'volume', parseFloat(e.target.value))}
                      className="track-volume-slider"
                    />
                    <span className="volume-label">{Math.round((settings.volume || 1) * 100)}%</span>
                  </div>
                </div>
              </div>

              <div className="track-waveform">
                <div className="waveform-container">
                  {waveformData.map((amplitude, i) => (
                    <div
                      key={i}
                      className="waveform-bar"
                      style={{
                        height: `${amplitude * 100}%`,
                        backgroundColor: settings.isMuted ? '#ccc' : 
                                       settings.isSolo ? '#8b5cf6' : '#3b82f6'
                      }}
                    />
                  ))}
                  <div 
                    className="waveform-playhead"
                    style={{ left: `${(currentTime / duration) * 100}%` }}
                  />
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Track Actions */}
      <div className="track-actions">
        <button className="action-button">
          Export Individual Tracks
        </button>
        <button className="action-button">
          Export Master Mix
        </button>
        <button className="action-button">
          Generate Transcript
        </button>
      </div>
    </div>
  );
};

export default MultiTrackPlayback;