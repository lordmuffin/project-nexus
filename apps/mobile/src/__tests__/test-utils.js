// Test utilities for consistent testing setup
import React from 'react';
import { render } from '@testing-library/react-native';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';

const Stack = createStackNavigator();

// Mock NavigationContainer wrapper for testing components with navigation
const NavigationWrapper = ({ children, initialRouteName = 'Test' }) => (
  <NavigationContainer>
    <Stack.Navigator initialRouteName={initialRouteName}>
      <Stack.Screen name="Test" component={() => children} />
    </Stack.Navigator>
  </NavigationContainer>
);

// Custom render function with navigation context
export const renderWithNavigation = (ui, options = {}) => {
  const { initialRouteName, ...renderOptions } = options;
  
  const Wrapper = ({ children }) => (
    <NavigationWrapper initialRouteName={initialRouteName}>
      {children}
    </NavigationWrapper>
  );

  return render(ui, { wrapper: Wrapper, ...renderOptions });
};

// Mock socket instance for testing WebSocket functionality
export const createMockSocket = () => ({
  on: jest.fn(),
  off: jest.fn(),
  emit: jest.fn(),
  connect: jest.fn(),
  disconnect: jest.fn(),
  connected: true,
  id: 'mock-socket-id',
});

// Mock audio recording for testing recording functionality
export const createMockRecording = () => ({
  startAsync: jest.fn(),
  stopAndUnloadAsync: jest.fn(),
  getURI: jest.fn(() => 'mock-recording-uri'),
  getStatusAsync: jest.fn(() => Promise.resolve({
    isRecording: false,
    isDoneRecording: true,
    durationMillis: 5000,
  })),
});

// Mock camera permissions
export const mockCameraPermissions = (status = 'granted') => {
  const { BarCodeScanner } = require('expo-barcode-scanner');
  BarCodeScanner.requestPermissionsAsync.mockResolvedValue({ status });
};

// Mock audio permissions
export const mockAudioPermissions = (status = 'granted') => {
  const { Audio } = require('expo-av');
  Audio.requestPermissionsAsync.mockResolvedValue({ status });
};

// Mock network state
export const mockNetworkState = (isConnected = true, type = 'WIFI') => {
  const ExpoNetwork = require('expo-network');
  ExpoNetwork.getNetworkStateAsync.mockResolvedValue({
    type,
    isConnected,
    isInternetReachable: isConnected,
  });
};

// Helper to wait for async operations in tests
export const waitFor = (callback, timeout = 1000) => {
  return new Promise((resolve, reject) => {
    const startTime = Date.now();
    
    const check = () => {
      try {
        const result = callback();
        if (result) {
          resolve(result);
        } else if (Date.now() - startTime >= timeout) {
          reject(new Error('Timeout waiting for condition'));
        } else {
          setTimeout(check, 10);
        }
      } catch (error) {
        if (Date.now() - startTime >= timeout) {
          reject(error);
        } else {
          setTimeout(check, 10);
        }
      }
    };
    
    check();
  });
};

// Helper to create mock navigation prop
export const createMockNavigation = (overrides = {}) => ({
  navigate: jest.fn(),
  goBack: jest.fn(),
  reset: jest.fn(),
  setParams: jest.fn(),
  dispatch: jest.fn(),
  setOptions: jest.fn(),
  isFocused: jest.fn(() => true),
  addListener: jest.fn(() => jest.fn()),
  ...overrides,
});

// Helper to create mock route prop
export const createMockRoute = (params = {}) => ({
  params,
  key: 'mock-key',
  name: 'MockScreen',
});

// Re-export everything from @testing-library/react-native
export * from '@testing-library/react-native';

// Export default render function
export { render };