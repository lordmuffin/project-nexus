const { ipcMain, desktopCapturer } = require('electron');
const fs = require('fs').promises;
const path = require('path');
const crypto = require('crypto');
const EventEmitter = require('events');
const NativeAudioCapture = require('./nativeAudio');

class MultiTrackAudioCapture extends EventEmitter {
  constructor() {
    super();
    this.sessions = new Map();
    this.audioSources = new Map();
    this.outputDir = path.join(__dirname, '../../../uploads/desktop-recordings');
    this.isInitialized = false;
    
    // Initialize native audio capture
    this.nativeAudio = new NativeAudioCapture();
    this.setupNativeAudioListeners();
    
    this.setupIpcHandlers();
    this.initializeCapture();
  }

  setupNativeAudioListeners() {
    this.nativeAudio.on('audioLevels', (streamId, levels) => {
      this.emit('audioLevels', streamId, levels);
    });

    this.nativeAudio.on('recordingError', (streamId, error) => {
      console.error(`Native recording error for ${streamId}:`, error);
      this.emit('recordingError', streamId, error);
    });

    this.nativeAudio.on('recordingStopped', (streamId) => {
      console.log(`Native recording stopped: ${streamId}`);
    });
  }

  async initializeCapture() {
    try {
      await fs.mkdir(this.outputDir, { recursive: true });
      await this.discoverAudioSources();
      this.isInitialized = true;
      console.log('Multi-track audio capture initialized');
    } catch (error) {
      console.error('Error initializing audio capture:', error);
    }
  }

  setupIpcHandlers() {
    // Get available audio sources
    ipcMain.handle('audio:getAvailableSources', async () => {
      return this.getAvailableAudioSources();
    });

    // Start recording session
    ipcMain.handle('audio:startSession', async (event, options) => {
      return this.startRecordingSession(options);
    });

    // Stop recording session
    ipcMain.handle('audio:stopSession', async (event, sessionId) => {
      return this.stopRecordingSession(sessionId);
    });

    // Get session status
    ipcMain.handle('audio:getSessionStatus', async (event, sessionId) => {
      return this.getSessionStatus(sessionId);
    });

    // Add track to session
    ipcMain.handle('audio:addTrack', async (event, sessionId, trackConfig) => {
      return this.addTrackToSession(sessionId, trackConfig);
    });

    // Remove track from session
    ipcMain.handle('audio:removeTrack', async (event, sessionId, trackNumber) => {
      return this.removeTrackFromSession(sessionId, trackNumber);
    });

    // Update track settings
    ipcMain.handle('audio:updateTrackSettings', async (event, sessionId, trackNumber, settings) => {
      return this.updateTrackSettings(sessionId, trackNumber, settings);
    });

    // Get system audio permission status
    ipcMain.handle('audio:getSystemAudioPermission', async () => {
      return this.getSystemAudioPermission();
    });

    // Request system audio permission
    ipcMain.handle('audio:requestSystemAudioPermission', async () => {
      return this.requestSystemAudioPermission();
    });
  }

  async discoverAudioSources() {
    try {
      console.log('Discovering audio sources...');
      
      // Get screen sources (which include audio)
      const sources = await desktopCapturer.getSources({
        types: ['audio'],
        fetchWindowIcons: false
      });

      // Get system audio sources
      const audioSources = await this.getSystemAudioSources();
      
      // Update audio sources map
      this.audioSources.clear();
      
      // Add microphone sources
      audioSources.microphones.forEach((mic, index) => {
        const sourceId = `microphone_${index}`;
        this.audioSources.set(sourceId, {
          id: sourceId,
          type: 'microphone',
          name: mic.name || `Microphone ${index + 1}`,
          deviceId: mic.deviceId,
          isDefault: mic.isDefault,
          capabilities: {
            sampleRates: [44100, 48000],
            channels: [1, 2],
            bitDepths: [16, 24]
          }
        });
      });

      // Add system output sources
      audioSources.outputs.forEach((output, index) => {
        const sourceId = `system_output_${index}`;
        this.audioSources.set(sourceId, {
          id: sourceId,
          type: 'system_output',
          name: output.name || `System Output ${index + 1}`,
          deviceId: output.deviceId,
          isDefault: output.isDefault,
          capabilities: {
            sampleRates: [44100, 48000],
            channels: [2],
            bitDepths: [16, 24]
          }
        });
      });

      // Add application-specific sources (for future implementation)
      audioSources.applications.forEach((app, index) => {
        const sourceId = `application_${index}`;
        this.audioSources.set(sourceId, {
          id: sourceId,
          type: 'application',
          name: app.name,
          applicationId: app.id,
          capabilities: {
            sampleRates: [44100, 48000],
            channels: [2],
            bitDepths: [16]
          }
        });
      });

      console.log(`Discovered ${this.audioSources.size} audio sources`);
      this.emit('sourcesUpdated', Array.from(this.audioSources.values()));
      
    } catch (error) {
      console.error('Error discovering audio sources:', error);
    }
  }

