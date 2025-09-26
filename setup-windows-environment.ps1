# Windows Flutter Development Environment Setup Script
# Run this script once to configure your Windows environment for Flutter development

# Requires PowerShell 5.0+ and Administrator privileges for some operations
# Usage: .\setup-windows-environment.ps1

param(
    [switch]$SkipDownloads,
    [switch]$Force
)

# Set error handling
$ErrorActionPreference = "Continue"

# Colors for output
function Write-ColorOutput([string]$Message, [string]$Color = "White") {
    switch ($Color) {
        "Red" { Write-Host $Message -ForegroundColor Red }
        "Green" { Write-Host $Message -ForegroundColor Green }
        "Yellow" { Write-Host $Message -ForegroundColor Yellow }
        "Blue" { Write-Host $Message -ForegroundColor Blue }
        "Cyan" { Write-Host $Message -ForegroundColor Cyan }
        "Magenta" { Write-Host $Message -ForegroundColor Magenta }
        default { Write-Host $Message }
    }
}

function Write-Step([string]$Message) {
    Write-ColorOutput "`n[STEP] $Message" "Blue"
}

function Write-Success([string]$Message) {
    Write-ColorOutput "[SUCCESS] $Message" "Green"
}

function Write-Warning([string]$Message) {
    Write-ColorOutput "[WARNING] $Message" "Yellow"
}

function Write-Info([string]$Message) {
    Write-ColorOutput "[INFO] $Message" "Cyan"
}

Write-ColorOutput "🚀 Windows Flutter Development Environment Setup" "Magenta"
Write-ColorOutput "This script will configure your Windows environment for Flutter development" "Cyan"
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Warning "Some operations require Administrator privileges"
    Write-Info "Consider running PowerShell as Administrator for complete setup"
}

# Step 1: Configure PowerShell execution policy
Write-Step "1. Configuring PowerShell execution policy..."

try {
    $currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
    if ($currentPolicy -eq "Restricted" -or $currentPolicy -eq "Undefined") {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Write-Success "PowerShell execution policy updated to RemoteSigned"
    } else {
        Write-Success "PowerShell execution policy already configured: $currentPolicy"
    }
} catch {
    Write-Warning "Could not update execution policy: $($_.Exception.Message)"
}

# Step 2: Check Flutter installation
Write-Step "2. Checking Flutter installation..."

try {
    $flutterVersion = & flutter --version 2>&1 | Select-Object -First 1
    Write-Success "Flutter is installed: $flutterVersion"
} catch {
    Write-Warning "Flutter not found in PATH"
    Write-Info "Please install Flutter from: https://flutter.dev/docs/get-started/install/windows"
    Write-Info "Or specify Flutter installation path manually"
    
    if (-not $SkipDownloads) {
        Write-Info "Opening Flutter installation page..."
        Start-Process "https://flutter.dev/docs/get-started/install/windows"
    }
}

# Step 3: Check Android Studio installation
Write-Step "3. Checking Android Studio installation..."

$androidStudioPaths = @(
    "${env:ProgramFiles}\Android\Android Studio",
    "${env:ProgramFiles(x86)}\Android\Android Studio",
    "$env:LOCALAPPDATA\Programs\Android Studio"
)

$androidStudioFound = $false
foreach ($path in $androidStudioPaths) {
    if (Test-Path $path) {
        Write-Success "Android Studio found at: $path"
        $androidStudioFound = $true
        
        # Set JAVA_HOME to Android Studio JDK
        $jdkPath = Join-Path $path "jbr"
        if (Test-Path $jdkPath) {
            $env:JAVA_HOME = $jdkPath
            Write-Success "JAVA_HOME set to Android Studio JDK: $jdkPath"
        }
        break
    }
}

if (-not $androidStudioFound) {
    Write-Warning "Android Studio not found in standard locations"
    Write-Info "Please install Android Studio from: https://developer.android.com/studio"
    
    if (-not $SkipDownloads) {
        Write-Info "Opening Android Studio download page..."
        Start-Process "https://developer.android.com/studio"
    }
}

# Step 4: Check Android SDK
Write-Step "4. Checking Android SDK..."

$androidSdkPaths = @(
    "$env:LOCALAPPDATA\Android\Sdk",
    "$env:ANDROID_HOME",
    "$env:ANDROID_SDK_ROOT"
)

$androidSdkFound = $false
foreach ($path in $androidSdkPaths) {
    if ($path -and (Test-Path $path)) {
        Write-Success "Android SDK found at: $path"
        $androidSdkFound = $true
        
        # Check for platform-tools (ADB)
        $platformTools = Join-Path $path "platform-tools"
        if (Test-Path $platformTools) {
            Write-Success "Platform tools (ADB) found"
        } else {
            Write-Warning "Platform tools not found - install via SDK Manager"
        }
        break
    }
}

