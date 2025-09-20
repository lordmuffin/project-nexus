# Project Nexus

Project Nexus is an AI-powered local productivity suite designed for privacy-conscious users who want powerful collaboration tools without compromising their data security. All processing happens locally on your machine, ensuring your conversations, meetings, and documents never leave your control.

## 🚀 Features

### 🎯 Core Functionality
- **Local AI Processing**: All AI operations run on your hardware
- **Real-time Transcription**: Powered by OpenAI's Whisper model
- **Meeting Management**: Schedule, conduct, and archive meetings
- **Smart Chat**: AI-enhanced conversation interface
- **Cross-Platform**: Web app with optional desktop wrapper

### 🛡️ Privacy & Security
- **100% Local**: No data sent to external servers
- **Offline Capable**: Core features work without internet
- **Encrypted Storage**: Local data protection
- **No Telemetry**: Zero data collection

### 📱 Multi-Platform Support
- **Desktop App**: Electron wrapper for native experience
- **Web Interface**: Modern responsive web application
- **Mobile Companion**: Remote microphone and basic controls

## 🏗️ Architecture

Project Nexus is built as a monorepo with clearly separated concerns:

```
nexus/
├── apps/
│   ├── desktop/          # Electron desktop wrapper
│   └── web/              # React web application
└── packages/
    ├── backend/          # Node.js API server
    ├── transcription-service/  # Python Whisper service
    └── eslint-config-nexus/    # Shared linting config
```

### Technology Stack
- **Frontend**: React, TypeScript, Modern CSS
- **Backend**: Node.js, Express, SQLite
- **Transcription**: Python, OpenAI Whisper, FastAPI
- **Desktop**: Electron
- **Mobile**: React Native (separate repository)
- **Build System**: Turborepo, pnpm workspaces

## 🚦 Getting Started

### Prerequisites
- Node.js 18+ and pnpm 8+
- Python 3.8+ (for transcription service)
- Docker and Docker Compose (recommended)

### Quick Start with Docker

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/nexus.git
   cd nexus
   ```

2. **Start all services**
   ```bash
   pnpm run docker:up
   ```

3. **Access the applications**
   - Web interface: http://localhost:3000
   - Backend API: http://localhost:3001
   - Transcription service: http://localhost:8000

### Development Setup

1. **Install dependencies**
   ```bash
   pnpm install
   ```

2. **Start development servers**
   ```bash
   # Start all services in parallel
   pnpm run dev
   
   # Or start individual services
   pnpm run web        # Web app only
   pnpm run backend    # Backend only
   pnpm run desktop    # Desktop app only
   ```

3. **Build for production**
   ```bash
   pnpm run build
   ```

## 📋 Available Scripts

### Root Commands
- `pnpm run dev` - Start all development servers
- `pnpm run build` - Build all packages
- `pnpm run test` - Run all tests
- `pnpm run lint` - Lint all packages
- `pnpm run type-check` - Type check all TypeScript

### Docker Commands
- `pnpm run docker:up` - Start all services with Docker
- `pnpm run docker:down` - Stop all Docker services
- `pnpm run docker:build` - Build Docker images
- `pnpm run docker:logs` - View service logs

### Individual Services
- `pnpm run web` - Start web development server
- `pnpm run backend` - Start backend development server
- `pnpm run desktop` - Start desktop app in development
- `pnpm run transcription` - Start transcription service

## 🐳 Docker Deployment

The project includes a complete Docker Compose setup for easy deployment:

```yaml
# Core services included:
- backend          # Node.js API server
- transcription    # Python Whisper service
```

For production deployment, see the `docker-compose.yml` file for configuration options including GPU support for faster transcription.

## 🔧 Configuration

### Environment Variables

Create `.env.local` files in the appropriate directories:

**Backend (`packages/backend/.env.local`):**
```env
NODE_ENV=development
PORT=3001
FRONTEND_URL=http://localhost:3000
TRANSCRIPTION_SERVICE_URL=http://localhost:8000
```

**Web App (`apps/web/.env.local`):**
```env
REACT_APP_API_URL=http://localhost:3001
REACT_APP_WS_URL=ws://localhost:3001
```

### Transcription Models

The transcription service supports multiple Whisper models:
- `tiny` - Fastest, least accurate (39 MB)
- `base` - Good balance (74 MB) **[Default]**
- `small` - Better accuracy (244 MB)
- `medium` - Even better accuracy (769 MB)
- `large` - Best accuracy, slowest (1550 MB)

## 📱 Mobile Companion

The mobile companion app is available in a separate repository: `nexus-companion`

Features:
- Remote microphone for meetings
- Real-time connection status
- Simple recording controls
- Local network discovery

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow the existing code style (ESLint + Prettier configured)
- Write tests for new features
- Update documentation as needed
- Ensure all CI checks pass

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [OpenAI Whisper](https://github.com/openai/whisper) for the transcription engine
- [React](https://reactjs.org/) for the frontend framework
- [Electron](https://www.electronjs.org/) for cross-platform desktop support
- All the amazing open-source contributors who make projects like this possible

## 📞 Support

If you encounter any issues or have questions:

1. Check the [Issues](https://github.com/your-username/nexus/issues) page
2. Create a new issue with detailed information
3. Join our community discussions

---

**Made with ❤️ for privacy-conscious productivity enthusiasts**