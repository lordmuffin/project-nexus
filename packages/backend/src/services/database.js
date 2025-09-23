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
      
      // Run schema verification and migrations
      await this.verifyAndMigrateSchema();

      console.log('✅ Database initialized successfully');
    } catch (error) {
      console.warn('⚠️ Database connection failed, running without persistent storage:', error.message);
      this.pool = null; // Set to null to indicate no database
      // Don't throw error - allow server to start without database
    }
  }

  /**
   * Verify database schema and run migrations if needed
   */
  async verifyAndMigrateSchema() {
    try {
      console.log('🔍 Verifying database schema...');
      
      // Check if device_pairs table has correct schema
      const devicePairsCheck = await this.pool.query(`
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE table_name = 'device_pairs'
        ORDER BY column_name
      `);
      
      const columns = devicePairsCheck.rows.map(row => row.column_name);
      const requiredColumns = ['device_id', 'device_info', 'paired_at', 'is_active'];
      
      // Check if we have old schema (pairing_code instead of device_id)
      const hasOldSchema = columns.includes('pairing_code') && !columns.includes('device_id');
      const hasMissingColumns = requiredColumns.some(col => !columns.includes(col));
      
      if (hasOldSchema || hasMissingColumns) {
        console.log('⚠️  Detected outdated database schema, running migration...');
        await this.runSchemaMigration();
        console.log('✅ Database schema migration completed');
      } else if (columns.length > 0) {
        console.log('✅ Database schema is up to date');
      } else {
        console.log('ℹ️  device_pairs table will be created by init.sql on first run');
      }
      
    } catch (error) {
      console.error('❌ Schema verification failed:', error);
      // Don't throw here - let the app continue if schema verification fails
      // The init.sql should handle table creation
    }
  }

  /**
   * Run schema migration for device_pairs table
   */
  async runSchemaMigration() {
    const migrationSQL = `
      -- Drop old device_pairs table if it exists with wrong schema
      DROP TABLE IF EXISTS device_pairs CASCADE;
      
      -- Create device_pairs table with correct schema
      CREATE TABLE IF NOT EXISTS device_pairs (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          device_id VARCHAR(255) UNIQUE NOT NULL,
          device_info JSONB DEFAULT '{}',
          paired_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          unpaired_at TIMESTAMP WITH TIME ZONE,
          is_active BOOLEAN DEFAULT true,
          last_seen TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
      
      -- Create indexes
      CREATE INDEX IF NOT EXISTS idx_device_pairs_device_id ON device_pairs(device_id);
      CREATE INDEX IF NOT EXISTS idx_device_pairs_active ON device_pairs(is_active);
    `;
    
    await this.pool.query(migrationSQL);
  }

  // The database schema is now handled by the init.sql file
  // This method is kept for compatibility but not used in PostgreSQL setup
  async createTables() {
    console.log('📄 Database tables are initialized via init.sql');
  }

  // PostgreSQL query methods
  async query(sql, params = []) {
    if (!this.pool) {
      console.warn('Database not available, skipping query:', sql.substring(0, 50) + '...');
      return { rows: [], rowCount: 0 };
    }
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
      if (!this.pool) {
        return { status: 'not_initialized', error: 'Database pool not initialized', timestamp: new Date().toISOString() };
      }
      
      const result = await this.pool.query('SELECT 1 as healthy');
      console.log('Database health check successful:', result.rows[0]);
      return { status: 'connected', timestamp: new Date().toISOString() };
    } catch (error) {
      console.error('Database health check failed:', error.message);
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