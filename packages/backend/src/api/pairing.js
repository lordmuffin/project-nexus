const express = require('express');
const crypto = require('crypto');
const QRCode = require('qrcode');
const os = require('os');
const dbService = require('../services/database');

const router = express.Router();

// In-memory storage for pairing tokens (use Redis in production)
const pairingTokens = new Map();

// Generate secure pairing token
function generatePairingToken() {
  return crypto.randomBytes(32).toString('hex');
}

// Get the best host IP for mobile access based on request context
async function getBestHostIP(req) {
  // If there's a specific override in headers (useful for development/testing)
  const overrideIP = req.headers['x-host-override'];
  if (overrideIP && /^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/.test(overrideIP)) {
    console.log('Using override IP:', overrideIP);
    return overrideIP;
  }
  
  // Get the IP that the frontend used to reach us
  const requestHost = req.get('host');
  const requestIP = req.connection?.remoteAddress || req.socket?.remoteAddress;
  
  console.log('Request came from:', requestIP, 'to host:', requestHost);
  
  // If the request came through localhost, try to determine the actual network IP
  if (requestHost && (requestHost.includes('localhost') || requestHost.includes('127.0.0.1'))) {
    console.log('Request via localhost, attempting to find network IP...');
    return await getHostMachineIP();
  }
  
  // If the request has a valid host IP that's not localhost, use it
  if (requestHost) {
    const hostFromHeader = requestHost.split(':')[0]; // Remove port if present
    if (/^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/.test(hostFromHeader) && 
        !hostFromHeader.startsWith('127.') && 
        !hostFromHeader.startsWith('172.17.') && 
        !hostFromHeader.startsWith('172.18.')) {
      console.log('Using host from request header:', hostFromHeader);
      return hostFromHeader;
    }
  }
  
  // Fallback to auto-detection
  return await getHostMachineIP();
}

