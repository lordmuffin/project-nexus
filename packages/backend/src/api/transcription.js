const express = require('express');
const multer = require('multer');
const path = require('path');
const router = express.Router();
const transcriptionService = require('../services/transcription');

// Helper function to get file extension from MIME type
function getExtensionFromMimeType(mimetype) {
  const mimeToExt = {
    'audio/wav': '.wav',
    'audio/mp3': '.mp3',
    'audio/mpeg': '.mp3',
    'audio/mp4': '.m4a',
    'audio/webm': '.webm',
    'audio/ogg': '.ogg',
    'video/mp4': '.mp4',
    'video/webm': '.webm'
  };
  return mimeToExt[mimetype] || '.unknown';
}

// Configure multer for audio uploads
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, path.join(__dirname, '../../uploads/temp'));
  },
  filename: function (req, file, cb) {
    // Preserve original extension or use appropriate one based on mimetype
    const ext = path.extname(file.originalname) || getExtensionFromMimeType(file.mimetype);
    cb(null, `${Date.now()}-${Math.round(Math.random() * 1E9)}${ext}`);
  }
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 100 * 1024 * 1024 // 100MB limit
  },
  fileFilter: (req, file, cb) => {
    const allowedMimes = [
      'audio/wav',
      'audio/mp3',
      'audio/mpeg',
      'audio/mp4',
      'audio/webm',
      'audio/ogg',
      'video/mp4',
      'video/webm'
    ];
    
    if (allowedMimes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type. Only audio and video files are allowed.'));
    }
  }
});

// Get transcription service status
router.get('/status', async (req, res) => {
  try {
    const status = await transcriptionService.getStatus();
    res.json({
      success: true,
      data: status
    });
  } catch (error) {
    console.error('Error checking transcription status:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to check transcription service status'
    });
  }
});

// Upload audio from mobile app for transcription
router.post('/upload', upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        error: 'Audio file is required'
      });
    }
    
    const { language = 'auto', model = 'base', format = 'json' } = req.body;
    
    // Start transcription
    const transcriptionId = await transcriptionService.startTranscription({
      filePath: req.file.path,
      filename: req.file.originalname,
      language,
      model,
      format,
      userId: req.user?.id || 'anonymous',
      source: 'mobile_upload'
    });
    
    // Notify connected clients via WebSocket
    const io = req.app.get('io');
    if (io) {
      io.emit('transcription_started', {
        transcriptionId,
        filename: req.file.originalname,
        timestamp: new Date().toISOString()
      });
    }
    
    res.status(202).json({
      success: true,
      data: {
        transcriptionId,
        status: 'processing',
        message: 'Audio uploaded and transcription started.'
      }
    });
  } catch (error) {
    console.error('Error uploading audio:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to upload audio for transcription'
    });
  }
});

// Transcribe audio file
router.post('/transcribe', upload.single('audio'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        error: 'Audio file is required'
      });
    }
    
    const { language = 'auto', model = 'base' } = req.body;
    
    // Start transcription
    const jobId = await transcriptionService.startTranscription({
      filePath: req.file.path,
      filename: req.file.originalname,
      language,
      model,
      userId: req.user?.id || 'anonymous'
    });
    
    res.status(202).json({
      success: true,
      data: {
        jobId,
        status: 'processing',
        message: 'Transcription started. Use the job ID to check progress.'
      }
    });
  } catch (error) {
    console.error('Error starting transcription:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to start transcription'
    });
  }
});

// Get transcription job status
router.get('/jobs/:jobId', async (req, res) => {
  try {
    const { jobId } = req.params;
    const job = await transcriptionService.getJob(jobId);
    
    if (!job) {
      return res.status(404).json({
        success: false,
        error: 'Transcription job not found'
      });
    }
    
    res.json({
      success: true,
      data: job
    });
  } catch (error) {
    console.error('Error fetching transcription job:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch transcription job'
    });
  }
});

