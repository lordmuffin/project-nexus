# QR Code Pairing End-to-End Testing Guide

This document provides comprehensive testing procedures for the mobile device QR code pairing system in Project Nexus.

## Overview

The QR code pairing system allows mobile devices running the Nexus Companion app to connect to the desktop application by scanning a QR code generated in the web interface.

### System Architecture

```
┌─────────────────┐    HTTP     ┌─────────────────┐
│   Web Frontend  │─────────────│  Docker Backend │
│  (port 3000)    │             │   (port 3001)   │
└─────────────────┘             └─────────────────┘
                                          │
                                    WebSocket/HTTP
                                          │
┌─────────────────┐    Scan QR   ┌─────────────────┐
│   Mobile App    │──────────────│   QR Code with  │
│   (Expo Go)     │              │   Token + URL   │
└─────────────────┘              └─────────────────┘
```

## Prerequisites

- Docker containers running (`docker-compose up`)
- Expo development server running (`npx expo start --port 8082`)
- Mobile device on same network as host machine
- Backend accessible at `192.168.1.61:3001` from mobile device

## End-to-End Testing Process

### Step 1: Generate QR Code

**Purpose**: Test QR code generation and token creation

```bash
# Test QR code generation
curl -X POST http://localhost:3001/api/pairing/generate-qr \
  -H "Content-Type: application/json" \
  -s | jq '.'
```

**Expected Response**:
```json
{
  "success": true,
  "data": {
    "token": "abc123...",
    "qrCode": "data:image/png;base64,...",
    "expiresAt": 1234567890000,
    "serverInfo": {
      "host": "192.168.1.61",
      "port": "3001"
    }
  }
}
```

**Validation Checks**:
- ✅ `success: true`
- ✅ Token is 64-character hex string
- ✅ QR code is base64 PNG data URL
- ✅ Host IP is network IP (192.168.1.61), not localhost
- ✅ Expiration is 5 minutes in future

### Step 2: Extract QR Data

**Purpose**: Verify the JSON data embedded in the QR code

```bash
# Extract the data that mobile app would receive from QR scan
curl -X POST http://localhost:3001/api/pairing/generate-qr \
  -H "Content-Type: application/json" -s | \
  jq -r '.data | {token, serverUrl: ("ws://" + .serverInfo.host + ":" + .serverInfo.port), expiresAt}'
```

**Expected QR Content**:
```json
{
  "token": "abc123...",
  "serverUrl": "ws://192.168.1.61:3001",
  "expiresAt": 1234567890000
}
```

**Validation Checks**:
- ✅ Contains `token` field
- ✅ Contains `serverUrl` field with WebSocket protocol
- ✅ Server URL uses network IP, not localhost
- ✅ Contains `expiresAt` timestamp

### Step 3: Simulate Mobile App Validation

**Purpose**: Test token validation from mobile device perspective

**For testing from the same host machine**:
```bash
# Generate token on localhost
TOKEN=$(curl -X POST http://localhost:3001/api/pairing/generate-qr \
  -H "Content-Type: application/json" -s | jq -r '.data.token')

# Test validation from network IP (mobile device perspective)
curl -X POST http://192.168.1.61:3001/api/pairing/validate-token \
  -H "Content-Type: application/json" \
  -d "{\"token\":\"$TOKEN\",\"deviceInfo\":{\"platform\":\"mobile\",\"userAgent\":\"Nexus Companion App\",\"version\":\"1.0.0\",\"deviceName\":\"Mobile Device\"}}" \
  -s
```

**For testing from a remote computer on the network**:
```bash
# Generate token using network IP (ensures same backend)
TOKEN=$(curl -X POST http://192.168.1.61:3001/api/pairing/generate-qr \
  -H "Content-Type: application/json" -s | jq -r '.data.token')

# Verify token was captured
echo "Generated token: ${TOKEN:0:16}..."

# Test validation from the same backend
curl -X POST http://192.168.1.61:3001/api/pairing/validate-token \
  -H "Content-Type: application/json" \
  -d "{\"token\":\"$TOKEN\",\"deviceInfo\":{\"platform\":\"mobile\"}}" \
  -s
```

**Expected Response**:
```json
{
  "success": true,
  "data": {
    "deviceId": "uuid-here",
    "message": "Device paired successfully",
    "timestamp": "2025-09-22T21:51:02.948Z"
  }
}
```

