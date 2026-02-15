# Marketing Agent - AI-Powered Campaign Optimization

> Intelligent reasoning layer that analyzes campaign performance and recommends optimal marketing workflows

## 📋 Overview

This Marketing Agent replaces manual analysis of campaign performance with AI-powered reasoning. Instead of marketing executives manually deciding whether a CPA increase requires creative refresh, audience expansion, or bid adjustment—the agent analyzes multiple data sources, identifies root causes, and recommends specific actions with evidence-based reasoning.

**Example Recommendation:**
```
Campaign: Spring Sale 2026
Recommended Action: Bid Adjustment (+15%)

Reasoning: CPA increased 30% over 3 days. Analysis shows:
- Creative CTR stable (no fatigue)
- Audience near saturation (95% impression share)
- Competitor activity up 40%

Root Cause: Competitive pressure → Recommend bid adjustment
Expected Impact: Restore CPA to $47-49 within 2-3 days
Confidence: 82%
```

## 🎯 Key Features

- **Multi-Source Analysis**: Campaign metrics, creative performance, competitor signals, audience analytics
- **Causal Reasoning**: Identifies root causes, not just symptoms
- **Structured Recommendations**: Specific actions with reasoning, risks, alternatives
- **Human-in-the-Loop**: All recommendations require approval initially
- **Outcome Tracking**: Measures actual impact to improve over time
- **Production-Grade**: Monitoring, evaluation, CI/CD from day one

## 🏗️ Architecture

```
Marketing Dashboard → API Gateway → Agent Workflow → Data Sources
                         ↓              ↓
                   Evaluation    Monitoring
```

**Tech Stack:**
- **Backend**: Python 3.11+, FastAPI
- **Agent**: LangGraph + LangChain
- **LLMs**: OpenAI GPT-4o / Anthropic Claude 3.5
- **Database**: PostgreSQL + Redis
- **Observability**: LangSmith, Prometheus, Grafana
- **Deployment**: Docker Compose (dev), Kubernetes (prod)

## 📖 Documentation

- **[MARKETING_AGENT_IMPLEMENTATION_GUIDE.md](./MARKETING_AGENT_IMPLEMENTATION_GUIDE.md)** - Complete implementation guide (73 pages)
- **[QUICK_START.md](./QUICK_START.md)** - Get started immediately

## 🚀 Quick Start

### Prerequisites

- Python 3.11+
- Docker & Docker Compose
- OpenAI API Key or Anthropic API Key
- Access to marketing data sources (Google Ads, Meta Ads, etc.)

### Setup

```bash
# Clone repository
git clone <repo-url>
cd marketing-agent-workflow

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Set up environment variables
cp .env.example .env
# Edit .env with your API keys

# Start services (PostgreSQL, Redis)
docker-compose up -d

# Run database migrations
alembic upgrade head

# Start development server
uvicorn src.api.main:app --reload
```

### Generate First Recommendation

```bash
# Using CLI
python -m src.cli generate-recommendation --campaign-id "campaign_123"

# Or using API
curl -X POST http://localhost:8000/api/v1/recommendations/analyze \
  -H "Content-Type: application/json" \
  -d '{"campaign_id": "campaign_123"}'
```

## 📊 Success Metrics

**Quality Metrics:**
- Recommendation acceptance rate: Target >70%
- Positive impact when followed: Target >80%
- Agreement with human experts: Target >75%

**Operational Metrics:**
- Latency: <30 seconds per recommendation
- Uptime: 99.5%+
- Cost per recommendation: Optimized and tracked

## 📅 Implementation Timeline

| Phase | Duration | Focus |
|-------|----------|-------|
| **Phase 0** | Week 1-2 | Setup & foundations |
| **Phase 1** | Week 3-4 | Data integration |
| **Phase 2** | Week 5-8 | Core agent MVP |
| **Phase 3** | Week 9-12 | Evaluation framework |
| **Phase 4** | Week 13-16 | Production API & UI |
| **Phase 5** | Week 17-18 | Monitoring & observability |
| **Phase 6** | Week 19-24 | Advanced features |
| **Phase 7** | Month 7+ | Trust building & iteration |

**Note:** Timeline is flexible. Production deployment happens when quality is proven, not on a fixed schedule.

## 🧪 Testing

```bash
# Run unit tests
pytest tests/unit

# Run integration tests
pytest tests/integration

# Run evaluation on golden dataset
python -m evaluation.run_golden_set

# Run promptfoo tests
promptfoo eval
```

## 🔍 Monitoring

**Dashboards:**
- http://localhost:3001 - Grafana (metrics)
- https://smith.langchain.com - LangSmith (LLM traces)
- http://localhost:9090 - Prometheus (raw metrics)

**Key Metrics:**
- Recommendations per day
- Acceptance rate
- p95 latency
- LLM costs
- Error rates

## 📈 Deployment

```bash
# Deploy to staging
kubectl apply -f k8s/staging/

# Deploy to production (requires approval)
kubectl apply -f k8s/production/
```

## 🤝 Contributing

1. Create feature branch: `git checkout -b feature/amazing-improvement`
2. Make changes and add tests
3. Ensure all tests pass and acceptance rate maintained
4. Create PR with evaluation results
5. Get review from team
6. Merge after CI passes

## 🔐 Security

- API keys stored in secrets manager
- Input validation on all endpoints
- Audit trail for all recommendations and decisions
- Rate limiting to prevent abuse

## 📚 Additional Resources

**AI Agent Patterns:**
- [Building Effective Agents - Anthropic](https://www.anthropic.com/research/building-effective-agents)
- [LangGraph Documentation](https://docs.langchain.com/oss/python/langgraph/overview)

**Evaluation:**
- [LangSmith Guide](https://docs.langchain.com/langsmith/evaluation)
- [promptfoo Docs](https://www.promptfoo.dev/docs/intro/)

## 🐛 Troubleshooting

**Agent generates low-quality recommendations?**
- Check evaluation results in LangSmith
- Review prompt versions in `prompts/` directory
- Compare with golden dataset cases

**High latency?**
- Check data collector health
- Review cache hit rates
- Consider model optimization

**Low acceptance rate?**
- Review feedback from marketing team
- Analyze rejected recommendations for patterns
- Iterate on prompts based on specific failure modes

## 📞 Support

- **Slack**: #marketing-agent
- **Email**: genai-team@company.com
- **Documentation**: [Full Implementation Guide](./MARKETING_AGENT_IMPLEMENTATION_GUIDE.md)

## 📄 License

[Your License Here]

---

**Built with** ❤️ **by the GenAI Engineering Team**

Last updated: February 11, 2026
