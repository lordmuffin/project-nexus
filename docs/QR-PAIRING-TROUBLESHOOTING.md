# QR Code Pairing Troubleshooting Guide

This guide helps diagnose and resolve common issues with the QR code pairing system.

## Problem Diagnosis Flowchart

```
QR Pairing Not Working
        │
        ├─ QR Code Generation Fails
        │  ├─ Frontend not reaching backend → Check backend status
        │  ├─ Backend CORS errors → Check CORS configuration
        │  └─ Invalid response format → Check API implementation
        │
        ├─ Mobile App Not Scanning
        │  ├─ QR scanner not opening → Check camera permissions
        │  ├─ QR code not detected → Check QR code display
        │  └─ App crashes on scan → Check mobile app logs
        │
        ├─ "Invalid Token" Error
        │  ├─ Multiple backend servers → Check for conflicts
        │  ├─ Token expired → Check timing
        │  └─ Network routing issues → Check IP configuration
        │
        └─ Connection/Network Issues
           ├─ Mobile device can't reach backend → Check network
           ├─ CORS blocking requests → Check CORS settings
           └─ WebSocket connection fails → Check WebSocket setup
```

## Step-by-Step Diagnosis

### Step 1: Verify Backend Status

**Command**:
```bash
curl -s http://localhost:3001/api/health | jq '.'
```

**Expected Response**:
```json
{
  "status": "healthy",
  "timestamp": "2025-09-22T21:51:02.948Z",
  "uptime": 1234.567,
  "version": "1.0.0",
  "services": {
    "database": "connected",
    "transcription": "ready", 
    "websocket": "active"
  }
}
```

**If Backend Not Responding**:
- Check Docker containers: `docker ps`
- Check backend logs: `docker logs project-nexus-backend-1`
- Restart backend: `docker-compose restart backend`

### Step 2: Test QR Code Generation

**Command**:
```bash
curl -X POST http://localhost:3001/api/pairing/generate-qr \
  -H "Content-Type: application/json" -v
```

**Common Issues**:

**CORS Error**:
```
< HTTP/1.1 403 Forbidden
< Access-Control-Allow-Origin: http://different-origin
```
**Solution**: Update CORS configuration in backend server.js

**404 Not Found**:
```
< HTTP/1.1 404 Not Found
{"error":"Not found","message":"Route POST /api/pairing/generate-qr not found"}
```
**Solution**: Check if pairing routes are properly registered

**500 Internal Error**:
```
< HTTP/1.1 500 Internal Server Error
{"error":"Internal server error"}
```
**Solution**: Check backend logs for specific error details

### Step 3: Test Network Connectivity

**From Host Machine**:
```bash
# Test local access
curl -s http://localhost:3001/api/health

# Test network access
curl -s http://192.168.1.61:3001/api/health
```

**From Mobile Device**:
- Open browser on mobile device
- Navigate to `http://192.168.1.61:3001/api/health`
- Should see JSON health response

**If Network Access Fails**:
- Check firewall settings
- Verify mobile device is on same network
- Check IP address: `ip addr show`
- Test ping: `ping 192.168.1.61`

### Step 4: Diagnose "Invalid Token" Error

**Test Token Flow from Host Machine**:
```bash
# Generate token on localhost
TOKEN=$(curl -X POST http://localhost:3001/api/pairing/generate-qr \
  -H "Content-Type: application/json" -s | jq -r '.data.token')

echo "Generated token: ${TOKEN:0:16}..."

# Test validation on localhost
echo "Testing localhost validation:"
curl -X POST http://localhost:3001/api/pairing/validate-token \
  -H "Content-Type: application/json" \
  -d "{\"token\":\"$TOKEN\",\"deviceInfo\":{\"platform\":\"test\"}}" -s

# Test validation on network IP  
echo "Testing network IP validation:"
curl -X POST http://192.168.1.61:3001/api/pairing/validate-token \
  -H "Content-Type: application/json" \
  -d "{\"token\":\"$TOKEN\",\"deviceInfo\":{\"platform\":\"test\"}}" -s
```

**Test Token Flow from Remote Computer on Network**:
```bash
# IMPORTANT: Use the same backend endpoint for both generation and validation
TOKEN=$(curl -X POST http://192.168.1.61:3001/api/pairing/generate-qr \
  -H "Content-Type: application/json" -s | jq -r '.data.token')

echo "Generated token: ${TOKEN:0:16}..."

# Test validation on the same backend
curl -X POST http://192.168.1.61:3001/api/pairing/validate-token \
  -H "Content-Type: application/json" \
  -d "{\"token\":\"$TOKEN\",\"deviceInfo\":{\"platform\":\"test\"}}" -s
```

**If localhost works but 192.168.1.61 fails**:
- **Multiple backend servers running**
- **Solution**: Check for conflicts and ensure single backend