**Validation Checks**:
- ✅ `success: true`
- ✅ Device ID is generated
- ✅ Timestamp is current
- ✅ No CORS errors
- ✅ Token is consumed (subsequent requests should fail)

### Step 4: Verify Token Consumption

**Purpose**: Ensure tokens can only be used once

```bash
# Try to use the same token again
curl -X POST http://192.168.1.61:3001/api/pairing/validate-token \
  -H "Content-Type: application/json" \
  -d "{\"token\":\"$TOKEN\",\"deviceInfo\":{\"platform\":\"mobile\"}}" \
  -s
```

**Expected Response**:
```json
{
  "success": false,
  "error": "Token already used"
}
```

## Complete Test Script

```bash
#!/bin/bash

echo "=== Project Nexus QR Pairing End-to-End Test ==="
echo

# Step 1: Generate QR Code
echo "1. Generating QR Code..."
RESPONSE=$(curl -X POST http://localhost:3001/api/pairing/generate-qr \
  -H "Content-Type: application/json" -s)

if [ $? -ne 0 ]; then
  echo "❌ Failed to generate QR code"
  exit 1
fi

TOKEN=$(echo $RESPONSE | jq -r '.data.token')
HOST=$(echo $RESPONSE | jq -r '.data.serverInfo.host')

echo "✅ QR Code generated"
echo "   Token: ${TOKEN:0:16}..."
echo "   Host: $HOST"
echo

# Step 2: Validate QR Data Structure
echo "2. Validating QR data structure..."
QR_DATA=$(echo $RESPONSE | jq -r '.data | {token, serverUrl: ("ws://" + .serverInfo.host + ":" + .serverInfo.port), expiresAt}')
echo "   QR contains: $(echo $QR_DATA | jq -r 'keys | join(", ")')"

if echo $QR_DATA | jq -e '.token and .serverUrl' > /dev/null; then
  echo "✅ QR data structure valid"
else
  echo "❌ QR data structure invalid"
  exit 1
fi
echo

# Step 3: Test Mobile Validation
echo "3. Testing mobile device validation..."
VALIDATION_RESPONSE=$(curl -X POST http://192.168.1.61:3001/api/pairing/validate-token \
  -H "Content-Type: application/json" \
  -d "{\"token\":\"$TOKEN\",\"deviceInfo\":{\"platform\":\"mobile\",\"userAgent\":\"Test\"}}" \
  -s)

if echo $VALIDATION_RESPONSE | jq -e '.success' > /dev/null; then
  DEVICE_ID=$(echo $VALIDATION_RESPONSE | jq -r '.data.deviceId')
  echo "✅ Mobile validation successful"
  echo "   Device ID: $DEVICE_ID"
else
  echo "❌ Mobile validation failed"
  echo "   Error: $(echo $VALIDATION_RESPONSE | jq -r '.error')"
  exit 1
fi
echo

# Step 4: Test Token Consumption
echo "4. Testing token consumption..."
REUSE_RESPONSE=$(curl -X POST http://192.168.1.61:3001/api/pairing/validate-token \
  -H "Content-Type: application/json" \
  -d "{\"token\":\"$TOKEN\",\"deviceInfo\":{\"platform\":\"mobile\"}}" \
  -s)

if echo $REUSE_RESPONSE | jq -e '.success == false' > /dev/null; then
  echo "✅ Token properly consumed (cannot be reused)"
else
  echo "❌ Token reuse prevention failed"
  exit 1
fi
echo

echo "🎉 All tests passed! QR pairing system is working correctly."
```

## Success Criteria

A successful end-to-end test should demonstrate:

1. **QR Generation**: Frontend can generate QR codes with valid tokens
2. **Network Accessibility**: Mobile devices can reach the backend server
3. **Token Validation**: Tokens can be successfully validated from mobile network requests
4. **Security**: Tokens are single-use and expire appropriately
5. **Data Integrity**: QR code contains correct server information for mobile connection

## Next Steps

After successful testing:

1. Test with actual mobile device using Expo Go
2. Verify WebSocket connection establishment after pairing
3. Test audio recording and transcription workflow
4. Validate device management (listing, unpairing)

## Related Documentation

- [Troubleshooting Guide](./QR-PAIRING-TROUBLESHOOTING.md)
- [Common Issues](./QR-PAIRING-COMMON-ISSUES.md)
- [API Reference](./QR-PAIRING-API.md)