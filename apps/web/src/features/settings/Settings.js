import React, { useState } from 'react';
import { useTheme } from '../../lib/theme';
import { useHealthCheck } from '../../hooks/useHealthCheck';
import './Settings.css';

const API_BASE = process.env.REACT_APP_API_URL || `http://${window.location.hostname}:3001`;

function Settings() {
  const { theme, toggleTheme } = useTheme();
  const { health, checkHealth } = useHealthCheck();
  const [qrCode, setQrCode] = useState(null);
  const [isGeneratingQR, setIsGeneratingQR] = useState(false);

  const generateQRCode = async () => {
    try {
      setIsGeneratingQR(true);
      const response = await fetch(`${API_BASE}/api/pairing/generate-qr`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
      });

      const data = await response.json();
      
      if (data.success) {
        setQrCode(data.data);
        // Auto-hide QR code after 5 minutes
        setTimeout(() => setQrCode(null), 5 * 60 * 1000);
      }
    } catch (error) {
      console.error('Failed to generate QR code:', error);
    } finally {
      setIsGeneratingQR(false);
    }
  };

  const getStatusIcon = (status) => {
    switch (status) {
      case 'healthy': return '🟢';
      case 'unhealthy': return '🔴';
      case 'checking': return '🟡';
      default: return '⚪';
    }
  };

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
          <h3>Device Pairing</h3>
          <div className="setting-item">
            <div className="setting-info">
              <label>Mobile Companion</label>
              <span className="setting-description">Pair your mobile device for remote recording</span>
            </div>
            <button 
              className="pair-button"
              onClick={generateQRCode}
              disabled={isGeneratingQR}
            >
              {isGeneratingQR ? 'Generating...' : '📱 Generate QR Code'}
            </button>
          </div>
          
          {qrCode && (
            <div className="qr-code-container">
              <div className="qr-code-header">
                <h4>Scan with your mobile device</h4>
                <p>This code expires in 5 minutes</p>
              </div>
              <img src={qrCode.qrCode} alt="QR Code for device pairing" className="qr-code" />
              <div className="qr-code-info">
                <p>Token: {qrCode.token?.substring(0, 8)}...</p>
                <p>Expires: {new Date(qrCode.expiresAt).toLocaleTimeString()}</p>
              </div>
            </div>
          )}
        </div>

        <div className="settings-section">
          <h3>System Health</h3>
          <div className="health-check">
            <div className="health-header">
              <span>Service Status</span>
              <button onClick={checkHealth} className="refresh-button">
                🔄 Refresh
              </button>
            </div>
            
            <div className="health-items">
              <div className="health-item">
                <span className="health-label">Backend API</span>
                <span className={`health-status ${health.backend.status}`}>
                  {getStatusIcon(health.backend.status)} {health.backend.status}
                </span>
              </div>
              
              <div className="health-item">
                <span className="health-label">Database</span>
                <span className={`health-status ${health.database.status}`}>
                  {getStatusIcon(health.database.status)} {health.database.status}
                </span>
              </div>
              
              <div className="health-item">
                <span className="health-label">AI Service (Ollama)</span>
                <span className={`health-status ${health.ollama.status}`}>
                  {getStatusIcon(health.ollama.status)} {health.ollama.status}
                </span>
                {health.ollama.data?.defaultModel && (
                  <span className="health-detail">Model: {health.ollama.data.defaultModel}</span>
                )}
              </div>
            </div>
          </div>
        </div>

        <div className="settings-section">
          <h3>About</h3>
          <div className="about-info">
            <div className="about-item">
              <span className="about-label">Version</span>
              <span className="about-value">1.0.0-alpha</span>
            </div>
            <div className="about-item">
              <span className="about-label">License</span>
              <span className="about-value">MIT License</span>
            </div>
            <div className="about-item">
              <span className="about-label">Last Updated</span>
              <span className="about-value">{new Date().toLocaleDateString()}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default Settings;