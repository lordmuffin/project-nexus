const db = require('./database');
const path = require('path');
const fs = require('fs').promises;

class MeetingsService {
  // Get meetings with pagination and filters
  async getMeetings(options = {}) {
    const { limit = 20, offset = 0, status, search, userId = null } = options;
    
    let query = `SELECT * FROM meeting_recordings WHERE 1=1`;
    const params = [];
    let paramIndex = 1;
    
    if (userId) {
      query += ` AND user_id = $${paramIndex}`;
      params.push(userId);
      paramIndex++;
    }
    
    if (status) {
      query += ` AND status = $${paramIndex}`;
      params.push(status);
      paramIndex++;
    }
    
    if (search) {
      query += ` AND (title ILIKE $${paramIndex} OR description ILIKE $${paramIndex})`;
      params.push(`%${search}%`);
      paramIndex++;
    }
    
    query += ` ORDER BY created_at DESC`;
    
    if (limit) {
      query += ` LIMIT $${paramIndex}`;
      params.push(limit);
      paramIndex++;
    }
    
    if (offset) {
      query += ` OFFSET $${paramIndex}`;
      params.push(offset);
    }
    
    try {
      const result = await db.query(query, params);
      return result.rows;
    } catch (error) {
      console.error('Error getting meetings:', error);
      throw error;
    }
  }

  // Get all meetings (legacy method)
  async getAllMeetings(userId = null) {
    return this.getMeetings({ userId });
  }

  // Get meeting by ID
  async getMeetingById(meetingId) {
    const query = `
      SELECT * FROM meeting_recordings 
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
      INSERT INTO meeting_recordings (title, summary, user_id, created_at)
      VALUES ($1, $2, $3, NOW())
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
    const allowedFields = ['title', 'transcript', 'summary', 'action_items', 'metadata'];
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
      UPDATE meeting_recordings 
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
    const query = `DELETE FROM meeting_recordings WHERE id = $1 RETURNING *`;
    
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
      UPDATE meeting_recordings 
      SET metadata = metadata || jsonb_build_object('audio_file', $2, 'audio_original_name', $3, 'audio_file_size', $4), 
          updated_at = NOW()
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
    if (!meeting || !meeting.metadata?.audio_file) {
      return null;
    }
    
    return path.join(__dirname, '../../uploads/audio', meeting.metadata.audio_file);
  }

  // Start a meeting (updates status)
  async startMeeting(meetingId) {
    return this.updateMeeting(meetingId, { metadata: { status: 'active' } });
  }

  // End a meeting (updates status) 
  async endMeeting(meetingId) {
    return this.updateMeeting(meetingId, { metadata: { status: 'ended' } });
  }

  // Add audio recording to meeting
  async addAudioRecording(meetingId, audioData) {
    const metadata = {
      audio_file: audioData.filename,
      audio_original_name: audioData.originalName,
      audio_mimetype: audioData.mimetype,
      audio_size: audioData.size,
      audio_path: audioData.path,
      audio_uploaded_at: audioData.uploadedAt || new Date()
    };
    
    return this.updateMeeting(meetingId, { metadata });
  }

  // Get transcription for a meeting
  async getTranscription(meetingId) {
    const meeting = await this.getMeetingById(meetingId);
    return meeting?.transcript || null;
  }
}

module.exports = new MeetingsService();