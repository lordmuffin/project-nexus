# Quick Deploy with AndroidManifest Fix
# This script pulls the latest fix and deploys to your device

param(
    [Parameter(Mandatory=$true)]
    [string]$DeviceId
)

Write-Host "🔧 Deploying with AndroidManifest.xml fix..." -ForegroundColor Cyan
Write-Host "Device: $DeviceId" -ForegroundColor Blue
Write-Host ""

try {
    # Step 1: Pull latest changes with the fix
    Write-Host "[STEP 1] Pulling latest changes..." -ForegroundColor Blue
    git pull origin main
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Git pull failed" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Latest changes pulled" -ForegroundColor Green

    # Step 2: Fix Java environment
    Write-Host "[STEP 2] Setting up Java environment..." -ForegroundColor Blue
    $env:JAVA_HOME = "${env:ProgramFiles}\Android\Android Studio1\jbr"
    $env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
    Write-Host "✅ Java environment configured" -ForegroundColor Green

    # Step 3: Clean everything
    Write-Host "[STEP 3] Cleaning project..." -ForegroundColor Blue
    flutter clean | Out-Null
    if (Test-Path "build") { Remove-Item -Recurse -Force "build" -ErrorAction SilentlyContinue }
    if (Test-Path ".dart_tool") { Remove-Item -Recurse -Force ".dart_tool" -ErrorAction SilentlyContinue }
    Write-Host "✅ Project cleaned" -ForegroundColor Green

    # Step 4: Get dependencies
    Write-Host "[STEP 4] Getting fresh dependencies..." -ForegroundColor Blue
    flutter pub get | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to get dependencies" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Dependencies updated" -ForegroundColor Green

    # Step 5: Deploy
    Write-Host "[STEP 5] Deploying to device $DeviceId..." -ForegroundColor Blue
    Write-Host "This may take a few minutes..." -ForegroundColor Yellow
    
    flutter run --debug --device-id="$DeviceId"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "🎉 Deployment successful!" -ForegroundColor Green
        Write-Host "App is running on device $DeviceId" -ForegroundColor Green
    } else {
        Write-Host "❌ Deployment failed" -ForegroundColor Red
        Write-Host "Check the error output above for details" -ForegroundColor Yellow
        exit 1
    }
}
catch {
    Write-Host "❌ Error occurred: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}