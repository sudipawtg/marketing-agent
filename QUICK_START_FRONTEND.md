# 🚀 Quick Start - Full Stack Demo

Get the complete Marketing Agent POC running with frontend in under 2 minutes!

## Prerequisites

- ✅ Python 3.11+ installed
- ✅ Node.js 18+ installed  
- ✅ Docker Desktop running
- ✅ OpenAI or Anthropic API key

## Step 1: Backend Setup (60 seconds)

```powershell
# Clone and navigate to project
cd marketing-agent-workflow

# Install Python dependencies
pip install -e .

# Configure environment
cp .env.example .env
# Edit .env and add your API key:
# OPENAI_API_KEY=sk-your-key-here

# Start database services
docker-compose up -d

# Initialize database
python -c "import asyncio; from src.database import init_db; asyncio.run(init_db())"

# Start backend API
uvicorn src.api.main:app --reload
```

Backend ready at: http://localhost:8000

## Step 2: Frontend Setup (30 seconds)

```powershell
# New terminal window
cd frontend

# Install dependencies (first time only)
npm install

# Start dev server
npm run dev
```

Frontend ready at: http://localhost:3000

## Step 3: Demo! (2 minutes)

1. Open http://localhost:3000
2. Click "Analyze Campaign" on any scenario
3. Watch the AI reason through the problem
4. Review the full analysis breakdown
5. Click "Approve" or "Reject"
6. View decision history

## One-Command Launch 🎯

Or use the automated launcher:

```powershell
.\start_demo.ps1
```

This starts:
- ✅ PostgreSQL & Redis (Docker)
- ✅ FastAPI backend (port 8000)
- ✅ React frontend (port 3000)

## Troubleshooting

**"Module not found" errors:**
```bash
pip install -e .
cd frontend && npm install
```

**"Connection refused" errors:**
```bash
# Check backend is running
curl http://localhost:8000/health

# Verify Docker services
docker-compose ps
```

**"API key not configured" warnings:**
```bash
# Edit .env file
OPENAI_API_KEY=sk-your-actual-key
# or
ANTHROPIC_API_KEY=sk-ant-your-key
```

## What to Show

### Key Features
1. **AI Reasoning** - Full explanation with root cause analysis
2. **Multi-Source Context** - Campaign, creative, competitor data
3. **Human-in-the-Loop** - Approve/reject with feedback
4. **Decision Tracking** - Full audit trail

### Demo Scenarios
- 🎯 Competitive Pressure → Tests external factor reasoning
- 🎨 Creative Fatigue → Tests internal factor reasoning  
- ✨ Winning Campaign → Tests restraint (no action needed)
- 🔍 Multi-Signal → Tests prioritization

## Next Steps

- 📖 Read [FULL_STACK_DEMO.md](FULL_STACK_DEMO.md) for detailed walkthrough
- 🎤 Review [PRESENTATION_GUIDE.md](PRESENTATION_GUIDE.md) for talking points
- 📊 Check [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md) for feature details

---

**Demo Ready in 2 Minutes Total! 🎉**
