# Setup Script for Marketing Agent POC

Write-Host "Marketing Agent POC - Setup Script" -ForegroundColor Green
Write-Host "====================================`n" -ForegroundColor Green

# Check Python version
Write-Host "Checking Python version..." -ForegroundColor Yellow
$pythonVersion = python --version 2>&1
if ($pythonVersion -match "Python 3\.1[1-9]") {
    Write-Host "✓ Python version OK: $pythonVersion" -ForegroundColor Green
} else {
    Write-Host "✗ Python 3.11+ required. Found: $pythonVersion" -ForegroundColor Red
    exit 1
}

# Check if .env exists
Write-Host "`nChecking environment configuration..." -ForegroundColor Yellow
if (!(Test-Path ".env")) {
    Write-Host "Creating .env from template..." -ForegroundColor Yellow
    Copy-Item ".env.example" ".env"
    Write-Host "⚠ Please edit .env file and add your API keys!" -ForegroundColor Yellow
}

# Create virtual environment
Write-Host "`nCreating virtual environment..." -ForegroundColor Yellow
if (!(Test-Path "venv")) {
    python -m venv venv
    Write-Host "✓ Virtual environment created" -ForegroundColor Green
} else {
    Write-Host "✓ Virtual environment already exists" -ForegroundColor Green
}

# Activate virtual environment
Write-Host "`nActivating virtual environment..." -ForegroundColor Yellow
& "venv\Scripts\Activate.ps1"

# Install dependencies
Write-Host "`nInstalling dependencies..." -ForegroundColor Yellow
pip install -e ".[dev]"

# Start Docker services
Write-Host "`nStarting Docker services (PostgreSQL & Redis)..." -ForegroundColor Yellow
docker-compose up -d

Write-Host "`nWaiting for services to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Run database migrations
Write-Host "`nInitializing database..." -ForegroundColor Yellow
python -c "import asyncio; from src.database import init_db; asyncio.run(init_db())"

Write-Host "`n====================================`n" -ForegroundColor Green
Write-Host "✓ Setup complete!" -ForegroundColor Green
Write-Host "`n🎬 Quick Demo:" -ForegroundColor Cyan
Write-Host "  .\run_demo.ps1                    # Interactive demo with scenarios" -ForegroundColor White
Write-Host "  .\run_demo.ps1 competitive_pressure # Run specific scenario" -ForegroundColor White
Write-Host "  .\run_demo.ps1 --all              # Run all scenarios" -ForegroundColor White
Write-Host "`n⚙️  Full Development:" -ForegroundColor Cyan
Write-Host "1. Edit .env file and add your OpenAI or Anthropic API key" -ForegroundColor White
Write-Host "2. Run the API server: uvicorn src.api.main:app --reload" -ForegroundColor White
Write-Host "3. Or test the agent directly: python -m src.cli.test_agent campaign_123" -ForegroundColor White
Write-Host "4. API docs will be available at: http://localhost:8000/api/docs" -ForegroundColor White
Write-Host "`n📚 Documentation:" -ForegroundColor Cyan
Write-Host "  DEMO_GUIDE.md         # How to present to stakeholders" -ForegroundColor White
Write-Host "  PRESENTATION_GUIDE.md # Talking points and Q&A" -ForegroundColor White
Write-Host "  QUICKSTART.md         # Detailed setup guide`n" -ForegroundColor White
