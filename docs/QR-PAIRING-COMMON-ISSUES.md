# QR Code Pairing Common Issues

This document catalogs the most frequently encountered issues with QR code pairing and their solutions.

## Issue #1: Multiple Backend Servers Conflict

### Symptoms
- Frontend generates QR codes successfully
- Mobile app gets "Invalid token" error consistently
- curl tests show different behavior for localhost vs network IP

### Root Cause
Two backend servers running simultaneously:
- Docker container on port 3001 (network accessible)
- Local node server on port 3001 (localhost only)

Frontend generates tokens on one server, mobile validates on different server.

### Diagnostic Commands
```bash
# Check for multiple backends
ps aux | grep "node.*server" | grep -v grep
docker ps | grep backend

# Test both endpoints
curl -s http://localhost:3001/api/health | jq '.uptime'
curl -s http://192.168.1.61:3001/api/health | jq '.uptime'
```

### Solution
1. **Stop local node server**:
   ```bash
   pkill -f "node.*server"
   ```

2. **Ensure Docker backend is running**:
   ```bash
   docker-compose restart backend
   ```

3. **Verify single backend**:
   ```bash
   TOKEN=$(curl -X POST http://localhost:3001/api/pairing/generate-qr -H "Content-Type: application/json" -s | jq -r '.data.token')
   curl -X POST http://192.168.1.61:3001/api/pairing/validate-token -H "Content-Type: application/json" -d "{\"token\":\"$TOKEN\",\"deviceInfo\":{\"platform\":\"mobile\"}}" -s
   ```

### Prevention
- Use Docker Compose for consistent environment
- Check for running processes before starting development
- Configure development scripts to avoid port conflicts

---

## Issue #2: CORS Blocking Mobile Requests

### Symptoms
- QR generation works in browser
- Mobile app makes requests but gets CORS errors
- Network requests fail with access control errors

### Root Cause
Backend CORS configuration only allows `http://localhost:3000`, but mobile apps send requests without origin headers or from different origins.

### Diagnostic Commands
```bash
# Test CORS from different origin
curl -X POST http://192.168.1.61:3001/api/pairing/validate-token \
  -H "Origin: http://mobile-app" \
  -H "Content-Type: application/json" \
  -d '{"token":"test","deviceInfo":{"platform":"mobile"}}' \
  -v
```

### Solution
Update CORS configuration in `packages/backend/src/server.js`:

```javascript
app.use(cors({
  origin: function (origin, callback) {
    // Allow requests with no origin (mobile apps)
    if (!origin) return callback(null, true);
    
    const allowedOrigins = [
      process.env.FRONTEND_URL || "http://localhost:3000",
      "http://localhost:8082", // Expo dev server
      "http://192.168.1.61:3000", // Network access
      "http://192.168.1.61:8082"
    ];
    
    // Allow network IP origins for mobile apps
    if (origin.startsWith('http://192.168.1.61') || 
        origin.startsWith('http://localhost') ||
        allowedOrigins.includes(origin)) {
      return callback(null, true);
    }
    
    return callback(null, true); // Permissive for mobile pairing
  },
  credentials: true
}));
```

### Prevention
- Test mobile requests during development
- Use permissive CORS for development environment
- Document mobile app origin requirements

---

## Issue #3: Network IP Detection Problems

### Symptoms
- QR codes contain localhost or Docker internal IPs
- Mobile devices cannot reach the server URL in QR codes
- Backend runs in Docker with incorrect network detection

### Root Cause
Backend IP detection logic returns Docker bridge IPs (172.x.x.x) instead of host network IP.

### Diagnostic Commands
```bash
# Check current IP detection
curl -X POST http://localhost:3001/api/pairing/generate-qr \
  -H "Content-Type: application/json" -s | jq '.data.serverInfo'

# Check actual host IP
ip route get 8.8.8.8 | awk '{print $7}' | head -1
```

### Solution
Enhanced IP detection in `packages/backend/src/api/pairing.js`:

