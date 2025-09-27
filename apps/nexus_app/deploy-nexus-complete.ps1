#!/usr/bin/env pwsh
param(
    [Parameter(Mandatory=$true)]
    [string]$DeviceId
)

Write-Host "🚀 Complete Nexus App Deployment Script" -ForegroundColor Cyan
Write-Host "Device: $DeviceId" -ForegroundColor White
Write-Host "=" * 50 -ForegroundColor Gray

# Step 1: Environment Check
Write-Host "`n[STEP 1] 🔍 Checking environment..." -ForegroundColor Yellow
if (!(Test-Path "build/app/outputs/flutter-apk/app-debug.apk")) {
    Write-Host "⚠️ APK not found. Building fresh APK..." -ForegroundColor Yellow
    Write-Host "🧹 Cleaning project..." -ForegroundColor Blue
    flutter clean | Out-Null
    Write-Host "📦 Getting dependencies..." -ForegroundColor Blue
    flutter pub get | Out-Null
    Write-Host "🔧 Generating database code..." -ForegroundColor Blue
    dart run build_runner build --delete-conflicting-outputs | Out-Null
    Write-Host "🔨 Building APK..." -ForegroundColor Blue
    flutter build apk --debug --target-platform android-arm64
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ APK build failed!" -ForegroundColor Red
        exit 1
    }
}
Write-Host "✅ APK ready for deployment" -ForegroundColor Green

# Step 2: Device Connection Check
Write-Host "`n[STEP 2] 📱 Checking device connection..." -ForegroundColor Yellow
$deviceList = adb devices
$deviceFound = $false
foreach ($line in $deviceList) {
    if ($line -match "$DeviceId\s+device") {
        $deviceFound = $true
        break
    }
}
if (-not $deviceFound) {
    Write-Host "❌ Device $DeviceId not found!" -ForegroundColor Red
    Write-Host "📋 Available devices:" -ForegroundColor Yellow
    adb devices
    exit 1
}
Write-Host "✅ Device $DeviceId connected" -ForegroundColor Green

# Step 3: Clean Installation
Write-Host "`n[STEP 3] 🧹 Removing old/conflicting apps..." -ForegroundColor Yellow

# Remove old Flutter demo app
Write-Host "🗑️ Removing old Flutter demo app..." -ForegroundColor Blue
$result1 = adb -s $DeviceId uninstall com.example.flutter_application_1 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Removed old Flutter demo app" -ForegroundColor Green
} else {
    Write-Host "ℹ️ Old Flutter demo app not found (already removed)" -ForegroundColor Cyan
}

# Remove any existing Nexus app
Write-Host "🗑️ Removing existing Nexus app for clean install..." -ForegroundColor Blue
$result2 = adb -s $DeviceId uninstall com.nexus.nexus_app 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Removed existing Nexus app" -ForegroundColor Green
} else {
    Write-Host "ℹ️ No existing Nexus app found" -ForegroundColor Cyan
}

# Step 4: Fresh Installation
Write-Host "`n[STEP 4] 📦 Installing fresh Nexus app..." -ForegroundColor Yellow
$installResult = adb -s $DeviceId install build/app/outputs/flutter-apk/app-debug.apk
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Nexus app installed successfully!" -ForegroundColor Green
} else {
    Write-Host "❌ Installation failed!" -ForegroundColor Red
    Write-Host "$installResult" -ForegroundColor Red
    exit 1
}

# Step 5: Verification
Write-Host "`n[STEP 5] ✅ Verifying installation..." -ForegroundColor Yellow

# Check if Nexus app is installed
$nexusCheck = adb -s $DeviceId shell pm list packages | Select-String -Pattern "com.nexus.nexus_app"
if ($nexusCheck) {
    Write-Host "✅ Nexus app (com.nexus.nexus_app) confirmed installed" -ForegroundColor Green
} else {
    Write-Host "❌ Nexus app not found after installation!" -ForegroundColor Red
    exit 1
}

# Check for any remaining Flutter demo apps
$flutterApps = adb -s $DeviceId shell pm list packages | Select-String -Pattern "flutter" -CaseSensitive:$false
$exampleApps = adb -s $DeviceId shell pm list packages | Select-String -Pattern "example" -CaseSensitive:$false

Write-Host "`n📋 Current Flutter-related apps on device:" -ForegroundColor Blue
if ($flutterApps) {
    $flutterApps | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
} else {
    Write-Host "  No other Flutter apps found" -ForegroundColor Gray
}

# Final Success Message
Write-Host "`n" + "=" * 50 -ForegroundColor Gray
Write-Host "🎉 DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "=" * 50 -ForegroundColor Gray

Write-Host "`n📱 What to expect on your device:" -ForegroundColor Cyan
Write-Host "  • App name: 'Nexus' (not 'flutter_application_1')" -ForegroundColor White
Write-Host "  • App icon: Should appear in your app drawer" -ForegroundColor White
Write-Host "  • Interface: Bottom navigation with 4 tabs:" -ForegroundColor White
Write-Host "    - Chat (AI assistant)" -ForegroundColor Gray
Write-Host "    - Meetings (recording & transcription)" -ForegroundColor Gray
Write-Host "    - Notes (personal notes)" -ForegroundColor Gray
Write-Host "    - Settings (app configuration)" -ForegroundColor Gray

Write-Host "`n💡 Troubleshooting tips:" -ForegroundColor Yellow
Write-Host "  • If you still see old app names, restart your device" -ForegroundColor White
Write-Host "  • Look for 'Nexus' specifically, not 'flutter_application_1'" -ForegroundColor White
Write-Host "  • The app should have blue theming and proper branding" -ForegroundColor White

Write-Host "`n✨ Deployment successful! Your Nexus app is ready to use." -ForegroundColor Green