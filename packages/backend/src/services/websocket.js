class WebSocketService {
  constructor() {
    this.io = null;
    this.clients = new Map();
  }

  // Initialize Socket.IO server
  initialize(io) {
    this.io = io;
    
    this.io.on('connection', (socket) => {
      const clientId = socket.id;
      this.clients.set(clientId, {
        socket,
        id: clientId,
        connectedAt: new Date(),
        lastActivity: new Date(),
        type: 'unknown'
      });

      console.log(`Socket.IO client connected: ${clientId}`);

      // Handle mobile client connection
      socket.on('mobile_client_connected', (data) => {
        console.log('Mobile client connected:', data);
        const client = this.clients.get(clientId);
        if (client) {
          client.type = 'mobile';
          client.deviceInfo = data.deviceInfo;
          client.lastActivity = new Date();
        }
        
        // Send server info back
        socket.emit('server_info', {
          name: 'Nexus Server',
          version: '1.0.0',
          timestamp: new Date().toISOString()
        });
      });

      // Handle generic messages
      socket.on('message', (data) => {
        try {
          this.handleMessage(clientId, data);
        } catch (error) {
          console.error('Socket.IO message handling error:', error);
          socket.emit('error', { message: 'Error processing message' });
        }
      });

      // Handle recording events
      socket.on('recording_started', (data) => {
        console.log('Recording started by mobile client:', data);
        const client = this.clients.get(clientId);
        if (client) {
          client.lastActivity = new Date();
          client.isRecording = true;
        }
        
        // Broadcast to other clients if needed
        this.broadcastToOthers(clientId, 'recording_started', data);
      });

      socket.on('recording_stopped', (data) => {
        console.log('Recording stopped by mobile client:', data);
        const client = this.clients.get(clientId);
        if (client) {
          client.lastActivity = new Date();
          client.isRecording = false;
        }
        
        // Broadcast to other clients if needed
        this.broadcastToOthers(clientId, 'recording_stopped', data);
      });

      // Handle audio upload notifications
      socket.on('audio_uploaded', (data) => {
        console.log('Audio uploaded by mobile client:', data);
        const client = this.clients.get(clientId);
        if (client) {
          client.lastActivity = new Date();
        }
        
        // Broadcast to other clients if needed
        this.broadcastToOthers(clientId, 'audio_uploaded', data);
      });

      // Handle client disconnect
      socket.on('disconnect', (reason) => {
        console.log(`Socket.IO client disconnected: ${clientId}, reason: ${reason}`);
        this.clients.delete(clientId);
      });

      // Send welcome message
      socket.emit('welcome', {
        clientId,
        timestamp: new Date().toISOString()
      });
    });

    console.log('Socket.IO WebSocket server initialized');
  }

  // Generate unique client ID
  generateClientId() {
    return `client_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  // Handle incoming messages
  handleMessage(clientId, data) {
    const client = this.clients.get(clientId);
    if (!client) return;

    client.lastActivity = new Date();

    switch (data.type) {
      case 'ping':
        this.sendMessage(clientId, { type: 'pong', timestamp: new Date().toISOString() });
        break;

      case 'subscribe':
        // Handle subscription to specific channels
        client.subscriptions = client.subscriptions || new Set();
        if (data.channel) {
          client.subscriptions.add(data.channel);
          this.sendMessage(clientId, {
            type: 'subscribed',
            channel: data.channel,
            timestamp: new Date().toISOString()
          });
        }
        break;

      case 'unsubscribe':
        // Handle unsubscription
        if (client.subscriptions && data.channel) {
          client.subscriptions.delete(data.channel);
          this.sendMessage(clientId, {
            type: 'unsubscribed',
            channel: data.channel,
            timestamp: new Date().toISOString()
          });
        }
        break;

      default:
        console.log(`Unknown message type: ${data.type}`);
        this.sendError(clientId, 'Unknown message type');
    }
  }

  // Send message to specific client
  sendMessage(clientId, event, data) {
    const client = this.clients.get(clientId);
    if (!client || !client.socket.connected) {
      return false;
    }

    try {
      client.socket.emit(event, data);
      return true;
    } catch (error) {
      console.error(`Error sending message to client ${clientId}:`, error);
      this.clients.delete(clientId);
      return false;
    }
  }

  // Send error message
  sendError(clientId, message) {
    this.sendMessage(clientId, 'error', {
      message,
      timestamp: new Date().toISOString()
    });
  }

  // Broadcast to all clients
  broadcast(event, data) {
    let sentCount = 0;
    for (const [clientId, client] of this.clients) {
      if (this.sendMessage(clientId, event, data)) {
        sentCount++;
      }
    }
    return sentCount;
  }

  // Broadcast to all clients except sender
  broadcastToOthers(senderClientId, event, data) {
    let sentCount = 0;
    for (const [clientId, client] of this.clients) {
      if (clientId !== senderClientId) {
        if (this.sendMessage(clientId, event, data)) {
          sentCount++;
        }
      }
    }
    return sentCount;
  }

  // Broadcast to subscribed clients
  broadcastToChannel(channel, event, data) {
    let sentCount = 0;
    for (const [clientId, client] of this.clients) {
      if (client.subscriptions && client.subscriptions.has(channel)) {
        if (this.sendMessage(clientId, event, { ...data, channel })) {
          sentCount++;
        }
      }
    }
    return sentCount;
  }

  // Get connected clients count
  getClientCount() {
    return this.clients.size;
  }

  // Get client info
  getClientInfo(clientId) {
    const client = this.clients.get(clientId);
    if (!client) return null;

    return {
      id: clientId,
      connectedAt: client.connectedAt,
      lastActivity: client.lastActivity,
      subscriptions: client.subscriptions ? Array.from(client.subscriptions) : []
    };
  }

  // Clean up inactive clients
  cleanupInactiveClients(timeoutMs = 300000) { // 5 minutes default
    const now = new Date();
    const inactiveClients = [];

    for (const [clientId, client] of this.clients) {
      if (now - client.lastActivity > timeoutMs) {
        inactiveClients.push(clientId);
      }
    }

    inactiveClients.forEach(clientId => {
      const client = this.clients.get(clientId);
      if (client) {
        client.socket.disconnect(true);
        this.clients.delete(clientId);
        console.log(`Cleaned up inactive client: ${clientId}`);
      }
    });

    return inactiveClients.length;
  }
}

module.exports = new WebSocketService();