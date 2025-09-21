import { useState, useEffect } from 'react';

const API_BASE = process.env.REACT_APP_API_URL || 'http://localhost:3001';

export function useHealthCheck() {
  const [health, setHealth] = useState({
    backend: { status: 'checking', timestamp: null },
    database: { status: 'checking', timestamp: null },
    ollama: { status: 'checking', timestamp: null }
  });

  const checkHealth = async () => {
    try {
      // Check backend health
      const backendResponse = await fetch(`${API_BASE}/api/health`);
      const backendData = await backendResponse.json();
      
      // Check chat/LLM health
      const ollamaResponse = await fetch(`${API_BASE}/api/chat/health`);
      const ollamaData = await ollamaResponse.json();

      setHealth({
        backend: {
          status: backendResponse.ok ? 'healthy' : 'unhealthy',
          timestamp: new Date().toISOString(),
          data: backendData
        },
        database: {
          status: backendData.services?.database === 'connected' || 
                  (backendData.services?.database?.status === 'connected') ? 'healthy' : 'unhealthy',
          timestamp: backendData.services?.database?.timestamp || backendData.timestamp || new Date().toISOString(),
          data: backendData.services?.database
        },
        ollama: {
          status: ollamaData.success && ollamaData.data?.status === 'healthy' ? 'healthy' : 'unhealthy',
          timestamp: ollamaData.data?.timestamp || new Date().toISOString(),
          data: ollamaData.data
        }
      });
    } catch (error) {
      console.error('Health check failed:', error);
      setHealth(prev => ({
        ...prev,
        backend: {
          status: 'unhealthy',
          timestamp: new Date().toISOString(),
          error: error.message
        }
      }));
    }
  };

  useEffect(() => {
    checkHealth();
    const interval = setInterval(checkHealth, 30000); // Check every 30 seconds
    
    return () => clearInterval(interval);
  }, []);

  return { health, checkHealth };
}