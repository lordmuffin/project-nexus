import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Header from './components/Header';
import Sidebar from './components/Sidebar';
import Dashboard from './features/dashboard/Dashboard';
import Chat from './features/chat/Chat';
import Notes from './features/notes/Notes';
import Meetings from './features/meetings/Meetings';
import Settings from './features/settings/Settings';
import './App.css';

function App() {
  return (
<<<<<<< Updated upstream
    <ThemeProvider>
      <NotificationProvider>
        <Router
          future={{
            v7_startTransition: true,
            v7_relativeSplatPath: true
          }}
        >
          <div className="app">
            <Header />
            <div className="app-body">
              <Sidebar />
              <main className="main-content">
                <Routes>
                  <Route path="/" element={<Dashboard />} />
                  <Route path="/chat" element={<Chat />} />
                  <Route path="/notes" element={<Notes />} />
                  <Route path="/meetings" element={<Meetings />} />
                  <Route path="/settings" element={<Settings />} />
                </Routes>
              </main>
            </div>
          </div>
        </Router>
      </NotificationProvider>
    </ThemeProvider>
=======
    <Router>
      <div className="app">
        <Header />
        <div className="app-body">
          <Sidebar />
          <main className="main-content">
            <Routes>
              <Route path="/" element={<Dashboard />} />
              <Route path="/chat" element={<Chat />} />
              <Route path="/notes" element={<Notes />} />
              <Route path="/meetings" element={<Meetings />} />
              <Route path="/settings" element={<Settings />} />
            </Routes>
          </main>
        </div>
      </div>
    </Router>
>>>>>>> Stashed changes
  );
}

export default App;