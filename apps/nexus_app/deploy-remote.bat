@echo off
REM Flutter Remote Deployment Script for Nexus App (Windows Batch)
REM Usage: deploy-remote.bat <DEVICE_ID>
REM Example: deploy-remote.bat 45301FDAP003JE

setlocal EnableDelayedExpansion

if "%1"=="" (
    echo [ERROR] Device ID required
    echo Usage: %0 ^<DEVICE_ID^>
    echo Example: %0 45301FDAP003JE
    echo.
    echo To find your device ID:
    echo   adb devices -l
    exit /b 1
)

set DEVICE_ID=%1

echo [INFO] Flutter Nexus App Deployment ^(Windows^)
echo [INFO] Device: %DEVICE_ID%
echo.

REM Step 1: Set Java environment
echo [STEP] 1. Setting up environment...

REM Try different Android Studio JDK locations
set "ANDROID_STUDIO_JDK=%LOCALAPPDATA%\Android\Android Studio\jbr"
if not exist "%ANDROID_STUDIO_JDK%" (
    set "ANDROID_STUDIO_JDK=%ProgramFiles%\Android\Android Studio\jbr"
)
if not exist "%ANDROID_STUDIO_JDK%" (
    set "ANDROID_STUDIO_JDK=%ProgramFiles(x86)%\Android\Android Studio\jbr"
)

if exist "%ANDROID_STUDIO_JDK%" (
    set "JAVA_HOME=%ANDROID_STUDIO_JDK%"
    set "PATH=%ANDROID_STUDIO_JDK%\bin;%PATH%"
    echo [SUCCESS] Java environment set to Android Studio JDK
) else (
    echo [WARNING] Android Studio JDK not found in standard locations
    echo Please set JAVA_HOME manually to your Android Studio JDK path
)

REM Check if we're in the right directory
if not exist "pubspec.yaml" (
    echo [ERROR] Not in a Flutter project directory!
    echo Make sure you're in the apps\nexus_app\ directory
    exit /b 1
)

REM Check if this is nexus_app
findstr /C:"name: nexus_app" pubspec.yaml >nul
if errorlevel 1 (
    echo [ERROR] This doesn't appear to be the nexus_app project
    echo Make sure you're in the apps\nexus_app\ directory
    exit /b 1
)

echo [SUCCESS] Environment OK - In nexus_app directory

REM Step 2: Check device connection
echo [STEP] 2. Checking device connection...

where adb >nul 2>&1
if errorlevel 1 (
    echo [ERROR] ADB not found! Make sure Android SDK is installed and in PATH
    exit /b 1
)

adb devices -l | findstr "%DEVICE_ID%" >nul
if errorlevel 1 (
    echo [ERROR] Device %DEVICE_ID% not found!
    echo.
    echo Available devices:
    adb devices -l
    echo.
    echo Troubleshooting:
    echo 1. Enable USB Debugging on your Android device
    echo 2. Connect device via USB
    echo 3. Allow USB debugging when prompted
    echo 4. Try: adb kill-server ^&^& adb start-server
    exit /b 1
)

echo [SUCCESS] Device %DEVICE_ID% connected

REM Step 3: Check Flutter
echo [STEP] 3. Checking Flutter environment...

where flutter >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Flutter not found! Make sure Flutter SDK is installed and in PATH
    exit /b 1
)

if defined JAVA_HOME (
    flutter config --jdk-dir="%JAVA_HOME%" >nul 2>&1
)

echo [SUCCESS] Flutter environment configured

REM Step 4: Clean project
echo [STEP] 4. Cleaning project...

flutter clean >nul 2>&1
if exist build rmdir /s /q build 2>nul
if exist .dart_tool rmdir /s /q .dart_tool 2>nul

echo [SUCCESS] Project cleaned

REM Step 5: Get dependencies
echo [STEP] 5. Getting dependencies...

flutter pub get >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Failed to get dependencies
    exit /b 1
)

echo [SUCCESS] Dependencies updated

REM Step 6: Verify configuration
echo [STEP] 6. Verifying project configuration...

findstr /C:"flutterEmbedding" android\app\src\main\AndroidManifest.xml >nul && findstr /C:"android:value=\"2\"" android\app\src\main\AndroidManifest.xml >nul
if errorlevel 1 (
    echo [ERROR] Android v2 embedding not properly configured
    exit /b 1
)

findstr /C:"FlutterActivity" android\app\src\main\kotlin\com\nexus\nexus_app\MainActivity.kt >nul
if errorlevel 1 (
    echo [ERROR] MainActivity configuration issue
    exit /b 1
)

echo [SUCCESS] Project configuration verified

REM Step 7: Build and deploy
echo [STEP] 7. Building and deploying to device...
echo [INFO] This may take a few minutes...

flutter run --debug --device-id="%DEVICE_ID%" --verbose
if errorlevel 1 (
    echo [ERROR] Deployment failed
    echo.
    echo Common solutions:
    echo 1. Check device is unlocked and USB debugging allowed
    echo 2. Try: flutter clean ^&^& flutter pub get
    echo 3. Restart ADB: adb kill-server ^&^& adb start-server
    echo 4. Check Java version: java -version ^(should be OpenJDK 21^)
    exit /b 1
) else (
    echo [SUCCESS] Deployment successful!
    echo.
    echo App is now running on device %DEVICE_ID%
    echo Press 'r' to hot reload, 'R' to hot restart, 'q' to quit
)

endlocal