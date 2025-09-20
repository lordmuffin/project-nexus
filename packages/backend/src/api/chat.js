const express = require('express');
const router = express.Router();
const chatService = require('../services/chat');

// Get all chat messages
router.get('/messages', async (req, res) => {
  try {
    const { limit = 50, offset = 0, search } = req.query;
    
    const messages = await chatService.getMessages({
      limit: parseInt(limit),
      offset: parseInt(offset),
      search
    });
    
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

// Send a new chat message
router.post('/messages', async (req, res) => {
  try {
    const { content, type = 'text', metadata = {} } = req.body;
    
    if (!content || content.trim().length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Message content is required'
      });
    }
    
    const message = await chatService.createMessage({
      content: content.trim(),
      type,
      metadata,
      timestamp: new Date(),
      userId: req.user?.id || 'anonymous' // TODO: Implement user authentication
    });
    
    // Emit to all connected clients
    req.app.get('io').emit('chat:message', message);
    
    res.status(201).json({
      success: true,
      data: message
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

module.exports = router;