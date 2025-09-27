#!/usr/bin/env pwsh
param(
    [Parameter(Mandatory=$true)]
    [string]$DeviceId
)

Write-Host "🔍 Checking installed apps on device $DeviceId..." -ForegroundColor Cyan

Write-Host "`n📱 Looking for Flutter/Nexus related apps:" -ForegroundColor Yellow
adb -s $DeviceId shell pm list packages | Select-String -Pattern "flutter" -CaseSensitive:$false
adb -s $DeviceId shell pm list packages | Select-String -Pattern "nexus" -CaseSensitive:$false
adb -s $DeviceId shell pm list packages | Select-String -Pattern "example" -CaseSensitive:$false

Write-Host "`n🔍 Checking if com.nexus.nexus_app is installed:" -ForegroundColor Yellow
adb -s $DeviceId shell pm list packages | Select-String -Pattern "com.nexus.nexus_app"

Write-Host "`n📋 All installed packages containing 'com.':" -ForegroundColor Yellow
adb -s $DeviceId shell pm list packages | Select-String -Pattern "com\." | Sort-Object