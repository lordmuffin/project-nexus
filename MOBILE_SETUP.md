# Mobile App Setup Guide

## Node.js 22 Compatibility Issue

If you're using Node.js 22 with pnpm 8.0.0, you may encounter `ERR_INVALID_THIS` errors when installing dependencies. This is a known compatibility issue.

## Solutions

### Option 1: Use Node.js 18 LTS (Recommended)
```bash
# Install Node.js 18 LTS using nvm
nvm install 18
nvm use 18
pnpm install
```

### Option 2: Use npm instead of pnpm
```bash
cd apps/mobile
npm install
npm start
```

### Option 3: Upgrade pnpm (if you have sudo access)
```bash
sudo npm install -g pnpm@latest
pnpm install
```

### Option 4: Use Docker (Bypasses local Node.js issues)
```bash
pnpm run docker:up:full
```

## Quick Start (After resolving Node.js issues)

1. **Install dependencies**:
   ```bash
   cd apps/mobile
   pnpm install  # or npm install
   ```

2. **Start development server**:
   ```bash
   pnpm start  # or npm start
   ```

3. **Connect mobile device**:
   - Install Expo Go on your phone
   - Scan QR code from terminal
   - Make sure phone and computer are on same WiFi

4. **Test QR pairing**:
   - Open desktop app → Settings → Generate QR Code
   - In mobile app, tap "Scan QR Code"
   - Scan the QR code to pair devices

## Alternative: Use Existing nexus-companion

If you prefer to use the existing standalone mobile app:

```bash
cd ../nexus-companion
npm install
npm start
```

## Docker Development (Recommended for avoiding Node.js issues)

The Docker setup uses Node.js 18 which avoids compatibility issues:

```bash
# Start all services including mobile development
pnpm run docker:up:full

# Access mobile dev server at:
# http://localhost:19000
```

## Troubleshooting

- **QR scanning not working**: Make sure you have camera permissions
- **Connection failed**: Check that backend is running on port 3001
- **Build errors**: Try clearing cache with `expo start -c`
- **Network issues**: Ensure devices are on same WiFi network