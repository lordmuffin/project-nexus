const { Pool } = require('pg');

class DatabaseService {
  constructor() {
    this.pool = null;
  }

  async initialize() {
    try {
      // Create PostgreSQL connection pool
      this.pool = new Pool({
        connectionString: process.env.DATABASE_URL || 'postgresql://nexus:nexus_password@localhost:5432/nexus',
        max: 20,
        idleTimeoutMillis: 30000,
        connectionTimeoutMillis: 2000,
      });

      // Test connection
      await this.pool.query('SELECT NOW()');

      console.log('✅ Database initialized successfully');
    } catch (error) {
      console.error('❌ Database initialization failed:', error);
      throw error;
    }
  }

  // The database schema is now handled by the init.sql file
  // This method is kept for compatibility but not used in PostgreSQL setup
  async createTables() {
    console.log('📄 Database tables are initialized via init.sql');
  }

  // PostgreSQL query methods
  async query(sql, params = []) {
    try {
      const result = await this.pool.query(sql, params);
      return result;
    } catch (error) {
      console.error('Database query error:', error);
      throw error;
    }
  }

  async run(sql, params = []) {
    const result = await this.query(sql, params);
    return { rowCount: result.rowCount, rows: result.rows };
  }

  async get(sql, params = []) {
    const result = await this.query(sql, params);
    return result.rows[0] || null;
  }

  async all(sql, params = []) {
    const result = await this.query(sql, params);
    return result.rows;
  }

  // Transaction support
  async getClient() {
    return await this.pool.connect();
  }

  async beginTransaction() {
    const client = await this.getClient();
    await client.query('BEGIN');
    return client;
  }

  async commit(client) {
    await client.query('COMMIT');
    client.release();
  }

  async rollback(client) {
    await client.query('ROLLBACK');
    client.release();
  }

  // Close database connection
  async close() {
    if (this.pool) {
      await this.pool.end();
    }
  }

  // Health check
  async healthCheck() {
    try {
      await this.pool.query('SELECT 1');
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