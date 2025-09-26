# Flutter Remote Deployment Script for Nexus App (Windows PowerShell)
# Usage: .\deploy-remote.ps1 <DEVICE_ID>
# Example: .\deploy-remote.ps1 45301FDAP003JE

param(
    [Parameter(Mandatory=$true)]
    [string]$DeviceId
)

# Set error handling
$ErrorActionPreference = "Stop"

# Colors for output
function Write-ColorOutput([string]$Message, [string]$Color = "White") {
    switch ($Color) {
        "Red" { Write-Host $Message -ForegroundColor Red }
        "Green" { Write-Host $Message -ForegroundColor Green }
        "Yellow" { Write-Host $Message -ForegroundColor Yellow }
        "Blue" { Write-Host $Message -ForegroundColor Blue }
        "Cyan" { Write-Host $Message -ForegroundColor Cyan }
        default { Write-Host $Message }
    }
}

function Write-Step([string]$Message) {
    Write-ColorOutput "[STEP] $Message" "Blue"
}

function Write-Success([string]$Message) {
    Write-ColorOutput "[SUCCESS] $Message" "Green"
}

function Write-Error([string]$Message) {
    Write-ColorOutput "[ERROR] $Message" "Red"
}

function Write-Warning([string]$Message) {
    Write-ColorOutput "[WARNING] $Message" "Yellow"
}

Write-ColorOutput "🚀 Flutter Nexus App Deployment (Windows)" "Cyan"
Write-ColorOutput "Device: $DeviceId" "Blue"
Write-Host ""

