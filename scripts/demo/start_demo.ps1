#!/usr/bin/env pwsh

# Marketing Agent - Full Stack Demo Launcher

Write-Host "Marketing Agent - Full Stack Demo" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Check Python
try {
    $pythonVersion = python --version 2>&1
    Write-Host "[OK] Python detected: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Python not found" -ForegroundColor Red
    exit 1
}

# Check Node.js
try {
    $nodeVersion = node --version 2>&1
    Write-Host "[OK] Node.js detected: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Node.js not found" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Starting services..." -ForegroundColor Yellow
Write-Host ""

Write-Host "Using SQLite database (no Docker required)" -ForegroundColor Green
Write-Host ""

# Start Backend in background
Write-Host "1. Starting FastAPI backend..." -ForegroundColor Cyan

$venvUvicorn = Join-Path $PSScriptRoot ".venv\Scripts\uvicorn.exe"
if (-not (Test-Path $venvUvicorn)) {
    Write-Host "[ERROR] Virtual environment not found. Installing dependencies..." -ForegroundColor Red
    $venvPython = Join-Path $PSScriptRoot ".venv\Scripts\python.exe"
    if (Test-Path $venvPython) {
        & $venvPython -m pip install -e .
    } else {
        Write-Host "[ERROR] Please create virtual environment first: python -m venv .venv" -ForegroundColor Red
        exit 1
    }
}

$backendJob = Start-Job -ScriptBlock {
    Set-Location $using:PSScriptRoot
    $uvicorn = Join-Path $using:PSScriptRoot ".venv\Scripts\uvicorn.exe"
    & $uvicorn src.api.main:app --reload --port 8000
}
Start-Sleep -Seconds 5

# Check backend health
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8000/health" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
    Write-Host "   [OK] Backend ready at http://localhost:8000" -ForegroundColor Green
} catch {
    Write-Host "   [WARN] Backend starting (check logs if issues persist)" -ForegroundColor Yellow
}

# Start Frontend
Write-Host "2. Starting React frontend..." -ForegroundColor Cyan
$frontendPath = Join-Path $PSScriptRoot "frontend"
Set-Location $frontendPath

if (-not (Test-Path "node_modules")) {
    Write-Host "   Installing frontend dependencies..." -ForegroundColor Yellow
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Failed to install frontend dependencies" -ForegroundColor Red
        Stop-Job $backendJob -ErrorAction SilentlyContinue
        Remove-Job $backendJob -ErrorAction SilentlyContinue
        Set-Location $PSScriptRoot
        docker-compose down
        exit 1
    }
}

Write-Host ""
Write-Host "Demo ready!" -ForegroundColor Green
Write-Host ""
Write-Host "Frontend:    http://localhost:3000" -ForegroundColor Cyan
Write-Host "Backend API: http://localhost:8000" -ForegroundColor Cyan
Write-Host "API Docs:    http://localhost:8000/docs" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press Ctrl+C to stop all services" -ForegroundColor Gray
Write-Host ""

# Start frontend (this will block)
try {
    npm run dev
} finally {
    # Cleanup on exit
    Write-Host ""
    Write-Host "Stopping services..." -ForegroundColor Yellow
    Stop-Job $backendJob -ErrorAction SilentlyContinue
    Remove-Job $backendJob -ErrorAction SilentlyContinue
    Set-Location $PSScriptRoot
    Write-Host "All services stopped" -ForegroundColor Green
}
