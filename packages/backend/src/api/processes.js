const express = require('express');
const router = express.Router();
const aiProcessManager = require('../services/aiProcessManager');
const databaseService = require('../services/database');

// Get all processes for a specific meeting
router.get('/meeting/:meetingId', async (req, res) => {
  try {
    const { meetingId } = req.params;
    
    // Get processes from memory (recent/active processes)
    const memoryProcesses = aiProcessManager.getProcessesForMeeting(meetingId);
    
    // Get historical processes from database
    let dbProcesses = [];
    try {
      const result = await databaseService.query(`
        SELECT 
          id,
          meeting_id,
          process_type,
          status,
          progress,
          phase,
          message,
          start_time,
          end_time,
          elapsed_time,
          estimated_time_remaining,
          resource_usage,
          logs,
          error_details,
          result,
          metadata,
          created_at,
          updated_at
        FROM ai_processes 
        WHERE meeting_id = $1 
        ORDER BY created_at DESC
      `, [meetingId]);
      
      dbProcesses = result.rows || [];
    } catch (dbError) {
      console.warn('Failed to fetch processes from database:', dbError.message);
      // Continue with memory processes only
    }

    // Merge and deduplicate processes (memory processes take precedence)
    const processMap = new Map();
    
    // Add memory processes first (these are most current)
    memoryProcesses.forEach(process => {
      processMap.set(process.id, {
        ...process,
        source: 'memory'
      });
    });
    
    // Add database processes that aren't already in memory
    dbProcesses.forEach(dbProcess => {
      if (!processMap.has(dbProcess.id)) {
        processMap.set(dbProcess.id, {
          ...dbProcess,
          // Convert timestamps to Date objects for consistency
          startTime: dbProcess.start_time ? new Date(dbProcess.start_time) : null,
          endTime: dbProcess.end_time ? new Date(dbProcess.end_time) : null,
          createdAt: new Date(dbProcess.created_at),
          updatedAt: new Date(dbProcess.updated_at),
          // Convert JSON fields
          resourceUsage: dbProcess.resource_usage || { cpu: 0, memory: 0 },
          logs: dbProcess.logs || [],
          errorDetails: dbProcess.error_details,
          result: dbProcess.result,
          metadata: dbProcess.metadata || {},
          source: 'database'
        });
      }
    });

    const allProcesses = Array.from(processMap.values())
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

    res.json({
      success: true,
      data: allProcesses,
      statistics: {
        total: allProcesses.length,
        active: allProcesses.filter(p => p.status === 'running' || p.status === 'queued').length,
        completed: allProcesses.filter(p => p.status === 'completed').length,
        failed: allProcesses.filter(p => p.status === 'failed').length
      }
    });
  } catch (error) {
    console.error('Error fetching processes:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch processes'
    });
  }
});

// Get a specific process by ID
router.get('/:processId', async (req, res) => {
  try {
    const { processId } = req.params;
    
    // Try memory first
    let process = aiProcessManager.getProcess(processId);
    
    if (!process) {
      // Try database
      try {
        const result = await databaseService.query(`
          SELECT * FROM ai_processes WHERE id = $1
        `, [processId]);
        
        if (result.rows && result.rows.length > 0) {
          const dbProcess = result.rows[0];
          process = {
            ...dbProcess,
            startTime: dbProcess.start_time ? new Date(dbProcess.start_time) : null,
            endTime: dbProcess.end_time ? new Date(dbProcess.end_time) : null,
            createdAt: new Date(dbProcess.created_at),
            resourceUsage: dbProcess.resource_usage || { cpu: 0, memory: 0 },
            logs: dbProcess.logs || [],
            errorDetails: dbProcess.error_details,
            result: dbProcess.result,
            metadata: dbProcess.metadata || {},
            source: 'database'
          };
        }
      } catch (dbError) {
        console.warn('Failed to fetch process from database:', dbError.message);
      }
    } else {
      process.source = 'memory';
    }
    
    if (!process) {
      return res.status(404).json({
        success: false,
        error: 'Process not found'
      });
    }
    
    res.json({
      success: true,
      data: process
    });
  } catch (error) {
    console.error('Error fetching process:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch process'
    });
  }
});

