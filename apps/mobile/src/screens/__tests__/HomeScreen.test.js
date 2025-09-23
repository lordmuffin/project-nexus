// Characterization tests for existing HomeScreen component
import React from 'react';
import { Alert } from 'react-native';
import { render, screen, fireEvent, waitFor } from '../../__tests__/test-utils';
import { renderWithNavigation, createMockNavigation } from '../../__tests__/test-utils';
import HomeScreen from '../HomeScreen';
import WebSocketClient from '../../services/WebSocketClient';

// Mock WebSocketClient
jest.mock('../../services/WebSocketClient', () => ({
  initialize: jest.fn(),
  onConnectionChange: jest.fn(() => jest.fn()), // Return unsubscribe function
  discoverServer: jest.fn(),
  connectToServer: jest.fn(),
}));

// Mock Alert
jest.spyOn(Alert, 'alert').mockImplementation(() => {});
jest.spyOn(Alert, 'prompt').mockImplementation(() => {});

describe('HomeScreen Component', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Initial Render', () => {
    test('should display app title and subtitle', () => {
      render(<HomeScreen />);
      
      expect(screen.getByText('Nexus Companion')).toBeOnTheScreen();
      expect(screen.getByText('Remote Microphone')).toBeOnTheScreen();
    });

    test('should display all navigation buttons', () => {
      render(<HomeScreen />);
      
      expect(screen.getByText('Start Recording')).toBeOnTheScreen();
      expect(screen.getByText('Scan QR Code')).toBeOnTheScreen();
      expect(screen.getByText('Connect Manually')).toBeOnTheScreen();
      expect(screen.getByText('Settings')).toBeOnTheScreen();
    });

    test('should display footer instructions', () => {
      render(<HomeScreen />);
      
      expect(screen.getByText(/Scan the QR code from Nexus Desktop Settings/)).toBeOnTheScreen();
    });

    test('should display record button with microphone icon', () => {
      render(<HomeScreen />);
      
      expect(screen.getByText('🎤')).toBeOnTheScreen();
    });
  });

  describe('WebSocket Initialization', () => {
    test('should initialize WebSocket client on mount', () => {
      render(<HomeScreen />);
      
      expect(WebSocketClient.initialize).toHaveBeenCalledTimes(1);
      expect(WebSocketClient.onConnectionChange).toHaveBeenCalledTimes(1);
      expect(WebSocketClient.discoverServer).toHaveBeenCalledTimes(1);
    });

    test('should set up connection status listener', () => {
      const mockUnsubscribe = jest.fn();
      WebSocketClient.onConnectionChange.mockReturnValue(mockUnsubscribe);
      
      const { unmount } = render(<HomeScreen />);
      
      expect(WebSocketClient.onConnectionChange).toHaveBeenCalledWith(
        expect.any(Function)
      );
      
      unmount();
      expect(mockUnsubscribe).toHaveBeenCalledTimes(1);
    });
  });

  describe('Navigation Actions', () => {
    test('should navigate to QRScanner when scan button is pressed', () => {
      const mockNavigation = createMockNavigation();
      
      render(<HomeScreen navigation={mockNavigation} />);
      
      fireEvent.press(screen.getByText('Scan QR Code'));
      
      expect(mockNavigation.navigate).toHaveBeenCalledWith('QRScanner');
    });

    test('should navigate to Settings when settings button is pressed', () => {
      const mockNavigation = createMockNavigation();
      
      render(<HomeScreen navigation={mockNavigation} />);
      
      fireEvent.press(screen.getByText('Settings'));
      
      expect(mockNavigation.navigate).toHaveBeenCalledWith('Settings');
    });
  });

  describe('Recording Functionality', () => {
    test('should show alert when trying to record while disconnected', () => {
      render(<HomeScreen />);
      
      fireEvent.press(screen.getByText('Start Recording'));
      
      expect(Alert.alert).toHaveBeenCalledWith(
        'Not Connected',
        'Please connect to a Nexus server before starting recording.',
        [{ text: 'OK' }]
      );
    });

    test('should navigate to Recording when connected and record button pressed', () => {
      const mockNavigation = createMockNavigation();
      
      // Mock the connection status listener to simulate connected state
      WebSocketClient.onConnectionChange.mockImplementation((callback) => {
        // Immediately call with connected status
        callback('connected', { host: '192.168.1.100', port: 3001 });
        return jest.fn(); // Return unsubscribe function
      });
      
      render(<HomeScreen navigation={mockNavigation} />);
      
      fireEvent.press(screen.getByText('Start Recording'));
      
      expect(mockNavigation.navigate).toHaveBeenCalledWith('Recording');
    });
  });

  describe('Manual Connection', () => {
    test('should show prompt for manual connection', () => {
      render(<HomeScreen />);
      
      fireEvent.press(screen.getByText('Connect Manually'));
      
      expect(Alert.prompt).toHaveBeenCalledWith(
        'Connect to Server',
        'Enter the IP address of your Nexus server:',
        [
          { text: 'Cancel', style: 'cancel' },
          {
            text: 'Connect',
            onPress: expect.any(Function),
          },
        ],
        'plain-text',
        '192.168.1.100'
      );
    });

    test('should call WebSocketClient.connectToServer when IP is provided', () => {
      render(<HomeScreen />);
      
      fireEvent.press(screen.getByText('Connect Manually'));
      
      // Get the onPress function from the Connect button
      const alertCall = Alert.prompt.mock.calls[0];
      const connectButton = alertCall[2][1]; // Second button (Connect)
      const onPress = connectButton.onPress;
      
      // Simulate entering an IP address
      onPress('192.168.1.200');
      
      expect(WebSocketClient.connectToServer).toHaveBeenCalledWith('192.168.1.200');
    });

    test('should not call WebSocketClient.connectToServer when no IP provided', () => {
      render(<HomeScreen />);
      
      fireEvent.press(screen.getByText('Connect Manually'));
      
      const alertCall = Alert.prompt.mock.calls[0];
      const connectButton = alertCall[2][1];
      const onPress = connectButton.onPress;
      
      // Simulate empty input
      onPress('');
      
      expect(WebSocketClient.connectToServer).not.toHaveBeenCalled();
    });
  });

  describe('Connection Status Display', () => {
    test('should display ConnectionStatus component', () => {
      render(<HomeScreen />);
      
      // The ConnectionStatus component should be rendered
      // We can test this by checking if the component receives the correct props
      expect(screen.getByTestId('connection-status')).toBeDefined();
    });

    test('should disable record button when disconnected', () => {
      render(<HomeScreen />);
      
      const recordButton = screen.getByText('Start Recording').parent;
      
      // Button should be disabled by default (disconnected state)
      expect(recordButton.props.accessibilityState?.disabled).toBe(true);
    });
  });

  describe('Component State Management', () => {
    test('should update connection status when WebSocket status changes', async () => {
      let statusCallback;
      WebSocketClient.onConnectionChange.mockImplementation((callback) => {
        statusCallback = callback;
        return jest.fn();
      });
      
      render(<HomeScreen />);
      
      // Simulate connection status change
      statusCallback('connected', { 
        host: '192.168.1.100', 
        port: 3001,
        name: 'Test Server',
        version: '1.0.0'
      });
      
      await waitFor(() => {
        // The component should re-render with new status
        // This would be reflected in the ConnectionStatus component
        expect(screen.getByText('Connected')).toBeOnTheScreen();
      });
    });
  });
});