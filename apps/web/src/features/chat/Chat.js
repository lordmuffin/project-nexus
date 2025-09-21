import React, { useState, useEffect, useRef } from 'react';
import './Chat.css';

const API_BASE = process.env.REACT_APP_API_URL || `http://${window.location.hostname}:3001`;

function Chat() {
  const [messages, setMessages] = useState([]);
  const [inputValue, setInputValue] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [sessionId, setSessionId] = useState(null);
  const [connectionStatus, setConnectionStatus] = useState('disconnected');
  const messagesEndRef = useRef(null);

  // Initialize chat session
  useEffect(() => {
    const initializeSession = async () => {
      try {
        setConnectionStatus('connecting');
        const response = await fetch(`${API_BASE}/api/chat/sessions`);
        const data = await response.json();
        
        if (data.success) {
          setSessionId(data.data.id);
          setConnectionStatus('connected');
          loadMessages(data.data.id);
        }
      } catch (error) {
        console.error('Failed to initialize chat session:', error);
        setConnectionStatus('error');
      }
    };

    initializeSession();
  }, []);

  // Load existing messages
  const loadMessages = async (sessionId) => {
    try {
      const response = await fetch(`${API_BASE}/api/chat/sessions/${sessionId}/messages`);
      const data = await response.json();
      
      if (data.success) {
        setMessages(data.data);
      }
    } catch (error) {
      console.error('Failed to load messages:', error);
    }
  };

  // Send message
  const sendMessage = async () => {
    if (!inputValue.trim() || !sessionId || isLoading) return;

    const userMessage = {
      id: Date.now().toString(),
      role: 'user',
      content: inputValue.trim(),
      created_at: new Date(),
      pending: true
    };

    setMessages(prev => [...prev, userMessage]);
    setInputValue('');
    setIsLoading(true);

    try {
      const response = await fetch(`${API_BASE}/api/chat/sessions/${sessionId}/messages`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          content: inputValue.trim()
        }),
      });

      const data = await response.json();

      if (data.success) {
        // Remove pending user message and add both real messages
        setMessages(prev => [
          ...prev.filter(msg => !msg.pending),
          data.data.userMessage,
          data.data.aiMessage
        ]);
      } else {
        throw new Error(data.error || 'Failed to send message');
      }
    } catch (error) {
      console.error('Error sending message:', error);
      // Show error message
      setMessages(prev => [
        ...prev.filter(msg => !msg.pending),
        {
          id: Date.now().toString(),
          role: 'assistant',
          content: 'Sorry, I encountered an error while processing your message. Please ensure the AI service is running and try again.',
          created_at: new Date(),
          error: true
        }
      ]);
    } finally {
      setIsLoading(false);
    }
  };

  // Handle enter key
  const handleKeyPress = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  };

  // Auto scroll to bottom
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  // Connection status indicator
  const getStatusColor = () => {
    switch (connectionStatus) {
      case 'connected': return 'green';
      case 'connecting': return 'orange';
      case 'error': return 'red';
      default: return 'gray';
    }
  };

  const getStatusText = () => {
    switch (connectionStatus) {
      case 'connected': return 'Connected to Local AI';
      case 'connecting': return 'Connecting...';
      case 'error': return 'Connection Error';
      default: return 'Disconnected';
    }
  };

  return (
    <div className="chat">
      <div className="chat-header">
        <h1>Assistant</h1>
        <div className="connection-status">
          <div 
            className="status-indicator" 
            style={{ backgroundColor: getStatusColor() }}
          ></div>
          <span className="status-text">{getStatusText()}</span>
        </div>
      </div>
      
      <div className="chat-container">
        <div className="chat-messages">
          {messages.length === 0 ? (
            <div className="empty-state">
              <div className="empty-icon">🤖</div>
              <h3>Hello! I'm Nexus</h3>
              <p>I'm your local AI assistant. Your conversations stay private and secure on your device. How can I help you today?</p>
            </div>
          ) : (
            messages.map((message, index) => (
              <div key={message.id || index} className={`message ${message.role} ${message.error ? 'error' : ''}`}>
                <div className="message-avatar">
                  {message.role === 'user' ? '👤' : '🤖'}
                </div>
                <div className="message-content">
                  <div className="message-text">{message.content}</div>
                  <div className="message-time">
                    {new Date(message.created_at).toLocaleTimeString()}
                    {message.metadata?.model && (
                      <span className="model-info"> • {message.metadata.model}</span>
                    )}
                  </div>
                </div>
              </div>
            ))
          )}
          {isLoading && (
            <div className="message assistant loading">
              <div className="message-avatar">🤖</div>
              <div className="message-content">
                <div className="typing-indicator">
                  <span></span>
                  <span></span>
                  <span></span>
                </div>
              </div>
            </div>
          )}
          <div ref={messagesEndRef} />
        </div>
        
        <div className="chat-input">
          <div className="input-container">
            <textarea
              value={inputValue}
              onChange={(e) => setInputValue(e.target.value)}
              onKeyDown={handleKeyPress}
              placeholder="Type your message... (Press Enter to send)"
              className="message-input"
              rows="1"
              disabled={isLoading || connectionStatus !== 'connected'}
            />
            <button 
              onClick={sendMessage}
              className="send-button"
              disabled={!inputValue.trim() || isLoading || connectionStatus !== 'connected'}
            >
              <span>{isLoading ? '...' : 'Send'}</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

export default Chat;