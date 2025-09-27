#!/usr/bin/env pwsh
param(
    [Parameter(Mandatory=$true)]
    [string]$DeviceId
)

Write-Host "🔍 Checking installed apps on device $DeviceId..." -ForegroundColor Cyan

Write-Host "`n📱 Looking for Flutter/Nexus related apps:" -ForegroundColor Yellow
adb -s $DeviceId shell pm list packages | grep -i flutter
adb -s $DeviceId shell pm list packages | grep -i nexus
adb -s $DeviceId shell pm list packages | grep -i example

Write-Host "`n🔍 Checking app details for com.nexus.nexus_app:" -ForegroundColor Yellow
adb -s $DeviceId shell dumpsys package com.nexus.nexus_app | grep -E "(applicationLabel|versionName)"

Write-Host "`n📋 All installed packages containing 'com.':" -ForegroundColor Yellow
adb -s $DeviceId shell pm list packages | grep "com\." | sort