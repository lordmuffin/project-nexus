# Flutter Deployment Guide

## Issue Resolution: Android v1 Embedding Error

The "Build failed due to use of deleted Android v1 embedding" error occurs when:
1. Running Flutter from the wrong directory
2. Using cached build artifacts from old Flutter versions
3. Java/Gradle version mismatches

## ✅ Solution

### 1. Verified Project Status
All Flutter projects in this repository use **Android v2 embedding correctly**:
- ✅ `apps/nexus_app/` - Main production app (RECOMMENDED)
- ✅ `flutter/nexus_app/` - Development version
- ✅ `flutter/flutter_application_1/` - Template app

### 2. Root Cause
The error likely occurs because:
- **Running from wrong directory**: Must run from Flutter project directory, not root
- **Cached artifacts**: Old build files from previous Flutter versions
- **Java version**: System Java vs Android Studio JDK mismatch

## 🚀 Deployment Instructions

### For Local Development Machine

1. **Navigate to correct directory**:
   ```bash
   cd /home/lordmuffin/Claude/Git/project-nexus/apps/nexus_app
   ```

2. **Clean everything**:
   ```bash
   flutter clean
   rm -rf build/ .dart_tool/
   ```

3. **Set proper Java environment**:
   ```bash
   export JAVA_HOME=/home/lordmuffin/Desktop/AndroidStudio/jbr
   export PATH=$JAVA_HOME/bin:$PATH
   flutter config --jdk-dir=/home/lordmuffin/Desktop/AndroidStudio/jbr
   ```

4. **Get dependencies and test**:
   ```bash
   flutter pub get
   flutter analyze
   ```

### For Remote PC Testing

1. **Pull latest changes**:
   ```bash
   git pull origin main
   cd apps/nexus_app
   ```

2. **Use the deployment script**:
   ```bash
   ./deploy-remote.sh 45301FDAP003JE
   ```

## 📱 Device Connection Troubleshooting

### If device not found:
1. **Enable Developer Options** on Android device
2. **Enable USB Debugging** in Developer Options
3. **Connect device** and allow USB debugging
4. **Verify connection**:
   ```bash
   adb devices -l
   ```
5. **If still not found**:
   ```bash
   adb kill-server
   adb start-server
   adb devices -l
   ```

### Check device ID:
```bash
adb devices -l
# Look for your device ID (e.g., 45301FDAP003JE)
```

## 🔧 Build Environment Setup

### Required Java Version
- Use Android Studio JDK (OpenJDK 21)
- NOT system Java (OpenJDK 24)

### Set Java Environment (Important!):
```bash
export JAVA_HOME=/path/to/android-studio/jbr
export PATH=$JAVA_HOME/bin:$PATH
flutter config --jdk-dir="/path/to/android-studio/jbr"
```

### Verify Setup:
```bash
flutter doctor -v
java -version  # Should show OpenJDK 21
```

## 📂 Project Structure

```
project-nexus/
├── apps/nexus_app/          ← MAIN APP (use this)
├── flutter/nexus_app/       ← Development version
└── flutter/flutter_application_1/  ← Template
```

**Always use `apps/nexus_app/` for production deployment!**

## 🐛 Common Issues & Solutions

### "v1 embedding" error:
- ✅ **Solution**: Make sure you're in `apps/nexus_app/` directory
- ❌ **Don't run**: `flutter run` from project root

### "Unsupported class file major version":
- ✅ **Solution**: Set proper JAVA_HOME to Android Studio JDK
- ❌ **Problem**: Using system Java instead of Android Studio JDK

### "Device not found":
- ✅ **Solution**: Enable USB debugging, check `adb devices`
- ❌ **Problem**: Device not in developer mode

### Gradle errors:
- ✅ **Solution**: `flutter clean && flutter pub get`
- ✅ **Alternative**: Delete `build/` and `.dart_tool/` directories

## 🔄 Git Workflow for Cross-Environment

### Development Workflow:
1. **Local development**:
   ```bash
   git checkout -b feature/my-feature
   # Make changes in apps/nexus_app/
   flutter test
   git commit -am "Add feature"
   git push origin feature/my-feature
   ```

2. **Remote testing**:
   ```bash
   git pull origin feature/my-feature
   cd apps/nexus_app
   ./deploy-remote.sh 45301FDAP003JE
   ```

3. **Merge when ready**:
   ```bash
   git checkout main
   git merge feature/my-feature
   git push origin main
   ```

## ⚡ Quick Commands

### Local testing:
```bash
cd apps/nexus_app
flutter clean && flutter pub get
flutter analyze
flutter test
```

### Remote deployment:
```bash
cd apps/nexus_app
./deploy-remote.sh 45301FDAP003JE
```

### Reset everything:
```bash
cd apps/nexus_app
flutter clean
rm -rf build/ .dart_tool/
flutter pub get
```

## 📞 Emergency Recovery

If nothing works:
1. Check you're in `apps/nexus_app/` directory
2. Set Java environment variables
3. Run `flutter clean && flutter pub get`
4. Verify device with `adb devices -l`
5. Try `flutter run --verbose` for detailed logs

## ✅ Verification Checklist

- [ ] In correct directory (`apps/nexus_app/`)
- [ ] Java environment set (Android Studio JDK)
- [ ] Device connected and authorized
- [ ] `flutter doctor` shows no critical issues
- [ ] `adb devices` shows your device
- [ ] `flutter clean && flutter pub get` completed