try {
    # Step 1: Check environment
    Write-Step "1. Checking environment..."

    # Set proper Java environment for Android builds
    $AndroidStudioJdk = "$env:LOCALAPPDATA\Android\Android Studio\jbr"
    if (-not (Test-Path $AndroidStudioJdk)) {
        # Try alternative paths
        $AndroidStudioJdk = "${env:ProgramFiles}\Android\Android Studio\jbr"
        if (-not (Test-Path $AndroidStudioJdk)) {
            $AndroidStudioJdk = "${env:ProgramFiles(x86)}\Android\Android Studio\jbr"
            if (-not (Test-Path $AndroidStudioJdk)) {
                Write-Warning "Android Studio JDK not found in standard locations"
                Write-Host "Please set JAVA_HOME manually to your Android Studio JDK path"
            }
        }
    }

    if (Test-Path $AndroidStudioJdk) {
        $env:JAVA_HOME = $AndroidStudioJdk
        $env:PATH = "$AndroidStudioJdk\bin;$env:PATH"
        Write-Success "✅ Java environment set to Android Studio JDK"
    }

    # Verify we're in the right directory
    if (-not (Test-Path "pubspec.yaml")) {
        Write-Error "Not in a Flutter project directory!"
        Write-Host "Make sure you're in the apps\nexus_app\ directory"
        exit 1
    }

    # Check if this is the nexus_app
    $pubspecContent = Get-Content "pubspec.yaml" -Raw
    if (-not ($pubspecContent -match "name: nexus_app")) {
        Write-Error "This doesn't appear to be the nexus_app project"
        Write-Host "Make sure you're in the apps\nexus_app\ directory"
        exit 1
    }

    Write-Success "✅ Environment OK - In nexus_app directory"

    # Step 2: Check device connection
    Write-Step "2. Checking device connection..."

    # Check if ADB is available
    try {
        $null = Get-Command adb -ErrorAction Stop
    }
    catch {
        Write-Error "ADB not found! Make sure Android SDK is installed and in PATH"
        Write-Host "Add Android SDK platform-tools to your PATH environment variable"
        exit 1
    }

    # Check if device is connected
    $adbDevices = & adb devices -l
    if (-not ($adbDevices -match $DeviceId)) {
        Write-Error "Device $DeviceId not found!"
        Write-Host ""
        Write-Host "Available devices:"
        & adb devices -l
        Write-Host ""
        Write-Host "Troubleshooting:"
        Write-Host "1. Enable USB Debugging on your Android device"
        Write-Host "2. Connect device via USB"
        Write-Host "3. Allow USB debugging when prompted"
        Write-Host "4. Try: adb kill-server; adb start-server"
        exit 1
    }

    Write-Success "✅ Device $DeviceId connected"

    # Step 3: Check Flutter environment
    Write-Step "3. Checking Flutter environment..."

    # Check if Flutter is available
    try {
        $null = Get-Command flutter -ErrorAction Stop
    }
    catch {
        Write-Error "Flutter not found! Make sure Flutter SDK is installed and in PATH"
        exit 1
    }

    # Configure Flutter to use correct JDK
    if ($env:JAVA_HOME) {
        & flutter config --jdk-dir="$env:JAVA_HOME" | Out-Null
    }

    # Quick Flutter doctor check
    try {
        & flutter doctor --quiet
        Write-Success "✅ Flutter environment configured"
    }
    catch {
        Write-Warning "⚠️  Flutter doctor found some issues, but continuing..."
    }

    # Step 4: Clean and prepare
    Write-Step "4. Cleaning project..."

    & flutter clean | Out-Null
    if (Test-Path "build") { Remove-Item -Recurse -Force "build" -ErrorAction SilentlyContinue }
    if (Test-Path ".dart_tool") { Remove-Item -Recurse -Force ".dart_tool" -ErrorAction SilentlyContinue }

    Write-Success "✅ Project cleaned"

    # Step 5: Get dependencies
    Write-Step "5. Getting dependencies..."

    $pubGetResult = & flutter pub get 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to get dependencies"
        Write-Host $pubGetResult
        exit 1
    }

    Write-Success "✅ Dependencies updated"

    # Step 6: Verify project structure
    Write-Step "6. Verifying project configuration..."

    # Check for Android v2 embedding
    $manifestPath = "android\app\src\main\AndroidManifest.xml"
    if (Test-Path $manifestPath) {
        $manifestContent = Get-Content $manifestPath -Raw
        if (($manifestContent -match "flutterEmbedding") -and ($manifestContent -match 'android:value="2"')) {
            Write-Success "✅ Android v2 embedding configured"
        }
        else {
            Write-Error "Android v2 embedding not properly configured"
            exit 1
        }
    }
    else {
        Write-Error "AndroidManifest.xml not found"
        exit 1
    }

    # Check MainActivity
    $mainActivityPath = "android\app\src\main\kotlin\com\nexus\nexus_app\MainActivity.kt"
    if (Test-Path $mainActivityPath) {
        $mainActivityContent = Get-Content $mainActivityPath -Raw
        if ($mainActivityContent -match "FlutterActivity") {
            Write-Success "✅ MainActivity extends FlutterActivity"
        }
        else {
            Write-Error "MainActivity configuration issue"
            exit 1
        }
    }
    else {
        Write-Error "MainActivity.kt not found"
        exit 1
    }

    # Step 7: Build and deploy
    Write-Step "7. Building and deploying to device..."

    Write-ColorOutput "This may take a few minutes..." "Yellow"

    # Build and run with detailed output
    $runResult = & flutter run --debug --device-id="$DeviceId" --verbose 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "🎉 Deployment successful!"
        Write-Host ""
        Write-ColorOutput "App is now running on device $DeviceId" "Green"
        Write-Host "Press 'r' to hot reload, 'R' to hot restart, 'q' to quit"
    }
    else {
        Write-Error "Deployment failed"
        Write-Host ""
        Write-Host "Build output:"
        Write-Host $runResult
        Write-Host ""
        Write-Host "Common solutions:"
        Write-Host "1. Check device is unlocked and USB debugging allowed"
        Write-Host "2. Try: flutter clean; flutter pub get"
        Write-Host "3. Restart ADB: adb kill-server; adb start-server"
        Write-Host "4. Check Java version: java -version (should be OpenJDK 21)"
        exit 1
    }
}
catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    Write-Host "Stack trace: $($_.ScriptStackTrace)"
    exit 1
}