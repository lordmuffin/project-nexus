# Fix Java Path for Flutter Android Build (Windows)
# This script resolves JAVA_HOME path issues for Android builds

param(
    [switch]$Force
)

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

Write-ColorOutput "🔧 Fixing Java Path for Flutter Android Build" "Cyan"
Write-Host ""

# Current JAVA_HOME
Write-ColorOutput "Current JAVA_HOME: $env:JAVA_HOME" "Blue"

# Search for Android Studio JDK installations
$PossiblePaths = @(
    "$env:LOCALAPPDATA\Android\Android Studio\jbr",
    "${env:ProgramFiles}\Android\Android Studio\jbr",
    "${env:ProgramFiles(x86)}\Android\Android Studio\jbr",
    "${env:ProgramFiles}\Android\Android Studio1\jbr",  # Your specific path
    "${env:ProgramFiles(x86)}\Android\Android Studio1\jbr"
)

Write-ColorOutput "Searching for Android Studio JDK..." "Blue"

$ValidJdkPath = $null
foreach ($path in $PossiblePaths) {
    if (Test-Path $path) {
        $javaExe = Join-Path $path "bin\java.exe"
        if (Test-Path $javaExe) {
            Write-ColorOutput "✅ Found valid JDK at: $path" "Green"
            
            # Test Java version
            try {
                $javaVersion = & $javaExe -version 2>&1 | Select-Object -First 1
                Write-ColorOutput "   Java version: $javaVersion" "Blue"
                $ValidJdkPath = $path
                break
            }
            catch {
                Write-ColorOutput "   ❌ Java executable not working" "Red"
            }
        }
    }
}

if (-not $ValidJdkPath) {
    Write-ColorOutput "❌ No valid Android Studio JDK found!" "Red"
    Write-Host ""
    Write-Host "Manual solutions:"
    Write-Host "1. Install Android Studio with default settings"
    Write-Host "2. Or manually set JAVA_HOME to a valid OpenJDK 21 installation"
    Write-Host "3. Or download OpenJDK 21 from: https://adoptium.net/"
    exit 1
}

# Set environment variables for current session
$env:JAVA_HOME = $ValidJdkPath
$env:PATH = "$ValidJdkPath\bin;$env:PATH"

Write-ColorOutput "✅ Fixed JAVA_HOME for current session" "Green"
Write-ColorOutput "JAVA_HOME = $env:JAVA_HOME" "Blue"

# Configure Flutter to use this JDK
Write-ColorOutput "Configuring Flutter to use this JDK..." "Blue"
try {
    & flutter config --jdk-dir="$ValidJdkPath"
    Write-ColorOutput "✅ Flutter configured successfully" "Green"
}
catch {
    Write-ColorOutput "⚠️  Could not configure Flutter automatically" "Yellow"
}

# Test Java installation
Write-ColorOutput "Testing Java installation..." "Blue"
try {
    $javaVersion = & java -version 2>&1 | Select-Object -First 1
    Write-ColorOutput "✅ Java working: $javaVersion" "Green"
}
catch {
    Write-ColorOutput "❌ Java test failed" "Red"
    exit 1
}

# Create a batch file to set environment for future sessions
$envBatch = @"
@echo off
REM Set Android Studio JDK environment
set JAVA_HOME=$ValidJdkPath
set PATH=%JAVA_HOME%\bin;%PATH%
echo JAVA_HOME set to: %JAVA_HOME%
"@

$batchFile = "set-java-env.bat"
$envBatch | Out-File -FilePath $batchFile -Encoding ASCII
Write-ColorOutput "✅ Created $batchFile for future sessions" "Green"

Write-Host ""
Write-ColorOutput "🎯 Next Steps:" "Green"
Write-Host "1. Your Java environment is fixed for this PowerShell session"
Write-Host "2. Try deployment again: .\deploy-remote.ps1 45301FDAP003JE"
Write-Host "3. For future sessions, run: .\set-java-env.bat"
Write-Host ""
Write-ColorOutput "If you still get Java errors, restart PowerShell and run this script again" "Yellow"