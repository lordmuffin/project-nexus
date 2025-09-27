#!/usr/bin/env pwsh
param(
    [Parameter(Mandatory=$true)]
    [string]$DeviceId
)

Write-Host "🔧 Fixing app name issue on device $DeviceId..." -ForegroundColor Cyan

Write-Host "`n❌ Uninstalling old Flutter demo app..." -ForegroundColor Red
$result1 = adb -s $DeviceId uninstall com.example.flutter_application_1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Successfully removed old Flutter demo app" -ForegroundColor Green
} else {
    Write-Host "⚠️ Old app may not have been installed or already removed" -ForegroundColor Yellow
}

Write-Host "`n🔍 Checking our Nexus app status..." -ForegroundColor Blue
$packageCheck = adb -s $DeviceId shell pm list packages | Select-String -Pattern "com.nexus.nexus_app"
if ($packageCheck) {
    Write-Host "✅ Nexus app (com.nexus.nexus_app) is installed" -ForegroundColor Green
    Write-Host "📱 Look for the app named 'Nexus' in your app drawer" -ForegroundColor Cyan
    Write-Host "🎯 It should have the proper Nexus interface with Chat, Meetings, Notes, Settings tabs" -ForegroundColor Cyan
} else {
    Write-Host "❌ Nexus app not found. Reinstalling..." -ForegroundColor Red
    adb -s $DeviceId install -r build/app/outputs/flutter-apk/app-debug.apk
}

Write-Host "`n📋 Current Flutter/Nexus apps on device:" -ForegroundColor Yellow
adb -s $DeviceId shell pm list packages | Select-String -Pattern "flutter" -CaseSensitive:$false
adb -s $DeviceId shell pm list packages | Select-String -Pattern "nexus" -CaseSensitive:$false

Write-Host "`n🎉 Done! The app should now appear as 'Nexus' in your app drawer." -ForegroundColor Green
Write-Host "💡 If you still see 'flutter_application_1', try restarting your device or clearing launcher cache." -ForegroundColor Cyan