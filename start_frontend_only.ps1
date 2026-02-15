# Marketing Agent - Frontend Only

Write-Host "Marketing Agent - Starting Frontend" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# Check Node.js
try {
    $nodeVersion = node --version 2>&1
    Write-Host "[OK] Node.js detected: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Node.js not found" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Make sure backend is running at: http://localhost:8000" -ForegroundColor Yellow
Write-Host ""

# Navigate to frontend
$frontendPath = Join-Path $PSScriptRoot "frontend"
Set-Location $frontendPath

# Install dependencies if needed
if (-not (Test-Path "node_modules")) {
    Write-Host "Installing dependencies..." -ForegroundColor Yellow
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Failed to install dependencies" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "Starting frontend dev server..." -ForegroundColor Cyan
Write-Host ""
Write-Host "Frontend will open at: http://localhost:3000" -ForegroundColor Green
Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
Write-Host ""

npm run dev
