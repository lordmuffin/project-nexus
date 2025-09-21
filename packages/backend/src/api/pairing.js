const express = require('express');
const crypto = require('crypto');
const QRCode = require('qrcode');
const dbService = require('../services/database');

const router = express.Router();

// In-memory storage for pairing tokens (use Redis in production)
const pairingTokens = new Map();

// Generate secure pairing token
function generatePairingToken() {
  return crypto.randomBytes(32).toString('hex');
}

// Generate QR code for device pairing
router.post('/generate-qr', async (req, res) => {
  try {
    const token = generatePairingToken();
    const expiresAt = Date.now() + (5 * 60 * 1000); // 5 minutes
    
    // Store token with expiration
    pairingTokens.set(token, {
      createdAt: Date.now(),
      expiresAt,
      used: false,
      deviceInfo: null
    });
    
    // Create pairing data
    const pairingData = {
      token,
      serverUrl: `ws://${req.get('host')}`,
      expiresAt
    };
    
    // Generate QR code
    const qrCodeDataUrl = await QRCode.toDataURL(JSON.stringify(pairingData), {
      errorCorrectionLevel: 'M',
      type: 'image/png',
      quality: 0.92,
      margin: 1,
      color: {
        dark: '#000000',
        light: '#FFFFFF'
      }
    });
    
    res.json({
      success: true,
      data: {
        token,
        qrCode: qrCodeDataUrl,
        expiresAt,
        serverInfo: {
          host: req.get('host'),
          port: process.env.PORT || 3001
        }
      }
    });
    
    console.log(`Generated pairing token: ${token.substring(0, 8)}... (expires in 5 minutes)`);
    
  } catch (error) {
    console.error('QR generation error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to generate QR code'
    });
  }
});

// Validate pairing token
router.post('/validate-token', async (req, res) => {
  try {
    const { token, deviceInfo } = req.body;
    
    if (!token) {
      return res.status(400).json({
        success: false,
        error: 'Token is required'
      });
    }
    
    const tokenData = pairingTokens.get(token);
    
    if (!tokenData) {
      return res.status(404).json({
        success: false,
        error: 'Invalid token'
      });
    }
    
    if (Date.now() > tokenData.expiresAt) {
      pairingTokens.delete(token);
      return res.status(410).json({
        success: false,
        error: 'Token expired'
      });
    }
    
    if (tokenData.used) {
      return res.status(409).json({
        success: false,
        error: 'Token already used'
      });
    }
    
    // Mark token as used
    tokenData.used = true;
    tokenData.deviceInfo = deviceInfo;
    
    // Store device pairing in database
    try {
      const deviceId = crypto.randomUUID();
      await dbService.query(`
        INSERT INTO device_pairs (id, device_id, device_info, paired_at, is_active)
        VALUES ($1, $2, $3, $4, $5)
      `, [crypto.randomUUID(), deviceId, JSON.stringify(deviceInfo), new Date(), true]);
      
      // Clean up token after successful pairing
      setTimeout(() => {
        pairingTokens.delete(token);
      }, 1000);
      
      res.json({
        success: true,
        data: {
          deviceId,
          message: 'Device paired successfully',
          timestamp: new Date().toISOString()
        }
      });
      
      console.log(`Device paired successfully: ${deviceId}`);
      
      // Notify desktop app via WebSocket
      const io = req.app.get('io');
      if (io) {
        io.emit('device_paired', {
          deviceId,
          deviceInfo,
          timestamp: new Date().toISOString()
        });
      }
      
    } catch (dbError) {
      console.error('Database error during pairing:', dbError);
      res.status(500).json({
        success: false,
        error: 'Failed to store device pairing'
      });
    }
    
  } catch (error) {
    console.error('Token validation error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to validate token'
    });
  }
});

// Get paired devices
router.get('/devices', async (req, res) => {
  try {
    const result = await dbService.query(`
      SELECT device_id, device_info, paired_at, is_active, last_seen
      FROM device_pairs
      WHERE is_active = true
      ORDER BY paired_at DESC
    `);
    
    res.json({
      success: true,
      data: {
        devices: result.rows.map(row => ({
          deviceId: row.device_id,
          deviceInfo: JSON.parse(row.device_info || '{}'),
          pairedAt: row.paired_at,
          isActive: row.is_active,
          lastSeen: row.last_seen
        }))
      }
    });
    
  } catch (error) {
    console.error('Error fetching paired devices:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch paired devices'
    });
  }
});

// Unpair device
router.delete('/devices/:deviceId', async (req, res) => {
  try {
    const { deviceId } = req.params;
    
    await dbService.query(`
      UPDATE device_pairs 
      SET is_active = false, unpaired_at = $1
      WHERE device_id = $2
    `, [new Date(), deviceId]);
    
    res.json({
      success: true,
      message: 'Device unpaired successfully'
    });
    
    console.log(`Device unpaired: ${deviceId}`);
    
    // Notify via WebSocket
    const io = req.app.get('io');
    if (io) {
      io.emit('device_unpaired', { deviceId });
    }
    
  } catch (error) {
    console.error('Error unpairing device:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to unpair device'
    });
  }
});

// Clean up expired tokens periodically
setInterval(() => {
  const now = Date.now();
  let cleanedCount = 0;
  
  for (const [token, data] of pairingTokens.entries()) {
    if (now > data.expiresAt) {
      pairingTokens.delete(token);
      cleanedCount++;
    }
  }
  
  if (cleanedCount > 0) {
    console.log(`Cleaned up ${cleanedCount} expired pairing tokens`);
  }
}, 60000); // Clean up every minute

module.exports = router;