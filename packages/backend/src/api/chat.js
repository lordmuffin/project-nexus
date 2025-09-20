const express = require('express');
const router = express.Router();
const chatService = require('../services/chat');
const ollamaService = require('../services/ollama');
const databaseService = require('../services/database');

// Get all chat messages for a session
router.get('/sessions/:sessionId/messages', async (req, res) => {
  try {
    const { sessionId } = req.params;
    const { limit = 50, offset = 0 } = req.query;
    
    const messages = await databaseService.all(
      'SELECT * FROM chat_messages WHERE session_id = $1 ORDER BY created_at ASC LIMIT $2 OFFSET $3',
      [sessionId, parseInt(limit), parseInt(offset)]
    );
    
    res.json({
      success: true,
      data: messages,
      pagination: {
        limit: parseInt(limit),
        offset: parseInt(offset),
        total: messages.length
      }
    });
  } catch (error) {
    console.error('Error fetching chat messages:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch chat messages'
    });
  }
});

// Get or create a chat session
router.get('/sessions', async (req, res) => {
  try {
    // For now, just return/create a default session
    const userId = '00000000-0000-0000-0000-000000000001'; // Demo user
    
    let session = await databaseService.get(
      'SELECT * FROM chat_sessions WHERE user_id = $1 ORDER BY created_at DESC LIMIT 1',
      [userId]
    );

    if (!session) {
      const sessionId = databaseService.generateId();
      await databaseService.run(
        'INSERT INTO chat_sessions (id, user_id, title) VALUES ($1, $2, $3)',
        [sessionId, userId, 'New Chat']
      );
      session = { id: sessionId, user_id: userId, title: 'New Chat', created_at: new Date() };
    }

    res.json({
      success: true,
      data: session
    });
  } catch (error) {
    console.error('Error handling chat session:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to handle chat session'
    });
  }
});

// Send a new chat message and get AI response
router.post('/sessions/:sessionId/messages', async (req, res) => {
  try {
    const { sessionId } = req.params;
    const { content } = req.body;
    
    if (!content || content.trim().length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Message content is required'
      });
    }

    // Save user message
    const userMessageId = databaseService.generateId();
    await databaseService.run(
      'INSERT INTO chat_messages (id, session_id, role, content, created_at) VALUES ($1, $2, $3, $4, $5)',
      [userMessageId, sessionId, 'user', content.trim(), new Date()]
    );

    const userMessage = {
      id: userMessageId,
      session_id: sessionId,
      role: 'user',
      content: content.trim(),
      created_at: new Date()
    };

    // Get conversation history for context
    const conversationHistory = await databaseService.all(
      'SELECT role, content FROM chat_messages WHERE session_id = $1 ORDER BY created_at ASC',
      [sessionId]
    );

    // Generate AI response
    const aiResponse = await ollamaService.generateResponse(
      content.trim(),
      conversationHistory.slice(-10) // Last 10 messages for context
    );

    // Save AI response
    const aiMessageId = databaseService.generateId();
    await databaseService.run(
      'INSERT INTO chat_messages (id, session_id, role, content, metadata, created_at) VALUES ($1, $2, $3, $4, $5, $6)',
      [aiMessageId, sessionId, 'assistant', aiResponse.content, JSON.stringify({
        model: aiResponse.model,
        total_duration: aiResponse.total_duration,
        eval_count: aiResponse.eval_count,
        error: aiResponse.error || false
      }), new Date()]
    );

    const aiMessage = {
      id: aiMessageId,
      session_id: sessionId,
      role: 'assistant',
      content: aiResponse.content,
      metadata: {
        model: aiResponse.model,
        total_duration: aiResponse.total_duration,
        eval_count: aiResponse.eval_count,
        error: aiResponse.error || false
      },
      created_at: new Date()
    };

    // Emit both messages to connected clients if WebSocket is available
    if (req.app.get('io')) {
      req.app.get('io').emit('chat:message', userMessage);
      req.app.get('io').emit('chat:message', aiMessage);
    }
    
    res.status(201).json({
      success: true,
      data: {
        userMessage,
        aiMessage
      }
    });
  } catch (error) {
    console.error('Error creating chat message:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to create chat message'
    });
  }
});

// Get a specific message
router.get('/messages/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const message = await chatService.getMessageById(id);
    
    if (!message) {
      return res.status(404).json({
        success: false,
        error: 'Message not found'
      });
    }
    
    res.json({
      success: true,
      data: message
    });
  } catch (error) {
    console.error('Error fetching chat message:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch chat message'
    });
  }
});

// Update a message
router.put('/messages/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { content } = req.body;
    
    if (!content || content.trim().length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Message content is required'
      });
    }
    
    const updatedMessage = await chatService.updateMessage(id, {
      content: content.trim(),
      updatedAt: new Date()
    });
    
    if (!updatedMessage) {
      return res.status(404).json({
        success: false,
        error: 'Message not found'
      });
    }
    
    // Emit update to all connected clients
    req.app.get('io').emit('chat:message_updated', updatedMessage);
    
    res.json({
      success: true,
      data: updatedMessage
    });
  } catch (error) {
    console.error('Error updating chat message:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to update chat message'
    });
  }
});

// Delete a message
router.delete('/messages/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const deleted = await chatService.deleteMessage(id);
    
    if (!deleted) {
      return res.status(404).json({
        success: false,
        error: 'Message not found'
      });
    }
    
    // Emit deletion to all connected clients
    req.app.get('io').emit('chat:message_deleted', { id });
    
    res.json({
      success: true,
      message: 'Message deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting chat message:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to delete chat message'
    });
  }
});

// Search messages
router.get('/search', async (req, res) => {
  try {
    const { q, limit = 20, offset = 0 } = req.query;
    
    if (!q || q.trim().length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Search query is required'
      });
    }
    
    const results = await chatService.searchMessages({
      query: q.trim(),
      limit: parseInt(limit),
      offset: parseInt(offset)
    });
    
    res.json({
      success: true,
      data: results,
      query: q.trim(),
      pagination: {
        limit: parseInt(limit),
        offset: parseInt(offset),
        total: results.length
      }
    });
  } catch (error) {
    console.error('Error searching chat messages:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to search chat messages'
    });
  }
});

// Health check for LLM service
router.get('/health', async (req, res) => {
  try {
    const ollamaHealth = await ollamaService.healthCheck();
    res.json({
      success: true,
      data: ollamaHealth
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Health check failed'
    });
  }
});

// Generate QR code for device pairing
router.post('/pair/generate', async (req, res) => {
  try {
    const QRCode = require('qrcode');
    
    // Generate unique pairing code
    const pairingCode = require('crypto').randomBytes(32).toString('hex');
    const deviceName = req.body.deviceName || 'Mobile Device';
    
    // Store pairing code in database with expiration
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes
    await databaseService.run(
      'INSERT INTO device_pairs (id, pairing_code, device_name, expires_at) VALUES ($1, $2, $3, $4)',
      [databaseService.generateId(), pairingCode, deviceName, expiresAt]
    );
    
    // Create QR code with connection info
    const connectionInfo = {
      code: pairingCode,
      url: `ws://localhost:3001`,
      expires: expiresAt.toISOString()
    };
    
    const qrCodeDataUrl = await QRCode.toDataURL(JSON.stringify(connectionInfo));
    
    res.json({
      success: true,
      data: {
        pairingCode,
        qrCode: qrCodeDataUrl,
        expiresAt,
        connectionInfo
      }
    });
  } catch (error) {
    console.error('Error generating pairing QR code:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to generate pairing code'
    });
  }
});

module.exports = router;