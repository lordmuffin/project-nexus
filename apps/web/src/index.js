import React from 'react';
import ReactDOM from 'react-dom';
import App from './App';
import { registerSW } from './serviceWorkerRegistration';

// Render app using React 17 syntax
ReactDOM.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
  document.getElementById('root')
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