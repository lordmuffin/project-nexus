// ESLint configuration for mobile app with testing support
module.exports = {
  extends: [
    'expo',
    '@react-native-community',
    'plugin:react-hooks/recommended',
    'plugin:@typescript-eslint/recommended',
  ],
  plugins: [
    'react',
    'react-native',
    'react-hooks',
    '@typescript-eslint',
  ],
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaFeatures: {
      jsx: true,
    },
    ecmaVersion: 2021,
    sourceType: 'module',
  },
  env: {
    'react-native/react-native': true,
    es6: true,
    node: true,
    jest: true,
  },
  rules: {
    // React Native specific rules
    'react-native/no-unused-styles': 'error',
    'react-native/split-platform-components': 'error',
    'react-native/no-inline-styles': 'warn',
    'react-native/no-color-literals': 'warn',
    'react-native/no-raw-text': 'off', // Allow raw text for testing
    
    // React rules
    'react/prop-types': 'off', // Using TypeScript instead
    'react/react-in-jsx-scope': 'off', // Not needed in React Native
    'react-hooks/rules-of-hooks': 'error',
    'react-hooks/exhaustive-deps': 'warn',
    
    // Testing-related rules
    'jest/no-disabled-tests': 'warn',
    'jest/no-focused-tests': 'error',
    'jest/no-identical-title': 'error',
    'jest/prefer-to-have-length': 'warn',
    'jest/valid-expect': 'error',
    
    // General JavaScript rules
    'no-console': 'warn',
    'no-debugger': 'error',
    'no-unused-vars': 'off', // Using TypeScript version
    '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
    
    // Accessibility rules
    'jsx-a11y/accessible-emoji': 'off', // Allow emojis for mobile
  },
  overrides: [
    {
      files: ['**/__tests__/**/*', '**/*.test.*', '**/*.spec.*'],
      env: {
        jest: true,
      },
      rules: {
        // Allow test-specific patterns
        'react-native/no-inline-styles': 'off',
        'no-console': 'off',
      },
    },
  ],
  settings: {
    react: {
      version: 'detect',
    },
  },
};