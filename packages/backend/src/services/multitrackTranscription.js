const fs = require('fs').promises;
const path = require('path');
const axios = require('axios');
const FormData = require('form-data');
const crypto = require('crypto');
const dbService = require('./database');
const transcriptionService = require('./transcription');

class MultiTrackTranscriptionService {
  constructor() {
    this.supportedFormats = ['.mp3', '.wav', '.m4a', '.ogg', '.flac', '.mp4', '.webm'];
    this.transcriptionServiceUrl = process.env.TRANSCRIPTION_SERVICE_URL || 'http://localhost:8000';
    this.jobs = new Map(); // Multi-track job storage
    this.outputDir = process.env.AUDIO_OUTPUT_DIR || path.join(__dirname, '../../uploads/multitrack');
  }

  // Ensure output directory exists
  async ensureOutputDirectory() {
    try {
      await fs.mkdir(this.outputDir, { recursive: true });
    } catch (error) {
      console.error('Error creating output directory:', error);
    }
  }

  // Start multi-track transcription session
  async startMultiTrackSession(options = {}) {
    try {
      const {
        sessionName,
        userId = 'anonymous',
        selectedTracks = [],
        syncReferenceTrack = 1,
        realTimeTranscription = false,
        outputFormat = 'multitrack'
      } = options;

      await this.ensureOutputDirectory();

      // Generate unique session ID
      const sessionId = crypto.randomUUID();
      const outputDirectory = path.join(this.outputDir, sessionId);
      await fs.mkdir(outputDirectory, { recursive: true });

      // Create session record in database
      await dbService.query(`
        INSERT INTO recording_sessions (
          id, user_id, session_name, recording_format, selected_tracks,
          output_directory, sync_reference_track, real_time_transcription
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      `, [
        sessionId,
        userId,
        sessionName || `Session ${new Date().toISOString()}`,
        outputFormat,
        JSON.stringify(selectedTracks),
        outputDirectory,
        syncReferenceTrack,
        realTimeTranscription
      ]);

      // Initialize job tracking
      const job = {
        id: sessionId,
        sessionName,
        userId,
        selectedTracks,
        outputDirectory,
        status: 'initialized',
        tracks: new Map(),
        masterMix: null,
        createdAt: new Date(),
        progress: 0
      };

      this.jobs.set(sessionId, job);
      console.log(`Created multi-track session: ${sessionId}`);
      
      return sessionId;

    } catch (error) {
      console.error('Error starting multi-track session:', error);
      throw error;
    }
  }

  // Add audio track to session
  async addTrackToSession(sessionId, trackOptions = {}) {
    try {
      const {
        trackNumber,
        sourceType,
        sourceName,
        filePath,
        deviceId = null,
        applicationName = null,
        isEnabled = true,
        gainDb = 0.0
      } = trackOptions;

      const job = this.jobs.get(sessionId);
      if (!job) {
        throw new Error('Session not found');
      }

      // Validate audio file
      await transcriptionService.validateAudioFile(filePath);
      
      // Get file stats
      const stats = await fs.stat(filePath);
      const audioInfo = await this.getAudioInfo(filePath);

      // Generate track ID
      const trackId = crypto.randomUUID();

      // Store track in database
      await dbService.query(`
        INSERT INTO audio_tracks (
          id, recording_id, track_number, source_type, source_name,
          device_id, application_name, file_path, duration_seconds,
          sample_rate, channels, bit_depth, file_size_bytes
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
      `, [
        trackId,
        sessionId,
        trackNumber,
        sourceType,
        sourceName,
        deviceId,
        applicationName,
        filePath,
        audioInfo.duration || 0,
        audioInfo.sampleRate || 48000,
        audioInfo.channels || 1,
        audioInfo.bitDepth || 16,
        stats.size
      ]);

      // Add track to job
      const trackData = {
        id: trackId,
        trackNumber,
        sourceType,
        sourceName,
        filePath,
        isEnabled,
        gainDb,
        status: 'ready',
        audioInfo,
        transcriptionResult: null
      };

      job.tracks.set(trackNumber, trackData);
      
      console.log(`Added track ${trackNumber} to session ${sessionId}: ${sourceName}`);
      return trackId;

    } catch (error) {
      console.error('Error adding track to session:', error);
      throw error;
    }
  }