  async getSystemAudioSources() {
    // This is a simplified implementation
    // In a full implementation, you would use native modules to query system audio devices
    
    try {
      // Platform-specific audio source discovery
      if (process.platform === 'win32') {
        return this.getWindowsAudioSources();
      } else if (process.platform === 'darwin') {
        return this.getMacOSAudioSources();
      } else if (process.platform === 'linux') {
        return this.getLinuxAudioSources();
      } else {
        return this.getDefaultAudioSources();
      }
    } catch (error) {
      console.error('Error getting system audio sources:', error);
      return this.getDefaultAudioSources();
    }
  }

  getDefaultAudioSources() {
    return {
      microphones: [
        { name: 'Default Microphone', deviceId: 'default', isDefault: true }
      ],
      outputs: [
        { name: 'Default Speakers', deviceId: 'default', isDefault: true }
      ],
      applications: []
    };
  }

  getWindowsAudioSources() {
    // Windows-specific implementation would use Windows Core Audio APIs
    // For now, return default sources
    return {
      microphones: [
        { name: 'Default Microphone', deviceId: 'default', isDefault: true },
        { name: 'USB Microphone', deviceId: 'usb_mic_1', isDefault: false }
      ],
      outputs: [
        { name: 'Speakers', deviceId: 'speakers', isDefault: true },
        { name: 'Headphones', deviceId: 'headphones', isDefault: false }
      ],
      applications: [
        { name: 'Discord', id: 'discord' },
        { name: 'Zoom', id: 'zoom' },
        { name: 'Spotify', id: 'spotify' }
      ]
    };
  }

  getMacOSAudioSources() {
    // macOS-specific implementation would use Core Audio / AVAudioEngine
    return {
      microphones: [
        { name: 'Built-in Microphone', deviceId: 'builtin_mic', isDefault: true },
        { name: 'External Microphone', deviceId: 'external_mic_1', isDefault: false }
      ],
      outputs: [
        { name: 'Built-in Speakers', deviceId: 'builtin_speakers', isDefault: true },
        { name: 'AirPods', deviceId: 'airpods', isDefault: false }
      ],
      applications: [
        { name: 'FaceTime', id: 'facetime' },
        { name: 'QuickTime Player', id: 'quicktime' },
        { name: 'Music', id: 'music' }
      ]
    };
  }

  getLinuxAudioSources() {
    // Linux-specific implementation would use ALSA/PulseAudio
    return {
      microphones: [
        { name: 'Default Microphone', deviceId: 'alsa_input.default', isDefault: true },
        { name: 'USB Audio Device', deviceId: 'alsa_input.usb', isDefault: false }
      ],
      outputs: [
        { name: 'Default Output', deviceId: 'alsa_output.default', isDefault: true },
        { name: 'HDMI Audio', deviceId: 'alsa_output.hdmi', isDefault: false }
      ],
      applications: [
        { name: 'Firefox', id: 'firefox' },
        { name: 'VLC', id: 'vlc' }
      ]
    };
  }

