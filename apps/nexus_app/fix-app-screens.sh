#!/bin/bash

echo "🔧 Nexus App Screen Fix Script"
echo "=============================="

echo "📋 Step 1: Cleaning project..."
flutter clean

echo "📦 Step 2: Getting dependencies..."
flutter pub get

echo "🔧 Step 3: Generating database code..."
dart run build_runner build --delete-conflicting-outputs

echo "🔍 Step 4: Analyzing code..."
flutter analyze --no-fatal-infos lib/ | head -20

echo "✅ App fix complete!"
echo ""
echo "🚀 To run the app:"
echo "   flutter run -d <device-id>"
echo ""
echo "📱 To build APK:"
echo "   flutter build apk --debug"
echo ""
echo "🔍 Check console output for screen initialization messages:"
echo "   - 💬 ChatScreen initializing..."
echo "   - 🎤 MeetingsScreen initializing..."
echo "   - 📝 NotesScreen initializing..."
echo "   - ⚙️ SettingsScreen initializing..."