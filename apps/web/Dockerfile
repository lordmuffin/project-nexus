FROM node:18-alpine

# Create app directory
WORKDIR /app

# Create a non-root user with proper permissions
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

# Create necessary directories with proper ownership
RUN mkdir -p /app/node_modules/.cache && \
    chown -R nextjs:nodejs /app

# Copy package files
COPY package*.json ./

# Install dependencies as root, then fix permissions
RUN npm install --legacy-peer-deps && \
    chown -R nextjs:nodejs /app/node_modules

# Copy source code
COPY . .

# Fix ownership of all files
RUN chown -R nextjs:nodejs /app

# Switch to non-root user
USER nextjs

# Expose port
EXPOSE 3000

# Set environment variables
ENV NODE_ENV=development
ENV CHOKIDAR_USEPOLLING=true
ENV WATCHPACK_POLLING=true

# Start the application
CMD ["npm", "start"]