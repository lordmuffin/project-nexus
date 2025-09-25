# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Root-level Commands (pnpm workspace)
- `pnpm run dev` - Start all development servers in parallel
- `pnpm run build` - Build all packages using Turborepo
- `pnpm run test` - Run all tests across packages
- `pnpm run lint` - Lint all packages
- `pnpm run type-check` - Type check all TypeScript code

### Docker Development
- `pnpm run docker:up` - Start core services (web, backend, database, AI)
- `pnpm run docker:up:full` - Start all services including mobile development server
- `pnpm run docker:up:dev` - Start development profile services
- `pnpm run docker:down` - Stop all Docker services
- `pnpm run docker:logs` - View service logs

### Individual Services
- `pnpm run web` - Start web app (React) on port 3000
- `pnpm run backend` - Start backend API server on port 3001
- `pnpm run desktop` - Start Electron desktop app
- `pnpm run mobile` - Start mobile app with Expo (port 8081/19000)
- `pnpm run transcription` - Start transcription service on port 8000

### Backend-specific Commands
Navigate to `packages/backend/` for:
- `npm run dev` - Start with nodemon
- `npm run test` - Run Jest tests
- `npm run lint` - ESLint validation
- `npm run db:setup` - Initialize database
- `npm run db:migrate` - Run database migrations

## Architecture Overview

Project Nexus is a privacy-first, local AI productivity suite built as a monorepo with distinct application layers:

### Core Applications
- **Web App** (`apps/web/`) - React SPA with routing, features organized by domain (chat, meetings, notes, settings)
- **Desktop App** (`apps/desktop/`) - Electron wrapper around web app with native OS integration
- **Mobile App** (`apps/mobile/`) - React Native/Expo companion app for remote microphone and QR pairing

### Backend Services
- **Node.js API** (`packages/backend/`) - Express server with Socket.IO WebSocket support
- **Transcription Service** (`packages/transcription-service/`) - Python FastAPI service using OpenAI Whisper
- **Database** - PostgreSQL with initialization scripts in `packages/backend/db/`

### Key Architectural Patterns

#### Service Communication
- **WebSocket**: Real-time communication via Socket.IO between frontend and backend
- **REST API**: Standard HTTP APIs for CRUD operations
- **QR Pairing**: Mobile devices connect via QR code authentication system
- **File Uploads**: Multer-based audio file handling with temporary storage

#### Data Flow
1. **Audio Recording**: Mobile → WebSocket → Backend → Transcription Service
2. **AI Processing**: Backend → Ollama (local LLM) → Frontend via WebSocket
3. **Data Persistence**: PostgreSQL for meetings, notes, chat history
4. **File Storage**: Local uploads directory with audio processing pipeline

#### Frontend Architecture
- **Feature-based structure**: `/features/` directory with domain-specific components
- **Shared components**: Header, Sidebar in `/components/`
- **Service hooks**: Custom React hooks like `useHealthCheck` for API integration
- **Theme system**: Centralized theme management in `/lib/theme.js`

### Technology Stack Details

#### Frontend Stack
- **React 18** with functional components and hooks
- **React Router v6** for client-side routing with future flags enabled
- **Socket.IO Client** for real-time WebSocket communication
- **CSS Modules** for component-scoped styling

#### Backend Stack
- **Express.js** with comprehensive middleware (CORS, Helmet, Morgan)
- **Socket.IO** for WebSocket server with room-based messaging
- **PostgreSQL** with connection pooling and prepared statements
- **Multer** for multipart form handling and file uploads
- **JWT + bcrypt** for authentication (device pairing)

#### AI/ML Stack
- **OpenAI Whisper** (base model default) for speech-to-text
- **Ollama** for local LLM inference with model management
- **FastAPI** for Python transcription service with async support
- **PyTorch** backend for Whisper model execution

#### Build System
- **Turborepo** for monorepo orchestration and caching
- **pnpm workspaces** for dependency management
- **Docker Compose** for service orchestration with profiles
- **Electron Builder** for desktop app packaging

### Critical Configuration Notes

#### Environment Variables
Backend requires:
- `FRONTEND_URL` - CORS origin configuration
- `DATABASE_URL` - PostgreSQL connection string  
- `OLLAMA_URL` - Local LLM service endpoint
- `TRANSCRIPTION_SERVICE_URL` - Python Whisper service

#### Service Dependencies
- Backend depends on: Database, Ollama, Transcription Service
- Frontend connects to: Backend API + WebSocket
- Mobile app connects to: Backend (network discovery + QR pairing)
- Desktop app serves: Bundled web app with native shell

#### Docker Networking
All services communicate via `nexus-network` bridge with:
- Frontend: Port 3000 (web interface)
- Backend: Port 3001 (API + WebSocket)
- Database: Port 5432 (PostgreSQL)
- Ollama: Port 11434 (LLM inference)
- Transcription: Port 8000 (FastAPI)
- Mobile Dev: Ports 8081, 19000-19002 (Expo)

### Known Issues & Considerations
- Web app has merge conflicts in `App.js` and `package.json` (theme provider integration)
- Mobile app now integrated into monorepo at `apps/mobile/` (formerly separate repository)
- CORS configuration allows broad origins for mobile development
- GPU support available but commented out in Docker configs
- Workspace configuration excludes backend from pnpm workspace (separate package.json)