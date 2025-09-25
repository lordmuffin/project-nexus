const fs = require('fs').promises;
const path = require('path');
const dbService = require('./database');

class MigrationService {
  constructor() {
    this.migrationsDir = path.join(__dirname, '../../db/migrations');
    this.migrationTableName = 'schema_migrations';
  }

  // Initialize migrations table
  async initializeMigrationsTable() {
    try {
      await dbService.query(`
        CREATE TABLE IF NOT EXISTS ${this.migrationTableName} (
          version VARCHAR(255) PRIMARY KEY,
          filename VARCHAR(255) NOT NULL,
          applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          checksum VARCHAR(64),
          execution_time_ms INTEGER
        )
      `);
      console.log('Migrations table initialized');
    } catch (error) {
      console.error('Error initializing migrations table:', error);
      throw error;
    }
  }

  // Get list of applied migrations
  async getAppliedMigrations() {
    try {
      const result = await dbService.query(`
        SELECT version, filename, applied_at 
        FROM ${this.migrationTableName} 
        ORDER BY version
      `);
      return result.rows;
    } catch (error) {
      console.error('Error getting applied migrations:', error);
      return [];
    }
  }

  // Get list of pending migrations
  async getPendingMigrations() {
    try {
      const appliedMigrations = await this.getAppliedMigrations();
      const appliedVersions = new Set(appliedMigrations.map(m => m.version));
      
      const migrationFiles = await fs.readdir(this.migrationsDir);
      const sqlFiles = migrationFiles
        .filter(file => file.endsWith('.sql'))
        .sort();
      
      const pendingMigrations = [];
      
      for (const filename of sqlFiles) {
        const version = this.extractVersionFromFilename(filename);
        if (!appliedVersions.has(version)) {
          pendingMigrations.push({
            version,
            filename,
            filepath: path.join(this.migrationsDir, filename)
          });
        }
      }
      
      return pendingMigrations;
    } catch (error) {
      console.error('Error getting pending migrations:', error);
      throw error;
    }
  }

  // Extract version from migration filename (e.g., "001_add_multitrack_support.sql" -> "001")
  extractVersionFromFilename(filename) {
    const match = filename.match(/^(\d+)_/);
    return match ? match[1] : filename;
  }

  // Calculate checksum for migration file
  async calculateChecksum(content) {
    const crypto = require('crypto');
    return crypto.createHash('sha256').update(content).digest('hex');
  }

  // Apply a single migration
  async applyMigration(migration) {
    const startTime = Date.now();
    
    try {
      console.log(`Applying migration: ${migration.filename}`);
      
      const content = await fs.readFile(migration.filepath, 'utf8');
      const checksum = await this.calculateChecksum(content);
      
      // Start transaction
      await dbService.query('BEGIN');
      
      try {
        // Execute migration SQL
        await dbService.query(content);
        
        // Record migration as applied
        await dbService.query(`
          INSERT INTO ${this.migrationTableName} (version, filename, checksum, execution_time_ms)
          VALUES ($1, $2, $3, $4)
        `, [
          migration.version,
          migration.filename,
          checksum,
          Date.now() - startTime
        ]);
        
        // Commit transaction
        await dbService.query('COMMIT');
        
        console.log(`✅ Migration ${migration.filename} applied successfully (${Date.now() - startTime}ms)`);
        return true;
        
      } catch (error) {
        // Rollback on error
        await dbService.query('ROLLBACK');
        throw error;
      }
      
    } catch (error) {
      console.error(`❌ Error applying migration ${migration.filename}:`, error);
      throw error;
    }
  }

  // Run all pending migrations
  async runMigrations() {
    try {
      console.log('🔄 Starting database migrations...');
      
      await this.initializeMigrationsTable();
      const pendingMigrations = await getPendingMigrations();
      
      if (pendingMigrations.length === 0) {
        console.log('✅ No pending migrations');
        return { applied: 0, skipped: 0 };
      }
      
      console.log(`Found ${pendingMigrations.length} pending migration(s)`);
      
      let appliedCount = 0;
      
      for (const migration of pendingMigrations) {
        await this.applyMigration(migration);
        appliedCount++;
      }
      
      console.log(`✅ Successfully applied ${appliedCount} migration(s)`);
      return { applied: appliedCount, skipped: 0 };
      
    } catch (error) {
      console.error('❌ Migration failed:', error);
      throw error;
    }
  }

  // Rollback last migration (use with caution)
  async rollbackLastMigration() {
    try {
      const appliedMigrations = await this.getAppliedMigrations();
      
      if (appliedMigrations.length === 0) {
        console.log('No migrations to rollback');
        return false;
      }
      
      const lastMigration = appliedMigrations[appliedMigrations.length - 1];
      console.log(`⚠️  Rolling back migration: ${lastMigration.filename}`);
      
      // Check if rollback script exists
      const rollbackFilename = lastMigration.filename.replace('.sql', '_rollback.sql');
      const rollbackPath = path.join(this.migrationsDir, rollbackFilename);
      
      try {
        const rollbackContent = await fs.readFile(rollbackPath, 'utf8');
        
        await dbService.query('BEGIN');
        
        try {
          // Execute rollback SQL
          await dbService.query(rollbackContent);
          
          // Remove migration record
          await dbService.query(`
            DELETE FROM ${this.migrationTableName} 
            WHERE version = $1
          `, [lastMigration.version]);
          
          await dbService.query('COMMIT');
          
          console.log(`✅ Migration ${lastMigration.filename} rolled back successfully`);
          return true;
          
        } catch (error) {
          await dbService.query('ROLLBACK');
          throw error;
        }
        
      } catch (error) {
        if (error.code === 'ENOENT') {
          console.error(`❌ Rollback script not found: ${rollbackFilename}`);
          console.error('Manual rollback required');
        } else {
          console.error('❌ Error during rollback:', error);
        }
        throw error;
      }
      
    } catch (error) {
      console.error('❌ Rollback failed:', error);
      throw error;
    }
  }

  // Get migration status
  async getMigrationStatus() {
    try {
      await this.initializeMigrationsTable();
      
      const applied = await this.getAppliedMigrations();
      const pending = await this.getPendingMigrations();
      
      return {
        applied: applied.length,
        pending: pending.length,
        appliedMigrations: applied,
        pendingMigrations: pending
      };
    } catch (error) {
      console.error('Error getting migration status:', error);
      throw error;
    }
  }
}

module.exports = new MigrationService();