# Marketing Agent POC

A production-grade Marketing Reasoning Agent with **Human-in-the-Loop approval interface** that analyzes campaign performance and recommends workflow actions.

## 🎯 What It Does

The agent replaces manual decision-making by marketing executives with AI-powered reasoning:

- **Analyzes** campaign performance, creative metrics, and competitor activity
- **Reasons** about root causes (creative fatigue vs competitive pressure vs audience saturation)
- **Recommends** specific workflow actions (Bid Adjustment, Creative Refresh, Audience Expansion, etc.)
- **Explains** its reasoning with confidence scores and risk assessment
- **Requires human approval** for every recommendation (Human-in-the-Loop)

**Example Output:**
```
CPA increased 32% over 7 days. Analysis shows:
- Creative CTR stable at 2.8% (no fatigue detected)
- 3 new competitors entered market
- Auction competition score: 87.5/100
- Competitor bids increased 28%

Root Cause: Increased competitive pressure in auction environment
Recommended Action: Bid Adjustment (+15-20%), NOT creative refresh
Confidence: 82% | Risk: MEDIUM

[Approve] [Reject] ← Human Decision Required
```

## 🎨 Visual Demo (Frontend + Backend)

The POC includes a **complete web interface** showcasing AI reasoning with human oversight:

```bash
# One-command launch (starts everything)
.\start_demo.ps1

# Or start manually:
# Terminal 1 - Backend:
uvicorn src.api.main:app --reload

# Terminal 2 - Frontend:
cd frontend && npm run dev
```

**Access at:**
- 🎨 **Frontend:** http://localhost:3000 (Visual demo interface)
- 🔧 **Backend API:** http://localhost:8000/docs (API documentation)

**Frontend Features:**
- 5 demo scenarios with visual selection
- Full AI reasoning visualization
- **Human-in-the-Loop approval interface** (Approve/Reject buttons)
- Campaign context display (metrics + creative health + market signals)
- Decision history tracking with feedback

See [POC_SUMMARY.md](POC_SUMMARY.md) for complete feature walkthrough.

## 🚀 Quick Demo (2 minutes)

See the agent in action with pre-built scenarios:

```bash
# 1. Install dependencies
pip install -e .

# 2. Add your API key to .env
cp .env.example .env
# Edit .env: OPENAI_API_KEY=sk-your-key

# 3. Run interactive demo
python -m src.demo.run_demo
```

**Demo scenarios showcase:**
- 🎯 Competitive Pressure (external factors)
- 🎨 Creative Fatigue (internal issues)
- 👥 Audience Saturation (need expansion)
- 🏆 Winning Campaign (no action needed)
- 🔀 Complex Multi-Signal Problems

See [DEMO_GUIDE.md](DEMO_GUIDE.md) for presentation tips and script.

## 📋 Full Setup

### Prerequisites

- Python 3.11+
- Docker Desktop (for PostgreSQL & Redis)
- OpenAI API key or Anthropic API key

### Installation

**Windows:**
```powershell
.\setup.ps1
```

**Manual Setup:**
```bash
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -e ".[dev]"
cp .env.example .env
# Edit .env with your API keys
docker-compose up -d
python -c "import asyncio; from src.database import init_db; asyncio.run(init_db())"
```

### Usage

**Interactive Demo:**
```bash
python -m src.demo.run_demo
```

**CLI Analysis:**
```bash
python -m src.cli.test_agent campaign_12345
```

**API Server:**
```bash
uvicorn src.api.main:app --reload
# API docs at http://localhost:8000/api/docs
```

**Test with cURL:**
```bash
curl -X POST http://localhost:8000/api/v1/recommendations/analyze \
  -H "Content-Type: application/json" \
  -d '{"campaign_id": "campaign_12345"}'
```

