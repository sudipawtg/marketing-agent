# Marketing Agent - Start Backend with Logs Visible

Write-Host "Marketing Agent - Starting Backend API" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

# Check Python
try {
    $pythonVersion = python --version 2>&1
    Write-Host "[OK] Python detected: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Python not found" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Starting services..." -ForegroundColor Yellow
Write-Host ""

# Check if Docker is available and start it
Write-Host ""
Write-Host "SQLite database will be created automatically" -ForegroundColor Green
Write-Host "No Docker required for this demo!" -ForegroundColor Green
Write-Host ""
Write-Host "2. Starting FastAPI backend with logs visible..." -ForegroundColor Cyan
Write-Host ""
Write-Host "========================================" -ForegroundColor Gray
Write-Host "BACKEND LOGS (watch agent reasoning here)" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Gray
Write-Host ""
Write-Host "Open another terminal and run: cd frontend && npm run dev" -ForegroundColor Yellow
Write-Host "Then open: http://localhost:3000" -ForegroundColor Yellow
Write-Host ""
Write-Host "Press Ctrl+C to stop backend" -ForegroundColor Gray
Write-Host ""

# Activate virtual environment and start backend
$venvPython = Join-Path $PSScriptRoot ".venv\Scripts\python.exe"
$venvUvicorn = Join-Path $PSScriptRoot ".venv\Scripts\uvicorn.exe"

if (Test-Path $venvUvicorn) {
    # Use uvicorn from virtual environment
    try {
        & $venvUvicorn src.api.main:app --reload --port 8000
    } finally {
        Write-Host ""
        Write-Host "Backend stopped" -ForegroundColor Green
    }
} else {
    Write-Host "[ERROR] Virtual environment not found. Run: pip install -e ." -ForegroundColor Red
    exit 1
}
