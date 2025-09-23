# Nexus Mobile Companion

The mobile companion app for Project Nexus, built with React Native and Expo.

## Features

- 📱 **QR Code Pairing**: Scan QR codes from the desktop app to pair devices securely
- 🎤 **Remote Recording**: Use your mobile device as a remote microphone for meetings
- 🔄 **Real-time Connection**: WebSocket connection for instant status updates
- 🔒 **Privacy-First**: All data stays on your local network

## Getting Started

### Prerequisites

- Node.js 18+ and pnpm 8+
- Expo CLI (`npm install -g @expo/cli`)
- Expo Go app on your mobile device

### Development

1. **Install dependencies**:
   ```bash
   pnpm install
   ```

2. **Start the development server**:
   ```bash
   pnpm start
   # or from the root directory
   pnpm mobile
   ```

3. **Run on device**:
   - Install Expo Go on your mobile device
   - Scan the QR code displayed in the terminal
   - Make sure your mobile device and development machine are on the same network

### Usage

1. **Pairing with Desktop**:
   - Open Nexus Desktop Settings
   - Generate a QR code for device pairing
   - Open the mobile app and tap "Scan QR Code"
   - Scan the QR code to pair your device

2. **Recording Audio**:
   - Once paired, tap the microphone button to start recording
   - Your audio will be sent to the desktop for transcription
   - View transcription results in the desktop app

## Project Structure

```
src/
├── App.js              # Main app navigation
├── components/         # Reusable components
│   └── ConnectionStatus.js
├── screens/           # Screen components
│   ├── HomeScreen.js     # Main screen with connection status
│   ├── QRScannerScreen.js # QR code scanning
│   ├── RecordingScreen.js # Audio recording
│   └── SettingsScreen.js  # App settings
└── services/          # Business logic
    └── WebSocketClient.js # Server communication
```

## Permissions

The app requires the following permissions:

- **Camera**: For QR code scanning
- **Microphone**: For audio recording

These permissions are requested when needed and can be managed in your device settings.

## Privacy

- ✅ All audio processing happens locally on your Nexus server
- ✅ No data is sent to external servers
- ✅ Communication is limited to your local network only
- ✅ QR codes contain time-limited tokens for secure pairing

## Troubleshooting

### Connection Issues

1. **Make sure both devices are on the same WiFi network**
2. **Check that the Nexus server is running** (`pnpm backend` from root directory)
3. **Try manual connection** with the server IP address
4. **Regenerate QR code** if pairing fails (tokens expire after 5 minutes)

### Recording Issues

1. **Check microphone permissions** in device settings
2. **Ensure good network connection** for audio upload
3. **Verify server connection** in the app settings

## Building for Production

### Android
```bash
pnpm build:android
```

### iOS
```bash
pnpm build:ios
```

## Contributing

See the main [project README](../../README.md) for contribution guidelines.

## License

MIT License - see [LICENSE](../../LICENSE) for details.