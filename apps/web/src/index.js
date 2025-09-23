import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';
import { ThemeProvider } from './lib/theme';
import { registerSW } from './serviceWorkerRegistration';

// Render app using React 18 syntax
const container = document.getElementById('root');
const root = createRoot(container);
root.render(
  <React.StrictMode>
    <ThemeProvider>
      <App />
    </ThemeProvider>
  </React.StrictMode>
);

// Register service worker for PWA capabilities
registerSW({
  onSuccess: (registration) => {
    console.log('SW registered: ', registration);
  },
  onUpdate: (registration) => {
    console.log('SW updated: ', registration);
    // Show update available notification
    if (window.confirm('A new version is available. Reload to update?')) {
      window.location.reload();
    }
  },
  onOffline: () => {
    console.log('No internet connection found. App is running in offline mode.');
  },
  onError: (error) => {
    console.error('SW registration failed: ', error);
  }
});