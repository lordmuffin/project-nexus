# Comprehensive TDD Testing Strategy for Project Nexus

## Executive Summary

This document provides a complete Test-Driven Development (TDD) strategy for Project Nexus, a privacy-first AI productivity suite. The strategy covers our Expo Go mobile application, React web app, Node.js backend, and Python transcription services.

**Key Objectives**: Establish robust TDD practices, improve code quality, reduce bugs, accelerate development velocity, and provide confidence for rapid feature deployment.

## Table of Contents

1. [Current State Analysis](#current-state-analysis)
2. [TDD Fundamentals](#tdd-fundamentals)
3. [Testing Framework Setup](#testing-framework-setup)
4. [TDD Workflow Implementation](#tdd-workflow-implementation)
5. [Component-Specific Testing Strategies](#component-specific-testing-strategies)
6. [Docker-Based Testing Infrastructure](#docker-based-testing-infrastructure)
7. [CI/CD Pipeline Integration](#ci-cd-pipeline-integration)
8. [Implementation Roadmap](#implementation-roadmap)
9. [Success Metrics](#success-metrics)

## Current State Analysis

### Project Architecture Overview

Project Nexus consists of:
- **Mobile App** (`apps/mobile/`) - React Native/Expo companion app for remote microphone and QR pairing
- **Web App** (`apps/web/`) - React SPA with routing, features organized by domain
- **Backend API** (`packages/backend/`) - Express server with Socket.IO WebSocket support
- **Transcription Service** (`packages/transcription-service/`) - Python FastAPI service using OpenAI Whisper
- **Database** - PostgreSQL with initialization scripts

### Current Testing Infrastructure

**Existing Setup**:
- Backend: Jest configuration with supertest for API testing
- Web App: React Testing Library and Jest DOM setup
- Mobile App: **Newly configured** with jest-expo and React Native Testing Library

**Testing Gaps Identified**:
- Zero existing tests in mobile application
- Limited integration testing across services
- No E2E testing for critical user flows
- Missing Docker-based testing infrastructure
- No TDD workflow documentation

## TDD Fundamentals

### The Red-Green-Refactor Cycle

TDD follows a strict three-phase cycle:

1. **🔴 RED Phase** (30-60 seconds): Write the smallest failing test that expresses desired behavior
2. **🟢 GREEN Phase** (2-3 minutes): Implement minimal code to make the test pass
3. **🔵 REFACTOR Phase** (1-5 minutes): Improve code quality while keeping all tests green

### Three Laws of TDD

1. **Write no production code** except to pass a failing test
2. **Write only enough test code** to demonstrate a failure
3. **Write only enough production code** to pass the test

### Benefits for Project Nexus

- **Reduced Debugging Time**: Catch issues immediately
- **Improved Design**: TDD forces consideration of API design
- **Documentation**: Tests serve as living documentation
- **Confidence**: Safe refactoring and feature additions
- **Team Onboarding**: Clear examples of intended behavior

## Testing Framework Setup

### Mobile App Testing Stack (Expo 50.x)

```json
{
  "devDependencies": {
    "@types/jest": "^29.5.5",
    "@testing-library/react-native": "^13.3.3",
    "@testing-library/jest-native": "^5.4.3",
    "@testing-library/user-event": "^14.5.0",
    "jest": "^29.7.0",
    "jest-expo": "~50.0.4",
    "react-test-renderer": "18.2.0"
  }
}
```

### Jest Configuration (Mobile)

```json
{
  "jest": {
    "preset": "jest-expo/universal",
    "setupFilesAfterEnv": [
      "@testing-library/jest-native/extend-expect",
      "<rootDir>/src/__tests__/setup.js"
    ],
    "transformIgnorePatterns": [
      "node_modules/(?!(?:.pnpm/)?((jest-)?react-native|@react-native(-community)?|expo(nent)?|@expo(nent)?/.*|react-navigation|@react-navigation/.*|socket.io-client))"
    ],
    "collectCoverageFrom": [
      "src/**/*.{js,jsx,ts,tsx}",
      "!src/**/*.d.ts",
      "!src/__tests__/**"
    ],
    "coverageThreshold": {
      "global": {
        "branches": 70,
        "functions": 70,
        "lines": 80,
        "statements": 80
      }
    }
  }
}
```

### Backend Testing Stack

```json
{
  "devDependencies": {
    "jest": "^29.6.2",
    "supertest": "^6.3.3",
    "@testcontainers/postgresql": "^10.2.1",
    "nock": "^13.3.6"
  }
}
```

## TDD Workflow Implementation

### 1. Mobile Component TDD Example

Let's implement a new component using strict TDD principles:

#### Step 1: Write Failing Test (RED)

```javascript
// src/components/ConnectionStatus/__tests__/ConnectionStatus.test.js
import React from 'react';
import { render, screen } from '../../__tests__/test-utils';
import ConnectionStatus from '../ConnectionStatus';

describe('ConnectionStatus Component', () => {
  test('should display connected status when connected', () => {
    render(<ConnectionStatus isConnected={true} />);
    
    expect(screen.getByText('Connected')).toBeOnTheScreen();
    expect(screen.getByTestId('status-indicator')).toHaveStyle({
      backgroundColor: '#10b981' // green
    });
  });
});
```

#### Step 2: Minimal Implementation (GREEN)

```javascript
// src/components/ConnectionStatus/ConnectionStatus.js
import React from 'react';
import { View, Text, StyleSheet } from 'react-native';

const ConnectionStatus = ({ isConnected }) => {
  return (
    <View style={styles.container}>
      <View 
        testID="status-indicator"
        style={[
          styles.indicator, 
          { backgroundColor: isConnected ? '#10b981' : '#ef4444' }
        ]} 
      />
      <Text style={styles.text}>
        {isConnected ? 'Connected' : 'Disconnected'}
      </Text>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 8,
  },
  indicator: {
    width: 12,
    height: 12,
    borderRadius: 6,
    marginRight: 8,
  },
  text: {
    fontSize: 14,
    fontWeight: '500',
  },
});

export default ConnectionStatus;
```

#### Step 3: Add More Tests (RED again)

```javascript
test('should display disconnected status when not connected', () => {
  render(<ConnectionStatus isConnected={false} />);
  
  expect(screen.getByText('Disconnected')).toBeOnTheScreen();
  expect(screen.getByTestId('status-indicator')).toHaveStyle({
    backgroundColor: '#ef4444' // red
  });
});

test('should have proper accessibility labels', () => {
  render(<ConnectionStatus isConnected={true} />);
  
  expect(screen.getByRole('text')).toHaveAccessibilityState({
    expanded: false
  });
});
```

#### Step 4: Refactor (BLUE)

```javascript
// Enhanced implementation with accessibility
const ConnectionStatus = ({ isConnected, testID = 'connection-status' }) => {
  const statusText = isConnected ? 'Connected' : 'Disconnected';
  const statusColor = isConnected ? '#10b981' : '#ef4444';
  
  return (
    <View 
      style={styles.container}
      testID={testID}
      accessible={true}
      accessibilityLabel={`Connection status: ${statusText}`}
      accessibilityRole="text"
    >
      <View 
        testID="status-indicator"
        style={[styles.indicator, { backgroundColor: statusColor }]} 
      />
      <Text style={styles.text}>{statusText}</Text>
    </View>
  );
};
```

### 2. API Endpoint TDD Example

#### Step 1: Write Failing Test (RED)

```javascript
// packages/backend/src/api/__tests__/pairing.test.js
const request = require('supertest');
const app = require('../../server');

describe('POST /api/pairing/generate', () => {
  test('should generate QR code data for device pairing', async () => {
    const response = await request(app)
      .post('/api/pairing/generate')
      .send({ deviceName: 'iPhone 15' })
      .expect(201);

    expect(response.body).toHaveProperty('qrData');
    expect(response.body).toHaveProperty('pairingId');
    expect(response.body.qrData).toMatch(/^nexus:\/\/pair\?id=.+&token=.+$/);
    expect(response.body.pairingId).toHaveLength(36); // UUID length
  });
});
```

#### Step 2: Minimal Implementation (GREEN)

```javascript
// packages/backend/src/api/pairing.js
const express = require('express');
const { v4: uuidv4 } = require('uuid');
const router = express.Router();

router.post('/generate', async (req, res) => {
  const { deviceName } = req.body;
  
  if (!deviceName) {
    return res.status(400).json({ error: 'Device name is required' });
  }
  
  const pairingId = uuidv4();
  const token = uuidv4();
  const qrData = `nexus://pair?id=${pairingId}&token=${token}`;
  
  // TODO: Store pairing data in database
  
  res.status(201).json({
    qrData,
    pairingId,
  });
});

module.exports = router;
```

### 3. Integration Testing with WebSocket

```javascript
// packages/backend/src/__tests__/websocket.integration.test.js
const { createServer } = require('http');
const Client = require('socket.io-client');
const { Server } = require('socket.io');

describe('WebSocket Integration', () => {
  let server, serverSocket, clientSocket;

  beforeAll((done) => {
    const httpServer = createServer();
    server = new Server(httpServer);
    httpServer.listen(() => {
      const port = httpServer.address().port;
      clientSocket = new Client(`http://localhost:${port}`);
      
      server.on('connection', (socket) => {
        serverSocket = socket;
      });
      
      clientSocket.on('connect', done);
    });
  });

  afterAll(() => {
    server.close();
    clientSocket.close();
  });

  test('should handle device pairing request', (done) => {
    clientSocket.emit('pair-device', { 
      pairingId: 'test-id', 
      deviceName: 'Test Device' 
    });
    
    serverSocket.on('pair-device', (data) => {
      expect(data.pairingId).toBe('test-id');
      expect(data.deviceName).toBe('Test Device');
      
      serverSocket.emit('pairing-success', { 
        success: true, 
        deviceId: 'new-device-id' 
      });
    });
    
    clientSocket.on('pairing-success', (data) => {
      expect(data.success).toBe(true);
      expect(data.deviceId).toBe('new-device-id');
      done();
    });
  });
});
```

## Component-Specific Testing Strategies

### Mobile App Testing Patterns

#### Screen Testing

```javascript
// src/screens/__tests__/HomeScreen.test.js
import React from 'react';
import { renderWithNavigation, fireEvent, waitFor } from '../../__tests__/test-utils';
import HomeScreen from '../HomeScreen';

describe('HomeScreen', () => {
  test('should navigate to QR scanner when scan button pressed', async () => {
    const mockNavigate = jest.fn();
    const navigation = { navigate: mockNavigate };
    
    const { getByTestId } = renderWithNavigation(
      <HomeScreen navigation={navigation} />
    );
    
    fireEvent.press(getByTestId('scan-qr-button'));
    
    expect(mockNavigate).toHaveBeenCalledWith('QRScanner');
  });
});
```

#### Service Testing

```javascript
// src/services/__tests__/WebSocketClient.test.js
import WebSocketClient from '../WebSocketClient';
import { createMockSocket } from '../../__tests__/test-utils';

describe('WebSocketClient', () => {
  let client, mockSocket;
  
  beforeEach(() => {
    mockSocket = createMockSocket();
    client = new WebSocketClient('ws://localhost:3001');
    client.socket = mockSocket;
  });

  test('should connect to server with correct URL', () => {
    client.connect();
    
    expect(mockSocket.connect).toHaveBeenCalled();
  });

  test('should emit pairing request with device info', () => {
    const deviceInfo = { name: 'Test Device', type: 'mobile' };
    
    client.requestPairing(deviceInfo);
    
    expect(mockSocket.emit).toHaveBeenCalledWith('pair-device', deviceInfo);
  });
});
```

### Backend Testing Patterns

#### Database Integration Testing

```javascript
// packages/backend/src/services/__tests__/database.integration.test.js
const { PostgreSqlContainer } = require('@testcontainers/postgresql');
const Database = require('../database');

describe('Database Integration', () => {
  let container, database;

  beforeAll(async () => {
    container = await new PostgreSqlContainer()
      .withDatabase('testdb')
      .withUsername('testuser')
      .withPassword('testpass')
      .start();
    
    const connectionString = container.getConnectionUri();
    database = new Database(connectionString);
    await database.initialize();
  }, 30000);

  afterAll(async () => {
    await database.close();
    await container.stop();
  });

  test('should store and retrieve pairing data', async () => {
    const pairingData = {
      id: 'test-id',
      deviceName: 'Test Device',
      token: 'test-token',
    };
    
    await database.storePairingData(pairingData);
    const retrieved = await database.getPairingData('test-id');
    
    expect(retrieved.deviceName).toBe('Test Device');
    expect(retrieved.token).toBe('test-token');
  });
});
```

#### API Testing with External Services

```javascript
// packages/backend/src/services/__tests__/transcription.test.js
const nock = require('nock');
const TranscriptionService = require('../transcription');

describe('TranscriptionService', () => {
  afterEach(() => {
    nock.cleanAll();
  });

  test('should transcribe audio file successfully', async () => {
    nock('http://localhost:8000')
      .post('/transcribe')
      .reply(200, {
        transcript: 'Hello world',
        confidence: 0.95
      });

    const service = new TranscriptionService('http://localhost:8000');
    const result = await service.transcribe('audio-file.wav');
    
    expect(result.transcript).toBe('Hello world');
    expect(result.confidence).toBeGreaterThan(0.9);
  });
});
```

## Docker-Based Testing Infrastructure

### Multi-Stage Dockerfile for Testing

```dockerfile
# Dockerfile.test
FROM node:18-alpine AS test-base
WORKDIR /app
RUN apk add --no-cache bash git python3 make g++

# Test dependencies
FROM test-base AS test-deps
COPY package*.json ./
RUN npm ci

# Mobile app tests
FROM test-deps AS mobile-tests
COPY apps/mobile/ ./apps/mobile/
WORKDIR /app/apps/mobile
RUN npm install
RUN npm run test:ci

# Backend tests
FROM test-deps AS backend-tests
COPY packages/backend/ ./packages/backend/
WORKDIR /app/packages/backend
RUN npm install
RUN npm run test

# Integration tests
FROM test-base AS integration-tests
COPY . .
RUN npm install
ENV NODE_ENV=test
RUN npm run test:integration
```

### Docker Compose for Testing

```yaml
# docker-compose.test.yml
version: '3.8'

services:
  # Unit tests
  test-mobile:
    build:
      context: .
      dockerfile: Dockerfile.test
      target: mobile-tests
    volumes:
      - ./apps/mobile:/app/apps/mobile
      - /app/apps/mobile/node_modules

  test-backend:
    build:
      context: .
      dockerfile: Dockerfile.test
      target: backend-tests
    volumes:
      - ./packages/backend:/app/packages/backend
      - /app/packages/backend/node_modules

  # Integration tests
  test-integration:
    build:
      context: .
      dockerfile: Dockerfile.test
      target: integration-tests
    environment:
      - DATABASE_URL=postgresql://testuser:testpass@postgres-test:5432/testdb
    depends_on:
      - postgres-test

  # Test database
  postgres-test:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: testdb
      POSTGRES_USER: testuser
      POSTGRES_PASSWORD: testpass
    tmpfs:
      - /var/lib/postgresql/data

  # Test transcription service
  transcription-test:
    build:
      context: ./packages/transcription-service
      dockerfile: Dockerfile
    environment:
      - NODE_ENV=test
      - HOST=0.0.0.0
      - PORT=8000
```

## CI/CD Pipeline Integration

### GitHub Actions Workflow

```yaml
# .github/workflows/test.yml
name: Test Suite

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test-mobile:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: apps/mobile
    
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'
          cache-dependency-path: apps/mobile/package-lock.json

      - run: npm ci
      - run: npm run test:ci
      
      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          file: ./apps/mobile/coverage/lcov.info
          flags: mobile

  test-backend:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: packages/backend
    
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'
          cache-dependency-path: packages/backend/package-lock.json

      - run: npm ci
      - run: npm test -- --coverage
      
      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          file: ./packages/backend/coverage/lcov.info
          flags: backend

  test-integration:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      - name: Run integration tests
        run: |
          docker-compose -f docker-compose.test.yml up --build --abort-on-container-exit
          docker-compose -f docker-compose.test.yml down

  e2e-test:
    runs-on: ubuntu-latest
    needs: [test-mobile, test-backend]
    
    steps:
      - uses: actions/checkout@v4
      - name: Install Maestro CLI
        run: |
          curl -Ls "https://get.maestro.mobile.dev" | bash
          echo "$HOME/.maestro/bin" >> $GITHUB_PATH
      
      - name: Run E2E tests
        run: |
          # Start services
          docker-compose up -d
          # Wait for services to be ready
          sleep 30
          # Run Maestro tests
          maestro test apps/mobile/.maestro/
```

## E2E Testing with Maestro

### Maestro Configuration

```yaml
# apps/mobile/.maestro/login-flow.yml
appId: com.nexus.companion
---
- launchApp
- tapOn: "Scan QR Code"
- assertVisible: "Point camera at QR code"
- tapOn: "Settings"
- assertVisible: "Device Settings"
- tapOn: "Connection Status"
- assertVisible: id: "connection-status"
```

### Critical User Flow Tests

```yaml
# apps/mobile/.maestro/pairing-flow.yml
appId: com.nexus.companion
---
- launchApp
- tapOn: "Scan QR Code"
- assertVisible: "Point camera at QR code"
# Simulate QR code scan
- inputText: "nexus://pair?id=test-id&token=test-token"
- tapOn: "Connect"
- assertVisible: "Successfully paired!"
- tapOn: "Start Recording"
- assertVisible: "Recording..."
- tapOn: "Stop Recording"
- assertVisible: "Recording saved"
```

## Implementation Roadmap

### Phase 1: Foundation (Weeks 1-2) ✅

**Completed**:
- ✅ Mobile app testing infrastructure setup
- ✅ Jest configuration with jest-expo
- ✅ Test utilities and mocks creation
- ✅ TDD documentation creation

**Remaining**:
- Create characterization tests for existing components
- Enhance backend testing infrastructure
- Set up Docker testing environment

### Phase 2: Expansion (Weeks 3-4)

**Goals**:
- Apply TDD to new feature development
- Add integration tests for WebSocket communication
- Implement database testing with test containers
- Create E2E tests with Maestro

### Phase 3: Optimization (Weeks 5-6)

**Goals**:
- Optimize test suite performance
- Implement CI/CD automation
- Add performance and accessibility testing
- Establish monitoring and metrics

## Success Metrics

### Coverage Targets
- **Unit Tests**: 80% line coverage, 70% branch coverage
- **Integration Tests**: All API endpoints covered
- **E2E Tests**: All critical user flows covered

### Performance Targets
- **Test Suite Execution**: <5 minutes for full suite
- **Feedback Loop**: <30 seconds for unit tests
- **CI/CD Pipeline**: <10 minutes total execution time

### Quality Metrics
- **Build Success Rate**: >95%
- **Mean Time to Detect Issues**: <1 day
- **Developer Confidence**: Track through surveys

### Team Adoption
- **TDD Compliance**: 100% for new features
- **Code Review**: Testing requirements enforced
- **Documentation**: All patterns documented and accessible

## Troubleshooting Common Issues

### Mobile Testing Issues

**React Navigation Mock Problems**:
```javascript
// If navigation mocks aren't working properly
jest.mock('@react-navigation/native', () => ({
  ...jest.requireActual('@react-navigation/native'),
  useNavigation: () => ({
    navigate: jest.fn(),
    goBack: jest.fn(),
  }),
}));
```

**Expo Module Mocking**:
```javascript
// For modules that don't have built-in mocks
jest.mock('expo-barcode-scanner', () => ({
  BarCodeScanner: {
    requestPermissionsAsync: jest.fn(() => 
      Promise.resolve({ status: 'granted' })
    ),
  },
}));
```

**Socket.IO Testing Issues**:
```javascript
// Mock socket for testing WebSocket functionality
const mockSocket = {
  emit: jest.fn(),
  on: jest.fn(),
  disconnect: jest.fn(),
};

jest.mock('socket.io-client', () => jest.fn(() => mockSocket));
```

### Backend Testing Issues

**Database Connection Issues**:
```javascript
// Use test containers for reliable database testing
const { PostgreSqlContainer } = require('@testcontainers/postgresql');

beforeAll(async () => {
  container = await new PostgreSqlContainer().start();
  process.env.DATABASE_URL = container.getConnectionUri();
});
```

## Conclusion

This comprehensive TDD strategy provides Project Nexus with:

1. **Immediate Implementation**: Ready-to-use testing infrastructure
2. **Future-Proof Practices**: Scalable testing patterns for growth
3. **Quality Assurance**: Automated testing at all levels
4. **Developer Confidence**: Safe refactoring and feature development
5. **Team Alignment**: Clear processes and documentation

The investment in TDD infrastructure will significantly improve code quality, reduce production bugs, accelerate development velocity, and provide confidence for rapid feature deployment.

**Next Steps**: Begin with Phase 1 implementation, focusing on creating characterization tests for existing components while applying TDD to all new development work.