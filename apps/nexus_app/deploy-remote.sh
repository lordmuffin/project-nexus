#!/bin/bash
# Flutter Remote Deployment Script for Nexus App
# Usage: ./deploy-remote.sh <DEVICE_ID>
# Example: ./deploy-remote.sh 45301FDAP003JE

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Device ID from command line
DEVICE_ID="$1"

if [ -z "$DEVICE_ID" ]; then
    echo -e "${RED}❌ Error: Device ID required${NC}"
    echo "Usage: $0 <DEVICE_ID>"
    echo "Example: $0 45301FDAP003JE"
    echo ""
    echo "To find your device ID:"
    echo "  adb devices -l"
    exit 1
fi

echo -e "${BLUE}🚀 Flutter Nexus App Deployment${NC}"
echo -e "${BLUE}Device: $DEVICE_ID${NC}"
echo ""

# Function to print status
print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Step 1: Check environment
print_step "1. Checking environment..."

# Set proper Java environment for Android builds
export JAVA_HOME=/home/lordmuffin/Desktop/AndroidStudio/jbr
export PATH=$JAVA_HOME/bin:$PATH

# Verify we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "Not in a Flutter project directory!"
    echo "Make sure you're in the apps/nexus_app/ directory"
    exit 1
fi

# Check if this is the nexus_app
if ! grep -q "name: nexus_app" pubspec.yaml; then
    print_error "This doesn't appear to be the nexus_app project"
    echo "Make sure you're in the apps/nexus_app/ directory"
    exit 1
fi

print_success "✅ Environment OK - In nexus_app directory"

# Step 2: Check device connection
print_step "2. Checking device connection..."

if ! command -v adb &> /dev/null; then
    print_error "ADB not found! Make sure Android SDK is installed"
    exit 1
fi

# Check if device is connected
if ! adb devices -l | grep -q "$DEVICE_ID"; then
    print_error "Device $DEVICE_ID not found!"
    echo ""
    echo "Available devices:"
    adb devices -l
    echo ""
    echo "Troubleshooting:"
    echo "1. Enable USB Debugging on your Android device"
    echo "2. Connect device via USB"
    echo "3. Allow USB debugging when prompted"
    echo "4. Try: adb kill-server && adb start-server"
    exit 1
fi

print_success "✅ Device $DEVICE_ID connected"

# Step 3: Check Flutter environment
print_step "3. Checking Flutter environment..."

# Configure Flutter to use correct JDK
flutter config --jdk-dir="$JAVA_HOME" > /dev/null 2>&1

# Quick Flutter doctor check
if ! flutter doctor --quiet; then
    print_warning "⚠️  Flutter doctor found some issues, but continuing..."
fi

print_success "✅ Flutter environment configured"

# Step 4: Clean and prepare
print_step "4. Cleaning project..."

flutter clean > /dev/null
rm -rf build/ .dart_tool/ 2>/dev/null || true

print_success "✅ Project cleaned"

# Step 5: Get dependencies
print_step "5. Getting dependencies..."

if ! flutter pub get; then
    print_error "Failed to get dependencies"
    exit 1
fi

print_success "✅ Dependencies updated"

# Step 6: Verify project structure
print_step "6. Verifying project configuration..."

# Check for Android v2 embedding
if grep -q "flutterEmbedding" android/app/src/main/AndroidManifest.xml && \
   grep -q "android:value=\"2\"" android/app/src/main/AndroidManifest.xml; then
    print_success "✅ Android v2 embedding configured"
else
    print_error "Android v2 embedding not properly configured"
    exit 1
fi

# Check MainActivity
if find android/app/src/main/kotlin -name "*.kt" -exec grep -l "FlutterActivity" {} \; | head -1 > /dev/null; then
    print_success "✅ MainActivity extends FlutterActivity"
else
    print_error "MainActivity configuration issue"
    exit 1
fi

# Step 7: Build and deploy
print_step "7. Building and deploying to device..."

echo -e "${YELLOW}This may take a few minutes...${NC}"

# Build and run with detailed output
if flutter run --debug --device-id="$DEVICE_ID" --verbose; then
    print_success "🎉 Deployment successful!"
    echo ""
    echo -e "${GREEN}App is now running on device $DEVICE_ID${NC}"
    echo "Press 'r' to hot reload, 'R' to hot restart, 'q' to quit"
else
    print_error "Deployment failed"
    echo ""
    echo "Common solutions:"
    echo "1. Check device is unlocked and USB debugging allowed"
    echo "2. Try: flutter clean && flutter pub get"
    echo "3. Restart ADB: adb kill-server && adb start-server"
    echo "4. Check Java version: java -version (should be OpenJDK 21)"
    exit 1
fi