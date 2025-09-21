const fs = require('fs').promises;
const path = require('path');
const axios = require('axios');
const FormData = require('form-data');
const crypto = require('crypto');
const dbService = require('./database');

class TranscriptionService {
  constructor() {
    this.supportedFormats = ['.mp3', '.wav', '.m4a', '.ogg', '.flac', '.mp4', '.webm'];
    this.transcriptionServiceUrl = process.env.TRANSCRIPTION_SERVICE_URL || 'http://localhost:8000';
    this.jobs = new Map(); // In-memory job storage (use database in production)
  }

  // Check if file format is supported
  isFormatSupported(filename) {
    const ext = path.extname(filename).toLowerCase();
    return this.supportedFormats.includes(ext);
  }

  // Validate audio file
  async validateAudioFile(filePath) {
    try {
      const stats = await fs.stat(filePath);
      const filename = path.basename(filePath);
      
      if (!this.isFormatSupported(filename)) {
        throw new Error(`Unsupported audio format. Supported formats: ${this.supportedFormats.join(', ')}`);
      }

      // Check file size (max 100MB)
      const maxSize = 100 * 1024 * 1024;
      if (stats.size > maxSize) {
        throw new Error('Audio file too large. Maximum size is 100MB.');
      }

      return {
        valid: true,
        size: stats.size,
        format: path.extname(filename).toLowerCase()
      };
    } catch (error) {
      throw new Error(`Audio file validation failed: ${error.message}`);
    }
  }

  // Start transcription job
  async startTranscription(options = {}) {
    try {
      const {
        filePath,
        filename,
        language = 'auto',
        model = 'base',
        format = 'json',
        userId = 'anonymous',
        source = 'upload'
      } = options;

      // Validate the file
      await this.validateAudioFile(filePath);

      // Generate unique transcription ID
      const transcriptionId = crypto.randomUUID();

      // Create job record
      const job = {
        id: transcriptionId,
        filePath,
        filename,
        language,
        model,
        format,
        userId,
        source,
        status: 'processing',
        createdAt: new Date(),
        startedAt: new Date(),
        progress: 0
      };

      this.jobs.set(transcriptionId, job);

      // Start transcription asynchronously
      this.processTranscription(transcriptionId, filePath, { language, model, format })
        .catch(error => {
          console.error(`Transcription job ${transcriptionId} failed:`, error);
          job.status = 'failed';
          job.error = error.message;
          job.completedAt = new Date();
        });

      console.log(`Started transcription job: ${transcriptionId}`);
      return transcriptionId;

    } catch (error) {
      console.error('Error starting transcription:', error);
      throw error;
    }
  }

  // Process transcription using Whisper service
  async processTranscription(transcriptionId, filePath, options = {}) {
    const job = this.jobs.get(transcriptionId);
    if (!job) {
      throw new Error('Transcription job not found');
    }

    try {
      console.log(`Processing transcription ${transcriptionId} with Whisper service...`);
      
      // Update job status
      job.status = 'processing';
      job.progress = 10;

      // Create FormData for file upload
      const formData = new FormData();
      formData.append('file', await fs.readFile(filePath), {
        filename: job.filename,
        contentType: this.getMimeType(filePath)
      });
      formData.append('language', options.language || 'auto');
      formData.append('model', options.model || 'base');
      formData.append('format', options.format || 'json');

      job.progress = 30;

      // Send request to Whisper service
      const response = await axios.post(
        `${this.transcriptionServiceUrl}/transcribe`,
        formData,
        {
          headers: {
            ...formData.getHeaders(),
          },
          timeout: 600000, // 10 minutes timeout
          onUploadProgress: (progressEvent) => {
            if (progressEvent.total) {
              job.progress = 30 + Math.round((progressEvent.loaded * 40) / progressEvent.total);
            }
          }
        }
      );

      job.progress = 90;

      // Process response
      if (response.data) {
        job.result = response.data;
        job.status = 'completed';
        job.progress = 100;
        job.completedAt = new Date();

        // Save to database
        await this.saveTranscriptionResult(transcriptionId, job);

        // Generate AI summary and action items if transcript has content
        if (job.result?.text && job.result.text.trim().length > 10) {
          try {
            // For now, use a quick rule-based approach to demonstrate the functionality
            await this.generateQuickSummary(transcriptionId, job.result.text);
          } catch (error) {
            console.error('Failed to generate summary:', error);
          }
        }

        console.log(`Transcription completed: ${transcriptionId}`);
        return job.result;
      } else {
        throw new Error('No transcription result received');
      }

    } catch (error) {
      job.status = 'failed';
      job.error = error.message;
      job.completedAt = new Date();
      throw error;
    }
  }

