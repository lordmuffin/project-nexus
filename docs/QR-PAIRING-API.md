# QR Code Pairing API Reference

This document provides detailed API specifications for the QR code pairing system.

## Base URL

- **Development**: `http://localhost:3001` or `http://192.168.1.61:3001`
- **Production**: `https://your-domain.com`

## Authentication

The pairing API uses temporary tokens for security. No persistent authentication is required for the pairing endpoints.

## Endpoints

### Generate QR Code

Generates a QR code with pairing token for mobile device connection.

**Endpoint**: `POST /api/pairing/generate-qr`

**Headers**:
```
Content-Type: application/json
```

**Request Body**: None

**Response**:
```json
{
  "success": true,
  "data": {
    "token": "64-character-hex-string",
    "qrCode": "data:image/png;base64,iVBORw0KGgo...",
    "expiresAt": 1234567890000,
    "serverInfo": {
      "host": "192.168.1.61",
      "port": "3001"
    }
  }
}
```

**Response Fields**:
- `token` (string): 64-character hexadecimal pairing token
- `qrCode` (string): Base64-encoded PNG image data URL
- `expiresAt` (number): Unix timestamp when token expires (5 minutes from generation)
- `serverInfo.host` (string): IP address mobile device should connect to
- `serverInfo.port` (string): Port number for backend API

**QR Code Content**:
The QR code contains JSON data that mobile apps scan:
```json
{
  "token": "64-character-hex-string",
  "serverUrl": "ws://192.168.1.61:3001",
  "expiresAt": 1234567890000
}
```

**Error Responses**:
```json
{
  "success": false,
  "error": "Failed to generate QR code"
}
```

**Status Codes**:
- `200`: Success
- `500`: Internal server error

---

### Validate Pairing Token

Validates a pairing token scanned from QR code and establishes device pairing.

**Endpoint**: `POST /api/pairing/validate-token`

**Headers**:
```
Content-Type: application/json
```

**Request Body**:
```json
{
  "token": "64-character-hex-string",
  "deviceInfo": {
    "platform": "mobile",
    "userAgent": "Nexus Companion App",
    "version": "1.0.0",
    "deviceName": "Mobile Device"
  }
}
```

**Request Fields**:
- `token` (string, required): Pairing token from QR code
- `deviceInfo` (object, required): Device information
  - `platform` (string): Device platform (e.g., "mobile", "ios", "android")
  - `userAgent` (string): Application identifier
  - `version` (string): App version
  - `deviceName` (string): Human-readable device name

**Success Response**:
```json
{
  "success": true,
  "data": {
    "deviceId": "uuid-generated-device-id",
    "message": "Device paired successfully",
    "timestamp": "2025-09-22T21:51:02.948Z"
  }
}
```

**Success Response Fields**:
- `deviceId` (string): Unique identifier for the paired device
- `message` (string): Success message
- `timestamp` (string): ISO timestamp of pairing

**Error Responses**:

**Missing Token**:
```json
{
  "success": false,
  "error": "Token is required"
}
```

**Invalid Token**:
```json
{
  "success": false,
  "error": "Invalid token"
}
```

**Expired Token**:
```json
{
  "success": false,
  "error": "Token expired"
}
```

**Already Used Token**:
```json
{
  "success": false,
  "error": "Token already used"
}
```

**Status Codes**:
- `200`: Success
- `400`: Missing required fields
- `404`: Invalid token
- `409`: Token already used
- `410`: Token expired
- `500`: Internal server error

---

### Get Paired Devices

Retrieves list of currently paired devices.

**Endpoint**: `GET /api/pairing/devices`

**Headers**: None required

**Response**:
```json
{
  "success": true,
  "data": {
    "devices": [
      {
        "deviceId": "uuid-device-id",
        "deviceInfo": {
          "platform": "mobile",
          "userAgent": "Nexus Companion App",
          "version": "1.0.0",
          "deviceName": "Mobile Device"
        },
        "pairedAt": "2025-09-22T21:51:02.948Z",
        "isActive": true,
        "lastSeen": "2025-09-22T22:15:30.123Z"
      }
    ]
  }
}
```

**Response Fields**:
- `devices` (array): List of paired devices
  - `deviceId` (string): Unique device identifier
  - `deviceInfo` (object): Device information from pairing
  - `pairedAt` (string): ISO timestamp when device was paired
  - `isActive` (boolean): Whether device is currently active
  - `lastSeen` (string): ISO timestamp of last activity

---

### Unpair Device

Removes a device from the paired devices list.

**Endpoint**: `DELETE /api/pairing/devices/{deviceId}`

**Path Parameters**:
- `deviceId` (string): Device ID to unpair

**Response**:
```json
{
  "success": true,
  "message": "Device unpaired successfully"
}
```