// Get all transcription jobs
router.get('/jobs', async (req, res) => {
  try {
    const { limit = 20, offset = 0, status, userId } = req.query;
    
    const jobs = await transcriptionService.getJobs({
      limit: parseInt(limit),
      offset: parseInt(offset),
      status,
      userId
    });
    
    res.json({
      success: true,
      data: jobs,
      pagination: {
        limit: parseInt(limit),
        offset: parseInt(offset),
        total: jobs.length
      }
    });
  } catch (error) {
    console.error('Error fetching transcription jobs:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch transcription jobs'
    });
  }
});

// Cancel transcription job
router.delete('/jobs/:jobId', async (req, res) => {
  try {
    const { jobId } = req.params;
    const cancelled = await transcriptionService.cancelJob(jobId);
    
    if (!cancelled) {
      return res.status(404).json({
        success: false,
        error: 'Transcription job not found or cannot be cancelled'
      });
    }
    
    res.json({
      success: true,
      message: 'Transcription job cancelled successfully'
    });
  } catch (error) {
    console.error('Error cancelling transcription job:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to cancel transcription job'
    });
  }
});

// Get transcription result
router.get('/jobs/:jobId/result', async (req, res) => {
  try {
    const { jobId } = req.params;
    const { format = 'json' } = req.query;
    
    const result = await transcriptionService.getResult(jobId, format);
    
    if (!result) {
      return res.status(404).json({
        success: false,
        error: 'Transcription result not found or not ready'
      });
    }
    
    if (format === 'txt') {
      res.setHeader('Content-Type', 'text/plain');
      res.send(result);
    } else if (format === 'srt') {
      res.setHeader('Content-Type', 'text/plain');
      res.setHeader('Content-Disposition', `attachment; filename="transcription-${jobId}.srt"`);
      res.send(result);
    } else if (format === 'vtt') {
      res.setHeader('Content-Type', 'text/vtt');
      res.setHeader('Content-Disposition', `attachment; filename="transcription-${jobId}.vtt"`);
      res.send(result);
    } else {
      res.json({
        success: true,
        data: result
      });
    }
  } catch (error) {
    console.error('Error fetching transcription result:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch transcription result'
    });
  }
});

// Real-time transcription endpoint (WebSocket-based)
router.post('/realtime/start', async (req, res) => {
  try {
    const { language = 'auto', model = 'base' } = req.body;
    
    const sessionId = await transcriptionService.startRealtimeSession({
      language,
      model,
      userId: req.user?.id || 'anonymous'
    });
    
    res.json({
      success: true,
      data: {
        sessionId,
        websocketUrl: `/transcription/realtime/${sessionId}`,
        message: 'Real-time transcription session started'
      }
    });
  } catch (error) {
    console.error('Error starting real-time transcription:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to start real-time transcription'
    });
  }
});

// Get supported languages
router.get('/languages', (req, res) => {
  const supportedLanguages = [
    { code: 'auto', name: 'Auto-detect' },
    { code: 'en', name: 'English' },
    { code: 'es', name: 'Spanish' },
    { code: 'fr', name: 'French' },
    { code: 'de', name: 'German' },
    { code: 'it', name: 'Italian' },
    { code: 'pt', name: 'Portuguese' },
    { code: 'ru', name: 'Russian' },
    { code: 'ja', name: 'Japanese' },
    { code: 'ko', name: 'Korean' },
    { code: 'zh', name: 'Chinese' },
    { code: 'ar', name: 'Arabic' },
    { code: 'hi', name: 'Hindi' }
  ];
  
  res.json({
    success: true,
    data: supportedLanguages
  });
});

// Get available models
router.get('/models', (req, res) => {
  const availableModels = [
    { 
      name: 'tiny', 
      description: 'Fastest, least accurate',
      size: '39 MB',
      languages: ['en']
    },
    { 
      name: 'base', 
      description: 'Good balance of speed and accuracy',
      size: '74 MB',
      languages: ['multilingual']
    },
    { 
      name: 'small', 
      description: 'Better accuracy, slower',
      size: '244 MB',
      languages: ['multilingual']
    },
    { 
      name: 'medium', 
      description: 'Even better accuracy',
      size: '769 MB',
      languages: ['multilingual']
    },
    { 
      name: 'large', 
      description: 'Best accuracy, slowest',
      size: '1550 MB',
      languages: ['multilingual']
    }
  ];
  
  res.json({
    success: true,
    data: availableModels
  });
});

module.exports = router;