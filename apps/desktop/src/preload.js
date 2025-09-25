const { contextBridge, ipcRenderer } = require('electron');

// Expose protected methods that allow the renderer process to use
// the ipcRenderer without exposing the entire object
contextBridge.exposeInMainWorld('electronAPI', {
  // Menu events
  onMenuNewMeeting: (callback) => ipcRenderer.on('menu-new-meeting', callback),
  onMenuSettings: (callback) => ipcRenderer.on('menu-settings', callback),
  
  // System info
  platform: process.platform,
  
  // App version
  getVersion: () => ipcRenderer.invoke('get-version'),
  
  // Window controls
  minimizeWindow: () => ipcRenderer.invoke('minimize-window'),
  maximizeWindow: () => ipcRenderer.invoke('maximize-window'),
  closeWindow: () => ipcRenderer.invoke('close-window'),
  
  // File operations (for future use)
  selectFile: (options) => ipcRenderer.invoke('select-file', options),
  
  // Notifications
  showNotification: (title, body) => ipcRenderer.invoke('show-notification', { title, body }),
  
  // Multi-track audio recording APIs
  audio: {
    // Get available audio sources
    getAvailableSources: () => ipcRenderer.invoke('audio:getAvailableSources'),
    
    // Session management
    startSession: (options) => ipcRenderer.invoke('audio:startSession', options),
    stopSession: (sessionId) => ipcRenderer.invoke('audio:stopSession', sessionId),
    getSessionStatus: (sessionId) => ipcRenderer.invoke('audio:getSessionStatus', sessionId),
    
    // Track management
    addTrack: (sessionId, trackConfig) => ipcRenderer.invoke('audio:addTrack', sessionId, trackConfig),
    removeTrack: (sessionId, trackNumber) => ipcRenderer.invoke('audio:removeTrack', sessionId, trackNumber),
    updateTrackSettings: (sessionId, trackNumber, settings) => ipcRenderer.invoke('audio:updateTrackSettings', sessionId, trackNumber, settings),
    
    // Permissions
    getSystemAudioPermission: () => ipcRenderer.invoke('audio:getSystemAudioPermission'),
    requestSystemAudioPermission: () => ipcRenderer.invoke('audio:requestSystemAudioPermission'),
    
    // Event listeners
    onSourcesUpdated: (callback) => ipcRenderer.on('audio:sourcesUpdated', callback),
    onSessionCreated: (callback) => ipcRenderer.on('audio:sessionCreated', callback),
    onSessionStopped: (callback) => ipcRenderer.on('audio:sessionStopped', callback),
    onTrackAdded: (callback) => ipcRenderer.on('audio:trackAdded', callback),
    onTrackRemoved: (callback) => ipcRenderer.on('audio:trackRemoved', callback),
    onRecordingStarted: (callback) => ipcRenderer.on('audio:recordingStarted', callback),
    onRecordingStopped: (callback) => ipcRenderer.on('audio:recordingStopped', callback),
    onAudioLevels: (callback) => ipcRenderer.on('audio:audioLevels', callback),
    
    // Cleanup listeners
    removeAllListeners: (channel) => ipcRenderer.removeAllListeners(`audio:${channel}`)
  }
});

// Remove the loading indicator when DOM is ready
window.addEventListener('DOMContentLoaded', () => {
  const loadingElement = document.getElementById('loading');
  if (loadingElement) {
    loadingElement.remove();
  }
});