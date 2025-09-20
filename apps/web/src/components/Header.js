import React, { useState, useEffect } from 'react';
import { useTheme } from '../lib/theme';
import './Header.css';

function Header() {
  const { theme, toggleTheme } = useTheme();
  const [showInstallPrompt, setShowInstallPrompt] = useState(false);

  useEffect(() => {
    // Check if app is already installed
    if (window.matchMedia('(display-mode: standalone)').matches || window.navigator.standalone) {
      setShowInstallPrompt(false);
      return;
    }

    // Listen for beforeinstallprompt event
    const handleBeforeInstallPrompt = (e) => {
      e.preventDefault();
      setShowInstallPrompt(true);
      
      window.deferredPrompt = e;
    };

    window.addEventListener('beforeinstallprompt', handleBeforeInstallPrompt);

    return () => {
      window.removeEventListener('beforeinstallprompt', handleBeforeInstallPrompt);
    };
  }, []);

  const handleInstallClick = async () => {
    if (!window.deferredPrompt) return;

    window.deferredPrompt.prompt();
    const { outcome } = await window.deferredPrompt.userChoice;
    
    if (outcome === 'accepted') {
      console.log('User accepted the install prompt');
    }
    
    window.deferredPrompt = null;
    setShowInstallPrompt(false);
  };

  return (
    <header className="header">
      <div className="header-content">
        <div className="header-left">
          <h1 className="logo">Project Nexus</h1>
        </div>
        
        <div className="header-center">
          <div className="connection-status">
            <span className="status-indicator online"></span>
            <span className="status-text">Connected</span>
          </div>
        </div>
        
        <div className="header-right">
          {showInstallPrompt && (
            <button 
              className="install-button"
              onClick={handleInstallClick}
              title="Install Nexus as a desktop app"
            >
              📱 Install
            </button>
          )}
          
          <button 
            className="theme-toggle"
            onClick={toggleTheme}
            aria-label={`Switch to ${theme === 'light' ? 'dark' : 'light'} theme`}
          >
            {theme === 'light' ? '🌙' : '☀️'}
          </button>
          
          <div className="user-menu">
            <button className="user-avatar">
              <span>U</span>
            </button>
          </div>
        </div>
      </div>
    </header>
  );
}

export default Header;