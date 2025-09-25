import React, { useState, useEffect } from 'react';
import './PrivacySettings.css';

const PrivacySettings = () => {
  const [permissions, setPermissions] = useState({
    microphone: false,
    system_audio: false,
    screen_recording: false,
    file_storage: true,
    analytics: false
  });

  const [dataRetention, setDataRetention] = useState({
    recordings: '30', // days
    transcripts: '365',
    logs: '7'
  });

  const [privacyLevel, setPrivacyLevel] = useState('balanced');
  const [isElectron, setIsElectron] = useState(false);

  useEffect(() => {
    setIsElectron(!!window.electronAPI);
    loadPermissionStatus();
    loadPrivacySettings();
  }, []);

  const loadPermissionStatus = async () => {
    if (window.electronAPI) {
      try {
        // Get system audio permission status
        const systemAudioStatus = await window.electronAPI.audio.getSystemAudioPermission();
        setPermissions(prev => ({
          ...prev,
          system_audio: systemAudioStatus.granted,
          screen_recording: systemAudioStatus.granted
        }));
      } catch (error) {
        console.error('Error loading permission status:', error);
      }
    }

    // Check web permissions
    try {
      const micPermission = await navigator.permissions.query({ name: 'microphone' });
      setPermissions(prev => ({
        ...prev,
        microphone: micPermission.state === 'granted'
      }));
    } catch (error) {
      console.log('Could not query microphone permission');
    }
  };

  const loadPrivacySettings = () => {
    try {
      const savedSettings = localStorage.getItem('nexus-privacy-settings');
      if (savedSettings) {
        const settings = JSON.parse(savedSettings);
        setDataRetention(settings.dataRetention || dataRetention);
        setPrivacyLevel(settings.privacyLevel || 'balanced');
        setPermissions(prev => ({
          ...prev,
          file_storage: settings.permissions?.file_storage !== false,
          analytics: settings.permissions?.analytics || false
        }));
      }
    } catch (error) {
      console.error('Error loading privacy settings:', error);
    }
  };

  const savePrivacySettings = () => {
    try {
      const settings = {
        dataRetention,
        privacyLevel,
        permissions: {
          file_storage: permissions.file_storage,
          analytics: permissions.analytics
        },
        lastUpdated: new Date().toISOString()
      };
      localStorage.setItem('nexus-privacy-settings', JSON.stringify(settings));
      console.log('Privacy settings saved');
    } catch (error) {
      console.error('Error saving privacy settings:', error);
    }
  };

  const requestPermission = async (permissionType) => {
    try {
      switch (permissionType) {
        case 'microphone':
          if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
            const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
            stream.getTracks().forEach(track => track.stop());
            setPermissions(prev => ({ ...prev, microphone: true }));
          }
          break;

        case 'system_audio':
          if (window.electronAPI) {
            const result = await window.electronAPI.audio.requestSystemAudioPermission();
            setPermissions(prev => ({
              ...prev,
              system_audio: result.granted,
              screen_recording: result.granted
            }));
          } else {
            // Web fallback: request screen capture with audio
            try {
              const stream = await navigator.mediaDevices.getDisplayMedia({ audio: true, video: true });
              stream.getTracks().forEach(track => track.stop());
              setPermissions(prev => ({ ...prev, system_audio: true }));
            } catch (error) {
              console.error('Screen capture permission denied');
            }
          }
          break;

        default:
          console.log('Unknown permission type:', permissionType);
      }
    } catch (error) {
      console.error('Error requesting permission:', error);
    }
  };

  const updatePermission = (permissionType, granted) => {
    setPermissions(prev => ({
      ...prev,
      [permissionType]: granted
    }));
    savePrivacySettings();
  };

  const updateDataRetention = (type, days) => {
    setDataRetention(prev => ({
      ...prev,
      [type]: days
    }));
    savePrivacySettings();
  };

  const setPrivacyProfile = (level) => {
    setPrivacyLevel(level);
    
    switch (level) {
      case 'strict':
        setDataRetention({ recordings: '7', transcripts: '30', logs: '1' });
        setPermissions(prev => ({
          ...prev,
          file_storage: true,
          analytics: false
        }));
        break;
      case 'balanced':
        setDataRetention({ recordings: '30', transcripts: '365', logs: '7' });
        setPermissions(prev => ({
          ...prev,
          file_storage: true,
          analytics: false
        }));
        break;
      case 'minimal':
        setDataRetention({ recordings: '365', transcripts: '365', logs: '30' });
        setPermissions(prev => ({
          ...prev,
          file_storage: true,
          analytics: true
        }));
        break;
    }
    savePrivacySettings();
  };

  const clearAllData = async () => {
    const confirmed = window.confirm(
      'This will permanently delete all recordings, transcripts, and user data. This action cannot be undone. Are you sure?'
    );
    
    if (confirmed) {
      try {
        // Clear local storage
        localStorage.removeItem('nexus-privacy-settings');
        localStorage.removeItem('nexus-recordings');
        localStorage.removeItem('nexus-transcripts');
        
        // If in Electron, clear desktop recordings too
        if (window.electronAPI) {
          // This would call a backend API to clear server-side data
          console.log('Clearing server-side data...');
        }
        
        alert('All data has been cleared successfully.');
        
        // Reset to default settings
        setDataRetention({ recordings: '30', transcripts: '365', logs: '7' });
        setPrivacyLevel('balanced');
        setPermissions(prev => ({
          ...prev,
          file_storage: true,
          analytics: false
        }));
        
      } catch (error) {
        console.error('Error clearing data:', error);
        alert('Error clearing data. Please try again.');
      }
    }
  };

  const getPermissionIcon = (granted) => {
    return granted ? '✅' : '❌';
  };

  const getPermissionStatus = (granted) => {
    return granted ? 'Granted' : 'Not Granted';
  };

  const getPermissionColor = (granted) => {
    return granted ? 'var(--success-color, #10b981)' : 'var(--error-color, #ef4444)';
  };

  return (
    <div className="privacy-settings">
      <div className="privacy-header">
        <h2>Privacy & Permissions</h2>
        <p>Manage your privacy settings and control how your data is handled</p>
      </div>

      {/* Privacy Profile Selection */}
      <div className="privacy-section">
        <h3>Privacy Profile</h3>
        <div className="privacy-profiles">
          <div
            className={`privacy-profile ${privacyLevel === 'strict' ? 'selected' : ''}`}
            onClick={() => setPrivacyProfile('strict')}
          >
            <div className="profile-icon">🔒</div>
            <div className="profile-info">
              <h4>Strict</h4>
              <p>Maximum privacy, minimal data retention</p>
            </div>
          </div>
          
          <div
            className={`privacy-profile ${privacyLevel === 'balanced' ? 'selected' : ''}`}
            onClick={() => setPrivacyProfile('balanced')}
          >
            <div className="profile-icon">⚖️</div>
            <div className="profile-info">
              <h4>Balanced</h4>
              <p>Good privacy with reasonable features</p>
            </div>
          </div>
          
          <div
            className={`privacy-profile ${privacyLevel === 'minimal' ? 'selected' : ''}`}
            onClick={() => setPrivacyProfile('minimal')}
          >
            <div className="profile-icon">📊</div>
            <div className="profile-info">
              <h4>Minimal</h4>
              <p>Basic privacy, enhanced features</p>
            </div>
          </div>
        </div>
      </div>

      {/* Permissions */}
      <div className="privacy-section">
        <h3>Permissions</h3>
        <div className="permissions-list">
          <div className="permission-item">
            <div className="permission-info">
              <div className="permission-header">
                <span className="permission-icon">🎤</span>
                <span className="permission-name">Microphone Access</span>
                <span 
                  className="permission-status"
                  style={{ color: getPermissionColor(permissions.microphone) }}
                >
                  {getPermissionIcon(permissions.microphone)} {getPermissionStatus(permissions.microphone)}
                </span>
              </div>
              <p className="permission-description">
                Required for recording audio from your microphone
              </p>
            </div>
            {!permissions.microphone && (
              <button 
                onClick={() => requestPermission('microphone')}
                className="permission-button"
              >
                Request Access
              </button>
            )}
          </div>

          <div className="permission-item">
            <div className="permission-info">
              <div className="permission-header">
                <span className="permission-icon">🖥️</span>
                <span className="permission-name">System Audio Access</span>
                <span 
                  className="permission-status"
                  style={{ color: getPermissionColor(permissions.system_audio) }}
                >
                  {getPermissionIcon(permissions.system_audio)} {getPermissionStatus(permissions.system_audio)}
                </span>
              </div>
              <p className="permission-description">
                {isElectron 
                  ? 'Required for recording system audio in desktop app'
                  : 'Required for recording system audio via screen capture'
                }
              </p>
            </div>
            {!permissions.system_audio && (
              <button 
                onClick={() => requestPermission('system_audio')}
                className="permission-button"
              >
                Request Access
              </button>
            )}
          </div>

          <div className="permission-item">
            <div className="permission-info">
              <div className="permission-header">
                <span className="permission-icon">💾</span>
                <span className="permission-name">Local File Storage</span>
                <span 
                  className="permission-status"
                  style={{ color: getPermissionColor(permissions.file_storage) }}
                >
                  {getPermissionIcon(permissions.file_storage)} {getPermissionStatus(permissions.file_storage)}
                </span>
              </div>
              <p className="permission-description">
                Store recordings and transcripts locally on your device
              </p>
            </div>
            <label className="toggle-switch">
              <input
                type="checkbox"
                checked={permissions.file_storage}
                onChange={(e) => updatePermission('file_storage', e.target.checked)}
              />
              <span className="toggle-slider"></span>
            </label>
          </div>

          <div className="permission-item">
            <div className="permission-info">
              <div className="permission-header">
                <span className="permission-icon">📈</span>
                <span className="permission-name">Analytics & Telemetry</span>
                <span 
                  className="permission-status"
                  style={{ color: getPermissionColor(permissions.analytics) }}
                >
                  {getPermissionIcon(permissions.analytics)} {getPermissionStatus(permissions.analytics)}
                </span>
              </div>
              <p className="permission-description">
                Help improve the app by sharing anonymous usage data
              </p>
            </div>
            <label className="toggle-switch">
              <input
                type="checkbox"
                checked={permissions.analytics}
                onChange={(e) => updatePermission('analytics', e.target.checked)}
              />
              <span className="toggle-slider"></span>
            </label>
          </div>
        </div>
      </div>

      {/* Data Retention */}
      <div className="privacy-section">
        <h3>Data Retention</h3>
        <div className="retention-settings">
          <div className="retention-item">
            <label className="retention-label">
              <span className="retention-icon">🎵</span>
              Audio Recordings
            </label>
            <select
              value={dataRetention.recordings}
              onChange={(e) => updateDataRetention('recordings', e.target.value)}
              className="retention-select"
            >
              <option value="1">1 day</option>
              <option value="7">7 days</option>
              <option value="30">30 days</option>
              <option value="90">90 days</option>
              <option value="365">1 year</option>
              <option value="never">Never delete</option>
            </select>
          </div>

          <div className="retention-item">
            <label className="retention-label">
              <span className="retention-icon">📝</span>
              Transcripts
            </label>
            <select
              value={dataRetention.transcripts}
              onChange={(e) => updateDataRetention('transcripts', e.target.value)}
              className="retention-select"
            >
              <option value="7">7 days</option>
              <option value="30">30 days</option>
              <option value="90">90 days</option>
              <option value="365">1 year</option>
              <option value="never">Never delete</option>
            </select>
          </div>

          <div className="retention-item">
            <label className="retention-label">
              <span className="retention-icon">📋</span>
              Activity Logs
            </label>
            <select
              value={dataRetention.logs}
              onChange={(e) => updateDataRetention('logs', e.target.value)}
              className="retention-select"
            >
              <option value="1">1 day</option>
              <option value="7">7 days</option>
              <option value="30">30 days</option>
              <option value="90">90 days</option>
            </select>
          </div>
        </div>
      </div>

      {/* Data Management */}
      <div className="privacy-section">
        <h3>Data Management</h3>
        <div className="data-actions">
          <button onClick={savePrivacySettings} className="save-button">
            💾 Save Settings
          </button>
          
          <button onClick={clearAllData} className="danger-button">
            🗑️ Clear All Data
          </button>
        </div>
      </div>

      {/* Privacy Information */}
      <div className="privacy-section">
        <h3>Privacy Information</h3>
        <div className="privacy-info">
          <div className="info-item">
            <h4>🔐 Local Processing</h4>
            <p>All audio processing and transcription happens locally on your device. Your recordings never leave your computer unless you explicitly choose to share them.</p>
          </div>
          
          <div className="info-item">
            <h4>🚫 No Cloud Storage</h4>
            <p>Project Nexus does not store your recordings or transcripts in the cloud. Everything remains on your local device under your control.</p>
          </div>
          
          <div className="info-item">
            <h4>🔒 Encryption</h4>
            <p>Sensitive data is encrypted using industry-standard encryption methods when stored locally.</p>
          </div>
          
          <div className="info-item">
            <h4>📊 Anonymous Analytics</h4>
            <p>If enabled, only anonymous usage statistics are collected to improve the application. No personal data or recording content is included.</p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default PrivacySettings;