  // Get basic audio information (placeholder - would use ffprobe in production)
  async getAudioInfo(filePath) {
    try {
      // This is a simplified implementation
      // In production, use ffprobe or similar tool for accurate audio metadata
      const stats = await fs.stat(filePath);
      const ext = path.extname(filePath).toLowerCase();
      
      return {
        duration: 0, // Would be extracted from audio file
        sampleRate: 48000, // Default assumption
        channels: ext === '.m4a' ? 2 : 1, // Guess based on format
        bitDepth: 16,
        codec: this.getCodecFromExtension(ext),
        fileSize: stats.size
      };
    } catch (error) {
      console.error('Error getting audio info:', error);
      return {
        duration: 0,
        sampleRate: 48000,
        channels: 1,
        bitDepth: 16,
        codec: 'unknown',
        fileSize: 0
      };
    }
  }

  // Get codec from file extension
  getCodecFromExtension(ext) {
    const codecMap = {
      '.mp3': 'mp3',
      '.wav': 'pcm',
      '.m4a': 'aac',
      '.ogg': 'vorbis',
      '.flac': 'flac',
      '.mp4': 'aac',
      '.webm': 'opus'
    };
    return codecMap[ext] || 'unknown';
  }

  // Process multi-track transcription
  async processMultiTrackTranscription(sessionId, options = {}) {
    const job = this.jobs.get(sessionId);
    if (!job) {
      throw new Error('Session not found');
    }

    try {
      console.log(`Processing multi-track transcription for session: ${sessionId}`);
      
      job.status = 'processing';
      job.startedAt = new Date();

      const {
        transcribeAllTracks = false,
        primaryTrackNumber = 1,
        combineTranscripts = true,
        generateSpeakerDiarization = true
      } = options;

      // Update session status
      await dbService.query(`
        UPDATE recording_sessions 
        SET status = 'active', started_at = $1
        WHERE id = $2
      `, [job.startedAt, sessionId]);

      const transcriptionPromises = [];
      const tracksToTranscribe = [];

      // Determine which tracks to transcribe
      if (transcribeAllTracks) {
        // Transcribe all enabled tracks
        for (const [trackNumber, track] of job.tracks) {
          if (track.isEnabled && this.isVocalTrack(track.sourceType)) {
            tracksToTranscribe.push(track);
          }
        }
      } else {
        // Transcribe only primary track (usually microphone)
        const primaryTrack = job.tracks.get(primaryTrackNumber);
        if (primaryTrack && primaryTrack.isEnabled) {
          tracksToTranscribe.push(primaryTrack);
        }
      }

      // Process each track for transcription
      for (const track of tracksToTranscribe) {
        const transcriptionPromise = this.transcribeTrack(sessionId, track)
          .then(result => {
            track.transcriptionResult = result;
            track.status = 'transcribed';
            job.progress += Math.floor(80 / tracksToTranscribe.length);
          })
          .catch(error => {
            console.error(`Error transcribing track ${track.trackNumber}:`, error);
            track.status = 'transcription_failed';
            track.error = error.message;
          });
        
        transcriptionPromises.push(transcriptionPromise);
      }

      // Wait for all transcriptions to complete
      await Promise.all(transcriptionPromises);

      // Combine transcripts if requested
      let combinedTranscript = null;
      if (combineTranscripts && tracksToTranscribe.length > 1) {
        combinedTranscript = await this.combineTranscripts(tracksToTranscribe);
      } else if (tracksToTranscribe.length === 1) {
        combinedTranscript = tracksToTranscribe[0].transcriptionResult;
      }

      // Create master mix if multiple tracks
      if (job.tracks.size > 1) {
        await this.createMasterMix(sessionId);
        job.progress = 95;
      }

      // Save final results
      await this.saveFinalResults(sessionId, combinedTranscript);
      
      job.status = 'completed';
      job.completedAt = new Date();
      job.progress = 100;

      console.log(`Multi-track transcription completed: ${sessionId}`);
      return {
        sessionId,
        status: 'completed',
        trackCount: job.tracks.size,
        transcribedTracks: tracksToTranscribe.length,
        combinedTranscript
      };

    } catch (error) {
      job.status = 'failed';
      job.error = error.message;
      job.completedAt = new Date();
      
      await dbService.query(`
        UPDATE recording_sessions 
        SET status = 'failed', ended_at = $1
        WHERE id = $2
      `, [job.completedAt, sessionId]);

      console.error(`Multi-track transcription failed: ${sessionId}`, error);
      throw error;
    }
  }

