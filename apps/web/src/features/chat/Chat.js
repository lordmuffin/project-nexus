import React from 'react';
import './Chat.css';

function Chat() {
  return (
    <div className="chat">
      <div className="chat-header">
        <h1>Chat</h1>
      </div>
      
      <div className="chat-container">
        <div className="chat-messages">
          <div className="empty-state">
            <div className="empty-icon">💬</div>
            <h3>Start a conversation</h3>
            <p>Send your first message to begin chatting with AI assistance.</p>
          </div>
        </div>
        
        <div className="chat-input">
          <div className="input-container">
            <input 
              type="text" 
              placeholder="Type your message..."
              className="message-input"
            />
            <button className="send-button">
              <span>Send</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

export default Chat;