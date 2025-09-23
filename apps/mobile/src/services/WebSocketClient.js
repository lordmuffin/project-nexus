import * as Network from 'expo-network';
import { io } from 'socket.io-client';

class WebSocketClient {
  constructor() {
    this.socket = null;
    this.connectionStatus = 'disconnected';
    this.serverInfo = null;
    this.listeners = [];
    this.reconnectAttempts = 0;
    this.maxReconnectAttempts = 5;
    this.reconnectDelay = 1000;
    this.discoveryAttempts = 0;
    this.maxDiscoveryAttempts = 3;
  }

  initialize() {
    this.connectionStatus = 'disconnected';
    this.notifyListeners();
  }

  onConnectionChange(callback) {
    this.listeners.push(callback);
    
    // Return unsubscribe function
    return () => {
      this.listeners = this.listeners.filter(listener => listener !== callback);
    };
  }

  notifyListeners() {
    this.listeners.forEach(callback => {
      callback(this.connectionStatus, this.serverInfo);
    });
  }

  async discoverServer() {
    this.connectionStatus = 'connecting';
    this.notifyListeners();

    try {
      // Get local network information
      const networkState = await Network.getNetworkStateAsync();
      
      if (!networkState.isConnected || !networkState.isInternetReachable) {
        console.log('No network connection available');
        this.connectionStatus = 'disconnected';
        this.notifyListeners();
        return;
      }

      // Try common local network ranges and ports
      const commonPorts = [3001, 8080, 8000];
      const localIPs = await this.getLocalNetworkIPs();

      for (const ip of localIPs) {
        for (const port of commonPorts) {
          const serverUrl = `ws://${ip}:${port}`;
          
          try {
            const isReachable = await this.testServerReachability(ip, port);
            if (isReachable) {
              await this.connectToServer(ip, port);
              return;
            }
          } catch (error) {
            console.log(`Failed to connect to ${serverUrl}:`, error.message);
          }
        }
      }

      // If no server found, update status
      this.connectionStatus = 'disconnected';
      this.notifyListeners();

    } catch (error) {
      console.error('Server discovery failed:', error);
      this.connectionStatus = 'disconnected';
      this.notifyListeners();
    }
  }

  async getLocalNetworkIPs() {
    // Generate common local network IP ranges
    const baseIPs = ['192.168.1', '192.168.0', '10.0.0', '172.16.0'];
    const ips = [];

    baseIPs.forEach(base => {
      // Try common host numbers
      for (let i = 1; i <= 254; i += 10) { // Sample every 10th IP for faster discovery
        ips.push(`${base}.${i}`);
      }
      // Always try common addresses
      [1, 2, 100, 101, 254].forEach(host => {
        ips.push(`${base}.${host}`);
      });
    });

    return [...new Set(ips)]; // Remove duplicates
  }

  async testServerReachability(ip, port) {
    return new Promise((resolve) => {
      const timeout = setTimeout(() => {
        resolve(false);
      }, 1000); // 1 second timeout for each test

      fetch(`http://${ip}:${port}/api/health`, {
        method: 'GET',
        timeout: 1000,
      })
        .then(response => {
          clearTimeout(timeout);
          resolve(response.ok);
        })
        .catch(() => {
          clearTimeout(timeout);
          resolve(false);
        });
    });
  }

  async connectToServer(ip, port = 3001) {
    try {
      if (this.socket) {
        this.socket.disconnect();
      }

      const serverUrl = `http://${ip}:${port}`;
      console.log(`Connecting to Nexus server at ${serverUrl}`);
      
      this.socket = io(serverUrl, {
        transports: ['websocket', 'polling'],
        autoConnect: true,
        reconnection: true,
        reconnectionAttempts: this.maxReconnectAttempts,
        reconnectionDelay: this.reconnectDelay,
        timeout: 5000
      });

      this.socket.on('connect', () => {
        console.log(`Connected to Nexus server at ${serverUrl}`);
        this.connectionStatus = 'connected';
        this.serverInfo = {
          host: ip,
          port: port,
          name: 'Nexus Server',
          version: '1.0.0'
        };
        this.reconnectAttempts = 0;
        this.notifyListeners();

        // Send initial handshake
        this.socket.emit('mobile_client_connected', {
          deviceInfo: {
            platform: 'mobile',
            userAgent: 'Nexus Companion App',
            timestamp: Date.now()
          }
        });
      });

      this.socket.on('disconnect', (reason) => {
        console.log('Socket.IO connection closed:', reason);
        this.connectionStatus = 'disconnected';
        this.serverInfo = null;
        this.notifyListeners();
      });

      this.socket.on('connect_error', (error) => {
        console.error('Socket.IO connection error:', error);
        this.connectionStatus = 'disconnected';
        this.notifyListeners();
      });

      // Handle server messages
      this.socket.on('server_info', (data) => {
        this.handleServerMessage({ type: 'server_info', data });
      });

      this.socket.on('meeting_started', (data) => {
        this.handleServerMessage({ type: 'meeting_started', data });
      });

      this.socket.on('meeting_ended', (data) => {
        this.handleServerMessage({ type: 'meeting_ended', data });
      });

      this.socket.on('transcription_ready', (data) => {
        this.handleServerMessage({ type: 'transcription_ready', data });
      });

    } catch (error) {
      console.error('Failed to connect to server:', error);
      this.connectionStatus = 'disconnected';
      this.notifyListeners();
      throw error;
    }
  }

