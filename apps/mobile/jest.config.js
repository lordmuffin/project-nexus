// Jest configuration for React Native/Expo app
module.exports = {
  preset: 'jest-expo',
  
  // Setup files
  setupFilesAfterEnv: [
    '@testing-library/jest-native/extend-expect',
    '<rootDir>/src/__tests__/setup.js'
  ],
  
  // Transform configuration - more permissive for testing
  transformIgnorePatterns: [
    'node_modules/(?!(?:.pnpm/)?((jest-)?react-native|@react-native(-community)?|expo(nent)?|@expo(nent)?/.*|@expo-google-fonts/.*|react-navigation|@react-navigation/.*|@sentry/react-native|native-base|react-native-svg|socket.io-client|react-native-reanimated))'
  ],
  
  // Test file patterns
  testMatch: [
    '<rootDir>/src/**/__tests__/**/*.{js,jsx,ts,tsx}',
    '<rootDir>/src/**/*.{test,spec}.{js,jsx,ts,tsx}'
  ],
  
  // Coverage configuration
  collectCoverageFrom: [
    'src/**/*.{js,jsx,ts,tsx}',
    '!src/**/*.d.ts',
    '!src/__tests__/**',
    '!src/**/*.stories.{js,jsx,ts,tsx}',
    '!src/index.js'
  ],
  
  // Coverage thresholds - more lenient for initial setup
  coverageThreshold: {
    global: {
      branches: 50,
      functions: 50,
      lines: 60,
      statements: 60
    }
  },
  
  // Verbose output
  verbose: true,
  
  // Clear cache to avoid babel issues
  clearMocks: true,
  
  // Max workers
  maxWorkers: process.env.CI ? 2 : '50%'
};