import React, { useState } from 'react';
import { useTheme } from '../../lib/theme';
import { useHealthCheck } from '../../hooks/useHealthCheck';
import PrivacySettings from './PrivacySettings';
import './Settings.css';

const API_BASE = process.env.REACT_APP_API_URL || `http://${window.location.hostname}:3001`;

function Settings() {
  const { theme, toggleTheme } = useTheme();
  const { health, checkHealth } = useHealthCheck();
  const [qrCode, setQrCode] = useState(null);
  const [isGeneratingQR, setIsGeneratingQR] = useState(false);
  const [activeTab, setActiveTab] = useState('general');

  const generateQRCode = async () => {
    try {
      setIsGeneratingQR(true);
      
      // Auto-detect the host IP for mobile device access
      const getHostIP = () => {
        // Try to get the actual host IP that mobile devices can reach
        // First check if we're accessed via IP
        const hostname = window.location.hostname;
        if (/^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/.test(hostname) && !hostname.startsWith('127.')) {
          return hostname;
        }
        
        // If accessed via localhost, we need to provide the actual network IP
        // In a real deployment, this might come from environment variables or detection
        if (hostname === 'localhost' || hostname === '127.0.0.1') {
          // For development, try to determine the network IP
          // This could be configured or detected by the backend
          return null; // Let backend handle detection
        }
        
        return hostname;
      };
      
      const hostIP = getHostIP();
      const headers = {
        'Content-Type': 'application/json',
      };
      
      // Add host override if we detected a specific IP
      if (hostIP) {
        headers['X-Host-Override'] = hostIP;
      }
      
      const response = await fetch(`${API_BASE}/api/pairing/generate-qr`, {
        method: 'POST',
        headers,
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

      <div className="settings-tabs">
        <button 
          className={`settings-tab ${activeTab === 'general' ? 'active' : ''}`}
          onClick={() => setActiveTab('general')}
        >
          General
        </button>
        <button 
          className={`settings-tab ${activeTab === 'privacy' ? 'active' : ''}`}
          onClick={() => setActiveTab('privacy')}
        >
          Privacy & Permissions
        </button>
      </div>
      
      <div className="settings-content">
        {activeTab === 'general' && (
          <div className="general-settings">
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
          </div>
        )}
        
        {activeTab === 'privacy' && (
          <PrivacySettings />
        )}
      </div>
    </div>
  );
}

export default Settings;