```javascript
async function getHostMachineIP() {
  try {
    // Method 1: Use ip route to get actual network IP
    const { stdout } = await execAsync("ip route get 8.8.8.8 | awk '{print $7}' | head -1");
    const actualIP = stdout.trim();
    
    if (actualIP && /^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/.test(actualIP) && !actualIP.startsWith('172.')) {
      console.log('Found actual host IP via ip route:', actualIP);
      return actualIP;
    }
  } catch (error) {
    console.warn('Failed to get IP via ip route:', error.message);
  }
  
  // Fallback methods...
}
```

### Prevention
- Test QR generation from network devices
- Verify IP addresses in development environment
- Use consistent network configuration

---

## Issue #4: Missing Mobile Dependencies

### Symptoms
- Expo Go drops back to main menu after scanning
- No error messages visible
- Mobile app appears to scan but nothing happens

### Root Cause
Missing required npm packages:
- `expo-network` - for network detection
- `socket.io-client` - for WebSocket connections

### Diagnostic Commands
```bash
# Check mobile app dependencies
cd apps/mobile
npm list expo-network socket.io-client
```

### Solution
Install missing dependencies:

```bash
cd apps/mobile
npm install expo-network@~6.0.0 socket.io-client@^4.7.0
```

Update imports in `src/services/WebSocketClient.js`:
```javascript
import * as Network from 'expo-network';
import { io } from 'socket.io-client';
```

### Prevention
- Include all required dependencies in package.json
- Test mobile app in fresh environment
- Document mobile-specific dependencies

---

## Issue #5: Token Expiration Issues

### Symptoms
- QR generation works
- Immediate testing works
- Mobile scanning fails with "Invalid token"

### Root Cause
Tokens expire after 5 minutes, or timing issues between generation and validation.

### Diagnostic Commands
```bash
# Test token timing
TOKEN=$(curl -X POST http://localhost:3001/api/pairing/generate-qr -H "Content-Type: application/json" -s | jq -r '.data.token')
echo "Token generated at: $(date)"
sleep 5
echo "Testing after 5 seconds: $(date)"
curl -X POST http://192.168.1.61:3001/api/pairing/validate-token -H "Content-Type: application/json" -d "{\"token\":\"$TOKEN\",\"deviceInfo\":{\"platform\":\"mobile\"}}" -s
```

### Solution
1. **Generate fresh QR codes** for each pairing attempt
2. **Complete pairing within 5 minutes** of generation
3. **Check system time synchronization** between devices

### Prevention
- Educate users about 5-minute expiration
- Add expiration countdown in UI
- Consider longer expiration for development

---

## Issue #6: WebSocket Connection Failures

### Symptoms
- QR pairing completes successfully
- Mobile app reports pairing success
- Audio/data transmission fails
- Connection status shows disconnected

### Root Cause
WebSocket connection establishment fails after pairing due to network configuration.

### Diagnostic Commands
```bash
# Test WebSocket endpoint
curl -I http://192.168.1.61:3001/socket.io/
```

### Solution
1. **Verify WebSocket endpoint** is accessible
2. **Check firewall settings** for WebSocket connections
3. **Update mobile app connection logic**:

```javascript
const socket = io(serverUrl, {
  transports: ['websocket', 'polling'],
  autoConnect: true,
  reconnection: true,
  timeout: 5000
});
```

### Prevention
- Test full WebSocket flow during development
- Monitor connection status in mobile app
- Implement connection retry logic

---

## Issue #7: Remote Computer Backend Endpoint Mismatch

### Symptoms
- QR generation works from host machine
- Remote computer gets "Invalid token" error consistently
- Docker logs show requests from different IP addresses
- Commands work when testing from host machine but fail from network computers

### Root Cause
Remote computers may be generating tokens on one backend (localhost or different IP) but validating on another backend. Each backend instance has its own in-memory token storage.