**🎨 Full Stack Demo (Frontend + Backend):**
```bash
# Option 1: One-command launch (starts everything)
.\start_demo.ps1

# Option 2: Start separately
# Terminal 1 - Backend API:
uvicorn src.api.main:app --reload

# Terminal 2 - Frontend:
.\start_frontend.ps1
# Or: cd frontend && npm install && npm run dev

# Access at:
# 🎨 Frontend: http://localhost:3000
# 🔧 Backend API: http://localhost:8000/docs
```

The frontend provides:
- **5 Demo Scenarios** with visual selection
- **AI Reasoning Visualization** showing full analysis
- **Human-in-the-Loop Approval** with approve/reject buttons
- **Campaign Context Display** (metrics, creative health, competitor signals)
- **Decision History** to track all recommendations

See [frontend/README.md](frontend/README.md) for detailed frontend documentation.

## Architecture

```
src/
├── agent/           # LangGraph agent workflow
├── api/             # FastAPI endpoints
├── config/          # Configuration management
├── data_collectors/ # Data source integrations
├── database/        # SQLAlchemy models & migrations
├── demo/            # 🎬 Demo scenarios & runner
├── evaluation/      # Testing & evaluation framework
└── utils/           # Shared utilities

frontend/
├── src/
│   ├── api/         # API client & types
│   ├── components/  # React components
│   └── App.tsx      # Main application
└── package.json     # Node.js dependencies
```

## 🌟 Key Features

✅ **Multi-Source Context Collection**
- Campaign metrics (CPA, CTR, spend, conversions)
- Creative performance & fatigue detection
- Competitor intelligence signals
- Parallel data collection (~2-5s)

✅ **LLM-Powered Reasoning**
- Signal correlation & root cause analysis
- Causal reasoning (not just correlation)
- Confidence scoring & risk assessment
- Self-critique for quality assurance

✅ **Production-Ready Architecture**
- LangGraph state machine workflow
- FastAPI async endpoints
- PostgreSQL + Redis
- End-to-end CI/CD pipeline
- Kubernetes deployment manifests

✅ **AI Operations (AI Ops)**
- Golden dataset evaluation framework
- LangSmith distributed tracing
- Prometheus metrics & Grafana dashboards
- Automated CI/CD evaluation workflow
- Custom evaluators (relevance, accuracy, safety)
- Quality gates with configurable thresholds
- Structured logging & error handling
- Type safety with Pydantic

✅ **Human-in-the-Loop**
- All recommendations require approval initially
- Feedback collection for continuous improvement
- Graduated autonomy as trust builds

## 🎯 What Makes This Special

**Problem:** Existing workflows can execute actions (generate ad copy, adjust bids) but can't reason about WHICH action to take in WHICH context.

**Solution:** Agent that:
1. Collects multi-source context
2. Correlates signals to identify root causes
3. Recommends specific, actionable workflows
4. Explains reasoning transparently

**Value:**
- ⏱️ **Time Saved:** Minutes vs hours of manual analysis
- 🎯 **Better Decisions:** Data-driven, correlates multiple signals
- 📈 **Scalable:** One agent handles unlimited campaigns
- 🔒 **Safe:** Human approval, gradual autonomy

## 📊 Agent Workflow

```
1. COLLECT CONTEXT (2-5s)
   ├─ Campaign Metrics
   ├─ Creative Performance
   └─ Competitor Signals

2. ANALYZE SIGNALS (5-10s)
   ├─ Correlate data
   ├─ Identify root cause
   └─ Assess confidence

3. GENERATE RECOMMENDATION (5-10s)
   ├─ Select workflow
   ├─ Specific actions
   └─ Risk assessment

4. SELF-CRITIQUE (3-5s)
   └─ Quality check

Total: ~15-30 seconds
```

## 🧪 Development

**Run tests:**
```bash
pytest tests/ -v
```

**Test data collectors:**
```bash
pytest tests/unit/test_data_collectors.py -v
```

**Check types:**
```bash
mypy src/
```

**Format code:**
```bash
black src/ tests/
ruff check src/ tests/
```

## 📚 Documentation

**Core Documentation:**
- [POC Summary](POC_SUMMARY.md) - Complete feature walkthrough
- [Demo Guide](DEMO_GUIDE.md) - Presentation tips and scripts
- [Frontend README](frontend/README.md) - UI documentation