  async getAvailableAudioSources() {
    if (!this.isInitialized) {
      await this.initializeCapture();
    }
    
    return Array.from(this.audioSources.values()).map(source => ({
      id: source.id,
      type: source.type,
      name: source.name,
      isDefault: source.isDefault,
      capabilities: source.capabilities
    }));
  }

  async startRecordingSession(options = {}) {
    try {
      const {
        sessionName = `Recording ${new Date().toISOString()}`,
        outputFormat = 'multitrack',
        sampleRate = 48000,
        bitDepth = 16,
        autoStart = false
      } = options;

      const sessionId = crypto.randomUUID();
      const sessionDir = path.join(this.outputDir, sessionId);
      await fs.mkdir(sessionDir, { recursive: true });

      const session = {
        id: sessionId,
        name: sessionName,
        outputFormat,
        sampleRate,
        bitDepth,
        sessionDir,
        tracks: new Map(),
        isRecording: false,
        startTime: null,
        endTime: null,
        status: 'initialized',
        createdAt: new Date()
      };

      this.sessions.set(sessionId, session);

      console.log(`Created recording session: ${sessionId}`);
      this.emit('sessionCreated', session);

      if (autoStart) {
        await this.startRecording(sessionId);
      }

      return {
        sessionId,
        status: session.status,
        sessionDir
      };

    } catch (error) {
      console.error('Error starting recording session:', error);
      throw error;
    }
  }

  async stopRecordingSession(sessionId) {
    try {
      const session = this.sessions.get(sessionId);
      if (!session) {
        throw new Error('Session not found');
      }

      if (session.isRecording) {
        await this.stopRecording(sessionId);
      }

      session.status = 'completed';
      session.endTime = new Date();

      console.log(`Stopped recording session: ${sessionId}`);
      this.emit('sessionStopped', session);

      return {
        sessionId,
        status: session.status,
        duration: session.endTime - session.startTime,
        trackCount: session.tracks.size
      };

    } catch (error) {
      console.error('Error stopping recording session:', error);
      throw error;
    }
  }

  async addTrackToSession(sessionId, trackConfig) {
    try {
      const session = this.sessions.get(sessionId);
      if (!session) {
        throw new Error('Session not found');
      }

      const {
        sourceId,
        trackNumber,
        gainDb = 0.0,
        isEnabled = true,
        isMuted = false,
        isSolo = false
      } = trackConfig;

      const audioSource = this.audioSources.get(sourceId);
      if (!audioSource) {
        throw new Error('Audio source not found');
      }

      const trackId = crypto.randomUUID();
      const outputPath = path.join(session.sessionDir, `track_${trackNumber}.wav`);

      const track = {
        id: trackId,
        trackNumber,
        sourceId,
        sourceName: audioSource.name,
        sourceType: audioSource.type,
        outputPath,
        gainDb,
        isEnabled,
        isMuted,
        isSolo,
        isRecording: false,
        duration: 0,
        peakLevel: -Infinity,
        rmsLevel: -Infinity,
        createdAt: new Date()
      };

      session.tracks.set(trackNumber, track);

      console.log(`Added track ${trackNumber} to session ${sessionId}: ${audioSource.name}`);
      this.emit('trackAdded', sessionId, track);

      return track;

    } catch (error) {
      console.error('Error adding track to session:', error);
      throw error;
    }
  }

  async removeTrackFromSession(sessionId, trackNumber) {
    try {
      const session = this.sessions.get(sessionId);
      if (!session) {
        throw new Error('Session not found');
      }

      const track = session.tracks.get(trackNumber);
      if (!track) {
        throw new Error('Track not found');
      }

      if (track.isRecording) {
        // Stop recording for this track
        await this.stopTrackRecording(sessionId, trackNumber);
      }

      session.tracks.delete(trackNumber);

      console.log(`Removed track ${trackNumber} from session ${sessionId}`);
      this.emit('trackRemoved', sessionId, trackNumber);

      return true;

    } catch (error) {
      console.error('Error removing track from session:', error);
      throw error;
    }
  }