  // Transcribe individual track
  async transcribeTrack(sessionId, track) {
    try {
      console.log(`Transcribing track ${track.trackNumber}: ${track.sourceName}`);
      
      // Use existing transcription service for individual track
      const transcriptionId = await transcriptionService.startTranscription({
        filePath: track.filePath,
        filename: path.basename(track.filePath),
        language: 'auto',
        model: 'base',
        userId: 'multitrack',
        source: 'multitrack'
      });

      // Wait for transcription to complete
      let result = null;
      let attempts = 0;
      const maxAttempts = 120; // 2 minutes timeout

      while (attempts < maxAttempts) {
        await new Promise(resolve => setTimeout(resolve, 1000)); // Wait 1 second
        result = await transcriptionService.getResult(transcriptionId);
        
        if (result) {
          break;
        }
        attempts++;
      }

      if (!result) {
        throw new Error('Transcription timeout');
      }

      // Update track with transcription result
      await dbService.query(`
        UPDATE audio_tracks 
        SET track_metadata = track_metadata || $1
        WHERE id = $2
      `, [
        JSON.stringify({ 
          transcription: result,
          transcribed_at: new Date().toISOString()
        }),
        track.id
      ]);

      return result;

    } catch (error) {
      console.error(`Error transcribing track ${track.trackNumber}:`, error);
      throw error;
    }
  }

  // Check if track type typically contains vocal content
  isVocalTrack(sourceType) {
    const vocalSources = ['microphone', 'line_input', 'usb_microphone'];
    return vocalSources.includes(sourceType);
  }

  // Combine transcripts from multiple tracks
  async combineTranscripts(tracks) {
    try {
      console.log(`Combining transcripts from ${tracks.length} tracks`);
      
      const transcripts = tracks
        .filter(track => track.transcriptionResult && track.transcriptionResult.text)
        .map(track => ({
          trackNumber: track.trackNumber,
          sourceName: track.sourceName,
          text: track.transcriptionResult.text,
          segments: track.transcriptionResult.segments || []
        }));

      if (transcripts.length === 0) {
        return null;
      }

      if (transcripts.length === 1) {
        return transcripts[0].text;
      }

      // Simple combination - in production would implement time-based merging
      const combinedText = transcripts
        .map(t => `[${t.sourceName}]: ${t.text}`)
        .join('\n\n');

      return {
        text: combinedText,
        tracks: transcripts,
        combinedAt: new Date().toISOString()
      };

    } catch (error) {
      console.error('Error combining transcripts:', error);
      throw error;
    }
  }

  // Create master audio mix (placeholder)
  async createMasterMix(sessionId) {
    try {
      console.log(`Creating master mix for session: ${sessionId}`);
      
      const job = this.jobs.get(sessionId);
      if (!job) {
        throw new Error('Session not found');
      }

      // This would use audio processing libraries like ffmpeg in production
      // For now, just create a placeholder file
      const masterMixPath = path.join(job.outputDirectory, 'master_mix.wav');
      
      // Placeholder: would actually mix all enabled tracks
      await fs.writeFile(masterMixPath, 'placeholder master mix');
      
      job.masterMix = masterMixPath;
      
      await dbService.query(`
        UPDATE recording_sessions 
        SET metadata = metadata || $1
        WHERE id = $2
      `, [
        JSON.stringify({ master_mix_path: masterMixPath }),
        sessionId
      ]);

      return masterMixPath;

    } catch (error) {
      console.error('Error creating master mix:', error);
      throw error;
    }
  }

