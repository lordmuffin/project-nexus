const db = require('./database');
const path = require('path');
const fs = require('fs').promises;

class MeetingsService {
  // Get all meetings
  async getAllMeetings(userId = null) {
    const query = userId 
      ? `SELECT * FROM meetings WHERE user_id = $1 ORDER BY created_at DESC`
      : `SELECT * FROM meetings ORDER BY created_at DESC`;
    
    try {
      const params = userId ? [userId] : [];
      const result = await db.query(query, params);
      return result.rows;
    } catch (error) {
      console.error('Error getting meetings:', error);
      throw error;
    }
  }

  // Get meeting by ID
  async getMeetingById(meetingId) {
    const query = `
      SELECT * FROM meetings 
      WHERE id = $1
    `;
    
    try {
      const result = await db.query(query, [meetingId]);
      return result.rows[0];
    } catch (error) {
      console.error('Error getting meeting:', error);
      throw error;
    }
  }

  // Create new meeting
  async createMeeting(title, description = '', userId = null) {
    const query = `
      INSERT INTO meetings (title, description, user_id, status, created_at)
      VALUES ($1, $2, $3, 'active', NOW())
      RETURNING *
    `;
    
    try {
      const result = await db.query(query, [title, description, userId]);
      return result.rows[0];
    } catch (error) {
      console.error('Error creating meeting:', error);
      throw error;
    }
  }

  // Update meeting
  async updateMeeting(meetingId, updates) {
    const allowedFields = ['title', 'description', 'status', 'transcription'];
    const setClause = [];
    const values = [];
    let paramIndex = 1;

    for (const [key, value] of Object.entries(updates)) {
      if (allowedFields.includes(key)) {
        setClause.push(`${key} = $${paramIndex}`);
        values.push(value);
        paramIndex++;
      }
    }

    if (setClause.length === 0) {
      throw new Error('No valid fields to update');
    }

    const query = `
      UPDATE meetings 
      SET ${setClause.join(', ')}, updated_at = NOW()
      WHERE id = $${paramIndex}
      RETURNING *
    `;
    values.push(meetingId);

    try {
      const result = await db.query(query, values);
      return result.rows[0];
    } catch (error) {
      console.error('Error updating meeting:', error);
      throw error;
    }
  }

  // Delete meeting
  async deleteMeeting(meetingId) {
    const query = `DELETE FROM meetings WHERE id = $1 RETURNING *`;
    
    try {
      const result = await db.query(query, [meetingId]);
      return result.rows[0];
    } catch (error) {
      console.error('Error deleting meeting:', error);
      throw error;
    }
  }

  // Save audio file reference
  async saveAudioFile(meetingId, filename, originalName, size) {
    const query = `
      UPDATE meetings 
      SET audio_file = $2, audio_original_name = $3, audio_file_size = $4, updated_at = NOW()
      WHERE id = $1
      RETURNING *
    `;
    
    try {
      const result = await db.query(query, [meetingId, filename, originalName, size]);
      return result.rows[0];
    } catch (error) {
      console.error('Error saving audio file:', error);
      throw error;
    }
  }

  // Get meeting audio file path
  async getAudioFilePath(meetingId) {
    const meeting = await this.getMeetingById(meetingId);
    if (!meeting || !meeting.audio_file) {
      return null;
    }
    
    return path.join(__dirname, '../../uploads/audio', meeting.audio_file);
  }
}

module.exports = new MeetingsService();