const EventEmitter = require('events');
const fs = require('fs');
const path = require('path');

class NativeAudioCapture extends EventEmitter {
  constructor() {
    super();
    this.isRecording = false;
    this.activeStreams = new Map();
    this.outputDir = null;
    
    // Try to load native audio modules
    this.initializeNativeModules();
  }

  initializeNativeModules() {
    try {
      // Try to load native audio recording module
      this.recorder = require('node-record-lpcm16');
      this.hasNativeRecording = true;
      console.log('Native audio recording module loaded successfully');
    } catch (error) {
      console.log('Native audio recording not available, using fallback methods');
      this.hasNativeRecording = false;
    }

    try {
      // Try to load speaker module for system audio monitoring
      this.Speaker = require('speaker');
      this.hasNativeSpeaker = true;
      console.log('Native speaker module loaded successfully');
    } catch (error) {
      console.log('Native speaker module not available');
      this.hasNativeSpeaker = false;
    }
  }

  // Start recording from microphone using native module
  async startMicrophoneRecording(options = {}) {
    if (!this.hasNativeRecording) {
      throw new Error('Native recording not available');
    }

    try {
      const {
        sampleRate = 48000,
        channels = 1,
        bitDepth = 16,
        device = null,
        outputPath
      } = options;

      console.log(`Starting microphone recording: ${outputPath}`);

      const recordingOptions = {
        sampleRate,
        channels,
        bitDepth,
        audioType: 'wav',
        device: device || 'default'
      };

      // Create recording stream
      const recording = this.recorder.record(recordingOptions);
      
      // Create output file stream
      const outputStream = fs.createWriteStream(outputPath);
      
      // Pipe recording to file
      recording.stream().pipe(outputStream);

      // Store stream reference
      const streamId = `microphone_${Date.now()}`;
      this.activeStreams.set(streamId, {
        type: 'microphone',
        recording,
        outputStream,
        outputPath,
        startTime: new Date()
      });

      // Emit audio level data
      recording.stream().on('data', (chunk) => {
        const levels = this.calculateAudioLevels(chunk, bitDepth);
        this.emit('audioLevels', streamId, levels);
      });

      recording.stream().on('error', (error) => {
        console.error('Recording error:', error);
        this.emit('recordingError', streamId, error);
      });

      console.log(`Microphone recording started: ${streamId}`);
      return streamId;

    } catch (error) {
      console.error('Error starting microphone recording:', error);
      throw error;
    }
  }

  // Start system audio recording (platform-specific)
  async startSystemAudioRecording(options = {}) {
    const { outputPath, platform = process.platform } = options;

    try {
      console.log(`Starting system audio recording on ${platform}: ${outputPath}`);

      if (platform === 'win32') {
        return this.startWindowsSystemAudio(options);
      } else if (platform === 'darwin') {
        return this.startMacOSSystemAudio(options);
      } else if (platform === 'linux') {
        return this.startLinuxSystemAudio(options);
      } else {
        throw new Error(`System audio recording not supported on ${platform}`);
      }
    } catch (error) {
      console.error('Error starting system audio recording:', error);
      throw error;
    }
  }

  // Windows system audio capture using loopback
  async startWindowsSystemAudio(options) {
    const { outputPath, sampleRate = 48000, channels = 2 } = options;
    
    try {
      // On Windows, use WASAPI loopback capture
      // This would require a native addon or external tool like SoundFlower
      
      // For now, use a placeholder implementation
      const streamId = `system_windows_${Date.now()}`;
      
      // In production, this would interface with Windows Core Audio APIs
      console.log('Windows system audio capture would be implemented here');
      
      // Create placeholder stream
      const stream = {
        type: 'system_audio',
        platform: 'windows',
        outputPath,
        startTime: new Date(),
        isActive: true
      };

      this.activeStreams.set(streamId, stream);
      
      // Simulate audio capture
      this.simulateSystemAudioCapture(streamId, outputPath);
      
      return streamId;
      
    } catch (error) {
      console.error('Error starting Windows system audio:', error);
      throw error;
    }
  }

