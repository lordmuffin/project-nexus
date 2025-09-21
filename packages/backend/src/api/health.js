const express = require('express');
const dbService = require('../services/database');
const router = express.Router();

// Health check endpoint
router.get('/', async (req, res) => {
  try {
    const dbHealth = await dbService.healthCheck();
    const transcriptionHealth = await checkTranscriptionService();
    
    const healthStatus = {
      status: dbHealth.status === 'connected' ? 'healthy' : 'degraded',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      version: process.env.npm_package_version || '1.0.0',
      node_version: process.version,
      memory: {
        used: Math.round(process.memoryUsage().heapUsed / 1024 / 1024 * 100) / 100,
        total: Math.round(process.memoryUsage().heapTotal / 1024 / 1024 * 100) / 100,
        external: Math.round(process.memoryUsage().external / 1024 / 1024 * 100) / 100
      },
      services: {
        database: dbHealth.status,
        transcription: transcriptionHealth,
        websocket: 'active'
      }
    };

    res.json(healthStatus);
  } catch (error) {
    console.error('Health check error:', error);
    res.status(503).json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      error: error.message
    });
  }
});

// Detailed health check
router.get('/detailed', async (req, res) => {
  try {
    const dbHealth = await dbService.healthCheck();
    const transcriptionHealth = await checkTranscriptionService();
    const storageHealth = await checkStorageService();
    
    const detailedHealth = {
      status: dbHealth.status === 'connected' ? 'healthy' : 'degraded',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      version: process.env.npm_package_version || '1.0.0',
      environment: process.env.NODE_ENV || 'development',
      platform: process.platform,
      architecture: process.arch,
      node_version: process.version,
      memory: process.memoryUsage(),
      cpu: process.cpuUsage(),
      services: {
        database: dbHealth,
        transcription: transcriptionHealth,
        websocket: 'active',
        storage: storageHealth
      },
      features: {
        chat: true,
        meetings: true,
        transcription: true,
        realtime: true
      }
    };

    res.json(detailedHealth);
  } catch (error) {
    console.error('Detailed health check error:', error);
    res.status(503).json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      error: error.message
    });
  }
});

// Readiness probe
router.get('/ready', async (req, res) => {
  try {
    const services = {
      database: await dbService.healthCheck(),
      transcription: await checkTranscriptionService()
    };

    const allServicesReady = Object.values(services).every(status => 
      status === 'connected' || status === 'ready' || (status.status && status.status === 'connected')
    );

    if (allServicesReady) {
      res.json({
        status: 'ready',
        services
      });
    } else {
      res.status(503).json({
        status: 'not_ready',
        services
      });
    }
  } catch (error) {
    console.error('Readiness check error:', error);
    res.status(503).json({
      status: 'not_ready',
      error: error.message
    });
  }
});

// Liveness probe
router.get('/live', (req, res) => {
  res.json({
    status: 'alive',
    timestamp: new Date().toISOString()
  });
});

// Helper functions
async function checkTranscriptionService() {
  try {
    const transcriptionUrl = process.env.TRANSCRIPTION_SERVICE_URL || 'http://transcription:8000';
    const axios = require('axios');
    const response = await axios.get(`${transcriptionUrl}/health`, { timeout: 5000 });
    return response.status === 200 ? 'ready' : 'unavailable';
  } catch (error) {
    console.log('Transcription service check failed:', error.message);
    return 'unavailable';
  }
}

async function checkStorageService() {
  try {
    const fs = require('fs').promises;
    const path = require('path');
    const uploadDir = path.join(process.cwd(), 'uploads');
    
    // Check if upload directory exists and is writable
    await fs.access(uploadDir, fs.constants.F_OK | fs.constants.W_OK);
    return { status: 'available', path: uploadDir };
  } catch (error) {
    console.log('Storage service check failed:', error.message);
    return { status: 'unavailable', error: error.message };
  }
}

module.exports = router;