# Run Demo - Quick Launcher
# Usage: .\run_demo.ps1 [scenario_name]
# Examples:
#   .\run_demo.ps1                    # Interactive mode
#   .\run_demo.ps1 competitive_pressure
#   .\run_demo.ps1 --all              # Run all scenarios

Write-Host "`n🤖 Marketing Agent Demo Launcher`n" -ForegroundColor Cyan

# Check if virtual environment is activated
if (-not $env:VIRTUAL_ENV) {
    Write-Host "⚠ Virtual environment not activated. Activating..." -ForegroundColor Yellow
    & "venv\Scripts\Activate.ps1"
}

# Check if API key is set
$envFile = Get-Content .env -ErrorAction SilentlyContinue
if (-not $envFile) {
    Write-Host "❌ .env file not found. Creating from template..." -ForegroundColor Red
    Copy-Item ".env.example" ".env"
    Write-Host "⚠ Please edit .env and add your OpenAI or Anthropic API key!" -ForegroundColor Yellow
    Write-Host "   Then run this script again.`n" -ForegroundColor Yellow
    exit 1
}

$hasApiKey = $envFile | Where-Object { $_ -match "^(OPENAI_API_KEY|ANTHROPIC_API_KEY)=sk-" }
if (-not $hasApiKey) {
    Write-Host "⚠ WARNING: No API key found in .env file" -ForegroundColor Yellow
    Write-Host "  Demo will run with mock data only (no LLM reasoning)" -ForegroundColor Yellow
    Write-Host "  Add OPENAI_API_KEY or ANTHROPIC_API_KEY to .env for full demo`n" -ForegroundColor Yellow
    Start-Sleep -Seconds 2
}

# Run the demo
Write-Host "🚀 Starting demo...`n" -ForegroundColor Green

if ($args.Count -gt 0) {
    python -m src.demo.run_demo $args[0]
} else {
    python -m src.demo.run_demo
}

Write-Host "`n✨ Demo complete!`n" -ForegroundColor Green
