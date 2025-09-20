const db = require('./database');

class ChatService {
  // Get all messages for a session
  async getMessages(sessionId) {
    const query = `
      SELECT id, content, role, timestamp, metadata
      FROM messages 
      WHERE session_id = $1 
      ORDER BY timestamp ASC
    `;
    
    try {
      const result = await db.query(query, [sessionId]);
      return result.rows;
    } catch (error) {
      console.error('Error getting messages:', error);
      throw error;
    }
  }

  // Save a new message
  async saveMessage(sessionId, content, role, metadata = {}) {
    const query = `
      INSERT INTO messages (session_id, content, role, metadata, timestamp)
      VALUES ($1, $2, $3, $4, NOW())
      RETURNING id, content, role, timestamp, metadata
    `;
    
    try {
      const result = await db.query(query, [sessionId, content, role, JSON.stringify(metadata)]);
      return result.rows[0];
    } catch (error) {
      console.error('Error saving message:', error);
      throw error;
    }
  }

  // Create a new chat session
  async createSession(userId = null) {
    const query = `
      INSERT INTO sessions (user_id, created_at)
      VALUES ($1, NOW())
      RETURNING id, user_id, created_at
    `;
    
    try {
      const result = await db.query(query, [userId]);
      return result.rows[0];
    } catch (error) {
      console.error('Error creating session:', error);
      throw error;
    }
  }

  // Get session info
  async getSession(sessionId) {
    const query = `
      SELECT id, user_id, created_at
      FROM sessions
      WHERE id = $1
    `;
    
    try {
      const result = await db.query(query, [sessionId]);
      return result.rows[0];
    } catch (error) {
      console.error('Error getting session:', error);
      throw error;
    }
  }
}

module.exports = new ChatService();