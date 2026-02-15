# Marketing Agent POC - Quick Start Guide

## 🚀 Quick Start (5 minutes)

### Prerequisites
- Python 3.11+
- Docker Desktop (for PostgreSQL & Redis)
- OpenAI API key OR Anthropic API key

### Step 1: Setup Environment

**Windows:**
```powershell
# Run the automated setup script
.\setup.ps1
```

**Manual Setup (all platforms):**
```bash
# 1. Create virtual environment
python -m venv venv

# 2. Activate (Windows)
venv\Scripts\activate
# Or (Mac/Linux)
source venv/bin/activate

# 3. Install dependencies
pip install -e .

# 4. Copy environment template
cp .env.example .env

# 5. Start services
docker-compose up -d

# 6. Initialize database
python -c "import asyncio; from src.database import init_db; asyncio.run(init_db())"
```

### Step 2: Configure API Keys

Edit `.env` file and add your API key:

```bash
# For OpenAI
OPENAI_API_KEY=sk-...your-key-here...

# Or for Anthropic
ANTHROPIC_API_KEY=sk-ant-...your-key-here...
DEFAULT_LLM_PROVIDER=anthropic
DEFAULT_MODEL=claude-3-5-sonnet-20241022
```

### Step 3: Test the Agent

**Option A: CLI Test** (Fastest way to see it work)
```bash
python -m src.cli.test_agent campaign_12345
```

This will:
1. ✅ Collect mock campaign data (CPA, CTR, spend, etc.)
2. ✅ Gather creative performance metrics
3. ✅ Analyze competitor signals
4. ✅ Use LLM to analyze root causes
5. ✅ Generate actionable recommendation
6. ✅ Display results in terminal

**Option B: API Server**
```bash
# Start the API server
uvicorn src.api.main:app --reload

# Server will start at http://localhost:8000
# API docs at http://localhost:8000/api/docs
```

Then test with curl:
```bash
# Analyze a campaign
curl -X POST http://localhost:8000/api/v1/recommendations/analyze \
  -H "Content-Type: application/json" \
  -d '{"campaign_id": "campaign_12345"}'

# Get recommendation details
curl http://localhost:8000/api/v1/recommendations/{recommendation_id}

# Record decision
curl -X POST http://localhost:8000/api/v1/recommendations/{recommendation_id}/decision \
  -H "Content-Type: application/json" \
  -d '{"decision": "approved", "feedback": "Good analysis"}'
```

---

## 📊 What Happens During Analysis

The agent follows this workflow:

```
1. COLLECT CONTEXT (parallel, ~2-5s)
   ├─ Campaign Metrics: CPA, CTR, spend, conversions
   ├─ Creative Performance: fatigue detection, engagement
   └─ Competitor Signals: market activity, auction pressure

2. ANALYZE SIGNALS (LLM, ~5-10s)
   ├─ Identify metric changes and trends
   ├─ Correlate signals across data sources
   └─ Determine root cause hypothesis

3. GENERATE RECOMMENDATION (LLM, ~5-10s)
   ├─ Select appropriate workflow
   ├─ Provide specific actions
   └─ Assess risks and expected impact

4. CRITIQUE (LLM, ~3-5s)
   ├─ Check logical consistency
   └─ Validate recommendation quality

Total: ~15-30 seconds
```

---

## 🎯 Example Output

```
📊 CAMPAIGN CONTEXT:
  Campaign: Campaign 2345
  CPA: $52.30 (+28.5%)
  CTR: 2.85% (-5.2%)
  Spend: $4,832.00

🔍 SIGNAL ANALYSIS:
  Root Cause: Increased competitive pressure
  Confidence: 82%

💡 RECOMMENDATION:
  Workflow: Bid Adjustment
  Risk Level: MEDIUM
  Confidence: 78%

  Reasoning:
  CPA increased 28.5% over 7 days while creative CTR remained stable at 2.85%. 
  Competitor analysis shows 3 new market entrants and 25% average bid increase. 
  This indicates auction environment has become more competitive rather than 
  internal performance degradation.

  Expected Impact:
  Restore CPA to $47-50 range within 2-3 days by increasing bids 15-20%.
```

---

## 🧪 Running Tests