  // Save final results to database
  async saveFinalResults(sessionId, combinedTranscript) {
    try {
      const job = this.jobs.get(sessionId);
      if (!job) {
        throw new Error('Session not found');
      }

      // Create meeting recording entry
      const recordingId = crypto.randomUUID();
      const title = job.sessionName || `Multi-track Recording ${new Date().toLocaleDateString()}`;
      
      await dbService.query(`
        INSERT INTO meeting_recordings (
          id, user_id, title, transcript, recording_format, total_tracks,
          tracks_file_path, master_mix_path, track_metadata, created_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
      `, [
        recordingId,
        job.userId,
        title,
        typeof combinedTranscript === 'string' ? combinedTranscript : combinedTranscript?.text || '',
        'multitrack',
        job.tracks.size,
        job.outputDirectory,
        job.masterMix,
        JSON.stringify({
          session_id: sessionId,
          tracks: Array.from(job.tracks.values()).map(track => ({
            trackNumber: track.trackNumber,
            sourceType: track.sourceType,
            sourceName: track.sourceName,
            hasTranscription: !!track.transcriptionResult
          }))
        }),
        job.createdAt
      ]);

      // Update session status
      await dbService.query(`
        UPDATE recording_sessions 
        SET status = 'completed', ended_at = $1
        WHERE id = $2
      `, [new Date(), sessionId]);

      console.log(`Saved final results for session: ${sessionId}`);
      return recordingId;

    } catch (error) {
      console.error('Error saving final results:', error);
      throw error;
    }
  }

  // Get session status
  async getSessionStatus(sessionId) {
    const job = this.jobs.get(sessionId);
    if (!job) {
      return null;
    }

    const trackStatuses = Array.from(job.tracks.values()).map(track => ({
      trackNumber: track.trackNumber,
      sourceName: track.sourceName,
      sourceType: track.sourceType,
      status: track.status,
      hasTranscription: !!track.transcriptionResult
    }));

    return {
      id: job.id,
      sessionName: job.sessionName,
      status: job.status,
      progress: job.progress,
      trackCount: job.tracks.size,
      tracks: trackStatuses,
      createdAt: job.createdAt,
      startedAt: job.startedAt,
      completedAt: job.completedAt,
      error: job.error
    };
  }

  // Get available audio sources
  async getAvailableAudioSources(deviceId = 'default') {
    try {
      const result = await dbService.query(`
        SELECT * FROM audio_sources 
        WHERE device_id = $1 AND is_available = true
        ORDER BY source_type, source_name
      `, [deviceId]);

      return result.rows;
    } catch (error) {
      console.error('Error getting available audio sources:', error);
      return [];
    }
  }

  // Update audio source availability
  async updateAudioSourceAvailability(sources) {
    try {
      // Mark all sources as unavailable first
      await dbService.query(`
        UPDATE audio_sources SET is_available = false, last_detected = NOW()
      `);

      // Update or insert current sources
      for (const source of sources) {
        await dbService.query(`
          INSERT INTO audio_sources (
            device_id, source_type, source_name, display_name, 
            is_system_source, is_available, capabilities
          ) VALUES ($1, $2, $3, $4, $5, $6, $7)
          ON CONFLICT (device_id, source_type, source_name)
          DO UPDATE SET 
            is_available = true,
            last_detected = NOW(),
            capabilities = $7
        `, [
          source.deviceId,
          source.sourceType,
          source.sourceName,
          source.displayName,
          source.isSystemSource,
          true,
          JSON.stringify(source.capabilities || {})
        ]);
      }

      console.log(`Updated availability for ${sources.length} audio sources`);
    } catch (error) {
      console.error('Error updating audio source availability:', error);
    }
  }
}

module.exports = new MultiTrackTranscriptionService();