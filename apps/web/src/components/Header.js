import React from 'react';
import { useTheme } from '../lib/theme';
import './Header.css';

function Header() {
  const { theme, toggleTheme } = useTheme();

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