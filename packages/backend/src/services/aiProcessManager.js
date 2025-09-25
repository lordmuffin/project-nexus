const { v4: uuidv4 } = require('uuid');
const EventEmitter = require('events');

class AIProcessManager extends EventEmitter {
  constructor() {
    super();
    this.processes = new Map(); // In-memory process storage
    this.resourceMonitor = {
      cpu: 0,
      memory: 0,
      lastUpdate: null
    };
  }

  /**
   * Create and register a new AI process
   * @param {string} meetingId - The meeting ID this process belongs to
   * @param {string} processType - Type of process ('transcription', 'analysis', 'chat', 'auto-summary')
   * @param {Object} metadata - Additional process metadata
   * @returns {string} processId - Unique process identifier
   */
  createProcess(meetingId, processType, metadata = {}) {
    const processId = uuidv4();
    const process = {
      id: processId,
      meetingId,
      processType,
      status: 'queued',
      progress: 0,
      startTime: null,
      endTime: null,
      elapsedTime: 0,
      estimatedTimeRemaining: metadata.estimatedTime || null,
      phase: 'initializing',
      message: 'Process queued...',
      resourceUsage: {
        cpu: 0,
        memory: 0
      },
      logs: [],
      errorDetails: null,
      metadata: metadata,
      createdAt: new Date()
    };

    this.processes.set(processId, process);
    this.emit('process:created', { processId, process });
    
    console.log(`AI Process created: ${processId} (${processType}) for meeting ${meetingId}`);
    return processId;
  }

  /**
   * Start a process
   * @param {string} processId - Process ID to start
   */
  startProcess(processId) {
    const process = this.processes.get(processId);
    if (!process) {
      throw new Error(`Process ${processId} not found`);
    }

    process.status = 'running';
    process.startTime = new Date();
    process.message = 'Process started...';
    this.addLog(processId, 'info', 'Process started');

    this.emit('process:started', { processId, process });
    console.log(`AI Process started: ${processId} (${process.processType})`);
  }

  /**
   * Update process progress
   * @param {string} processId - Process ID to update
   * @param {number} progress - Progress percentage (0-100)
   * @param {string} phase - Current phase name
   * @param {string} message - Status message
   * @param {number} estimatedTimeRemaining - Estimated time remaining in seconds
   */
  updateProgress(processId, progress, phase = null, message = null, estimatedTimeRemaining = null) {
    const process = this.processes.get(processId);
    if (!process || process.status !== 'running') {
      return; // Process not found or not running
    }

    process.progress = Math.min(100, Math.max(0, progress));
    if (phase) process.phase = phase;
    if (message) process.message = message;
    if (estimatedTimeRemaining !== null) process.estimatedTimeRemaining = estimatedTimeRemaining;
    
    // Calculate elapsed time
    if (process.startTime) {
      process.elapsedTime = Math.floor((Date.now() - process.startTime.getTime()) / 1000);
    }

    this.addLog(processId, 'info', `Progress: ${progress}% - ${message || phase || 'Processing...'}`);
    this.emit('process:progress', { processId, process });
  }

  /**
   * Complete a process successfully
   * @param {string} processId - Process ID to complete
   * @param {Object} result - Process result data
   */
  completeProcess(processId, result = {}) {
    const process = this.processes.get(processId);
    if (!process) {
      throw new Error(`Process ${processId} not found`);
    }

    process.status = 'completed';
    process.progress = 100;
    process.endTime = new Date();
    process.message = 'Process completed successfully';
    if (process.startTime) {
      process.elapsedTime = Math.floor((process.endTime.getTime() - process.startTime.getTime()) / 1000);
    }
    process.result = result;

    this.addLog(processId, 'success', 'Process completed successfully');
    this.emit('process:completed', { processId, process, result });
    
    console.log(`AI Process completed: ${processId} (${process.processType}) in ${process.elapsedTime}s`);
  }

  /**
   * Fail a process with error details
   * @param {string} processId - Process ID to fail
   * @param {Error|string} error - Error object or message
   */
  failProcess(processId, error) {
    const process = this.processes.get(processId);
    if (!process) {
      throw new Error(`Process ${processId} not found`);
    }

    process.status = 'failed';
    process.endTime = new Date();
    process.message = 'Process failed';
    if (process.startTime) {
      process.elapsedTime = Math.floor((process.endTime.getTime() - process.startTime.getTime()) / 1000);
    }
    
    const errorDetails = typeof error === 'string' ? { message: error } : {
      message: error.message || 'Unknown error',
      stack: error.stack,
      name: error.name
    };
    process.errorDetails = errorDetails;

    this.addLog(processId, 'error', `Process failed: ${errorDetails.message}`);
    this.emit('process:failed', { processId, process, error: errorDetails });
    
    console.error(`AI Process failed: ${processId} (${process.processType}):`, errorDetails.message);
  }

