# Dockerfile for Project Nexus Backend
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    curl

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --production --legacy-peer-deps

# Copy source code
COPY src/ ./src/
COPY db/ ./db/

# Create necessary directories
RUN mkdir -p /app/data /app/uploads

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:3001/api/health || exit 1

# Expose port
EXPOSE 3001

# Start the application
CMD ["npm", "start"]