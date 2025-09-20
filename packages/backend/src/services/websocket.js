const WebSocket = require('ws');

class WebSocketService {
  constructor() {
    this.wss = null;
    this.clients = new Map();
  }

  // Initialize WebSocket server
  initialize(server) {
    this.wss = new WebSocket.Server({ server });
    
    this.wss.on('connection', (ws, req) => {
      const clientId = this.generateClientId();
      this.clients.set(clientId, {
        ws,
        id: clientId,
        connectedAt: new Date(),
        lastActivity: new Date()
      });

      console.log(`WebSocket client connected: ${clientId}`);

      // Handle messages
      ws.on('message', (message) => {
        try {
          const data = JSON.parse(message);
          this.handleMessage(clientId, data);
        } catch (error) {
          console.error('WebSocket message parsing error:', error);
          this.sendError(clientId, 'Invalid message format');
        }
      });

      // Handle client disconnect
      ws.on('close', () => {
        console.log(`WebSocket client disconnected: ${clientId}`);
        this.clients.delete(clientId);
      });

      // Handle errors
      ws.on('error', (error) => {
        console.error(`WebSocket error for client ${clientId}:`, error);
        this.clients.delete(clientId);
      });

      // Send welcome message
      this.sendMessage(clientId, {
        type: 'welcome',
        clientId,
        timestamp: new Date().toISOString()
      });
    });

    console.log('WebSocket server initialized');
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
  sendMessage(clientId, data) {
    const client = this.clients.get(clientId);
    if (!client || client.ws.readyState !== WebSocket.OPEN) {
      return false;
    }

    try {
      client.ws.send(JSON.stringify(data));
      return true;
    } catch (error) {
      console.error(`Error sending message to client ${clientId}:`, error);
      this.clients.delete(clientId);
      return false;
    }
  }

  // Send error message
  sendError(clientId, message) {
    this.sendMessage(clientId, {
      type: 'error',
      message,
      timestamp: new Date().toISOString()
    });
  }

  // Broadcast to all clients
  broadcast(data) {
    let sentCount = 0;
    for (const [clientId, client] of this.clients) {
      if (this.sendMessage(clientId, data)) {
        sentCount++;
      }
    }
    return sentCount;
  }

  // Broadcast to subscribed clients
  broadcastToChannel(channel, data) {
    let sentCount = 0;
    for (const [clientId, client] of this.clients) {
      if (client.subscriptions && client.subscriptions.has(channel)) {
        if (this.sendMessage(clientId, { ...data, channel })) {
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
        client.ws.terminate();
        this.clients.delete(clientId);
        console.log(`Cleaned up inactive client: ${clientId}`);
      }
    });

    return inactiveClients.length;
  }
}

module.exports = new WebSocketService();