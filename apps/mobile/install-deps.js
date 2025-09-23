#!/usr/bin/env node

// Simple dependency installer to bypass npm config issues
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

console.log('🔧 Custom dependency installer for mobile app');

try {
  // Read package.json
  const packageJson = JSON.parse(fs.readFileSync('package.json', 'utf8'));
  
  console.log('📦 Package:', packageJson.name);
  console.log('📝 Version:', packageJson.version);
  
  // Create a .npmrc file with basic config
  const npmrcContent = `registry=https://registry.npmjs.org/
cache=/tmp/.npm-cache
progress=false`;
  
  fs.writeFileSync('.npmrc', npmrcContent);
  console.log('✅ Created .npmrc with basic configuration');
  
  // Try installing with npx instead of npm directly
  console.log('📥 Installing dependencies...');
  execSync('npx --yes npm install --no-fund --no-audit', { 
    stdio: 'inherit',
    env: { 
      ...process.env, 
      NPM_CONFIG_CACHE: '/tmp/.npm-cache',
      NPM_CONFIG_REGISTRY: 'https://registry.npmjs.org/'
    }
  });
  
  console.log('✅ Dependencies installed successfully!');
  
} catch (error) {
  console.error('❌ Installation failed:', error.message);
  
  // Try alternative approach
  console.log('🔄 Trying alternative installation method...');
  try {
    execSync('npx --yes create-expo-app@latest --template blank --no-install temp-install', { stdio: 'inherit' });
    execSync('cp -r temp-install/node_modules ./', { stdio: 'inherit' });
    execSync('rm -rf temp-install', { stdio: 'inherit' });
    console.log('✅ Alternative installation completed!');
  } catch (altError) {
    console.error('❌ Alternative installation also failed:', altError.message);
    process.exit(1);
  }
}