const express = require('express');
const router = express.Router();
const databaseService = require('../services/database');

// Get all notes
router.get('/', async (req, res) => {
  try {
    const userId = '00000000-0000-0000-0000-000000000001'; // Demo user
    const { limit = 50, offset = 0, search } = req.query;
    
    let query = 'SELECT * FROM notes WHERE user_id = $1';
    let params = [userId];
    
    if (search) {
      query += ' AND (title ILIKE $2 OR content ILIKE $2)';
      params.push(`%${search}%`);
    }
    
    query += ' ORDER BY updated_at DESC LIMIT $' + (params.length + 1) + ' OFFSET $' + (params.length + 2);
    params.push(parseInt(limit), parseInt(offset));
    
    const notes = await databaseService.all(query, params);
    
    res.json({
      success: true,
      data: notes,
      pagination: {
        limit: parseInt(limit),
        offset: parseInt(offset),
        total: notes.length
      }
    });
  } catch (error) {
    console.error('Error fetching notes:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch notes'
    });
  }
});

// Create a new note
router.post('/', async (req, res) => {
  try {
    const userId = '00000000-0000-0000-0000-000000000001'; // Demo user
    const { title, content = '', tags = [] } = req.body;
    
    if (!title || title.trim().length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Note title is required'
      });
    }
    
    const noteId = databaseService.generateId();
    const now = new Date();
    
    await databaseService.run(
      'INSERT INTO notes (id, user_id, title, content, tags, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7)',
      [noteId, userId, title.trim(), content, tags, now, now]
    );
    
    const note = {
      id: noteId,
      user_id: userId,
      title: title.trim(),
      content,
      tags,
      created_at: now,
      updated_at: now
    };
    
    res.status(201).json({
      success: true,
      data: note
    });
  } catch (error) {
    console.error('Error creating note:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to create note'
    });
  }
});

// Get a specific note
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const userId = '00000000-0000-0000-0000-000000000001'; // Demo user
    
    const note = await databaseService.get(
      'SELECT * FROM notes WHERE id = $1 AND user_id = $2',
      [id, userId]
    );
    
    if (!note) {
      return res.status(404).json({
        success: false,
        error: 'Note not found'
      });
    }
    
    res.json({
      success: true,
      data: note
    });
  } catch (error) {
    console.error('Error fetching note:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch note'
    });
  }
});

// Update a note
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const userId = '00000000-0000-0000-0000-000000000001'; // Demo user
    const { title, content, tags } = req.body;
    
    // Check if note exists
    const existingNote = await databaseService.get(
      'SELECT * FROM notes WHERE id = $1 AND user_id = $2',
      [id, userId]
    );
    
    if (!existingNote) {
      return res.status(404).json({
        success: false,
        error: 'Note not found'
      });
    }
    
    // Update fields
    const updates = [];
    const params = [];
    let paramIndex = 1;
    
    if (title !== undefined) {
      updates.push(`title = $${paramIndex++}`);
      params.push(title.trim());
    }
    
    if (content !== undefined) {
      updates.push(`content = $${paramIndex++}`);
      params.push(content);
    }
    
    if (tags !== undefined) {
      updates.push(`tags = $${paramIndex++}`);
      params.push(tags);
    }
    
    updates.push(`updated_at = $${paramIndex++}`);
    params.push(new Date());
    
    params.push(id, userId);
    
    await databaseService.run(
      `UPDATE notes SET ${updates.join(', ')} WHERE id = $${paramIndex++} AND user_id = $${paramIndex++}`,
      params
    );
    
    // Get updated note
    const updatedNote = await databaseService.get(
      'SELECT * FROM notes WHERE id = $1 AND user_id = $2',
      [id, userId]
    );
    
    res.json({
      success: true,
      data: updatedNote
    });
  } catch (error) {
    console.error('Error updating note:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to update note'
    });
  }
});

// Delete a note
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const userId = '00000000-0000-0000-0000-000000000001'; // Demo user
    
    const result = await databaseService.run(
      'DELETE FROM notes WHERE id = $1 AND user_id = $2',
      [id, userId]
    );
    
    if (result.rowCount === 0) {
      return res.status(404).json({
        success: false,
        error: 'Note not found'
      });
    }
    
    res.json({
      success: true,
      message: 'Note deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting note:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to delete note'
    });
  }
});

module.exports = router;