  // macOS system audio capture using screen recording APIs
  async startMacOSSystemAudio(options) {
    const { outputPath, sampleRate = 48000, channels = 2 } = options;
    
    try {
      // On macOS, system audio requires screen recording permission
      // This would use AVFoundation and ScreenCaptureKit
      
      const streamId = `system_macos_${Date.now()}`;
      
      console.log('macOS system audio capture would be implemented here');
      console.log('Requires screen recording permission for system audio access');
      
      // Create placeholder stream
      const stream = {
        type: 'system_audio',
        platform: 'macos',
        outputPath,
        startTime: new Date(),
        isActive: true
      };

      this.activeStreams.set(streamId, stream);
      
      // Simulate audio capture
      this.simulateSystemAudioCapture(streamId, outputPath);
      
      return streamId;
      
    } catch (error) {
      console.error('Error starting macOS system audio:', error);
      throw error;
    }
  }

  // Linux system audio capture using PulseAudio/ALSA
  async startLinuxSystemAudio(options) {
    const { outputPath, sampleRate = 48000, channels = 2 } = options;
    
    try {
      // On Linux, use PulseAudio monitor sources or ALSA loopback
      
      const streamId = `system_linux_${Date.now()}`;
      
      console.log('Linux system audio capture would be implemented here');
      console.log('Would use PulseAudio parec or ALSA loopback device');
      
      // Create placeholder stream
      const stream = {
        type: 'system_audio',
        platform: 'linux',
        outputPath,
        startTime: new Date(),
        isActive: true
      };

      this.activeStreams.set(streamId, stream);
      
      // Simulate audio capture
      this.simulateSystemAudioCapture(streamId, outputPath);
      
      return streamId;
      
    } catch (error) {
      console.error('Error starting Linux system audio:', error);
      throw error;
    }
  }

  // Simulate audio capture for development/testing
  simulateSystemAudioCapture(streamId, outputPath) {
    console.log(`Simulating audio capture for ${streamId}`);
    
    const stream = this.activeStreams.get(streamId);
    if (!stream) return;

    // Create a simple WAV file header (placeholder)
    const sampleRate = 48000;
    const channels = 2;
    const bitDepth = 16;
    
    // Write WAV header
    const writeWAVHeader = (fileStream, sampleRate, channels, bitDepth) => {
      const headerBuffer = Buffer.alloc(44);
      
      // WAV file header
      headerBuffer.write('RIFF', 0);
      headerBuffer.writeUInt32LE(36, 4); // File size (will update later)
      headerBuffer.write('WAVE', 8);
      headerBuffer.write('fmt ', 12);
      headerBuffer.writeUInt32LE(16, 16); // PCM header size
      headerBuffer.writeUInt16LE(1, 20); // PCM format
      headerBuffer.writeUInt16LE(channels, 22);
      headerBuffer.writeUInt32LE(sampleRate, 24);
      headerBuffer.writeUInt32LE(sampleRate * channels * bitDepth / 8, 28); // Byte rate
      headerBuffer.writeUInt16LE(channels * bitDepth / 8, 32); // Block align
      headerBuffer.writeUInt16LE(bitDepth, 34);
      headerBuffer.write('data', 36);
      headerBuffer.writeUInt32LE(0, 40); // Data size (will update later)
      
      return headerBuffer;
    };

    try {
      const outputStream = fs.createWriteStream(outputPath);
      stream.outputStream = outputStream;
      
      // Write WAV header
      const header = writeWAVHeader(outputStream, sampleRate, channels, bitDepth);
      outputStream.write(header);
      
      // Simulate audio data generation
      const bytesPerSecond = sampleRate * channels * bitDepth / 8;
      const chunkSize = Math.floor(bytesPerSecond / 10); // 100ms chunks
      
      stream.simulationInterval = setInterval(() => {
        if (!stream.isActive) {
          clearInterval(stream.simulationInterval);
          return;
        }
        
        // Generate silent audio data (zeros)
        const audioData = Buffer.alloc(chunkSize);
        outputStream.write(audioData);
        
        // Calculate and emit mock audio levels
        const levels = {
          peak: -60 + Math.random() * 20, // -60dB to -40dB
          rms: -66 + Math.random() * 20
        };
        
        this.emit('audioLevels', streamId, levels);
        
      }, 100); // Update every 100ms
      
    } catch (error) {
      console.error('Error in simulation:', error);
    }
  }

