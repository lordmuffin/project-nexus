const express = require('express');
const multer = require('multer');
const path = require('path');
const router = express.Router();
const meetingsService = require('../services/meetings');
const transcriptionService = require('../services/transcription');
const ollamaService = require('../services/ollama');

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
    
    const rawMeetings = await meetingsService.getMeetings({
      limit: parseInt(limit),
      offset: parseInt(offset),
      status,
      search
    });
    
    // Transform data to match frontend expectations
    const meetings = rawMeetings.map(meeting => {
      let actionItems = [];
      let metadata = {};
      
      // Safely parse action_items
      try {
        if (meeting.action_items && typeof meeting.action_items === 'string') {
          actionItems = JSON.parse(meeting.action_items);
        } else if (Array.isArray(meeting.action_items)) {
          actionItems = meeting.action_items;
        }
      } catch (e) {
        console.warn('Failed to parse action_items:', e);
        actionItems = [];
      }
      
      // Safely parse metadata
      try {
        if (meeting.metadata && typeof meeting.metadata === 'string') {
          metadata = JSON.parse(meeting.metadata);
        } else if (meeting.metadata && typeof meeting.metadata === 'object') {
          metadata = meeting.metadata;
        }
      } catch (e) {
        console.warn('Failed to parse metadata:', e);
        metadata = {};
      }
      
      return {
        id: meeting.id,
        title: meeting.title,
        transcript: meeting.transcript,
        summary: meeting.summary,
        actionItems: actionItems,
        segments: metadata?.transcription_result?.segments || [],
        duration: metadata?.transcription_result?.duration || 0,
        language: metadata?.transcription_result?.language || 'auto',
        createdAt: meeting.created_at,
        updatedAt: meeting.updated_at,
        // Additional metadata
        keyPoints: metadata?.ai_analysis?.keyPoints || [],
        decisions: metadata?.ai_analysis?.decisions || []
      };
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
    const rawMeeting = await meetingsService.getMeetingById(id);
    
    if (!rawMeeting) {
      return res.status(404).json({
        success: false,
        error: 'Meeting not found'
      });
    }
    
    // Transform data to match frontend expectations  
    let actionItems = [];
    let metadata = {};
    
    // Safely parse action_items
    try {
      if (rawMeeting.action_items && typeof rawMeeting.action_items === 'string') {
        actionItems = JSON.parse(rawMeeting.action_items);
      } else if (Array.isArray(rawMeeting.action_items)) {
        actionItems = rawMeeting.action_items;
      }
    } catch (e) {
      console.warn('Failed to parse action_items:', e);
      actionItems = [];
    }
    
    // Safely parse metadata
    try {
      if (rawMeeting.metadata && typeof rawMeeting.metadata === 'string') {
        metadata = JSON.parse(rawMeeting.metadata);
      } else if (rawMeeting.metadata && typeof rawMeeting.metadata === 'object') {
        metadata = rawMeeting.metadata;
      }
    } catch (e) {
      console.warn('Failed to parse metadata:', e);
      metadata = {};
    }
    
    const meeting = {
      id: rawMeeting.id,
      title: rawMeeting.title,
      transcript: rawMeeting.transcript,
      summary: rawMeeting.summary,
      actionItems: actionItems,
      segments: metadata?.transcription_result?.segments || [],
      duration: metadata?.transcription_result?.duration || 0,
      language: metadata?.transcription_result?.language || 'auto',
      createdAt: rawMeeting.created_at,
      updatedAt: rawMeeting.updated_at,
      keyPoints: metadata?.ai_analysis?.keyPoints || [],
      decisions: metadata?.ai_analysis?.decisions || []
    };
    
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

// Analyze meeting transcript with AI
router.post('/:id/analyze', async (req, res) => {
  try {
    const { id } = req.params;
    const { transcript } = req.body;
    
    if (!transcript || transcript.trim().length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Transcript content is required'
      });
    }
    
    // Generate AI summary and action items
    const analysisPrompt = `
Please analyze the following meeting transcript and provide:
1. A concise summary (2-3 sentences)
2. Key discussion points (bullet points)
3. Action items with responsible parties if mentioned
4. Important decisions made

Transcript:
${transcript}

Please format your response as JSON with the following structure:
{
  "summary": "Brief summary here",
  "keyPoints": ["point 1", "point 2", ...],
  "actionItems": ["action 1", "action 2", ...],
  "decisions": ["decision 1", "decision 2", ...]
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
        summary: aiResponse.substring(0, 200) + '...',
        keyPoints: [],
        actionItems: [],
        decisions: []
      };
    }
    
    // Save analysis to meeting record
    await meetingsService.updateMeeting(id, {
      summary: analysis.summary,
      actionItems: analysis.actionItems || [],
      keyPoints: analysis.keyPoints || [],
      decisions: analysis.decisions || [],
      analyzedAt: new Date()
    });
    
    // Emit to connected clients
    req.app.get('io').emit('meeting:analysis_complete', {
      meetingId: id,
      analysis
    });
    
    res.json({
      success: true,
      data: analysis
    });
  } catch (error) {
    console.error('Error analyzing meeting:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to analyze meeting transcript'
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