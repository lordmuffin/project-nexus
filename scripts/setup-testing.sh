#!/bin/bash
set -e

echo "🧪 Setting up Project Nexus Testing Environment"

# Navigate to mobile app directory
cd apps/mobile

echo "📱 Installing mobile app dependencies..."
npm install

echo "✅ Mobile dependencies installed"

# Navigate back to project root
cd ../..

echo "🐳 Building Docker test containers..."
docker-compose -f docker-compose.test.yml build

echo "🚀 Running mobile app tests..."
docker-compose -f docker-compose.test.yml up --abort-on-container-exit test-mobile

echo "🧹 Cleaning up containers..."
docker-compose -f docker-compose.test.yml down

echo "✅ Testing setup complete!"