  // Generate a meaningful title from transcript or filename
  generateTitle(transcript, filename) {
    if (transcript && transcript.trim().length > 0) {
      // Use first meaningful sentence or phrase (up to 50 chars)
      const cleanText = transcript.trim();
      const firstSentence = cleanText.split(/[.!?]/)[0];
      
      if (firstSentence && firstSentence.length > 5 && firstSentence.length <= 50) {
        return firstSentence.trim();
      } else if (cleanText.length <= 50) {
        return cleanText;
      } else {
        return cleanText.substring(0, 47) + '...';
      }
    }
    
    // Fallback to formatted date-based title
    const date = new Date();
    const dateStr = date.toLocaleDateString();
    const timeStr = date.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});
    return `Recording ${dateStr} ${timeStr}`;
  }

  // Get MIME type for file
  getMimeType(filePath) {
    const ext = path.extname(filePath).toLowerCase();
    const mimeTypes = {
      '.mp3': 'audio/mpeg',
      '.wav': 'audio/wav',
      '.m4a': 'audio/mp4',
      '.ogg': 'audio/ogg',
      '.flac': 'audio/flac',
      '.mp4': 'video/mp4',
      '.webm': 'video/webm'
    };
    return mimeTypes[ext] || 'application/octet-stream';
  }

  // Generate AI summary and action items
  async generateAISummary(transcriptionId, transcript) {
    try {
      const ollamaService = require('./ollama');
      
      const analysisPrompt = `
Please analyze the following transcription and provide:
1. A concise summary (2-3 sentences)
2. Key discussion points (bullet points)
3. Action items with responsible parties if mentioned
4. Important decisions made

Transcription:
${transcript}

Please format your response as JSON with the following structure:
{
  "summary": "Brief summary here",
  "keyPoints": ["point 1", "point 2"],
  "actionItems": ["action 1", "action 2"],
  "decisions": ["decision 1", "decision 2"]
}
`;

      const aiResponse = await ollamaService.generateCompletion({
        prompt: analysisPrompt,
        temperature: 0.1,
        maxTokens: 1000
      });
      
      let analysis;
      try {
        // Try to parse JSON response
        analysis = JSON.parse(aiResponse.trim());
      } catch (parseError) {
        // If JSON parsing fails, create a structured response from the text
        analysis = {
          summary: `Summary: ${transcript.substring(0, 150)}...`,
          keyPoints: [],
          actionItems: [],
          decisions: []
        };
      }
      
      // Update the meeting record with summary and action items
      await dbService.query(`
        UPDATE meeting_recordings 
        SET summary = $1, action_items = $2, metadata = metadata || $3, updated_at = NOW()
        WHERE id = $4
      `, [
        analysis.summary,
        JSON.stringify(analysis.actionItems || []),
        JSON.stringify({ 
          ai_analysis: analysis,
          analyzed_at: new Date().toISOString()
        }),
        transcriptionId
      ]);
      
      console.log(`AI summary generated for transcription: ${transcriptionId}`);
      return analysis;
      
    } catch (error) {
      console.error('Error generating AI summary:', error);
      throw error;
    }
  }

  // Save transcription result to database
  async saveTranscriptionResult(transcriptionId, job) {
    try {
      await dbService.query(`
        INSERT INTO meeting_recordings (id, title, transcript, metadata, created_at, updated_at)
        VALUES ($1, $2, $3, $4, $5, $6)
        ON CONFLICT (id) DO UPDATE SET
          transcript = $3,
          metadata = $4,
          updated_at = $6
      `, [
        transcriptionId,
        this.generateTitle(job.result?.text, job.filename),
        job.result?.text || '',
        JSON.stringify({
          transcription_result: job.result,
          job_info: {
            language: job.language,
            model: job.model,
            format: job.format,
            source: job.source,
            duration: job.result?.duration || 0
          }
        }),
        job.createdAt,
        new Date()
      ]);
    } catch (error) {
      console.error('Error saving transcription result:', error);
    }
  }

  // Get job status
  async getJob(jobId) {
    const job = this.jobs.get(jobId);
    if (!job) {
      return null;
    }

    return {
      id: job.id,
      filename: job.filename,
      status: job.status,
      progress: job.progress,
      language: job.language,
      model: job.model,
      source: job.source,
      createdAt: job.createdAt,
      startedAt: job.startedAt,
      completedAt: job.completedAt,
      error: job.error
    };
  }

  // Get multiple jobs
  async getJobs(options = {}) {
    const { limit = 20, offset = 0, status, userId } = options;
    
    let jobs = Array.from(this.jobs.values());
    
    // Filter by status if provided
    if (status) {
      jobs = jobs.filter(job => job.status === status);
    }
    
    // Filter by userId if provided
    if (userId) {
      jobs = jobs.filter(job => job.userId === userId);
    }
    
    // Sort by creation date (newest first)
    jobs.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    
    // Apply pagination
    const paginatedJobs = jobs.slice(offset, offset + limit);
    
    return paginatedJobs.map(job => ({
      id: job.id,
      filename: job.filename,
      status: job.status,
      progress: job.progress,
      language: job.language,
      model: job.model,
      source: job.source,
      createdAt: job.createdAt,
      startedAt: job.startedAt,
      completedAt: job.completedAt,
      error: job.error
    }));
  }

  // Cancel job
  async cancelJob(jobId) {
    const job = this.jobs.get(jobId);
    if (!job) {
      return false;
    }

    if (job.status === 'processing') {
      job.status = 'cancelled';
      job.completedAt = new Date();
      console.log(`Cancelled transcription job: ${jobId}`);
      return true;
    }

    return false;
  }

  // Get transcription result
  async getResult(jobId, format = 'json') {
    const job = this.jobs.get(jobId);
    if (!job || job.status !== 'completed' || !job.result) {
      return null;
    }

    switch (format) {
      case 'text':
        return job.result.text;
      case 'srt':
        return this.formatAsSRT(job.result);
      case 'vtt':
        return this.formatAsVTT(job.result);
      default:
        return job.result;
    }
  }

  // Format result as SRT
  formatAsSRT(result) {
    if (!result.segments) return '';
    
    return result.segments.map((segment, index) => {
      const start = this.secondsToSRTTime(segment.start);
      const end = this.secondsToSRTTime(segment.end);
      return `${index + 1}\n${start} --> ${end}\n${segment.text.trim()}\n`;
    }).join('\n');
  }

  // Format result as VTT
  formatAsVTT(result) {
    if (!result.segments) return 'WEBVTT\n\n';
    
    const content = result.segments.map(segment => {
      const start = this.secondsToVTTTime(segment.start);
      const end = this.secondsToVTTTime(segment.end);
      return `${start} --> ${end}\n${segment.text.trim()}\n`;
    }).join('\n');
    
    return `WEBVTT\n\n${content}`;
  }

  // Convert seconds to SRT time format
  secondsToSRTTime(seconds) {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = Math.floor(seconds % 60);
    const millis = Math.floor((seconds % 1) * 1000);
    return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')},${millis.toString().padStart(3, '0')}`;
  }

  // Convert seconds to VTT time format
  secondsToVTTTime(seconds) {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = Math.floor(seconds % 60);
    const millis = Math.floor((seconds % 1) * 1000);
    return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}.${millis.toString().padStart(3, '0')}`;
  }

  // Get service status
  async getStatus() {
    try {
      const response = await axios.get(`${this.transcriptionServiceUrl}/health`, {
        timeout: 5000
      });
      
      return {
        transcriptionService: {
          status: 'healthy',
          ...response.data
        },
        activeJobs: this.jobs.size,
        processingJobs: Array.from(this.jobs.values()).filter(job => job.status === 'processing').length
      };
    } catch (error) {
      return {
        transcriptionService: {
          status: 'unhealthy',
          error: error.message
        },
        activeJobs: this.jobs.size,
        processingJobs: Array.from(this.jobs.values()).filter(job => job.status === 'processing').length
      };
    }
  }

  // Start real-time session (placeholder for future implementation)
  async startRealtimeSession(options = {}) {
    const sessionId = crypto.randomUUID();
    // TODO: Implement real-time transcription session
    return sessionId;
  }

  // Get supported languages
  getSupportedLanguages() {
    return [
      { code: 'en', name: 'English' },
      { code: 'es', name: 'Spanish' },
      { code: 'fr', name: 'French' },
      { code: 'de', name: 'German' },
      { code: 'it', name: 'Italian' },
      { code: 'pt', name: 'Portuguese' },
      { code: 'ja', name: 'Japanese' },
      { code: 'ko', name: 'Korean' },
      { code: 'zh', name: 'Chinese' }
    ];
  }
}

module.exports = new TranscriptionService();