  // Calculate audio levels from PCM data
  calculateAudioLevels(buffer, bitDepth = 16) {
    if (buffer.length === 0) {
      return { peak: -Infinity, rms: -Infinity };
    }

    let peak = 0;
    let sum = 0;
    const sampleCount = buffer.length / (bitDepth / 8);
    
    for (let i = 0; i < buffer.length; i += bitDepth / 8) {
      let sample;
      
      if (bitDepth === 16) {
        sample = buffer.readInt16LE(i);
        sample = sample / 32768; // Normalize to -1 to 1
      } else if (bitDepth === 24) {
        // 24-bit sample (3 bytes)
        sample = (buffer[i] | (buffer[i + 1] << 8) | (buffer[i + 2] << 16));
        if (sample > 0x7FFFFF) sample -= 0x1000000; // Convert to signed
        sample = sample / 8388608; // Normalize to -1 to 1
      } else {
        continue; // Unsupported bit depth
      }
      
      const absValue = Math.abs(sample);
      peak = Math.max(peak, absValue);
      sum += absValue * absValue;
    }
    
    const rms = Math.sqrt(sum / sampleCount);
    
    // Convert to dB
    const peakDb = peak > 0 ? 20 * Math.log10(peak) : -Infinity;
    const rmsDb = rms > 0 ? 20 * Math.log10(rms) : -Infinity;
    
    return {
      peak: peakDb,
      rms: rmsDb
    };
  }

  // Stop recording stream
  async stopRecording(streamId) {
    try {
      const stream = this.activeStreams.get(streamId);
      if (!stream) {
        throw new Error('Stream not found');
      }

      console.log(`Stopping recording: ${streamId}`);
      
      stream.isActive = false;
      
      if (stream.type === 'microphone' && stream.recording) {
        // Stop native recording
        stream.recording.stop();
      }
      
      if (stream.simulationInterval) {
        clearInterval(stream.simulationInterval);
      }
      
      if (stream.outputStream) {
        // Close output stream
        stream.outputStream.end();
      }
      
      stream.endTime = new Date();
      
      console.log(`Recording stopped: ${streamId}`);
      this.emit('recordingStopped', streamId);
      
      return true;
      
    } catch (error) {
      console.error('Error stopping recording:', error);
      throw error;
    }
  }

  // Stop all active recordings
  async stopAllRecordings() {
    const promises = [];
    
    for (const [streamId, stream] of this.activeStreams) {
      if (stream.isActive) {
        promises.push(this.stopRecording(streamId));
      }
    }
    
    await Promise.all(promises);
    this.activeStreams.clear();
  }

  // Get stream status
  getStreamStatus(streamId) {
    const stream = this.activeStreams.get(streamId);
    if (!stream) {
      return null;
    }
    
    return {
      id: streamId,
      type: stream.type,
      isActive: stream.isActive,
      outputPath: stream.outputPath,
      startTime: stream.startTime,
      endTime: stream.endTime,
      duration: stream.startTime ? (stream.endTime || new Date()) - stream.startTime : 0
    };
  }

  // Get all active streams
  getActiveStreams() {
    return Array.from(this.activeStreams.keys()).map(streamId => 
      this.getStreamStatus(streamId)
    ).filter(status => status && status.isActive);
  }

  // Check if native recording is available
  isNativeRecordingAvailable() {
    return this.hasNativeRecording;
  }

  // Get available recording devices (would query system in production)
  async getAvailableDevices() {
    // This would query actual system devices in production
    return {
      microphones: [
        { id: 'default', name: 'Default Microphone', isDefault: true },
        { id: 'usb_mic_1', name: 'USB Microphone', isDefault: false }
      ],
      systemOutputs: [
        { id: 'default_out', name: 'Default Output', isDefault: true },
        { id: 'speakers', name: 'Speakers', isDefault: false },
        { id: 'headphones', name: 'Headphones', isDefault: false }
      ]
    };
  }

  // Cleanup resources
  cleanup() {
    this.stopAllRecordings().catch(console.error);
    this.removeAllListeners();
  }
}

module.exports = NativeAudioCapture;