### Step 5: Check for Multiple Backend Instances

**Commands**:
```bash
# Check for local node processes
ps aux | grep "node.*server" | grep -v grep

# Check Docker containers
docker ps | grep backend

# Check port usage
lsof -i :3001
```

**If Multiple Backends Found**:
1. Stop local node servers: `pkill -f "node.*server"`
2. Ensure only Docker backend is running
3. Verify both localhost and network IP hit same backend

### Step 6: Debug Mobile App Issues

**Add Debug Logging to Mobile App**:

In `QRScannerScreen.js`:
```javascript
const handleBarCodeScanned = async ({ type, data }) => {
  // Add immediate debug alert
  Alert.alert('QR Detected', 
    `Type: ${type}\nData Length: ${data.length}\nFirst 100 chars: ${data.substring(0, 100)}`);
  
  // Continue with normal processing...
};
```

**Common Mobile Issues**:

**QR Scanner Not Opening**:
- Check camera permissions in device settings
- Verify `expo-barcode-scanner` is installed
- Check for camera usage in other apps

**App Crashes on Scan**:
- Missing dependencies (`expo-network`, `socket.io-client`)
- JavaScript parsing errors
- Network request failures

**No Response After Scan**:
- Check Expo development server logs
- Verify mobile device can reach backend
- Add network error debugging

### Step 7: Verify Complete Data Flow

**Generate and Test Token**:
```bash
#!/bin/bash

echo "=== Complete Token Flow Test ==="

# Step 1: Generate QR
echo "1. Generating QR code..."
RESPONSE=$(curl -X POST http://localhost:3001/api/pairing/generate-qr \
  -H "Content-Type: application/json" -s)

TOKEN=$(echo $RESPONSE | jq -r '.data.token')
echo "Token: ${TOKEN:0:16}..."

# Step 2: Verify QR data structure  
echo "2. Checking QR data structure..."
QR_JSON=$(echo $RESPONSE | jq -r '.data | {token, serverUrl: ("ws://" + .serverInfo.host + ":" + .serverInfo.port), expiresAt}')
echo "QR would contain: $QR_JSON"

# Step 3: Test mobile validation
echo "3. Testing mobile validation..."
curl -X POST http://192.168.1.61:3001/api/pairing/validate-token \
  -H "Content-Type: application/json" \
  -d "{\"token\":\"$TOKEN\",\"deviceInfo\":{\"platform\":\"mobile\"}}" \
  -s | jq '.'

echo "4. Testing token reuse (should fail)..."
curl -X POST http://192.168.1.61:3001/api/pairing/validate-token \
  -H "Content-Type: application/json" \
  -d "{\"token\":\"$TOKEN\",\"deviceInfo\":{\"platform\":\"mobile\"}}" \
  -s | jq '.'
```

## Common Error Messages and Solutions

### "Invalid token"
**Cause**: Token not found in backend storage
**Solution**: Check for multiple backend instances

### "Token expired" 
**Cause**: More than 5 minutes passed since generation
**Solution**: Generate fresh QR code

### "Token already used"
**Cause**: Token was successfully used once (expected behavior)
**Solution**: Generate new QR code for new pairing

### "CORS error"
**Cause**: Mobile app origin not allowed by backend
**Solution**: Update CORS configuration in server.js

### "Network error"
**Cause**: Mobile device cannot reach backend
**Solution**: Check network connectivity and firewall

### "JSON parse error"
**Cause**: Invalid QR code data format
**Solution**: Check QR generation logic

## Prevention Checklist

Before starting QR pairing:

- [ ] Backend health check passes
- [ ] Only one backend instance running
- [ ] Mobile device on same network
- [ ] Firewall allows port 3001
- [ ] CORS configured for mobile requests
- [ ] Expo development server running
- [ ] Mobile app has required dependencies
- [ ] Camera permissions granted

## Monitoring and Logging

**Enable Backend Debug Logging**:
Add to backend `validate-token` endpoint:
```javascript
console.log('PAIRING: Token lookup result:', tokenData ? 'FOUND' : 'NOT_FOUND');
console.log('PAIRING: Total tokens in storage:', pairingTokens.size);
console.log('PAIRING: Request IP:', req.ip);
```

**Monitor Backend Logs**:
```bash
docker logs -f project-nexus-backend-1 | grep PAIRING
```

**Monitor Mobile App Logs**:
- Use React Native Debugger
- Check Expo development console
- Add alert-based debugging for production testing

## Escalation

If issues persist after following this guide:

1. Collect diagnostic information:
   - Backend health status
   - Docker container status  
   - Network connectivity test results
   - Mobile app error logs

2. Test with curl commands to isolate the issue

3. Check for recent code changes that might have broken the flow

4. Consider rolling back to last known working state