// Debug script to check Jest configuration
const path = require('path');

console.log('🔍 Debugging Jest Configuration');
console.log('Current directory:', process.cwd());
console.log('Node version:', process.version);

// Check if jest config exists
const jestConfigPath = path.join(process.cwd(), 'jest.config.js');
const packageJsonPath = path.join(process.cwd(), 'package.json');

try {
  const fs = require('fs');
  console.log('✅ jest.config.js exists:', fs.existsSync(jestConfigPath));
  console.log('✅ package.json exists:', fs.existsSync(packageJsonPath));
  
  if (fs.existsSync(jestConfigPath)) {
    console.log('📄 Loading jest.config.js...');
    const config = require(jestConfigPath);
    console.log('✅ Jest config loaded successfully');
    console.log('Preset:', config.preset);
  }
  
  console.log('📦 Checking installed packages...');
  const packageJson = require(packageJsonPath);
  const devDeps = packageJson.devDependencies || {};
  
  console.log('jest-expo version:', devDeps['jest-expo'] || 'NOT INSTALLED');
  console.log('jest version:', devDeps['jest'] || 'NOT INSTALLED');
  
} catch (error) {
  console.error('❌ Error loading configuration:', error.message);
}

console.log('🏁 Debug complete');