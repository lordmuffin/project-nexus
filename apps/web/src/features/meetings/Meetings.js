import React from 'react';
import './Meetings.css';

function Meetings() {
  return (
    <div className="meetings">
      <div className="meetings-header">
        <h1>Meetings</h1>
        <button className="btn-primary">New Meeting</button>
      </div>
      
      <div className="meetings-content">
        <div className="empty-state">
          <div className="empty-icon">📅</div>
          <h3>No meetings yet</h3>
          <p>Create your first meeting to get started with transcription and collaboration.</p>
          <button className="btn-secondary">Schedule Meeting</button>
        </div>
      </div>
    </div>
  );
}

export default Meetings;