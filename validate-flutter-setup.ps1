# Validate Flutter Setup for Cross-Environment Testing (Windows PowerShell)
# Usage: .\validate-flutter-setup.ps1

# Set error handling
$ErrorActionPreference = "Continue"

# Colors and formatting
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

# Check counters
$script:successCount = 0
$script:totalChecks = 8

function Test-Passed([string]$Message) {
    $script:successCount++
    Write-ColorOutput "✅ PASS: $Message" "Green"
}

function Test-Failed([string]$Message, [string]$Solution) {
    Write-ColorOutput "❌ FAIL: $Message" "Red"
    Write-ColorOutput "   Solution: $Solution" "Yellow"
}

function Test-Warning([string]$Message, [string]$Note) {
    Write-ColorOutput "⚠️  WARN: $Message" "Yellow"
    Write-ColorOutput "   Note: $Note" "Yellow"
}

Write-ColorOutput "🔍 Validating Flutter Setup for Cross-Environment Testing (Windows)" "Cyan"
Write-Host ""

Write-ColorOutput "Checking Flutter Environment..." "Blue"

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Check 1: Flutter installation
try {
    $flutterVersion = & flutter --version 2>&1 | Select-Object -First 1
    Test-Passed "Flutter is installed ($flutterVersion)"
}
catch {
    Test-Failed "Flutter not found" "Install Flutter SDK and add to PATH"
}

# Check 2: Java environment
try {
    $javaVersion = & java -version 2>&1 | Select-Object -First 1
    if ($javaVersion -match "21\.0") {
        Test-Passed "Java version is compatible ($javaVersion)"
    }
    elseif ($javaVersion -match "24\.0") {
        Test-Warning "Using system Java 24 instead of Android Studio JDK" "Set JAVA_HOME to Android Studio JDK"
    }
    else {
        Test-Failed "Java version issue ($javaVersion)" "Install OpenJDK 21 or use Android Studio JDK"
    }
}
catch {
    Test-Failed "Java not found" "Install Java JDK and add to PATH"
}

# Check 3: Android SDK
$AndroidSdkPaths = @(
    "$env:LOCALAPPDATA\Android\Sdk",
    "$env:ANDROID_HOME",
    "$env:ANDROID_SDK_ROOT",
    "${env:ProgramFiles}\Android\Android Studio\sdk",
    "${env:ProgramFiles(x86)}\Android\Android Studio\sdk"
)

$AndroidSdkFound = $false
foreach ($path in $AndroidSdkPaths) {
    if ($path -and (Test-Path $path)) {
        Test-Passed "Android SDK found at $path"
        $AndroidSdkFound = $true
        break
    }
}

if (-not $AndroidSdkFound) {
    Test-Failed "Android SDK not found" "Install Android SDK via Android Studio"
}

# Check 4: ADB available
try {
    $null = Get-Command adb -ErrorAction Stop
    Test-Passed "ADB is available"
}
catch {
    Test-Failed "ADB not found" "Add Android SDK platform-tools to PATH"
}

# Check 5: Main Flutter project structure
$nexusAppPath = Join-Path $ScriptDir "apps\nexus_app\pubspec.yaml"
if (Test-Path $nexusAppPath) {
    $pubspecContent = Get-Content $nexusAppPath -Raw
    if ($pubspecContent -match "name: nexus_app") {
        Test-Passed "Main Flutter project (nexus_app) found"
    }
    else {
        Test-Failed "Pubspec doesn't contain nexus_app name" "Check pubspec.yaml content"
    }
}
else {
    Test-Failed "Main Flutter project not found" "Check repository structure"
}

# Check 6: Android v2 embedding configuration
$manifestPath = Join-Path $ScriptDir "apps\nexus_app\android\app\src\main\AndroidManifest.xml"
if (Test-Path $manifestPath) {
    $manifestContent = Get-Content $manifestPath -Raw
    if (($manifestContent -match "flutterEmbedding") -and ($manifestContent -match 'android:value="2"')) {
        Test-Passed "Android v2 embedding correctly configured"
    }
    else {
        Test-Failed "Android v2 embedding not configured" "Check AndroidManifest.xml"
    }
}
else {
    Test-Failed "AndroidManifest.xml not found" "Check Flutter project structure"
}

# Check 7: MainActivity configuration
$mainActivityPath = Join-Path $ScriptDir "apps\nexus_app\android\app\src\main\kotlin\com\nexus\nexus_app\MainActivity.kt"
if (Test-Path $mainActivityPath) {
    $mainActivityContent = Get-Content $mainActivityPath -Raw
    if ($mainActivityContent -match "FlutterActivity") {
        Test-Passed "MainActivity extends FlutterActivity"
    }
    else {
        Test-Failed "MainActivity doesn't extend FlutterActivity" "Update MainActivity to extend FlutterActivity"
    }
}
else {
    Test-Failed "MainActivity.kt not found" "Check Flutter Android project structure"
}

# Check 8: Deployment script
$deployScriptPath = Join-Path $ScriptDir "apps\nexus_app\deploy-remote.ps1"
if (Test-Path $deployScriptPath) {
    Test-Passed "PowerShell deployment script is ready"
}
else {
    Test-Failed "PowerShell deployment script missing" "Ensure deploy-remote.ps1 exists"
}

Write-Host ""
Write-ColorOutput "Summary: $script:successCount/$script:totalChecks checks passed" "Blue"

if ($script:successCount -eq $script:totalChecks) {
    Write-ColorOutput "🎉 All checks passed! Ready for cross-environment testing" "Green"
    Write-Host ""
    Write-ColorOutput "Next steps for Windows PC:" "Blue"
    Write-Host "1. git pull origin main"
    Write-Host "2. .\validate-flutter-setup.ps1"
    Write-Host "3. cd apps\nexus_app"
    Write-Host "4. .\deploy-remote.ps1 45301FDAP003JE"
    exit 0
}
elseif ($script:successCount -ge 6) {
    Write-ColorOutput "⚠️  Most checks passed. Fix warnings for best results" "Yellow"
    exit 0
}
else {
    Write-ColorOutput "❌ Critical issues found. Fix failed checks before deployment" "Red"
    exit 1
}