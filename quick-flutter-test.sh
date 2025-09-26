#!/bin/bash
# Quick Flutter Test Script for Nexus App

set -e

echo "🚀 Quick Flutter Test for Nexus App"

# Set proper Java environment
export JAVA_HOME=/home/lordmuffin/Desktop/AndroidStudio/jbr
export PATH=$JAVA_HOME/bin:$PATH

# Navigate to main Flutter app
cd /home/lordmuffin/Claude/Git/project-nexus/apps/nexus_app

echo "📱 Checking Flutter environment..."
flutter doctor --verbose

echo "🧹 Cleaning project..."
flutter clean
rm -rf build/
rm -rf .dart_tool/

echo "📦 Getting dependencies..."
flutter pub get

echo "🔍 Checking for Android v1 embedding issues..."
if grep -q "flutterEmbedding.*2" android/app/src/main/AndroidManifest.xml; then
    echo "✅ Android v2 embedding correctly configured"
else
    echo "❌ Android v2 embedding not found"
    exit 1
fi

if grep -q "FlutterActivity" android/app/src/main/kotlin/*/*/*.kt; then
    echo "✅ MainActivity extends FlutterActivity"
else
    echo "❌ MainActivity doesn't extend FlutterActivity"
    exit 1
fi

echo "🏗️ Testing build process..."
flutter analyze

echo "🎯 Testing basic app structure..."
flutter test --no-sound-null-safety

echo "📱 Creating deployment files..."

# Create simple deployment script
cat > deploy-remote.sh << 'EOF'
#!/bin/bash
# Simple deployment script for remote PC

DEVICE_ID=$1

if [ -z "$DEVICE_ID" ]; then
    echo "Usage: $0 <DEVICE_ID>"
    echo "Example: $0 45301FDAP003JE"
    exit 1
fi

echo "🚀 Deploying to device: $DEVICE_ID"

# Check device
echo "Checking device connection..."
adb devices -l | grep "$DEVICE_ID" || {
    echo "❌ Device $DEVICE_ID not found"
    echo "Available devices:"
    adb devices -l
    exit 1
}

# Set Java environment
export JAVA_HOME=/home/lordmuffin/Desktop/AndroidStudio/jbr
export PATH=$JAVA_HOME/bin:$PATH

# Build and deploy
flutter clean
flutter pub get
flutter run --debug --device-id="$DEVICE_ID"
EOF

chmod +x deploy-remote.sh

echo "✅ Nexus app is ready!"
echo ""
echo "📋 Next steps for remote PC:"
echo "1. git pull origin main"
echo "2. cd apps/nexus_app"
echo "3. ./deploy-remote.sh 45301FDAP003JE"
echo ""
echo "🔧 If you get v1 embedding error:"
echo "- Make sure you're in the apps/nexus_app directory"
echo "- Run: flutter clean && flutter pub get"
echo "- Check Java version: java -version"
echo "- Set JAVA_HOME: export JAVA_HOME=/path/to/android-studio/jbr"