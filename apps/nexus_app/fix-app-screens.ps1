#!/usr/bin/env pwsh

Write-Host "🔧 Nexus App Screen Fix Script" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Gray

Write-Host "`n📋 Step 1: Cleaning project..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Flutter clean failed!" -ForegroundColor Red
    exit 1
}

Write-Host "`n📦 Step 2: Getting dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Flutter pub get failed!" -ForegroundColor Red
    exit 1
}

Write-Host "`n🔧 Step 3: Generating database code..." -ForegroundColor Yellow
dart run build_runner build --delete-conflicting-outputs
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️ Build runner had issues, continuing..." -ForegroundColor Yellow
}

Write-Host "`n🔍 Step 4: Analyzing code..." -ForegroundColor Yellow
$analysisOutput = flutter analyze --no-fatal-infos lib/ 2>&1 | Select-Object -First 20
$analysisOutput | ForEach-Object { Write-Host $_ -ForegroundColor White }

Write-Host "`n✅ App fix complete!" -ForegroundColor Green
Write-Host ""
Write-Host "🚀 To run the app:" -ForegroundColor Cyan
Write-Host "   flutter run -d <device-id>" -ForegroundColor White
Write-Host ""
Write-Host "📱 To build APK:" -ForegroundColor Cyan
Write-Host "   flutter build apk --debug" -ForegroundColor White
Write-Host ""
Write-Host "🔍 Check console output for screen initialization messages:" -ForegroundColor Cyan
Write-Host "   - 💬 ChatScreen initializing..." -ForegroundColor White
Write-Host "   - 🎤 MeetingsScreen initializing..." -ForegroundColor White
Write-Host "   - 📝 NotesScreen initializing..." -ForegroundColor White
Write-Host "   - ⚙️ SettingsScreen initializing..." -ForegroundColor White