```bash
# Run all tests
pytest tests/ -v

# Run specific test
pytest tests/unit/test_data_collectors.py -v

# Run with coverage
pytest tests/ --cov=src --cov-report=html
```

---

## 🏗️ Project Structure

```
marketing-agent-workflow/
├── src/
│   ├── agent/              # LangGraph workflow & prompts
│   │   ├── workflow.py     # Main agent orchestration
│   │   ├── prompts.py      # LLM prompts
│   │   └── models.py       # Pydantic models
│   ├── api/                # FastAPI endpoints
│   │   ├── main.py         # API server
│   │   ├── routers/        # Endpoint routers
│   │   └── schemas.py      # Request/response schemas
│   ├── data_collectors/    # Data source integrations
│   │   ├── campaign_collector.py
│   │   ├── creative_collector.py
│   │   ├── competitor_collector.py
│   │   └── context_builder.py
│   ├── database/           # SQLAlchemy models & migrations
│   │   ├── models.py
│   │   ├── connection.py
│   │   └── migrations/
│   ├── config/             # Configuration management
│   ├── cli/                # Command-line tools
│   └── utils/              # Shared utilities
├── tests/                  # Test suite
├── docs/                   # Documentation
├── docker-compose.yml      # Local services
├── pyproject.toml          # Dependencies
└── .env                    # Environment variables (create from .env.example)
```

---

## 🔑 Key Features Implemented

✅ **Data Collection**
- Campaign metrics (impressions, clicks, CPA, spend)
- Creative performance & fatigue detection
- Competitor intelligence signals
- Parallel collection for speed

✅ **Agent Workflow**
- LangGraph-based state machine
- Signal correlation & root cause analysis
- Structured recommendation generation
- Self-critique for quality assurance

✅ **API Server**
- RESTful endpoints
- Async database operations
- Auto-generated API docs
- Human-in-the-loop decision recording

✅ **Production Ready**
- Docker Compose for services
- Database migrations
- Structured logging
- Error handling
- Type safety with Pydantic

---

## 🐛 Troubleshooting

### Issue: ModuleNotFoundError
```bash
# Make sure you installed in editable mode
pip install -e .
```

### Issue: Database connection error
```bash
# Check if PostgreSQL is running
docker-compose ps

# Restart services
docker-compose restart postgres
```

### Issue: LLM API errors
- Check `.env` file has correct API key
- Verify API key has credits/is active
- Check internet connection

### Issue: Import errors
```bash
# Reinstall dependencies
pip install -e ".[dev]" --force-reinstall
```

---

## 📈 Next Steps

### Immediate (POC Enhancement)
1. Add real API integrations (Google Ads, Meta Ads)
2. Build simple frontend for reviewing recommendations
3. Add more sophisticated prompt engineering
4. Implement evaluation framework

### Short Term (Production)
1. Add authentication & authorization
2. Implement rate limiting
3. Add more comprehensive monitoring
4. Create golden dataset for evaluation
5. Deploy to staging environment

### Long Term (Scale)
1. Support multiple campaigns in batch
2. Automated workflow triggering
3. Outcome tracking & feedback loop
4. A/B test prompt versions
5. Graduated autonomy for high-confidence recs

---

## 💡 Tips for Development

1. **Iterating on Prompts**: Edit `src/agent/prompts.py` and restart API
2. **Testing Changes**: Use CLI tool for faster iteration
3. **Debugging**: Check logs in terminal or database `agent_executions` table
4. **Mock Data**: Collectors return random data - modify in `_generate_mock_*` methods
5. **Database Reset**: `docker-compose down -v && docker-compose up -d`

---

## 📚 Further Reading

- [Full Implementation Guide](docs/MARKETING_AGENT_IMPLEMENTATION_GUIDE.md)
- [LangGraph Documentation](https://python.langchain.com/docs/langgraph)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Anthropic Agent Patterns](https://docs.anthropic.com/en/docs/agents)

---

## 🆘 Getting Help

If you encounter issues:
1. Check the troubleshooting section above
2. Review logs in terminal
3. Check database for stored data
4. Verify all services are running: `docker-compose ps`

---

**Ready to analyze your first campaign!** 🚀

```bash
python -m src.cli.test_agent campaign_12345
```