**AI Operations (AI Ops):**
- [AI Ops Summary](docs/AIOPS_SUMMARY.md) - Complete AI Ops overview
- [AI Observability Guide](docs/AI_OBSERVABILITY.md) - Monitoring & tracing setup
- [Evaluation Framework](src/evaluation/README.md) - Testing & quality metrics

**Infrastructure & Deployment:**
- [CI/CD Pipeline](docs/CI_CD_PIPELINE.md) - Complete pipeline documentation
- [CI/CD Quick Start](docs/CICD_QUICKSTART.md) - Getting started guide
- [Architecture](docs/architecture/) - System design documentation

**Development:**
- [API Documentation](docs/api/) - API reference and examples
- [Project Structure](docs/PROJECT_STRUCTURE.md) - Codebase organization

## 📚 Documentation

- **[DEMO_GUIDE.md](DEMO_GUIDE.md)** - How to demo to stakeholders
- **[QUICKSTART.md](QUICKSTART.md)** - Detailed setup guide
- **[docs/MARKETING_AGENT_IMPLEMENTATION_GUIDE.md](docs/MARKETING_AGENT_IMPLEMENTATION_GUIDE.md)** - Full implementation details

## 🎬 Demo for Stakeholders

Perfect for showing the POC:

```bash
# Interactive demo with beautiful terminal UI
python -m src.demo.run_demo

# Or run specific scenario
python -m src.demo.run_demo competitive_pressure

# Run all scenarios
python -m src.demo.run_demo --all
```

The demo includes:
- 5 pre-built scenarios showing different reasoning patterns
- Color-coded output with key metrics
- Agent's reasoning and recommendation
- Expected vs actual workflow selection

See [DEMO_GUIDE.md](DEMO_GUIDE.md) for presentation script and tips.

## 🚢 What's Next

**Immediate (POC → Production):**
1. ✅ Core agent workflow - DONE
2. ✅ Demo scenarios - DONE
3. ✅ CI/CD pipeline - DONE
4. ✅ Evaluation framework - DONE
5. ✅ Monitoring & observability - DONE
6. ⏳ Integrate real campaign APIs (Google Ads, Meta)
7. ⏳ Build approval UI for marketing team
8. ⏳ Deploy to staging

**Production Foundations:** ✅ Complete
- ✅ CI/CD pipeline with automated testing
- ✅ Evaluation framework (golden datasets, custom evaluators)
- ✅ Monitoring & observability (LangSmith, Prometheus, Grafana)
- ⏳ Outcome tracking & feedback loop

**Trust Building (months 1-6):**
- Shadow mode: Compare agent vs human decisions
- Weekly feedback sessions with marketing team
- Iterate on prompts based on failures
- Establish baseline acceptance rate (target: >70%)

**Graduated Autonomy (months 6+):**
- Auto-approve high-confidence, low-risk recommendations
- Reduce oversight as patterns prove reliable
- Scale to more campaigns and workflows

## 🤝 Production Philosophy

We're not holding to fixed timelines - production GenAI rarely follows a neat schedule. What matters:

✅ **Systematic Progress:** Evaluation frameworks, monitoring, reliability
✅ **Building Trust:** Reliable recommendations, clear reasoning
✅ **Quality First:** Deploy when proven, not when calendars say so

**Realistic Timeline:**
- Months 1-3: Foundations & evaluation
- Months 4-6: Production deployment (when quality proven)
- Months 6+: Optimization & graduated autonomy
- Next application identified based on real learnings

## 🆘 Troubleshooting

**Module not found errors:**
```bash
pip install -e .
```

**Database connection issues:**
```bash
docker-compose restart postgres
```

**LLM API errors:**
- Check `.env` has valid API key
- Verify key has credits
- Check internet connection

**Demo not working:**
```bash
# Install demo dependencies
pip install -e .
# Should include 'rich' package for terminal UI
```