  /**
   * Cancel a running process
   * @param {string} processId - Process ID to cancel
   */
  cancelProcess(processId) {
    const process = this.processes.get(processId);
    if (!process) {
      throw new Error(`Process ${processId} not found`);
    }

    if (process.status === 'completed' || process.status === 'failed') {
      throw new Error(`Cannot cancel ${process.status} process`);
    }

    process.status = 'cancelled';
    process.endTime = new Date();
    process.message = 'Process cancelled by user';
    if (process.startTime) {
      process.elapsedTime = Math.floor((process.endTime.getTime() - process.startTime.getTime()) / 1000);
    }

    this.addLog(processId, 'warning', 'Process cancelled by user');
    this.emit('process:cancelled', { processId, process });
    
    console.log(`AI Process cancelled: ${processId} (${process.processType})`);
    return true;
  }

  /**
   * Add a log entry to a process
   * @param {string} processId - Process ID
   * @param {string} level - Log level ('info', 'warning', 'error', 'success')
   * @param {string} message - Log message
   */
  addLog(processId, level, message) {
    const process = this.processes.get(processId);
    if (!process) return;

    const logEntry = {
      timestamp: new Date(),
      level,
      message
    };

    process.logs.push(logEntry);
    
    // Keep only last 100 log entries to prevent memory issues
    if (process.logs.length > 100) {
      process.logs = process.logs.slice(-100);
    }
  }

  /**
   * Get a specific process by ID
   * @param {string} processId - Process ID
   * @returns {Object|null} Process object or null if not found
   */
  getProcess(processId) {
    return this.processes.get(processId) || null;
  }

  /**
   * Get all processes for a specific meeting
   * @param {string} meetingId - Meeting ID
   * @returns {Array} Array of processes for the meeting
   */
  getProcessesForMeeting(meetingId) {
    const processes = [];
    for (const process of this.processes.values()) {
      if (process.meetingId === meetingId) {
        processes.push(process);
      }
    }
    return processes.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
  }

  /**
   * Get all running processes
   * @returns {Array} Array of running processes
   */
  getRunningProcesses() {
    const runningProcesses = [];
    for (const process of this.processes.values()) {
      if (process.status === 'running') {
        runningProcesses.push(process);
      }
    }
    return runningProcesses;
  }

  /**
   * Update system resource usage
   * @param {number} cpu - CPU usage percentage
   * @param {number} memory - Memory usage in MB
   */
  updateResourceUsage(cpu, memory) {
    this.resourceMonitor.cpu = cpu;
    this.resourceMonitor.memory = memory;
    this.resourceMonitor.lastUpdate = new Date();

    // Update resource usage for running processes
    for (const process of this.processes.values()) {
      if (process.status === 'running') {
        process.resourceUsage.cpu = cpu;
        process.resourceUsage.memory = memory;
      }
    }

    this.emit('resources:updated', { cpu, memory, timestamp: this.resourceMonitor.lastUpdate });
  }

  /**
   * Get current system resource usage
   * @returns {Object} Resource usage information
   */
  getResourceUsage() {
    return { ...this.resourceMonitor };
  }

  /**
   * Clean up old completed/failed processes to prevent memory leaks
   * @param {number} maxAge - Maximum age in milliseconds (default: 24 hours)
   */
  cleanup(maxAge = 24 * 60 * 60 * 1000) {
    const cutoffTime = new Date(Date.now() - maxAge);
    let cleanedCount = 0;

    for (const [processId, process] of this.processes.entries()) {
      if ((process.status === 'completed' || process.status === 'failed') && 
          process.endTime && process.endTime < cutoffTime) {
        this.processes.delete(processId);
        cleanedCount++;
      }
    }

    if (cleanedCount > 0) {
      console.log(`AI Process Manager: Cleaned up ${cleanedCount} old processes`);
    }
  }

  /**
   * Get process statistics
   * @returns {Object} Process statistics
   */
  getStatistics() {
    const stats = {
      total: this.processes.size,
      running: 0,
      queued: 0,
      completed: 0,
      failed: 0,
      cancelled: 0
    };

    for (const process of this.processes.values()) {
      stats[process.status] = (stats[process.status] || 0) + 1;
    }

    return stats;
  }
}

// Create singleton instance
const aiProcessManager = new AIProcessManager();

// Set up periodic cleanup (run every hour)
setInterval(() => {
  aiProcessManager.cleanup();
}, 60 * 60 * 1000);

module.exports = aiProcessManager;