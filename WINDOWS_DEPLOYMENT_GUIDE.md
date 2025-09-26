# Windows Flutter Deployment Guide

## 🪟 Windows-Specific Instructions

This guide provides Windows PowerShell versions of all deployment scripts for testing the Flutter app on Windows with the Pixel 9 Pro device.

## ✅ Quick Start (Windows)

### For Windows Remote PC Testing

1. **Open PowerShell as Administrator** (recommended for first-time setup)

2. **Allow PowerShell script execution** (one-time setup):
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

3. **Navigate to project directory**:
   ```powershell
   cd C:\path\to\project-nexus
   ```

4. **Pull latest changes**:
   ```powershell
   git pull origin main
   ```

5. **Validate environment**:
   ```powershell
   .\validate-flutter-setup.ps1
   ```

6. **Deploy to device**:
   ```powershell
   cd apps\nexus_app
   .\deploy-remote.ps1 45301FDAP003JE
   ```

## 🔧 Windows Environment Setup

### Prerequisites
1. **Flutter SDK** - Download from [flutter.dev](https://flutter.dev/docs/get-started/install/windows)
2. **Android Studio** - Download from [developer.android.com](https://developer.android.com/studio)
3. **Git for Windows** - Download from [git-scm.com](https://git-scm.com/download/win)
4. **PowerShell 5.0+** (usually pre-installed on Windows 10/11)

### Environment Variables (Windows)
Set these in System Properties > Environment Variables:

1. **Flutter Path**:
   - Variable: `PATH`
   - Add: `C:\flutter\bin` (or your Flutter installation path)

2. **Android SDK Path**:
   - Variable: `ANDROID_HOME`
   - Value: `%LOCALAPPDATA%\Android\Sdk`

3. **Java Path** (if needed):
   - Variable: `JAVA_HOME`
   - Value: `%LOCALAPPDATA%\Android\Android Studio\jbr`

### Verify Setup:
```powershell
flutter doctor -v
adb devices
java -version
```

## 📱 Device Connection (Windows)

### Enable USB Debugging:
1. **Settings** > **About phone** > Tap **Build number** 7 times
2. **Settings** > **Developer options** > Enable **USB debugging**
3. Connect device via USB cable
4. Allow USB debugging when prompted on device

### Verify Device Connection:
```powershell
adb devices -l
# Should show: 45301FDAP003JE device product:caiman model:Pixel_9_Pro
```

### If Device Not Detected:
```powershell
# Install/update device drivers
adb kill-server
adb start-server
adb devices -l

# Check Windows Device Manager for any unknown devices
# Install Google USB Driver if needed
```

## 🚀 PowerShell Scripts

### Validation Script (`validate-flutter-setup.ps1`)
Checks 8 critical configuration points:
- ✅ Flutter installation
- ✅ Java environment
- ✅ Android SDK
- ✅ ADB availability
- ✅ Flutter project structure
- ✅ Android v2 embedding
- ✅ MainActivity configuration
- ✅ Deployment scripts

### Deployment Script (`deploy-remote.ps1`)
Automated deployment with error handling:
- ✅ Environment validation
- ✅ Device connection check
- ✅ Project cleaning
- ✅ Dependency management
- ✅ Build and deployment
- ✅ Comprehensive error reporting

## 🐛 Windows-Specific Troubleshooting

### PowerShell Execution Policy Error
```powershell
# Error: "execution of scripts is disabled on this system"
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Flutter Command Not Found
```powershell
# Add Flutter to PATH permanently
$env:PATH += ";C:\flutter\bin"
# Or set via System Properties > Environment Variables
```

### ADB Not Found
```powershell
# Add Android SDK platform-tools to PATH
$env:PATH += ";%LOCALAPPDATA%\Android\Sdk\platform-tools"
```

### Java Version Issues
```powershell
# Use Android Studio JDK
$env:JAVA_HOME = "$env:LOCALAPPDATA\Android\Android Studio\jbr"
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
```

### Device Not Detected
1. **Install Google USB Driver**:
   - Android Studio > SDK Manager > Extras > Google USB Driver
2. **Update Windows drivers**:
   - Device Manager > Update driver for unknown device
3. **Try different USB cable/port**
4. **Disable Windows Defender real-time protection** (temporarily)

### Antivirus Interference
```powershell
# Add exclusions to Windows Defender:
# - Flutter SDK directory
# - Android SDK directory
# - Project directory
# - Temporary build directories
```

## 📂 Windows Paths

### Standard Installation Paths:
- **Flutter**: `C:\flutter\`
- **Android Studio**: `C:\Program Files\Android\Android Studio\`
- **Android SDK**: `%LOCALAPPDATA%\Android\Sdk\`
- **Java (Android Studio)**: `%LOCALAPPDATA%\Android\Android Studio\jbr\`

### Project Structure (Windows):
```
project-nexus\
├── apps\nexus_app\              ← Main Flutter app
│   ├── deploy-remote.ps1        ← Windows deployment script
│   └── pubspec.yaml
├── validate-flutter-setup.ps1   ← Windows validation script
└── WINDOWS_DEPLOYMENT_GUIDE.md  ← This guide
```

## 🔄 Git Workflow (Windows)

### Development Workflow:
```powershell
# Create feature branch
git checkout -b feature/my-feature

# Make changes in apps\nexus_app\
# Test locally
.\validate-flutter-setup.ps1

# Commit and push
git add .
git commit -m "Add feature"
git push origin feature/my-feature
```

### Remote Testing:
```powershell
# Pull changes
git pull origin feature/my-feature

# Deploy to device
cd apps\nexus_app
.\deploy-remote.ps1 45301FDAP003JE
```

## ⚡ Quick Commands (Windows)

### Environment Check:
```powershell
flutter doctor -v
adb devices -l
java -version
```

### Clean and Build:
```powershell
cd apps\nexus_app
flutter clean
flutter pub get
flutter analyze
```

### Deploy:
```powershell
.\deploy-remote.ps1 45301FDAP003JE
```

### Reset Everything:
```powershell
flutter clean
Remove-Item -Recurse -Force build, .dart_tool -ErrorAction SilentlyContinue
flutter pub get
```

## 🆘 Emergency Recovery (Windows)

If deployment fails completely:

1. **Verify directory**:
   ```powershell
   Get-Location  # Should be in apps\nexus_app
   Get-Content pubspec.yaml | Select-String "name: nexus_app"
   ```

2. **Check Java environment**:
   ```powershell
   $env:JAVA_HOME = "$env:LOCALAPPDATA\Android\Android Studio\jbr"
   java -version
   ```

3. **Verify device**:
   ```powershell
   adb devices -l
   adb shell getprop ro.product.model  # Should show "Pixel 9 Pro"
   ```

4. **Complete reset**:
   ```powershell
   flutter clean
   flutter pub cache repair
   flutter pub get
   .\deploy-remote.ps1 45301FDAP003JE
   ```

## ✅ Windows Deployment Checklist

- [ ] PowerShell execution policy set
- [ ] Flutter SDK installed and in PATH
- [ ] Android Studio installed
- [ ] Android SDK configured
- [ ] Device drivers installed
- [ ] USB debugging enabled on device
- [ ] Device connected and authorized
- [ ] In correct directory (`apps\nexus_app`)
- [ ] Environment validated with script
- [ ] Java environment properly configured

## 🎯 Success Indicators

When everything works correctly, you should see:
- ✅ `.\validate-flutter-setup.ps1` passes 7-8 checks
- ✅ `adb devices -l` shows your Pixel 9 Pro
- ✅ `.\deploy-remote.ps1 45301FDAP003JE` builds and deploys successfully
- ✅ App launches on device with hot reload capability