if (-not $androidSdkFound) {
    Write-Warning "Android SDK not found"
    Write-Info "Install Android SDK via Android Studio SDK Manager"
}

# Step 5: Check environment variables
Write-Step "5. Checking environment variables..."

# Check PATH for Flutter
try {
    $null = Get-Command flutter -ErrorAction Stop
    Write-Success "Flutter is in PATH"
} catch {
    Write-Warning "Flutter not found in PATH"
    Write-Info "Add Flutter bin directory to your PATH environment variable"
}

# Check PATH for ADB
try {
    $null = Get-Command adb -ErrorAction Stop
    Write-Success "ADB is in PATH"
} catch {
    Write-Warning "ADB not found in PATH"
    Write-Info "Add Android SDK platform-tools to your PATH environment variable"
}

# Step 6: Run Flutter doctor
Write-Step "6. Running Flutter doctor..."

try {
    Write-Info "Running flutter doctor -v..."
    & flutter doctor -v
} catch {
    Write-Warning "Could not run flutter doctor - Flutter may not be installed properly"
}

# Step 7: Check Git installation
Write-Step "7. Checking Git installation..."

try {
    $gitVersion = & git --version 2>&1
    Write-Success "Git is installed: $gitVersion"
} catch {
    Write-Warning "Git not found"
    Write-Info "Install Git from: https://git-scm.com/download/win"
    
    if (-not $SkipDownloads) {
        Write-Info "Opening Git download page..."
        Start-Process "https://git-scm.com/download/win"
    }
}

# Step 8: Environment variables recommendations
Write-Step "8. Environment Variables Recommendations..."

Write-Info "Consider setting these environment variables (if not already set):"

if (-not $env:FLUTTER_HOME) {
    Write-Info "FLUTTER_HOME = C:\flutter (or your Flutter installation path)"
}

if (-not $env:ANDROID_HOME -and -not $env:ANDROID_SDK_ROOT) {
    Write-Info "ANDROID_HOME = %LOCALAPPDATA%\Android\Sdk"
}

if (-not $env:JAVA_HOME) {
    Write-Info "JAVA_HOME = %LOCALAPPDATA%\Android\Android Studio\jbr"
}

Write-Info "PATH should include:"
Write-Info "  - %FLUTTER_HOME%\bin"
Write-Info "  - %ANDROID_HOME%\platform-tools"
Write-Info "  - %JAVA_HOME%\bin"

# Step 9: Create environment setup script
Write-Step "9. Creating environment setup script..."

$envScript = @"
@echo off
REM Flutter Development Environment Setup
REM Run this script to set environment variables for current session

echo Setting up Flutter development environment...

REM Set Flutter path (update this to your Flutter installation)
set FLUTTER_HOME=C:\flutter
set PATH=%FLUTTER_HOME%\bin;%PATH%

REM Set Android SDK path
set ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk
set ANDROID_SDK_ROOT=%ANDROID_HOME%
set PATH=%ANDROID_HOME%\platform-tools;%PATH%

REM Set Java path (Android Studio JDK)
set JAVA_HOME=%LOCALAPPDATA%\Android\Android Studio\jbr
set PATH=%JAVA_HOME%\bin;%PATH%

echo Environment variables set for current session
echo.
echo Run 'flutter doctor -v' to verify setup
echo Run 'adb devices' to check device connectivity
echo.
"@

$envScriptPath = Join-Path $PSScriptRoot "setup-env.bat"
$envScript | Out-File -FilePath $envScriptPath -Encoding ASCII
Write-Success "Created environment setup script: $envScriptPath"

# Step 10: Summary and next steps
Write-Step "10. Setup Summary"

Write-ColorOutput "`n🎯 Next Steps:" "Magenta"
Write-Host "1. Install any missing components (Flutter, Android Studio, Git)"
Write-Host "2. Set environment variables (PATH, ANDROID_HOME, JAVA_HOME)"
Write-Host "3. Run: flutter doctor -v"
Write-Host "4. Run: .\validate-flutter-setup.ps1"
Write-Host "5. Connect your Android device and enable USB debugging"
Write-Host "6. Run: adb devices"
Write-Host "7. Deploy app: cd apps\nexus_app; .\deploy-remote.ps1 45301FDAP003JE"

Write-ColorOutput "`n📚 Documentation:" "Blue"
Write-Host "- Flutter setup: https://flutter.dev/docs/get-started/install/windows"
Write-Host "- Android setup: https://developer.android.com/studio/install"
Write-Host "- Project guide: .\WINDOWS_DEPLOYMENT_GUIDE.md"

Write-ColorOutput "`n✅ Setup script completed!" "Green"