import React from 'react';
import './Dashboard.css';

function Dashboard() {
  return (
    <div className="dashboard">
      <div className="dashboard-header">
        <h1>Dashboard</h1>
        <p className="dashboard-subtitle">Welcome to Project Nexus</p>
      </div>
      
      <div className="dashboard-grid">
        <div className="card">
          <div className="card-header">
            <h3>Recent Meetings</h3>
            <span className="card-icon">📊</span>
          </div>
          <div className="card-content">
            <p className="card-description">No recent meetings</p>
            <button className="card-action">View All Meetings</button>
          </div>
        </div>
        
        <div className="card">
          <div className="card-header">
            <h3>Quick Actions</h3>
            <span className="card-icon">⚡</span>
          </div>
          <div className="card-content">
            <div className="action-buttons">
              <button className="action-button primary">Start New Meeting</button>
              <button className="action-button secondary">Open Chat</button>
            </div>
          </div>
        </div>
        
        <div className="card">
          <div className="card-header">
            <h3>System Status</h3>
            <span className="card-icon">🔧</span>
          </div>
          <div className="card-content">
            <div className="status-list">
              <div className="status-item">
                <span className="status-label">Backend Service</span>
                <span className="status-value online">Online</span>
              </div>
              <div className="status-item">
                <span className="status-label">Transcription</span>
                <span className="status-value online">Ready</span>
              </div>
              <div className="status-item">
                <span className="status-label">Storage</span>
                <span className="status-value online">Available</span>
              </div>
            </div>
          </div>
        </div>
        
        <div className="card">
          <div className="card-header">
            <h3>Statistics</h3>
            <span className="card-icon">📈</span>
          </div>
          <div className="card-content">
            <div className="stats-grid">
              <div className="stat">
                <div className="stat-value">0</div>
                <div className="stat-label">Total Meetings</div>
              </div>
              <div className="stat">
                <div className="stat-value">0</div>
                <div className="stat-label">Hours Recorded</div>
              </div>
              <div className="stat">
                <div className="stat-value">0</div>
                <div className="stat-label">Transcriptions</div>
              </div>
              <div className="stat">
                <div className="stat-value">0</div>
                <div className="stat-label">Chat Messages</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default Dashboard;