**Error Response**:
```json
{
  "success": false,
  "error": "Device not found"
}
```

**Status Codes**:
- `200`: Success
- `404`: Device not found
- `500`: Internal server error

---

## WebSocket Events

After successful pairing, devices communicate via WebSocket events.

### Connection

**URL**: `ws://192.168.1.61:3001`

**Protocol**: Socket.IO

### Events

**Client → Server Events**:

**mobile_client_connected**:
```json
{
  "deviceInfo": {
    "platform": "mobile",
    "userAgent": "Nexus Companion App",
    "timestamp": 1234567890000
  }
}
```

**audio_uploaded**:
```json
{
  "transcriptionId": "uuid",
  "duration": 45.5,
  "timestamp": 1234567890000
}
```

**Server → Client Events**:

**device_paired**:
```json
{
  "deviceId": "uuid",
  "deviceInfo": {...},
  "timestamp": "2025-09-22T21:51:02.948Z"
}
```

**device_unpaired**:
```json
{
  "deviceId": "uuid"
}
```

**meeting_started**:
```json
{
  "meetingId": "uuid",
  "timestamp": "2025-09-22T21:51:02.948Z"
}
```

**transcription_ready**:
```json
{
  "transcriptionId": "uuid",
  "text": "Transcribed audio content",
  "timestamp": "2025-09-22T21:51:02.948Z"
}
```

---

## Rate Limits

- **QR Generation**: 10 requests per minute per IP
- **Token Validation**: 20 requests per minute per IP
- **Device Management**: 50 requests per minute per IP

---

## Security Considerations

### Token Security
- Tokens are 64-character cryptographically secure random strings
- Tokens expire after 5 minutes
- Tokens are single-use only
- Tokens are stored in memory only (not persisted)

### Network Security
- CORS configured to allow mobile app origins
- No persistent authentication required for pairing
- Device information is stored but not sensitive
- WebSocket connections use same security model

### Best Practices
- Generate new QR codes for each pairing session
- Validate device information on pairing
- Monitor for suspicious pairing activity
- Implement rate limiting in production
- Use HTTPS in production environments

---

## Error Handling

### Client Error Handling

**Network Errors**:
```javascript
try {
  const response = await fetch('/api/pairing/validate-token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ token, deviceInfo })
  });
  
  if (!response.ok) {
    throw new Error(`HTTP ${response.status}: ${response.statusText}`);
  }
  
  const result = await response.json();
  if (!result.success) {
    throw new Error(result.error);
  }
  
  return result.data;
} catch (error) {
  console.error('Pairing failed:', error);
  // Handle specific error types
  if (error.message.includes('Token expired')) {
    // Generate new QR code
  } else if (error.message.includes('Invalid token')) {
    // Show error to user
  }
}
```

### Server Error Logging

The backend logs pairing attempts with the following format:
```
PAIRING: validate-token endpoint called
PAIRING: Request IP: 192.168.1.61
PAIRING: Token lookup result: FOUND
PAIRING: Total tokens in storage: 1
```

---

## Testing

### Unit Tests

Test individual endpoints:
```bash
# Test QR generation
curl -X POST http://localhost:3001/api/pairing/generate-qr \
  -H "Content-Type: application/json"

# Test token validation
curl -X POST http://localhost:3001/api/pairing/validate-token \
  -H "Content-Type: application/json" \
  -d '{"token":"test-token","deviceInfo":{"platform":"test"}}'
```

### Integration Tests

Test complete pairing flow:
```bash
TOKEN=$(curl -X POST http://localhost:3001/api/pairing/generate-qr \
  -H "Content-Type: application/json" -s | jq -r '.data.token')

curl -X POST http://192.168.1.61:3001/api/pairing/validate-token \
  -H "Content-Type: application/json" \
  -d "{\"token\":\"$TOKEN\",\"deviceInfo\":{\"platform\":\"mobile\"}}"
```

### Load Testing

Test with multiple concurrent requests:
```bash
for i in {1..10}; do
  curl -X POST http://localhost:3001/api/pairing/generate-qr \
    -H "Content-Type: application/json" &
done
wait
```

---

## Migration Guide

### From Version 1.0 to 1.1

- No breaking changes
- Enhanced IP detection
- Improved CORS handling
- Added device management endpoints

### Database Schema

The pairing system uses the following database table:

```sql
CREATE TABLE device_pairs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id VARCHAR(255) UNIQUE NOT NULL,
    device_info JSONB NOT NULL,
    paired_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    unpaired_at TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    last_seen TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## Support

For API support and questions:

1. Check the [Troubleshooting Guide](./QR-PAIRING-TROUBLESHOOTING.md)
2. Review [Common Issues](./QR-PAIRING-COMMON-ISSUES.md)
3. Test with provided curl commands
4. Check backend logs for detailed error information