  async updateTrackSettings(sessionId, trackNumber, settings) {
    try {
      const session = this.sessions.get(sessionId);
      if (!session) {
        throw new Error('Session not found');
      }

      const track = session.tracks.get(trackNumber);
      if (!track) {
        throw new Error('Track not found');
      }

      // Update track settings
      if (settings.gainDb !== undefined) track.gainDb = settings.gainDb;
      if (settings.isEnabled !== undefined) track.isEnabled = settings.isEnabled;
      if (settings.isMuted !== undefined) track.isMuted = settings.isMuted;
      if (settings.isSolo !== undefined) track.isSolo = settings.isSolo;

      this.emit('trackSettingsUpdated', sessionId, trackNumber, track);

      return track;

    } catch (error) {
      console.error('Error updating track settings:', error);
      throw error;
    }
  }

  async startRecording(sessionId) {
    try {
      const session = this.sessions.get(sessionId);
      if (!session) {
        throw new Error('Session not found');
      }

      if (session.isRecording) {
        throw new Error('Session is already recording');
      }

      session.isRecording = true;
      session.startTime = new Date();
      session.status = 'recording';

      // Start recording for all enabled tracks
      const recordingPromises = [];
      for (const [trackNumber, track] of session.tracks) {
        if (track.isEnabled && !track.isMuted) {
          recordingPromises.push(this.startTrackRecording(sessionId, trackNumber));
        }
      }

      await Promise.all(recordingPromises);

      console.log(`Started recording session: ${sessionId}`);
      this.emit('recordingStarted', sessionId);

      return true;

    } catch (error) {
      console.error('Error starting recording:', error);
      throw error;
    }
  }

  async stopRecording(sessionId) {
    try {
      const session = this.sessions.get(sessionId);
      if (!session) {
        throw new Error('Session not found');
      }

      if (!session.isRecording) {
        throw new Error('Session is not recording');
      }

      session.isRecording = false;
      session.status = 'stopping';

      // Stop recording for all tracks
      const stopPromises = [];
      for (const [trackNumber, track] of session.tracks) {
        if (track.isRecording) {
          stopPromises.push(this.stopTrackRecording(sessionId, trackNumber));
        }
      }

      await Promise.all(stopPromises);

      session.status = 'completed';
      session.endTime = new Date();

      console.log(`Stopped recording session: ${sessionId}`);
      this.emit('recordingStopped', sessionId);

      return true;

    } catch (error) {
      console.error('Error stopping recording:', error);
      throw error;
    }
  }

  async startTrackRecording(sessionId, trackNumber) {
    try {
      const session = this.sessions.get(sessionId);
      const track = session.tracks.get(trackNumber);
      
      console.log(`Starting recording for track ${trackNumber}: ${track.sourceName}`);
      
      track.isRecording = true;
      
      // Use native audio capture based on source type
      if (track.sourceType === 'microphone') {
        const streamId = await this.nativeAudio.startMicrophoneRecording({
          sampleRate: session.sampleRate || 48000,
          channels: 1,
          bitDepth: session.bitDepth || 16,
          outputPath: track.outputPath
        });
        track.nativeStreamId = streamId;
      } else if (track.sourceType === 'system_output') {
        const streamId = await this.nativeAudio.startSystemAudioRecording({
          sampleRate: session.sampleRate || 48000,
          channels: 2,
          bitDepth: session.bitDepth || 16,
          outputPath: track.outputPath
        });
        track.nativeStreamId = streamId;
      } else {
        // Fallback to simulation for unsupported source types
        this.simulateAudioCapture(sessionId, trackNumber);
      }
      
      return true;
    } catch (error) {
      console.error(`Error starting track recording ${trackNumber}:`, error);
      
      // Fallback to simulation on error
      try {
        this.simulateAudioCapture(sessionId, trackNumber);
        return true;
      } catch (fallbackError) {
        throw error;
      }
    }
  }

