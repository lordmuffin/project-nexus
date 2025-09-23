// Integration tests for pairing API endpoints
const request = require('supertest');
const { v4: uuidv4 } = require('uuid');
const app = require('../../server');

describe('Pairing API Integration Tests', () => {
  describe('POST /api/pairing/generate', () => {
    test('should generate QR code data for device pairing', async () => {
      const response = await request(app)
        .post('/api/pairing/generate')
        .send({ deviceName: 'iPhone 15 Pro' })
        .expect(201);

      expect(response.body).toHaveProperty('qrData');
      expect(response.body).toHaveProperty('pairingId');
      expect(response.body.qrData).toMatch(/^nexus:\/\/pair\?id=.+&token=.+$/);
      expect(response.body.pairingId).toHaveLength(36); // UUID length
    });

    test('should return 400 when device name is missing', async () => {
      const response = await request(app)
        .post('/api/pairing/generate')
        .send({})
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('Device name is required');
    });

    test('should return 400 when device name is empty', async () => {
      const response = await request(app)
        .post('/api/pairing/generate')
        .send({ deviceName: '' })
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('Device name is required');
    });

    test('should generate unique pairing IDs for different requests', async () => {
      const response1 = await request(app)
        .post('/api/pairing/generate')
        .send({ deviceName: 'Device 1' })
        .expect(201);

      const response2 = await request(app)
        .post('/api/pairing/generate')
        .send({ deviceName: 'Device 2' })
        .expect(201);

      expect(response1.body.pairingId).not.toBe(response2.body.pairingId);
      expect(response1.body.qrData).not.toBe(response2.body.qrData);
    });
  });

  describe('POST /api/pairing/confirm', () => {
    let pairingId, token;

    beforeEach(async () => {
      // Generate a pairing request first
      const response = await request(app)
        .post('/api/pairing/generate')
        .send({ deviceName: 'Test Device' });
      
      pairingId = response.body.pairingId;
      // Extract token from QR data
      const qrData = response.body.qrData;
      const tokenMatch = qrData.match(/token=([^&]+)/);
      token = tokenMatch ? tokenMatch[1] : null;
    });

    test('should confirm pairing with valid ID and token', async () => {
      const response = await request(app)
        .post('/api/pairing/confirm')
        .send({ 
          pairingId,
          token,
          deviceInfo: {
            name: 'Test Device',
            type: 'mobile',
            platform: 'ios'
          }
        })
        .expect(200);

      expect(response.body).toHaveProperty('success', true);
      expect(response.body).toHaveProperty('deviceId');
      expect(response.body).toHaveProperty('sessionToken');
      expect(response.body.deviceId).toHaveLength(36); // UUID
    });

    test('should return 400 with invalid pairing ID', async () => {
      const response = await request(app)
        .post('/api/pairing/confirm')
        .send({ 
          pairingId: 'invalid-id',
          token,
          deviceInfo: { name: 'Test Device' }
        })
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('Invalid pairing request');
    });

    test('should return 400 with invalid token', async () => {
      const response = await request(app)
        .post('/api/pairing/confirm')
        .send({ 
          pairingId,
          token: 'invalid-token',
          deviceInfo: { name: 'Test Device' }
        })
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('Invalid pairing token');
    });

    test('should return 400 when device info is missing', async () => {
      const response = await request(app)
        .post('/api/pairing/confirm')
        .send({ pairingId, token })
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('Device information is required');
    });
  });

  describe('GET /api/pairing/status/:deviceId', () => {
    let deviceId, sessionToken;

    beforeEach(async () => {
      // Complete a pairing first
      const generateResponse = await request(app)
        .post('/api/pairing/generate')
        .send({ deviceName: 'Test Device' });
      
      const pairingId = generateResponse.body.pairingId;
      const qrData = generateResponse.body.qrData;
      const tokenMatch = qrData.match(/token=([^&]+)/);
      const token = tokenMatch[1];

      const confirmResponse = await request(app)
        .post('/api/pairing/confirm')
        .send({ 
          pairingId,
          token,
          deviceInfo: { name: 'Test Device', type: 'mobile' }
        });
      
      deviceId = confirmResponse.body.deviceId;
      sessionToken = confirmResponse.body.sessionToken;
    });

    test('should return device status when authenticated', async () => {
      const response = await request(app)
        .get(`/api/pairing/status/${deviceId}`)
        .set('Authorization', `Bearer ${sessionToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('status', 'paired');
      expect(response.body).toHaveProperty('deviceInfo');
      expect(response.body.deviceInfo).toHaveProperty('name', 'Test Device');
    });

    test('should return 401 without valid session token', async () => {
      const response = await request(app)
        .get(`/api/pairing/status/${deviceId}`)
        .expect(401);

      expect(response.body).toHaveProperty('error', 'Authentication required');
    });

    test('should return 403 with invalid session token', async () => {
      const response = await request(app)
        .get(`/api/pairing/status/${deviceId}`)
        .set('Authorization', 'Bearer invalid-token')
        .expect(403);

      expect(response.body).toHaveProperty('error', 'Invalid session token');
    });

    test('should return 404 for non-existent device', async () => {
      const fakeDeviceId = uuidv4();
      
      const response = await request(app)
        .get(`/api/pairing/status/${fakeDeviceId}`)
        .set('Authorization', `Bearer ${sessionToken}`)
        .expect(404);

      expect(response.body).toHaveProperty('error', 'Device not found');
    });
  });

  describe('DELETE /api/pairing/disconnect/:deviceId', () => {
    let deviceId, sessionToken;

    beforeEach(async () => {
      // Complete a pairing first
      const generateResponse = await request(app)
        .post('/api/pairing/generate')
        .send({ deviceName: 'Test Device' });
      
      const pairingId = generateResponse.body.pairingId;
      const qrData = generateResponse.body.qrData;
      const tokenMatch = qrData.match(/token=([^&]+)/);
      const token = tokenMatch[1];

      const confirmResponse = await request(app)
        .post('/api/pairing/confirm')
        .send({ 
          pairingId,
          token,
          deviceInfo: { name: 'Test Device', type: 'mobile' }
        });
      
      deviceId = confirmResponse.body.deviceId;
      sessionToken = confirmResponse.body.sessionToken;
    });

    test('should disconnect device when authenticated', async () => {
      const response = await request(app)
        .delete(`/api/pairing/disconnect/${deviceId}`)
        .set('Authorization', `Bearer ${sessionToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('success', true);
      expect(response.body).toHaveProperty('message', 'Device disconnected');
    });

    test('should return 401 without valid session token', async () => {
      const response = await request(app)
        .delete(`/api/pairing/disconnect/${deviceId}`)
        .expect(401);

      expect(response.body).toHaveProperty('error', 'Authentication required');
    });

    test('should return 404 after disconnection', async () => {
      // Disconnect the device
      await request(app)
        .delete(`/api/pairing/disconnect/${deviceId}`)
        .set('Authorization', `Bearer ${sessionToken}`)
        .expect(200);

      // Try to get status - should return 404
      const response = await request(app)
        .get(`/api/pairing/status/${deviceId}`)
        .set('Authorization', `Bearer ${sessionToken}`)
        .expect(404);

      expect(response.body).toHaveProperty('error', 'Device not found');
    });
  });
});