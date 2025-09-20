import React from 'react';
import { useTheme } from '../../lib/theme';
import './Settings.css';

function Settings() {
  const { theme, toggleTheme } = useTheme();

  return (
    <div className="settings">
      <div className="settings-header">
        <h1>Settings</h1>
        <p className="settings-subtitle">Configure your Nexus experience</p>
      </div>
      
      <div className="settings-content">
        <div className="settings-section">
          <h3>Appearance</h3>
          <div className="setting-item">
            <div className="setting-info">
              <label>Theme</label>
              <span className="setting-description">Choose your preferred color scheme</span>
            </div>
            <button 
              className="theme-toggle-btn"
              onClick={toggleTheme}
            >
              {theme === 'light' ? '🌙 Dark' : '☀️ Light'}
            </button>
          </div>
        </div>

        <div className="settings-section">
          <h3>Audio</h3>
          <div className="setting-item">
            <div className="setting-info">
              <label>Microphone</label>
              <span className="setting-description">Default microphone device</span>
            </div>
            <select className="setting-select">
              <option>Default - Built-in Microphone</option>
              <option>External USB Microphone</option>
            </select>
          </div>
          
          <div className="setting-item">
            <div className="setting-info">
              <label>Audio Quality</label>
              <span className="setting-description">Recording quality for transcription</span>
            </div>
            <select className="setting-select">
              <option>High (Recommended)</option>
              <option>Medium</option>
              <option>Low</option>
            </select>
          </div>
        </div>

        <div className="settings-section">
          <h3>Transcription</h3>
          <div className="setting-item">
            <div className="setting-info">
              <label>Language</label>
              <span className="setting-description">Primary language for transcription</span>
            </div>
            <select className="setting-select">
              <option>Auto-detect</option>
              <option>English</option>
              <option>Spanish</option>
              <option>French</option>
              <option>German</option>
            </select>
          </div>
          
          <div className="setting-item">
            <div className="setting-info">
              <label>Model</label>
              <span className="setting-description">Whisper model for transcription accuracy</span>
            </div>
            <select className="setting-select">
              <option>Base (Recommended)</option>
              <option>Tiny (Fast)</option>
              <option>Small</option>
              <option>Medium</option>
              <option>Large (Slow)</option>
            </select>
          </div>
        </div>

        <div className="settings-section">
          <h3>Privacy</h3>
          <div className="setting-item">
            <div className="setting-info">
              <label>Auto-delete recordings</label>
              <span className="setting-description">Automatically delete audio files after transcription</span>
            </div>
            <label className="toggle">
              <input type="checkbox" defaultChecked />
              <span className="slider"></span>
            </label>
          </div>
          
          <div className="setting-item">
            <div className="setting-info">
              <label>Local processing only</label>
              <span className="setting-description">Keep all data on your local machine</span>
            </div>
            <label className="toggle">
              <input type="checkbox" defaultChecked disabled />
              <span className="slider"></span>
            </label>
          </div>
        </div>

        <div className="settings-section">
          <h3>About</h3>
          <div className="about-info">
            <div className="about-item">
              <span className="about-label">Version</span>
              <span className="about-value">1.0.0</span>
            </div>
            <div className="about-item">
              <span className="about-label">Backend Status</span>
              <span className="about-value status online">Online</span>
            </div>
            <div className="about-item">
              <span className="about-label">Transcription Service</span>
              <span className="about-value status online">Ready</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default Settings;