### Diagnostic Commands
```bash
# From remote computer, check if different backends respond
curl -s http://localhost:3001/api/health | jq '.uptime'
curl -s http://192.168.1.61:3001/api/health | jq '.uptime'

# Different uptime values = different backend instances
```

### Solution
**Use the same backend endpoint for both generation and validation**:

```bash
# CORRECT: Both commands use the same backend
TOKEN=$(curl -X POST http://192.168.1.61:3001/api/pairing/generate-qr \
  -H "Content-Type: application/json" -s | jq -r '.data.token')

curl -X POST http://192.168.1.61:3001/api/pairing/validate-token \
  -H "Content-Type: application/json" \
  -d "{\"token\":\"$TOKEN\",\"deviceInfo\":{\"platform\":\"mobile\"}}" -s
```

**INCORRECT mixing of endpoints**:
```bash
# This will fail - different backends!
TOKEN=$(curl -X POST http://localhost:3001/api/pairing/generate-qr ...)  # Backend A
curl -X POST http://192.168.1.61:3001/api/pairing/validate-token ...      # Backend B
```

### Prevention
- Always use the network IP (192.168.1.61:3001) when testing from remote computers
- Ensure only one backend instance is running across the network
- Document the correct testing commands for remote computer scenarios

---

## Issue Summary Matrix

| Issue | Symptoms | Quick Test | Solution |
|-------|----------|------------|----------|
| Multiple Backends | "Invalid token" | `ps aux \| grep server` | Stop local server |
| CORS Blocking | Network errors | `curl -H "Origin: test"` | Update CORS config |
| Wrong IP Detection | localhost in QR | Check `serverInfo.host` | Fix IP detection |
| Missing Dependencies | App crashes/drops | `npm list` | Install packages |
| Token Expiration | Works then fails | Test timing | Generate fresh QR |
| WebSocket Issues | Pairing works, connection fails | Test `/socket.io/` | Fix WS config |
| Remote Computer Mismatch | "Invalid token" from remote | Check uptime values | Use same backend endpoint |

## Quick Diagnostic Script

```bash
#!/bin/bash

echo "=== QR Pairing Quick Diagnostic ==="

# Check backend processes
echo "1. Backend processes:"
ps aux | grep -E "(node.*server|docker.*backend)" | grep -v grep || echo "No backend processes found"

# Check backend health
echo -e "\n2. Backend health:"
curl -s http://localhost:3001/api/health > /dev/null && echo "✅ localhost:3001 OK" || echo "❌ localhost:3001 FAIL"
curl -s http://192.168.1.61:3001/api/health > /dev/null && echo "✅ 192.168.1.61:3001 OK" || echo "❌ 192.168.1.61:3001 FAIL"

# Test QR generation
echo -e "\n3. QR generation test:"
QR_RESPONSE=$(curl -X POST http://localhost:3001/api/pairing/generate-qr -H "Content-Type: application/json" -s 2>/dev/null)
if echo "$QR_RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
  HOST=$(echo "$QR_RESPONSE" | jq -r '.data.serverInfo.host')
  echo "✅ QR generation OK (host: $HOST)"
else
  echo "❌ QR generation FAIL"
fi

# Test mobile validation
echo -e "\n4. Mobile validation test:"
if [ ! -z "$QR_RESPONSE" ]; then
  TOKEN=$(echo "$QR_RESPONSE" | jq -r '.data.token')
  VALIDATION=$(curl -X POST http://192.168.1.61:3001/api/pairing/validate-token -H "Content-Type: application/json" -d "{\"token\":\"$TOKEN\",\"deviceInfo\":{\"platform\":\"test\"}}" -s 2>/dev/null)
  if echo "$VALIDATION" | jq -e '.success' > /dev/null 2>&1; then
    echo "✅ Mobile validation OK"
  else
    echo "❌ Mobile validation FAIL: $(echo "$VALIDATION" | jq -r '.error')"
  fi
fi

echo -e "\nDiagnostic complete."
```

Save this as `scripts/diagnose-qr-pairing.sh` and run when issues occur.