  handleServerMessage(message) {
    switch (message.type) {
      case 'server_info':
        this.serverInfo = {
          ...this.serverInfo,
          ...message.data
        };
        this.notifyListeners();
        break;
      
      case 'meeting_started':
        console.log('Meeting started:', message.data);
        break;
      
      case 'meeting_ended':
        console.log('Meeting ended:', message.data);
        break;
      
      case 'transcription_ready':
        console.log('Transcription ready:', message.data);
        break;
      
      default:
        console.log('Unknown message type:', message.type);
    }
  }

  sendMessage(message) {
    if (this.socket && this.socket.connected) {
      this.socket.emit('message', message);
    } else {
      console.warn('Socket.IO not connected, cannot send message');
    }
  }

  async sendAudioRecording(audioUri, duration) {
    try {
      // Create FormData for file upload
      const formData = new FormData();
      formData.append('file', {
        uri: audioUri,
        type: 'audio/mp4', // or audio/wav depending on recording format
        name: `recording_${Date.now()}.m4a`,
      });
      formData.append('language', 'auto');
      formData.append('model', 'base');
      formData.append('format', 'json');

      // Send via HTTP POST to the transcription service
      const serverUrl = `http://${this.serverInfo.host}:${this.serverInfo.port}`;
      const response = await fetch(`${serverUrl}/api/transcription/upload`, {
        method: 'POST',
        body: formData,
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });

      if (response.ok) {
        const result = await response.json();
        console.log('Audio uploaded successfully:', result);
        
        // Notify via Socket.IO that audio was uploaded
        this.socket.emit('audio_uploaded', {
          transcriptionId: result.data?.transcriptionId,
          duration: duration,
          timestamp: Date.now()
        });
        
        return result;
      } else {
        const errorText = await response.text();
        throw new Error(`Upload failed: ${response.status} - ${errorText}`);
      }
    } catch (error) {
      console.error('Failed to send audio recording:', error);
      throw error;
    }
  }

  async pairWithServer(qrData) {
    try {
      console.log('pairWithServer called with:', qrData);
      const { token, serverUrl } = JSON.parse(qrData);
      console.log('Extracted from QR:', { token: token.substring(0, 8) + '...', serverUrl });
      
      // Extract host and port from serverUrl
      const url = new URL(serverUrl);
      const host = url.hostname;
      const port = url.port || 3001;
      console.log('Connecting to:', { host, port });
      
      // Validate pairing token
      const apiUrl = `http://${host}:${port}/api/pairing/validate-token`;
      console.log('Making API request to:', apiUrl);
      
      const response = await fetch(apiUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          token,
          deviceInfo: {
            platform: 'mobile',
            userAgent: 'Nexus Companion App',
            version: '1.0.0',
            deviceName: 'Mobile Device'
          }
        }),
      });
      
      console.log('API response status:', response.status);
      const result = await response.json();
      console.log('API response result:', result);
      
      if (result.success) {
        // Connect to the WebSocket server
        await this.connectToServer(host, port);
        return result;
      } else {
        throw new Error(result.error || 'Failed to pair device');
      }
    } catch (error) {
      console.error('Pairing failed:', error);
      throw error;
    }
  }

  disconnect() {
    if (this.socket) {
      this.socket.disconnect();
      this.socket = null;
    }
    this.connectionStatus = 'disconnected';
    this.serverInfo = null;
    this.notifyListeners();
  }

  getConnectionStatus() {
    return this.connectionStatus;
  }

  getServerInfo() {
    return this.serverInfo;
  }
}

// Export singleton instance
export default new WebSocketClient();