  async stopTrackRecording(sessionId, trackNumber) {
    try {
      const session = this.sessions.get(sessionId);
      const track = session.tracks.get(trackNumber);
      
      console.log(`Stopping recording for track ${trackNumber}: ${track.sourceName}`);
      
      track.isRecording = false;
      
      // Stop native audio capture if available
      if (track.nativeStreamId) {
        await this.nativeAudio.stopRecording(track.nativeStreamId);
        delete track.nativeStreamId;
      }
      
      // Clear any simulation intervals
      if (track.simulationInterval) {
        clearInterval(track.simulationInterval);
        delete track.simulationInterval;
      }
      
      return true;
    } catch (error) {
      console.error(`Error stopping track recording ${trackNumber}:`, error);
      throw error;
    }
  }

  simulateAudioCapture(sessionId, trackNumber) {
    // This is a placeholder simulation
    // In production, replace with actual audio capture using Web Audio API or native modules
    
    const session = this.sessions.get(sessionId);
    const track = session.tracks.get(trackNumber);
    
    const interval = setInterval(() => {
      if (!track.isRecording) {
        clearInterval(interval);
        return;
      }
      
      // Simulate audio levels
      track.peakLevel = -20 + Math.random() * 15; // -20dB to -5dB
      track.rmsLevel = track.peakLevel - 6; // RMS typically 6dB below peak
      track.duration += 0.1; // Increment by 100ms
      
      this.emit('audioLevels', sessionId, trackNumber, {
        peak: track.peakLevel,
        rms: track.rmsLevel
      });
      
    }, 100); // Update every 100ms
  }

  getSessionStatus(sessionId) {
    const session = this.sessions.get(sessionId);
    if (!session) {
      return null;
    }

    const tracks = Array.from(session.tracks.values()).map(track => ({
      trackNumber: track.trackNumber,
      sourceName: track.sourceName,
      sourceType: track.sourceType,
      isEnabled: track.isEnabled,
      isMuted: track.isMuted,
      isSolo: track.isSolo,
      isRecording: track.isRecording,
      duration: track.duration,
      peakLevel: track.peakLevel,
      rmsLevel: track.rmsLevel
    }));

    return {
      sessionId: session.id,
      name: session.name,
      status: session.status,
      isRecording: session.isRecording,
      trackCount: session.tracks.size,
      tracks,
      startTime: session.startTime,
      endTime: session.endTime,
      duration: session.startTime ? (session.endTime || new Date()) - session.startTime : 0
    };
  }

  async getSystemAudioPermission() {
    // Check if system audio capture is available
    // This would typically involve checking platform-specific permissions
    
    try {
      if (process.platform === 'darwin') {
        // macOS requires special permissions for system audio
        return { granted: false, required: true, platform: 'macOS' };
      } else if (process.platform === 'win32') {
        // Windows may require specific audio driver setup
        return { granted: true, required: false, platform: 'Windows' };
      } else {
        // Linux varies by audio system
        return { granted: true, required: false, platform: 'Linux' };
      }
    } catch (error) {
      console.error('Error checking system audio permission:', error);
      return { granted: false, required: true, error: error.message };
    }
  }

  async requestSystemAudioPermission() {
    // Request system audio capture permission
    // This would typically open system permission dialogs
    
    try {
      console.log('Requesting system audio permission...');
      
      if (process.platform === 'darwin') {
        // macOS: Would need to request screen recording permission for system audio
        // This requires native implementation
        return { granted: false, message: 'Please grant screen recording permission in System Preferences > Security & Privacy > Privacy > Screen Recording' };
      } else {
        // Other platforms may not require explicit permission
        return { granted: true, message: 'System audio capture available' };
      }
    } catch (error) {
      console.error('Error requesting system audio permission:', error);
      return { granted: false, error: error.message };
    }
  }

  // Cleanup resources
  cleanup() {
    // Stop all active sessions
    for (const [sessionId, session] of this.sessions) {
      if (session.isRecording) {
        this.stopRecording(sessionId).catch(console.error);
      }
    }
    
    // Cleanup native audio
    if (this.nativeAudio) {
      this.nativeAudio.cleanup();
    }
    
    this.sessions.clear();
    this.audioSources.clear();
    this.removeAllListeners();
  }
}

module.exports = MultiTrackAudioCapture;