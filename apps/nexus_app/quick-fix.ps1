# Quick Fix for Java Path Issue
# Run this before deploying: .\quick-fix.ps1

# Set the correct Java path based on your system
$env:JAVA_HOME = "${env:ProgramFiles}\Android\Android Studio1\jbr"
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"

Write-Host "✅ Java environment fixed for this session" -ForegroundColor Green
Write-Host "JAVA_HOME = $env:JAVA_HOME" -ForegroundColor Blue

# Test Java
try {
    $javaVersion = & java -version 2>&1 | Select-Object -First 1
    Write-Host "✅ Java working: $javaVersion" -ForegroundColor Green
}
catch {
    Write-Host "❌ Java test failed - check the path" -ForegroundColor Red
    exit 1
}

Write-Host "Now run: .\deploy-remote.ps1 45301FDAP003JE" -ForegroundColor Cyan