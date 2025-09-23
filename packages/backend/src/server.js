const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');
const { Server } = require('socket.io');
const http = require('http');

// Import route handlers
const chatRoutes = require('./api/chat');
const meetingsRoutes = require('./api/meetings');
const transcriptionRoutes = require('./api/transcription');
const healthRoutes = require('./api/health');
const notesRoutes = require('./api/notes');
const pairingRoutes = require('./api/pairing');

// Import services
const dbService = require('./services/database');
const ollamaService = require('./services/ollama');
const wsService = require('./services/websocket');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: process.env.FRONTEND_URL || /^http:\/\/.*:3000$/,
    methods: ["GET", "POST"]
  }
});

const PORT = process.env.PORT || 3001;

// Middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
}));

app.use(cors({
  origin: function (origin, callback) {
    // Allow requests with no origin (like mobile apps or Postman)
    if (!origin) return callback(null, true);
    
    // Allow specific origins
    const allowedOrigins = [
      process.env.FRONTEND_URL || "http://localhost:3000",
      "http://localhost:8082", // Expo dev server
      "http://192.168.1.61:3000", // Network access to frontend
      "http://192.168.1.61:8082", // Network access to Expo
    ];
    
    // Allow any origin that starts with our network IP for mobile apps
    if (origin.startsWith('http://192.168.1.61') || 
        origin.startsWith('http://localhost') ||
        allowedOrigins.includes(origin)) {
      return callback(null, true);
    }
    
    return callback(null, true); // For now, allow all origins for mobile pairing
  },
  credentials: true
}));

app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Serve static files
app.use('/uploads', express.static('/tmp/nexus-uploads'));

// Make io available to routes
app.set('io', io);

// API Routes
app.use('/api/health', healthRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/meetings', meetingsRoutes);
app.use('/api/transcription', transcriptionRoutes);
app.use('/api/notes', notesRoutes);
app.use('/api/pairing', pairingRoutes);

// WebSocket setup
wsService.initialize(io);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err);
  
  if (err.type === 'entity.parse.failed') {
    return res.status(400).json({
      error: 'Invalid JSON payload'
    });
  }
  
  if (err.type === 'entity.too.large') {
    return res.status(413).json({
      error: 'Payload too large'
    });
  }
  
  res.status(500).json({
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong'
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not found',
    message: `Route ${req.method} ${req.path} not found`
  });
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  server.close(() => {
    console.log('Process terminated');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully');
  server.close(() => {
    console.log('Process terminated');
    process.exit(0);
  });
});

// Start server
async function startServer() {
  try {
    // Initialize database
    await dbService.initialize();
    
    // Initialize Ollama service
    await ollamaService.initialize();
    
    server.listen(PORT, '0.0.0.0', () => {
      console.log(`🚀 Nexus Backend Server running on 0.0.0.0:${PORT}`);
      console.log(`📡 WebSocket server ready on 0.0.0.0:${PORT}`);
      console.log(`🤖 AI service initialized`);
      console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
      
      if (process.env.NODE_ENV === 'development') {
        console.log(`🔗 Frontend URL: ${process.env.FRONTEND_URL || 'http://localhost:3000'}`);
        console.log(`🔗 Database URL: ${process.env.DATABASE_URL || 'postgresql://nexus:nexus_password@localhost:5432/nexus'}`);
        console.log(`🔗 Ollama URL: ${process.env.OLLAMA_URL || 'http://localhost:11434'}`);
        console.log(`🔗 Access server at: http://localhost:${PORT} or http://[YOUR_IP]:${PORT}`);
      }
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

// Start the server
startServer();