import React from 'react';
import { NavLink } from 'react-router-dom';
import './Sidebar.css';

const navigation = [
  { name: 'Dashboard', href: '/', icon: '📊' },
  { name: 'Meetings', href: '/meetings', icon: '🎯' },
  { name: 'Chat', href: '/chat', icon: '💬' },
  { name: 'Settings', href: '/settings', icon: '⚙️' },
];

function Sidebar() {
  return (
    <aside className="sidebar">
      <nav className="sidebar-nav">
        <ul className="nav-list">
          {navigation.map((item) => (
            <li key={item.name}>
              <NavLink
                to={item.href}
                className={({ isActive }) => 
                  `nav-item ${isActive ? 'active' : ''}`
                }
              >
                <span className="nav-icon">{item.icon}</span>
                <span className="nav-text">{item.name}</span>
              </NavLink>
            </li>
          ))}
        </ul>
      </nav>
      
      <div className="sidebar-footer">
        <button className="recording-button">
          <span className="recording-icon">🎤</span>
          <span className="recording-text">Start Recording</span>
        </button>
      </div>
    </aside>
  );
}

export default Sidebar;