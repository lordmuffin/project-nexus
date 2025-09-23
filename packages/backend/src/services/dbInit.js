const fs = require('fs').promises;
const path = require('path');
const dbService = require('./database');

/**
 * Database initialization and migration service
 * Ensures database schema is correct on startup
 */
class DatabaseInitializer {
  constructor() {
    this.migrationPath = path.join(__dirname, '../../db/migrate.sql');
  }

  /**
   * Initialize and migrate database schema
   */
  async initialize() {
    try {
      console.log('🔄 Initializing database schema...');
      
      // Wait for database connection to be ready
      await this.waitForDatabase();
      
      // Run migration script
      await this.runMigrations();
      
      // Verify critical tables exist
      await this.verifySchema();
      
      console.log('✅ Database schema initialization complete');
      
    } catch (error) {
      console.error('❌ Database initialization failed:', error);
      throw error;
    }
  }

  /**
   * Wait for database to be ready
   */
  async waitForDatabase(maxRetries = 30, delay = 1000) {
    for (let i = 0; i < maxRetries; i++) {
      try {
        await dbService.query('SELECT 1');
        console.log('📊 Database connection ready');
        return;
      } catch (error) {
        if (i === maxRetries - 1) {
          throw new Error(`Database not ready after ${maxRetries} attempts: ${error.message}`);
        }
        console.log(`⏳ Waiting for database... (${i + 1}/${maxRetries})`);
        await new Promise(resolve => setTimeout(resolve, delay));
      }
    }
  }

  /**
   * Run migration scripts
   */
  async runMigrations() {
    try {
      const migrationSQL = await fs.readFile(this.migrationPath, 'utf8');
      console.log('📋 Running database migrations...');
      
      await dbService.query(migrationSQL);
      console.log('✅ Database migrations completed');
      
    } catch (error) {
      if (error.code === 'ENOENT') {
        console.log('ℹ️  No migration file found, skipping migrations');
      } else {
        throw new Error(`Migration failed: ${error.message}`);
      }
    }
  }

  /**
   * Verify critical tables exist with correct schema
   */
  async verifySchema() {
    console.log('🔍 Verifying database schema...');
    
    const criticalTables = [
      'users',
      'chat_sessions', 
      'chat_messages',
      'notes',
      'device_pairs',
      'meeting_recordings',
      'system_status'
    ];

    for (const table of criticalTables) {
      const result = await dbService.query(`
        SELECT EXISTS (
          SELECT 1 FROM information_schema.tables 
          WHERE table_name = $1
        )
      `, [table]);
      
      if (!result.rows[0].exists) {
        throw new Error(`Critical table '${table}' does not exist`);
      }
    }

    // Verify device_pairs has correct columns
    const devicePairsColumns = await dbService.query(`
      SELECT column_name FROM information_schema.columns 
      WHERE table_name = 'device_pairs'
      ORDER BY column_name
    `);
    
    const expectedColumns = ['device_id', 'device_info', 'id', 'is_active', 'last_seen', 'paired_at', 'unpaired_at'];
    const actualColumns = devicePairsColumns.rows.map(row => row.column_name).sort();
    
    const missingColumns = expectedColumns.filter(col => !actualColumns.includes(col));
    if (missingColumns.length > 0) {
      throw new Error(`device_pairs table missing columns: ${missingColumns.join(', ')}`);
    }

    console.log('✅ Database schema verification complete');
  }

  /**
   * Get database statistics
   */
  async getStats() {
    try {
      const stats = await dbService.query(`
        SELECT 
          schemaname,
          tablename,
          n_tup_ins as inserts,
          n_tup_upd as updates,
          n_tup_del as deletes
        FROM pg_stat_user_tables 
        WHERE schemaname = 'public'
        ORDER BY tablename
      `);
      
      return stats.rows;
    } catch (error) {
      console.error('Failed to get database stats:', error);
      return [];
    }
  }
}

module.exports = new DatabaseInitializer();