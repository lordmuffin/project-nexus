#!/usr/bin/env pwsh
param(
    [Parameter(Mandatory=$true)]
    [string]$DeviceId
)

Write-Host "🔧 Uninstalling old app and deploying fresh Nexus APK..." -ForegroundColor Cyan

# First uninstall any existing version (try both possible package names)
Write-Host "📱 Uninstalling existing app..." -ForegroundColor Yellow
adb -s $DeviceId uninstall com.example.nexus_app 2>$null
adb -s $DeviceId uninstall com.nexus.nexus_app 2>$null

# Install the new APK
Write-Host "📦 Installing new Nexus APK..." -ForegroundColor Green
adb -s $DeviceId install -r build/app/outputs/flutter-apk/app-debug.apk

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Successfully deployed Nexus app!" -ForegroundColor Green
    Write-Host "📱 The app should now appear as 'Nexus' on your device" -ForegroundColor Cyan
} else {
    Write-Host "❌ Deployment failed!" -ForegroundColor Red
}