// Cancel a running process
router.delete('/:processId', async (req, res) => {
  try {
    const { processId } = req.params;
    
    // Check if process exists in memory (only memory processes can be cancelled)
    const process = aiProcessManager.getProcess(processId);
    
    if (!process) {
      return res.status(404).json({
        success: false,
        error: 'Process not found or cannot be cancelled (process may have already completed)'
      });
    }
    
    if (process.status === 'completed' || process.status === 'failed') {
      return res.status(400).json({
        success: false,
        error: `Cannot cancel ${process.status} process`
      });
    }
    
    // Cancel the process
    const cancelled = aiProcessManager.cancelProcess(processId);
    
    if (cancelled) {
      // Persist cancellation to database
      try {
        await persistProcessToDatabase(process);
      } catch (dbError) {
        console.warn('Failed to persist cancelled process to database:', dbError.message);
      }
      
      // Emit cancellation event via WebSocket
      req.app.get('io').emit('process:cancelled', {
        processId: processId,
        meetingId: process.meetingId,
        process: process
      });
      
      res.json({
        success: true,
        message: 'Process cancelled successfully',
        data: process
      });
    } else {
      res.status(400).json({
        success: false,
        error: 'Failed to cancel process'
      });
    }
  } catch (error) {
    console.error('Error cancelling process:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to cancel process'
    });
  }
});

// Get system resource usage and statistics
router.get('/system/stats', async (req, res) => {
  try {
    const resourceUsage = aiProcessManager.getResourceUsage();
    const processStats = aiProcessManager.getStatistics();
    const runningProcesses = aiProcessManager.getRunningProcesses();
    
    res.json({
      success: true,
      data: {
        resources: resourceUsage,
        processes: processStats,
        running: runningProcesses.map(p => ({
          id: p.id,
          meetingId: p.meetingId,
          type: p.processType,
          progress: p.progress,
          phase: p.phase,
          elapsedTime: p.elapsedTime
        }))
      }
    });
  } catch (error) {
    console.error('Error fetching system stats:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch system statistics'
    });
  }
});

// Helper function to persist process to database
async function persistProcessToDatabase(process) {
  try {
    await databaseService.query(`
      INSERT INTO ai_processes (
        id, meeting_id, process_type, status, progress, phase, message,
        start_time, end_time, elapsed_time, estimated_time_remaining,
        resource_usage, logs, error_details, result, metadata, created_at, updated_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18)
      ON CONFLICT (id) DO UPDATE SET
        status = EXCLUDED.status,
        progress = EXCLUDED.progress,
        phase = EXCLUDED.phase,
        message = EXCLUDED.message,
        end_time = EXCLUDED.end_time,
        elapsed_time = EXCLUDED.elapsed_time,
        estimated_time_remaining = EXCLUDED.estimated_time_remaining,
        resource_usage = EXCLUDED.resource_usage,
        logs = EXCLUDED.logs,
        error_details = EXCLUDED.error_details,
        result = EXCLUDED.result,
        updated_at = EXCLUDED.updated_at
    `, [
      process.id,
      process.meetingId,
      process.processType,
      process.status,
      process.progress,
      process.phase,
      process.message,
      process.startTime,
      process.endTime,
      process.elapsedTime,
      process.estimatedTimeRemaining,
      JSON.stringify(process.resourceUsage),
      JSON.stringify(process.logs),
      process.errorDetails ? JSON.stringify(process.errorDetails) : null,
      process.result ? JSON.stringify(process.result) : null,
      JSON.stringify(process.metadata),
      process.createdAt,
      new Date()
    ]);
  } catch (error) {
    console.error('Failed to persist process to database:', error);
    throw error;
  }
}

// Set up event listeners to automatically persist important process events
aiProcessManager.on('process:completed', async ({ processId, process }) => {
  try {
    await persistProcessToDatabase(process);
  } catch (error) {
    console.warn(`Failed to persist completed process ${processId}:`, error.message);
  }
});

aiProcessManager.on('process:failed', async ({ processId, process }) => {
  try {
    await persistProcessToDatabase(process);
  } catch (error) {
    console.warn(`Failed to persist failed process ${processId}:`, error.message);
  }
});

aiProcessManager.on('process:cancelled', async ({ processId, process }) => {
  try {
    await persistProcessToDatabase(process);
  } catch (error) {
    console.warn(`Failed to persist cancelled process ${processId}:`, error.message);
  }
});

module.exports = router;