// Get host machine's actual network IP address
async function getHostMachineIP() {
  const { exec } = require('child_process');
  const { promisify } = require('util');
  const execAsync = promisify(exec);
  
  try {
    // Method 1: Try to resolve host.docker.internal which should point to host
    const { stdout } = await execAsync("getent hosts host.docker.internal | awk '{print $1}' 2>/dev/null");
    const hostIP = stdout.trim();
    
    if (hostIP && /^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/.test(hostIP)) {
      console.log('Found host via host.docker.internal:', hostIP);
      return hostIP;
    }
  } catch (error) {
    console.warn('Failed to resolve host.docker.internal:', error.message);
  }
  
  try {
    // Method 2: Get the actual network IP using ip route (preferred method)
    const { stdout } = await execAsync("ip route get 8.8.8.8 | awk '{print $7}' | head -1");
    const actualIP = stdout.trim();
    
    if (actualIP && /^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/.test(actualIP) && !actualIP.startsWith('172.')) {
      console.log('Found actual host IP via ip route:', actualIP);
      return actualIP;
    }
  } catch (error) {
    console.warn('Failed to get IP via ip route:', error.message);
  }
  
  try {
    // Method 2b: If we got a Docker bridge IP, try getting the default interface IP
    const { stdout } = await execAsync("ip route | grep default | awk '{print $5}' | head -1");
    const defaultInterface = stdout.trim();
    
    if (defaultInterface) {
      const { stdout: interfaceIP } = await execAsync(`ip addr show ${defaultInterface} | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 | head -1`);
      const actualIP = interfaceIP.trim();
      
      if (actualIP && /^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/.test(actualIP) && !actualIP.startsWith('127.') && !actualIP.startsWith('172.')) {
        console.log('Found actual host IP via default interface:', actualIP);
        return actualIP;
      }
    }
  } catch (error) {
    console.warn('Failed to get IP via default interface:', error.message);
  }
  
  try {
    // Method 3: Directly test for common host IPs in the 192.168.1.x network
    console.log('Testing direct connection to common host IPs...');
    const directTestIPs = ['192.168.1.61', '192.168.1.100', '192.168.1.50', '192.168.1.10'];
    
    for (const testIP of directTestIPs) {
      try {
        console.log(`Testing direct connection to: ${testIP}`);
        await execAsync(`ping -c 1 -W 1 ${testIP} >/dev/null 2>&1`);
        console.log('Found reachable host IP via direct test:', testIP);
        return testIP;
      } catch (e) {
        console.log(`${testIP} not reachable`);
      }
    }
  } catch (error) {
    console.warn('Failed to test direct host IPs:', error.message);
  }
  
  try {
    // Method 4: Scan for reachable IPs in common network ranges
    const commonNetworks = ['192.168.1', '192.168.0', '10.0.0', '10.0.1'];
    
    for (const network of commonNetworks) {
      // Test if we can reach common gateway/router IPs
      const commonIPs = [`${network}.1`, `${network}.254`];
      
      for (const testIP of commonIPs) {
        try {
          await execAsync(`ping -c 1 -W 1 ${testIP} >/dev/null 2>&1`);
          console.log(`Found reachable network: ${network}.x`);
          
          // Now try to find what IP in this network might be our host
          // Common patterns: .61, .100, .10, .50, etc.
          const hostCandidates = [
            `${network}.61`,   // Based on your known IP
            `${network}.100`, 
            `${network}.10`,
            `${network}.50`,
            `${network}.2`,
            `${network}.5`
          ];
          
          console.log(`Testing host candidates in ${network}.x:`, hostCandidates);
          
          for (const candidate of hostCandidates) {
            try {
              console.log(`Testing candidate: ${candidate}`);
              await execAsync(`ping -c 1 -W 1 ${candidate} >/dev/null 2>&1`);
              console.log('Found reachable host candidate:', candidate);
              return candidate;
            } catch (e) {
              console.log(`Candidate ${candidate} not reachable`);
            }
          }
          
          // If no specific host found, return the gateway
          return testIP;
        } catch (e) {
          // Network not reachable, try next
        }
      }
    }
  } catch (error) {
    console.warn('Failed to scan network ranges:', error.message);
  }
  
  // Final fallback: analyze network interfaces  
  console.log('Falling back to network interface analysis...');
  const interfaces = os.networkInterfaces();
  
  for (const name of Object.keys(interfaces)) {
    const iface = interfaces[name];
    for (const alias of iface) {
      if (alias.family === 'IPv4' && !alias.internal) {
        console.log(`Found interface ${name}: ${alias.address}`);
        
        // If we find a 192.168.x.x address, prefer it (common home network)
        if (alias.address.startsWith('192.168.')) {
          console.log('Using 192.168.x.x interface as likely host network IP');
          return alias.address;
        }
        
        // For Docker bridge networks (172.x.x.x), calculate the likely host IP
        if (alias.address.startsWith('172.') && name.includes('eth')) {
          const parts = alias.address.split('.');
          // Docker bridge gateway is typically .1 in the subnet
          const possibleHostIP = `${parts[0]}.${parts[1]}.${parts[2]}.1`;
          console.log('Calculated Docker host IP from bridge:', possibleHostIP);
          return possibleHostIP;
        }
      }
    }
  }
  
  console.warn('Could not determine host machine IP, using localhost - mobile pairing may not work');
  return 'localhost';
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
    
    // Get the best IP for mobile device access based on request context
    const hostIP = await getBestHostIP(req);
    const port = process.env.PORT || 3001;
    
    // Create pairing data
    const host = req.get('host');
    const protocol = req.secure ? 'https' : 'http';
    const wsProtocol = req.secure ? 'wss' : 'ws';
    
    const pairingData = {
      token,
      serverUrl: `${protocol}://${hostIP}:${port}`,
      websocketUrl: `${wsProtocol}://${hostIP}:${port}`,
      apiUrl: `${protocol}://${hostIP}:${port}/api`,
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
          host: hostIP,
          port: port
        }
      }
    });
    
    console.log(`Generated pairing token: ${token.substring(0, 8)}... (expires in 5 minutes)`);
    console.log(`Pairing data:`, {
      serverUrl: pairingData.serverUrl,
      websocketUrl: pairingData.websocketUrl,
      apiUrl: pairingData.apiUrl
    });
    console.log(`Mobile app should connect to: ws://${hostIP}:${port}`);
    
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
    console.log('PAIRING: validate-token endpoint called');
    console.log('PAIRING: Request IP:', req.ip);
    console.log('PAIRING: Request body:', req.body);
    
    const { token, deviceInfo } = req.body;
    
    console.log(`Token validation attempt for: ${token ? token.substring(0, 8) + '...' : 'null'}`);
    console.log(`Device info:`, deviceInfo);
    
    if (!token) {
      return res.status(400).json({
        success: false,
        error: 'Token is required'
      });
    }
    
    const tokenData = pairingTokens.get(token);
    
    console.log('PAIRING: Token lookup result:', tokenData ? 'FOUND' : 'NOT_FOUND');
    console.log('PAIRING: Total tokens in storage:', pairingTokens.size);
    console.log('PAIRING: Looking for token:', token.substring(0, 16) + '...');
    
    if (!tokenData) {
      console.log('PAIRING: Available tokens:', Array.from(pairingTokens.keys()).map(t => t.substring(0, 16) + '...'));
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