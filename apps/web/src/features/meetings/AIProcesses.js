import React, { useState, useEffect } from 'react';
import './AIProcesses.css';

// Dynamic API base URL that works with actual host IP
const getApiBase = () => {
  if (process.env.REACT_APP_API_URL) {
    return process.env.REACT_APP_API_URL;
  }
  
  // Use current hostname with port 3001 for backend
  const protocol = window.location.protocol;
  const hostname = window.location.hostname;
  return `${protocol}//${hostname}:3001`;
};

const API_BASE = getApiBase();

const AIProcesses = ({ meetingId, socket }) => {
  const [processes, setProcesses] = useState([]);
  const [systemStats, setSystemStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (meetingId) {
      fetchProcesses();
      fetchSystemStats();
    }

    // Set up WebSocket listeners for real-time updates
    if (socket) {
      socket.on('process:started', handleProcessStarted);
      socket.on('process:progress', handleProcessProgress);
      socket.on('process:completed', handleProcessCompleted);
      socket.on('process:failed', handleProcessFailed);
      socket.on('process:cancelled', handleProcessCancelled);

      return () => {
        socket.off('process:started', handleProcessStarted);
        socket.off('process:progress', handleProcessProgress);
        socket.off('process:completed', handleProcessCompleted);
        socket.off('process:failed', handleProcessFailed);
        socket.off('process:cancelled', handleProcessCancelled);
      };
    }
  }, [meetingId, socket]);

  const fetchProcesses = async () => {
    try {
      const response = await fetch(`${API_BASE}/api/processes/meeting/${meetingId}`);
      const data = await response.json();
      
      if (data.success) {
        setProcesses(data.data || []);
      } else {
        setError(data.error || 'Failed to fetch processes');
      }
    } catch (err) {
      console.error('Error fetching processes:', err);
      setError('Network error while fetching processes');
    } finally {
      setLoading(false);
    }
  };

  const fetchSystemStats = async () => {
    try {
      const response = await fetch(`${API_BASE}/api/processes/system/stats`);
      const data = await response.json();
      
      if (data.success) {
        setSystemStats(data.data);
      }
    } catch (err) {
      console.error('Error fetching system stats:', err);
    }
  };

  const cancelProcess = async (processId) => {
    try {
      const response = await fetch(`${API_BASE}/api/processes/${processId}`, {
        method: 'DELETE',
      });
      
      const data = await response.json();
      
      if (data.success) {
        // Process will be updated via WebSocket event
        console.log('Process cancelled successfully');
      } else {
        console.error('Failed to cancel process:', data.error);
      }
    } catch (err) {
      console.error('Error cancelling process:', err);
    }
  };

  // WebSocket event handlers
  const handleProcessStarted = (data) => {
    if (data.meetingId === meetingId) {
      setProcesses(prev => [data.process, ...prev.filter(p => p.id !== data.processId)]);
    }
  };

  const handleProcessProgress = (data) => {
    if (data.meetingId === meetingId) {
      setProcesses(prev => prev.map(p => 
        p.id === data.processId ? data.process : p
      ));
    }
  };

  const handleProcessCompleted = (data) => {
    if (data.meetingId === meetingId) {
      setProcesses(prev => prev.map(p => 
        p.id === data.processId ? data.process : p
      ));
    }
  };

  const handleProcessFailed = (data) => {
    if (data.meetingId === meetingId) {
      setProcesses(prev => prev.map(p => 
        p.id === data.processId ? data.process : p
      ));
    }
  };

  const handleProcessCancelled = (data) => {
    if (data.meetingId === meetingId) {
      setProcesses(prev => prev.map(p => 
        p.id === data.processId ? data.process : p
      ));
    }
  };

  const formatDuration = (ms) => {
    if (!ms) return 'N/A';
    const seconds = Math.floor(ms / 1000);
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    
    if (minutes > 0) {
      return `${minutes}m ${remainingSeconds}s`;
    }
    return `${remainingSeconds}s`;
  };

  const formatTimestamp = (timestamp) => {
    if (!timestamp) return 'N/A';
    return new Date(timestamp).toLocaleString();
  };

  const getStatusIcon = (status) => {
    switch (status) {
      case 'queued': return '⏳';
      case 'running': return '🔄';
      case 'completed': return '✅';
      case 'failed': return '❌';
      case 'cancelled': return '⚪';
      default: return '❓';
    }
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'queued': return '#ffc107';
      case 'running': return '#007bff';
      case 'completed': return '#28a745';
      case 'failed': return '#dc3545';
      case 'cancelled': return '#6c757d';
      default: return '#6c757d';
    }
  };

  if (loading) {
    return (
      <div className="ai-processes-loading">
        <div className="loading-spinner">🔄</div>
        <p>Loading AI processes...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="ai-processes-error">
        <div className="error-icon">⚠️</div>
        <p>Error: {error}</p>
        <button onClick={fetchProcesses} className="retry-btn">
          Retry
        </button>
      </div>
    );
  }

  return (
    <div className="ai-processes">
      {/* System Statistics */}
      {systemStats && (
        <div className="system-stats">
          <h4>System Status</h4>
          <div className="stats-grid">
            <div className="stat-item">
              <span className="stat-label">CPU Usage:</span>
              <span className="stat-value">{systemStats.resources?.cpu?.toFixed(1) || '0.0'}%</span>
            </div>
            <div className="stat-item">
              <span className="stat-label">Memory:</span>
              <span className="stat-value">{systemStats.resources?.memory?.toFixed(1) || '0.0'}%</span>
            </div>
            <div className="stat-item">
              <span className="stat-label">Active Processes:</span>
              <span className="stat-value">{systemStats.processes?.active || 0}</span>
            </div>
            <div className="stat-item">
              <span className="stat-label">Total Completed:</span>
              <span className="stat-value">{systemStats.processes?.total || 0}</span>
            </div>
          </div>
        </div>
      )}

      {/* Processes List */}
      <div className="processes-list">
        <h4>AI Processes for this Meeting</h4>
        
        {processes.length === 0 ? (
          <div className="no-processes">
            <div className="empty-icon">🤖</div>
            <p>No AI processes found for this meeting</p>
            <p className="empty-subtitle">Processes will appear here when AI analysis is running</p>
          </div>
        ) : (
          <div className="processes-items">
            {processes.map(process => (
              <div key={process.id} className={`process-item status-${process.status}`}>
                <div className="process-header">
                  <div className="process-title">
                    <span className="process-icon">{getStatusIcon(process.status)}</span>
                    <span className="process-type">{process.processType || process.process_type}</span>
                    <span 
                      className="process-status" 
                      style={{ color: getStatusColor(process.status) }}
                    >
                      {process.status}
                    </span>
                  </div>
                  
                  <div className="process-actions">
                    {(process.status === 'running' || process.status === 'queued') && (
                      <button 
                        onClick={() => cancelProcess(process.id)}
                        className="cancel-btn"
                        title="Cancel Process"
                      >
                        🛑 Cancel
                      </button>
                    )}
                  </div>
                </div>

                <div className="process-details">
                  <div className="process-meta">
                    <span className="meta-item">
                      <strong>Started:</strong> {formatTimestamp(process.startTime || process.start_time)}
                    </span>
                    {process.endTime || process.end_time ? (
                      <span className="meta-item">
                        <strong>Ended:</strong> {formatTimestamp(process.endTime || process.end_time)}
                      </span>
                    ) : null}
                    <span className="meta-item">
                      <strong>Duration:</strong> {formatDuration(process.elapsedTime || process.elapsed_time)}
                    </span>
                  </div>

                  {process.progress !== undefined && process.progress !== null && (
                    <div className="process-progress">
                      <div className="progress-bar">
                        <div 
                          className="progress-fill" 
                          style={{ width: `${process.progress}%` }}
                        ></div>
                      </div>
                      <div className="progress-info">
                        <span className="progress-percentage">{process.progress}%</span>
                        {process.phase && (
                          <span className="progress-phase">{process.phase}</span>
                        )}
                        {process.estimatedTimeRemaining && (
                          <span className="time-remaining">
                            ~{process.estimatedTimeRemaining}s remaining
                          </span>
                        )}
                      </div>
                    </div>
                  )}

                  {process.message && (
                    <div className="process-message">
                      <strong>Status:</strong> {process.message}
                    </div>
                  )}

                  {process.resourceUsage && (
                    <div className="resource-usage">
                      <span className="resource-item">
                        CPU: {process.resourceUsage.cpu?.toFixed(1) || '0.0'}%
                      </span>
                      <span className="resource-item">
                        Memory: {process.resourceUsage.memory?.toFixed(1) || '0.0'}%
                      </span>
                    </div>
                  )}

                  {process.errorDetails && (
                    <div className="process-error">
                      <strong>Error:</strong> {JSON.stringify(process.errorDetails)}
                    </div>
                  )}

                  {/* Logs Section */}
                  {process.logs && process.logs.length > 0 && (
                    <div className="process-logs">
                      <details>
                        <summary>View Logs ({process.logs.length})</summary>
                        <div className="logs-content">
                          {process.logs.map((log, index) => (
                            <div key={index} className="log-entry">
                              <span className="log-timestamp">
                                {formatTimestamp(log.timestamp)}
                              </span>
                              <span className={`log-level log-${log.level}`}>
                                {log.level}
                              </span>
                              <span className="log-message">{log.message}</span>
                            </div>
                          ))}
                        </div>
                      </details>
                    </div>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default AIProcesses;