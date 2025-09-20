const express = require('express');
const multer = require('multer');
const path = require('path');
const router = express.Router();
const meetingsService = require('../services/meetings');
const transcriptionService = require('../services/transcription');

// Configure multer for file uploads
const upload = multer({
  dest: path.join(__dirname, '../../uploads/audio'),
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
      'audio/ogg'
    ];
    
    if (allowedMimes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type. Only audio files are allowed.'));
    }
  }
});

// Get all meetings
router.get('/', async (req, res) => {
  try {
    const { limit = 20, offset = 0, status, search } = req.query;
    
    const meetings = await meetingsService.getMeetings({
      limit: parseInt(limit),
      offset: parseInt(offset),
      status,
      search
    });
    
    res.json({
      success: true,
      data: meetings,
      pagination: {
        limit: parseInt(limit),
        offset: parseInt(offset),
        total: meetings.length
      }
    });
  } catch (error) {
    console.error('Error fetching meetings:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch meetings'
    });
  }
});

// Create a new meeting
router.post('/', async (req, res) => {
  try {
    const { title, description, participants = [], scheduledFor } = req.body;
    
    if (!title || title.trim().length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Meeting title is required'
      });
    }
    
    const meeting = await meetingsService.createMeeting({
      title: title.trim(),
      description: description?.trim() || '',
      participants,
      scheduledFor: scheduledFor ? new Date(scheduledFor) : null,
      status: 'scheduled',
      createdAt: new Date(),
      userId: req.user?.id || 'anonymous' // TODO: Implement user authentication
    });
    
    // Emit to all connected clients
    req.app.get('io').emit('meeting:created', meeting);
    
    res.status(201).json({
      success: true,
      data: meeting
    });
  } catch (error) {
    console.error('Error creating meeting:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to create meeting'
    });
  }
});

// Get a specific meeting
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const meeting = await meetingsService.getMeetingById(id);
    
    if (!meeting) {
      return res.status(404).json({
        success: false,
        error: 'Meeting not found'
      });
    }
    
    res.json({
      success: true,
      data: meeting
    });
  } catch (error) {
    console.error('Error fetching meeting:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch meeting'
    });
  }
});

// Update a meeting
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;
    
    const updatedMeeting = await meetingsService.updateMeeting(id, {
      ...updates,
      updatedAt: new Date()
    });
    
    if (!updatedMeeting) {
      return res.status(404).json({
        success: false,
        error: 'Meeting not found'
      });
    }
    
    // Emit update to all connected clients
    req.app.get('io').emit('meeting:updated', updatedMeeting);
    
    res.json({
      success: true,
      data: updatedMeeting
    });
  } catch (error) {
    console.error('Error updating meeting:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to update meeting'
    });
  }
});

// Start a meeting
router.post('/:id/start', async (req, res) => {
  try {
    const { id } = req.params;
    
    const meeting = await meetingsService.startMeeting(id);
    
    if (!meeting) {
      return res.status(404).json({
        success: false,
        error: 'Meeting not found'
      });
    }
    
    // Emit to all connected clients
    req.app.get('io').emit('meeting:started', meeting);
    
    res.json({
      success: true,
      data: meeting
    });
  } catch (error) {
    console.error('Error starting meeting:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to start meeting'
    });
  }
});

// End a meeting
router.post('/:id/end', async (req, res) => {
  try {
    const { id } = req.params;
    
    const meeting = await meetingsService.endMeeting(id);
    
    if (!meeting) {
      return res.status(404).json({
        success: false,
        error: 'Meeting not found'
      });
    }
    
    // Emit to all connected clients
    req.app.get('io').emit('meeting:ended', meeting);
    
    res.json({
      success: true,
      data: meeting
    });
  } catch (error) {
    console.error('Error ending meeting:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to end meeting'
    });
  }
});

// Upload audio recording for a meeting
router.post('/:id/audio', upload.single('audio'), async (req, res) => {
  try {
    const { id } = req.params;
    
    if (!req.file) {
      return res.status(400).json({
        success: false,
        error: 'Audio file is required'
      });
    }
    
    // Add audio file to meeting
    const meeting = await meetingsService.addAudioRecording(id, {
      filename: req.file.filename,
      originalName: req.file.originalname,
      mimetype: req.file.mimetype,
      size: req.file.size,
      path: req.file.path,
      uploadedAt: new Date()
    });
    
    if (!meeting) {
      return res.status(404).json({
        success: false,
        error: 'Meeting not found'
      });
    }
    
    // Start transcription process
    transcriptionService.transcribeAudio(req.file.path, id)
      .then(transcription => {
        req.app.get('io').emit('meeting:transcription_ready', {
          meetingId: id,
          transcription
        });
      })
      .catch(error => {
        console.error('Transcription failed:', error);
        req.app.get('io').emit('meeting:transcription_failed', {
          meetingId: id,
          error: error.message
        });
      });
    
    res.json({
      success: true,
      data: meeting,
      message: 'Audio uploaded successfully. Transcription in progress.'
    });
  } catch (error) {
    console.error('Error uploading audio:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to upload audio'
    });
  }
});

// Get meeting transcription
router.get('/:id/transcription', async (req, res) => {
  try {
    const { id } = req.params;
    const transcription = await meetingsService.getTranscription(id);
    
    if (!transcription) {
      return res.status(404).json({
        success: false,
        error: 'Transcription not found'
      });
    }
    
    res.json({
      success: true,
      data: transcription
    });
  } catch (error) {
    console.error('Error fetching transcription:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch transcription'
    });
  }
});

// Delete a meeting
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const deleted = await meetingsService.deleteMeeting(id);
    
    if (!deleted) {
      return res.status(404).json({
        success: false,
        error: 'Meeting not found'
      });
    }
    
    // Emit deletion to all connected clients
    req.app.get('io').emit('meeting:deleted', { id });
    
    res.json({
      success: true,
      message: 'Meeting deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting meeting:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to delete meeting'
    });
  }
});

module.exports = router;