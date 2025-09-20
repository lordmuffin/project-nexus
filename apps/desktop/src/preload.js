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
  showNotification: (title, body) => ipcRenderer.invoke('show-notification', { title, body })
});

// Remove the loading indicator when DOM is ready
window.addEventListener('DOMContentLoaded', () => {
  const loadingElement = document.getElementById('loading');
  if (loadingElement) {
    loadingElement.remove();
  }
});