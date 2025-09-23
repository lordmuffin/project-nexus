// Setup file for Jest tests
import 'react-native-gesture-handler/jestSetup';

// Polyfill for crypto.randomUUID if needed
if (!global.crypto) {
  global.crypto = {};
}
if (!global.crypto.randomUUID) {
  global.crypto.randomUUID = () => {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
      const r = Math.random() * 16 | 0;
      const v = c === 'x' ? r : (r & 0x3 | 0x8);
      return v.toString(16);
    });
  };
}

// Mock react-native-safe-area-context
jest.mock('react-native-safe-area-context', () => {
  const inset = { top: 0, right: 0, bottom: 0, left: 0 };
  return {
    SafeAreaProvider: jest.fn().mockImplementation(({ children }) => children),
    SafeAreaConsumer: jest.fn().mockImplementation(({ children }) => children(inset)),
    useSafeAreaInsets: jest.fn().mockImplementation(() => inset),
    useSafeAreaFrame: jest.fn().mockImplementation(() => ({ x: 0, y: 0, width: 390, height: 844 })),
  };
});

// Mock expo modules
jest.mock('expo-status-bar', () => ({
  StatusBar: 'StatusBar',
}));

jest.mock('expo-network', () => ({
  getNetworkStateAsync: jest.fn(() => Promise.resolve({
    type: 'WIFI',
    isConnected: true,
    isInternetReachable: true,
  })),
  addNetworkStateListener: jest.fn(() => ({ remove: jest.fn() })),
}));

jest.mock('expo-av', () => ({
  Audio: {
    requestPermissionsAsync: jest.fn(() => Promise.resolve({ status: 'granted' })),
    setAudioModeAsync: jest.fn(() => Promise.resolve()),
    Recording: {
      createAsync: jest.fn(() => Promise.resolve({
        recording: {
          startAsync: jest.fn(),
          stopAndUnloadAsync: jest.fn(),
          getURI: jest.fn(() => 'mock-recording-uri'),
        },
      })),
    },
  },
}));

jest.mock('expo-barcode-scanner', () => ({
  BarCodeScanner: {
    requestPermissionsAsync: jest.fn(() => Promise.resolve({ status: 'granted' })),
    Constants: {
      BarCodeType: {
        qr: 'qr',
      },
    },
  },
}));

// Mock Socket.IO client
jest.mock('socket.io-client', () => {
  const mockSocket = {
    on: jest.fn(),
    off: jest.fn(),
    emit: jest.fn(),
    connect: jest.fn(),
    disconnect: jest.fn(),
    connected: true,
    id: 'mock-socket-id',
  };
  
  return {
    __esModule: true,
    default: jest.fn(() => mockSocket),
    io: jest.fn(() => mockSocket),
  };
});

// Mock AsyncStorage if needed (commented out since not currently used)
// jest.mock('@react-native-async-storage/async-storage', () =>
//   require('@react-native-async-storage/async-storage/jest/async-storage-mock')
// );

// Mock navigation
jest.mock('@react-navigation/native', () => {
  const actualNav = jest.requireActual('@react-navigation/native');
  return {
    ...actualNav,
    useNavigation: () => ({
      navigate: jest.fn(),
      goBack: jest.fn(),
      reset: jest.fn(),
      setParams: jest.fn(),
      dispatch: jest.fn(),
      setOptions: jest.fn(),
      isFocused: jest.fn(() => true),
      addListener: jest.fn(() => jest.fn()),
    }),
    useRoute: () => ({
      params: {},
    }),
    useFocusEffect: jest.fn(),
  };
});

// Silence the warning: Animated: `useNativeDriver` is not supported
jest.mock('react-native/Libraries/Animated/NativeAnimatedHelper');

// Mock console.warn to reduce noise in tests
const originalWarn = console.warn;
beforeAll(() => {
  console.warn = (...args) => {
    if (
      typeof args[0] === 'string' &&
      args[0].includes('componentWillReceiveProps') ||
      args[0].includes('componentWillMount')
    ) {
      return;
    }
    originalWarn.call(console, ...args);
  };
});

afterAll(() => {
  console.warn = originalWarn;
});