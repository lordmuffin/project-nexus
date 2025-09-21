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
        timeout: 120000 // 2 minute timeout for slow systems
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

  async generateCompletion(options = {}) {
    const { 
      prompt, 
      model = this.defaultModel, 
      temperature = 0.7, 
      maxTokens = 1000,
      stream = false 
    } = options;

    try {
      const response = await axios.post(`${this.baseUrl}/api/generate`, {
        model: model,
        prompt: prompt,
        stream: stream,
        options: {
          temperature: temperature,
          num_predict: maxTokens
        }
      });

      return response.data.response || '';
    } catch (error) {
      console.error('Failed to generate completion:', error.message);
      throw new Error(`Completion generation failed: ${error.message}`);
    }
  }

  async generateResponse(userMessage, conversationHistory = []) {
    try {
      // Check if Ollama is responsive first
      try {
        await axios.get(`${this.baseUrl}/api/version`, { timeout: 5000 });
      } catch (error) {
        return {
          content: "I'm sorry, but the AI service is currently unavailable. The local Ollama service is not responding. This could be due to high system load or the service being offline.",
          model: "error",
          error: true
        };
      }

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
      
      // Provide specific error messages based on the type of error
      let errorMessage = 'I apologize, but I\'m having trouble processing your request right now.';
      
      if (error.code === 'ECONNREFUSED') {
        errorMessage = 'The AI service (Ollama) is not available. Please ensure it is running.';
      } else if (error.code === 'ETIMEDOUT' || error.message.includes('timeout')) {
        errorMessage = 'The AI is taking longer than usual to respond. This system may be running slowly. Please try a simpler question or wait for the system to catch up.';
      } else if (error.message.includes('model')) {
        errorMessage = 'There\'s an issue with the AI model. Please check that Llama 3.2:1b is properly loaded.';
      }
      
      return {
        content: `${errorMessage}\n\nTechnical details: ${error.message}`,
        model: 'error',
        error: true,
        timestamp: new Date().toISOString()
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