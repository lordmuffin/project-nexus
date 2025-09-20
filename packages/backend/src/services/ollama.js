const axios = require('axios');

class OllamaService {
  constructor() {
    this.baseUrl = process.env.OLLAMA_URL || 'http://localhost:11434';
    this.defaultModel = 'llama3.2:1b'; // Small, fast model for demos
    this.models = new Map(); // Cache for available models
  }

  async initialize() {
    try {
      // Check if Ollama is available
      await this.getVersion();
      
      // Try to pull the default model if it doesn't exist
      const models = await this.listModels();
      const hasDefaultModel = models.some(model => model.name === this.defaultModel);
      
      if (!hasDefaultModel) {
        console.log(`🔄 Pulling model ${this.defaultModel}...`);
        await this.pullModel(this.defaultModel);
      }
      
      console.log('✅ Ollama service initialized successfully');
    } catch (error) {
      console.error('❌ Ollama initialization failed:', error.message);
      // Don't throw error - let the app continue without LLM for now
    }
  }

  async getVersion() {
    try {
      const response = await axios.get(`${this.baseUrl}/api/version`);
      return response.data;
    } catch (error) {
      throw new Error(`Failed to connect to Ollama: ${error.message}`);
    }
  }

  async listModels() {
    try {
      const response = await axios.get(`${this.baseUrl}/api/tags`);
      return response.data.models || [];
    } catch (error) {
      console.error('Failed to list models:', error.message);
      return [];
    }
  }

  async pullModel(modelName) {
    try {
      const response = await axios.post(`${this.baseUrl}/api/pull`, {
        name: modelName
      });
      return response.data;
    } catch (error) {
      throw new Error(`Failed to pull model ${modelName}: ${error.message}`);
    }
  }

  async chat(messages, options = {}) {
    try {
      const payload = {
        model: options.model || this.defaultModel,
        messages: messages,
        stream: false,
        options: {
          temperature: options.temperature || 0.7,
          top_p: options.top_p || 0.9,
          max_tokens: options.max_tokens || 1000,
          ...options.modelOptions
        }
      };

      const response = await axios.post(`${this.baseUrl}/api/chat`, payload, {
        timeout: 30000 // 30 second timeout
      });

      return {
        content: response.data.message?.content || '',
        model: response.data.model,
        created_at: response.data.created_at,
        done: response.data.done,
        total_duration: response.data.total_duration,
        load_duration: response.data.load_duration,
        prompt_eval_count: response.data.prompt_eval_count,
        eval_count: response.data.eval_count
      };
    } catch (error) {
      if (error.code === 'ECONNREFUSED') {
        throw new Error('Ollama service is not available. Please ensure it is running.');
      }
      throw new Error(`Chat request failed: ${error.message}`);
    }
  }

  async generateResponse(userMessage, conversationHistory = []) {
    try {
      // Format conversation for Ollama
      const messages = [
        {
          role: 'system',
          content: 'You are Nexus, a helpful AI assistant focused on productivity and privacy. You run entirely locally to protect user privacy. Be concise but helpful.'
        },
        ...conversationHistory.map(msg => ({
          role: msg.role,
          content: msg.content
        })),
        {
          role: 'user',
          content: userMessage
        }
      ];

      const response = await this.chat(messages);
      return response;
    } catch (error) {
      console.error('Failed to generate response:', error.message);
      return {
        content: 'I apologize, but I\'m having trouble connecting to the AI service right now. Please ensure Ollama is running and try again.',
        model: 'error',
        error: true
      };
    }
  }

  async healthCheck() {
    try {
      const version = await this.getVersion();
      const models = await this.listModels();
      
      return {
        status: 'healthy',
        version: version.version,
        models: models.length,
        defaultModel: this.defaultModel,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      return {
        status: 'unhealthy',
        error: error.message,
        timestamp: new Date().toISOString()
      };
    }
  }
}

// Create singleton instance
const ollamaService = new OllamaService();

module.exports = ollamaService;