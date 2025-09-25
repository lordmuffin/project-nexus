const express = require('express');
const multer = require('multer');
const path = require('path');
const router = express.Router();
const meetingsService = require('../services/meetings');
const transcriptionService = require('../services/transcription');
const ollamaService = require('../services/ollama');
const aiProcessManager = require('../services/aiProcessManager');

// Configure multer for file uploads
const upload = multer({
  dest: '/tmp/nexus-uploads',
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
  let processId = null;
  const startTime = Date.now();
  
  try {
    const { id } = req.params;
    const { transcript, style = 'standard' } = req.body;
    
    if (!transcript || transcript.trim().length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Transcript content is required'
      });
    }
    
    // Estimate total time based on transcript length
    const transcriptLength = transcript.length;
    const baseTimeSeconds = 30;
    const timePerCharacter = 0.1;
    const totalEstimatedTime = Math.max(baseTimeSeconds, Math.min(300, baseTimeSeconds + (transcriptLength * timePerCharacter)));
    
    // Create AI process
    processId = aiProcessManager.createProcess(id, 'analysis', {
      style,
      transcriptLength,
      estimatedTime: totalEstimatedTime
    });
    
    console.log(`Starting AI analysis for meeting ${id} with style: ${style} (Process: ${processId})...`);
    
    // Start the process
    aiProcessManager.startProcess(processId);
    
    // Emit process started event
    req.app.get('io').emit('process:started', {
      processId,
      meetingId: id,
      process: aiProcessManager.getProcess(processId)
    });
    
    // Phase 1: Preparing analysis (0-25%)
    aiProcessManager.addLog(processId, 'info', `Starting analysis for meeting ${id} with style: ${style}`);
    aiProcessManager.addLog(processId, 'info', `Transcript length: ${transcriptLength} characters`);
    aiProcessManager.addLog(processId, 'info', `Estimated processing time: ${totalEstimatedTime} seconds`);
    
    aiProcessManager.updateProgress(processId, 10, 'preparing', 'Preparing analysis...', Math.round(totalEstimatedTime * 0.9));
    
    // Emit process progress event  
    req.app.get('io').emit('process:progress', {
      processId,
      meetingId: id,
      process: aiProcessManager.getProcess(processId)
    });
    
    req.app.get('io').emit('meeting:analysis_progress', {
      meetingId: id,
      phase: 'preparing',
      message: 'Preparing analysis...',
      progress: 10,
      estimatedTimeRemaining: Math.round(totalEstimatedTime * 0.9)
    });
    
    // Generate different prompts based on style
    let styleInstructions = '';
    switch (style) {
      case 'detailed':
        styleInstructions = 'Provide a comprehensive, detailed analysis with thorough explanations. Include more key points and elaborate on decisions.';
        break;
      case 'brief':
        styleInstructions = 'Keep the summary very concise and focus only on the most important points. Limit key points to 3-5 items.';
        break;
      case 'action-focused':
        styleInstructions = 'Focus heavily on action items and decisions. The summary should emphasize what needs to be done and what was decided.';
        break;
      default:
        styleInstructions = 'Provide a balanced analysis with clear, concise information.';
    }
    
    // Generate AI summary and action items with improved prompt
    const analysisPrompt = `
You are analyzing a meeting transcript. Please provide a structured analysis in valid JSON format.

STYLE: ${styleInstructions}

IMPORTANT: Respond ONLY with valid JSON. No additional text before or after.

Transcript:
${transcript}

Analyze and return this exact JSON structure:
{
  "summary": "Write a clear summary based on the requested style",
  "keyPoints": ["List", "key", "discussion", "points", "as", "separate", "strings"],
  "actionItems": ["List", "specific", "action", "items", "mentioned"],
  "decisions": ["List", "important", "decisions", "made"]
}
`;

    // Phase 2: Analyzing transcript (25-60%)
    aiProcessManager.addLog(processId, 'info', `Generated analysis prompt for ${style} style`);
    aiProcessManager.addLog(processId, 'info', 'Sending request to AI service (Ollama)...');
    
    aiProcessManager.updateProgress(processId, 35, 'analyzing', 'Analyzing transcript with AI...', Math.round(totalEstimatedTime * 0.6));
    
    // Emit process progress event
    req.app.get('io').emit('process:progress', {
      processId,
      meetingId: id,
      process: aiProcessManager.getProcess(processId)
    });
    
    req.app.get('io').emit('meeting:analysis_progress', {
      meetingId: id,
      phase: 'analyzing',
      message: 'Analyzing transcript with AI...',
      progress: 35,
      estimatedTimeRemaining: Math.round(totalEstimatedTime * 0.6)
    });

    const aiResponse = await ollamaService.generateCompletion({
      prompt: analysisPrompt,
      temperature: 0.1,
      maxTokens: 1000
    });
    
    aiProcessManager.addLog(processId, 'info', `Received AI response (${aiResponse.length} characters)`);
    
    // Phase 3: Extracting insights (60-85%)
    aiProcessManager.addLog(processId, 'info', 'Parsing AI response and extracting insights...');
    
    aiProcessManager.updateProgress(processId, 70, 'extracting', 'Extracting key insights...', Math.round(totalEstimatedTime * 0.3));
    
    // Emit process progress event
    req.app.get('io').emit('process:progress', {
      processId,
      meetingId: id,
      process: aiProcessManager.getProcess(processId)
    });
    
    req.app.get('io').emit('meeting:analysis_progress', {
      meetingId: id,
      phase: 'extracting',
      message: 'Extracting key insights...',
      progress: 70,
      estimatedTimeRemaining: Math.round(totalEstimatedTime * 0.3)
    });
    
    let analysis;
    let parseError = null;
    
    try {
      // Clean up the response and try to parse JSON
      aiProcessManager.addLog(processId, 'info', 'Attempting to parse JSON response from AI...');
      const cleanedResponse = aiResponse.trim()
        .replace(/^```json\s*/i, '')
        .replace(/\s*```$/i, '')
        .replace(/^[^{]*({.*})[^}]*$/s, '$1');
      
      analysis = JSON.parse(cleanedResponse);
      aiProcessManager.addLog(processId, 'info', 'Successfully parsed JSON response');
      
      // Validate the structure
      if (!analysis.summary) analysis.summary = 'Summary not available';
      if (!Array.isArray(analysis.keyPoints)) analysis.keyPoints = [];
      if (!Array.isArray(analysis.actionItems)) analysis.actionItems = [];
      if (!Array.isArray(analysis.decisions)) analysis.decisions = [];
      
      aiProcessManager.addLog(processId, 'info', `Extracted ${analysis.keyPoints.length} key points, ${analysis.actionItems.length} action items, ${analysis.decisions.length} decisions`);
      
    } catch (error) {
      parseError = error.message;
      aiProcessManager.addLog(processId, 'warn', `JSON parsing failed: ${error.message}. Using fallback parsing...`);
      console.warn('JSON parsing failed, creating fallback analysis:', error.message);
      
      // Extract information from raw text using simple patterns
      const lines = aiResponse.split('\n').filter(line => line.trim());
      const summary = lines.find(line => line.toLowerCase().includes('summary') || line.length > 50)?.trim() || 
                     transcript.substring(0, 200) + '...';
      
      analysis = {
        summary,
        keyPoints: lines.filter(line => 
          line.includes('•') || line.includes('-') || line.includes('*')
        ).map(line => line.replace(/^[•\-*\s]+/, '').trim()).slice(0, 5),
        actionItems: lines.filter(line => 
          line.toLowerCase().includes('action') || 
          line.toLowerCase().includes('todo') ||
          line.toLowerCase().includes('follow up')
        ).map(line => line.trim()).slice(0, 3),
        decisions: lines.filter(line => 
          line.toLowerCase().includes('decision') || 
          line.toLowerCase().includes('decided') ||
          line.toLowerCase().includes('agreed')
        ).map(line => line.trim()).slice(0, 3)
      };
      
      aiProcessManager.addLog(processId, 'info', `Fallback parsing extracted ${analysis.keyPoints.length} key points, ${analysis.actionItems.length} action items, ${analysis.decisions.length} decisions`);
    }
    
    const processingTime = ((Date.now() - startTime) / 1000).toFixed(1);
    
    // Phase 4: Finalizing summary (85-100%)
    aiProcessManager.addLog(processId, 'info', `Saving analysis results to database (processing time: ${processingTime}s)`);
    
    aiProcessManager.updateProgress(processId, 90, 'finalizing', 'Finalizing summary...', Math.round(totalEstimatedTime * 0.1));
    
    // Emit process progress event
    req.app.get('io').emit('process:progress', {
      processId,
      meetingId: id,
      process: aiProcessManager.getProcess(processId)
    });
    
    req.app.get('io').emit('meeting:analysis_progress', {
      meetingId: id,
      phase: 'finalizing',
      message: 'Finalizing summary...',
      progress: 90,
      estimatedTimeRemaining: Math.round(totalEstimatedTime * 0.1)
    });
    
    // Ensure we're saving clean text, not JSON strings
    const cleanSummary = typeof analysis.summary === 'string' ? analysis.summary : JSON.stringify(analysis.summary);
    
    // Save analysis to meeting record
    await meetingsService.updateMeeting(id, {
      summary: cleanSummary,
      actionItems: analysis.actionItems || [],
      keyPoints: analysis.keyPoints || [],
      decisions: analysis.decisions || [],
      analyzedAt: new Date()
    });
    
    aiProcessManager.addLog(processId, 'info', 'Analysis results saved to database successfully');
    console.log(`AI analysis completed for meeting ${id} in ${processingTime}s`);
    
    // Complete the process
    aiProcessManager.completeProcess(processId, {
      summary: analysis.summary,
      keyPoints: analysis.keyPoints,
      actionItems: analysis.actionItems,
      decisions: analysis.decisions,
      processingTime: parseFloat(processingTime),
      parseError
    });
    
    // Emit to connected clients
    req.app.get('io').emit('meeting:analysis_complete', {
      meetingId: id,
      analysis,
      processingTime: parseFloat(processingTime),
      parseError,
      processId
    });
    
    res.json({
      success: true,
      data: {
        ...analysis,
        processingTime: parseFloat(processingTime),
        parseError
      }
    });
  } catch (error) {
    const processingTime = ((Date.now() - startTime) / 1000).toFixed(1);
    console.error(`Error analyzing meeting ${req.params.id}:`, error);
    
    // Fail the process if it was created
    if (processId) {
      aiProcessManager.failProcess(processId, {
        error: error.message,
        processingTime: parseFloat(processingTime)
      });
      
      // Emit process failure event
      req.app.get('io').emit('process:failed', {
        processId,
        meetingId: req.params.id,
        error: error.message,
        process: aiProcessManager.getProcess(processId)
      });
    }
    
    res.status(500).json({
      success: false,
      error: error.message.includes('Ollama') ? 
        'AI service unavailable. Please ensure Ollama is running.' : 
        'Failed to analyze meeting transcript',
      processingTime: parseFloat(processingTime)
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