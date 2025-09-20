const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs').promises;

class DatabaseService {
  constructor() {
    this.db = null;
    this.dbPath = path.join(__dirname, '../../data/nexus.db');
  }

  async initialize() {
    try {
      // Ensure data directory exists
      const dataDir = path.dirname(this.dbPath);
      await fs.mkdir(dataDir, { recursive: true });

      // Open database connection
      this.db = new sqlite3.Database(this.dbPath);

      // Enable foreign keys
      await this.run('PRAGMA foreign_keys = ON');

      // Create tables
      await this.createTables();

      console.log('✅ Database initialized successfully');
    } catch (error) {
      console.error('❌ Database initialization failed:', error);
      throw error;
    }
  }

  async createTables() {
    const tables = [
      // Users table (for future user management)
      `CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        username TEXT UNIQUE NOT NULL,
        email TEXT UNIQUE,
        display_name TEXT,
        avatar_url TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )`,

      // Meetings table
      `CREATE TABLE IF NOT EXISTS meetings (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        status TEXT DEFAULT 'scheduled',
        scheduled_for DATETIME,
        started_at DATETIME,
        ended_at DATETIME,
        duration INTEGER,
        participants TEXT, -- JSON array
        metadata TEXT, -- JSON object
        user_id TEXT DEFAULT 'anonymous',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )`,

      // Audio recordings table
      `CREATE TABLE IF NOT EXISTS audio_recordings (
        id TEXT PRIMARY KEY,
        meeting_id TEXT NOT NULL,
        filename TEXT NOT NULL,
        original_name TEXT,
        file_path TEXT NOT NULL,
        mimetype TEXT,
        size INTEGER,
        duration REAL,
        uploaded_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (meeting_id) REFERENCES meetings (id) ON DELETE CASCADE
      )`,

      // Transcriptions table
      `CREATE TABLE IF NOT EXISTS transcriptions (
        id TEXT PRIMARY KEY,
        meeting_id TEXT,
        audio_recording_id TEXT,
        content TEXT NOT NULL,
        language TEXT,
        model TEXT,
        confidence REAL,
        segments TEXT, -- JSON array of timed segments
        status TEXT DEFAULT 'completed',
        processing_time INTEGER,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (meeting_id) REFERENCES meetings (id) ON DELETE CASCADE,
        FOREIGN KEY (audio_recording_id) REFERENCES audio_recordings (id) ON DELETE CASCADE
      )`,

      // Chat messages table
      `CREATE TABLE IF NOT EXISTS chat_messages (
        id TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        type TEXT DEFAULT 'text',
        meeting_id TEXT,
        user_id TEXT DEFAULT 'anonymous',
        metadata TEXT, -- JSON object
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (meeting_id) REFERENCES meetings (id) ON DELETE SET NULL
      )`,

      // Transcription jobs table
      `CREATE TABLE IF NOT EXISTS transcription_jobs (
        id TEXT PRIMARY KEY,
        filename TEXT NOT NULL,
        file_path TEXT NOT NULL,
        language TEXT DEFAULT 'auto',
        model TEXT DEFAULT 'base',
        status TEXT DEFAULT 'pending',
        progress INTEGER DEFAULT 0,
        result TEXT, -- JSON result
        error_message TEXT,
        user_id TEXT DEFAULT 'anonymous',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        started_at DATETIME,
        completed_at DATETIME
      )`,

      // Settings table
      `CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        description TEXT,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )`
    ];

    for (const table of tables) {
      await this.run(table);
    }

    // Create indexes for better performance
    const indexes = [
      'CREATE INDEX IF NOT EXISTS idx_meetings_status ON meetings (status)',
      'CREATE INDEX IF NOT EXISTS idx_meetings_created_at ON meetings (created_at)',
      'CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON chat_messages (created_at)',
      'CREATE INDEX IF NOT EXISTS idx_chat_messages_meeting_id ON chat_messages (meeting_id)',
      'CREATE INDEX IF NOT EXISTS idx_transcription_jobs_status ON transcription_jobs (status)',
      'CREATE INDEX IF NOT EXISTS idx_transcription_jobs_created_at ON transcription_jobs (created_at)'
    ];

    for (const index of indexes) {
      await this.run(index);
    }
  }

  // Promisify sqlite3 methods
  run(sql, params = []) {
    return new Promise((resolve, reject) => {
      this.db.run(sql, params, function(err) {
        if (err) {
          reject(err);
        } else {
          resolve({ id: this.lastID, changes: this.changes });
        }
      });
    });
  }

  get(sql, params = []) {
    return new Promise((resolve, reject) => {
      this.db.get(sql, params, (err, row) => {
        if (err) {
          reject(err);
        } else {
          resolve(row);
        }
      });
    });
  }

  all(sql, params = []) {
    return new Promise((resolve, reject) => {
      this.db.all(sql, params, (err, rows) => {
        if (err) {
          reject(err);
        } else {
          resolve(rows);
        }
      });
    });
  }

  // Transaction support
  async beginTransaction() {
    await this.run('BEGIN TRANSACTION');
  }

  async commit() {
    await this.run('COMMIT');
  }

  async rollback() {
    await this.run('ROLLBACK');
  }

  // Close database connection
  close() {
    return new Promise((resolve, reject) => {
      if (this.db) {
        this.db.close((err) => {
          if (err) {
            reject(err);
          } else {
            resolve();
          }
        });
      } else {
        resolve();
      }
    });
  }

  // Health check
  async healthCheck() {
    try {
      await this.get('SELECT 1');
      return { status: 'connected', timestamp: new Date().toISOString() };
    } catch (error) {
      return { status: 'error', error: error.message, timestamp: new Date().toISOString() };
    }
  }

  // Helper method to generate UUIDs
  generateId() {
    return require('crypto').randomUUID();
  }
}

// Create singleton instance
const databaseService = new DatabaseService();

module.exports = databaseService;