# Project Structure - Marketing Agent

Complete directory structure for the Marketing Agent implementation.

```
marketing-agent-workflow/
│
├── README.md                                    # Project overview
├── MARKETING_AGENT_IMPLEMENTATION_GUIDE.md      # Complete implementation guide
├── QUICK_START.md                               # 30-minute getting started
├── IMPLEMENTATION_CHECKLIST.md                  # Progress tracking
├── PROJECT_STRUCTURE.md                         # This file
│
├── .env.example                                 # Environment variables template
├── .env                                         # Actual secrets (gitignored)
├── .gitignore                                   # Git ignore rules
├── .dockerignore                                # Docker ignore rules
│
├── requirements.txt                             # Python dependencies
├── requirements-dev.txt                         # Dev/test dependencies
├── pyproject.toml                               # Python project config
├── setup.py                                     # Package setup
│
├── docker-compose.yml                           # Local development services
├── Dockerfile                                   # Application container
│
├── alembic.ini                                  # Database migrations config
├── pytest.ini                                   # Test configuration
├── mypy.ini                                     # Type checking config
├── .ruff.toml                                   # Linting config
│
├── src/                                         # Main application code
│   ├── __init__.py
│   │
│   ├── agent/                                   # Core agent logic
│   │   ├── __init__.py
│   │   ├── workflow.py                          # LangGraph workflow definition
│   │   ├── nodes.py                             # Workflow node implementations
│   │   ├── state.py                             # Agent state definitions
│   │   ├── models.py                            # Pydantic models
│   │   ├── prompts.py                           # Prompt templates (code)
│   │   ├── simple_agent.py                      # Simple MVP agent
│   │   └── cost_optimizer.py                    # Cost management
│   │
│   ├── data_collectors/                         # Data collection layer
│   │   ├── __init__.py
│   │   ├── base.py                              # Base collector class
│   │   ├── campaign_collector.py                # Campaign metrics
│   │   ├── creative_collector.py                # Creative performance
│   │   ├── competitor_collector.py              # Competitor signals
│   │   ├── audience_collector.py                # Audience analytics
│   │   ├── historical_analyzer.py               # Historical patterns
│   │   └── context_builder.py                   # Parallel collection orchestrator
│   │
│   ├── workflows/                               # Workflow execution
│   │   ├── __init__.py
│   │   ├── executor.py                          # Workflow execution engine
│   │   ├── handlers/                            # Workflow-specific handlers
│   │   │   ├── __init__.py
│   │   │   ├── bid_adjustment.py
│   │   │   ├── creative_refresh.py
│   │   │   ├── audience_expansion.py
│   │   │   └── campaign_pause.py
│   │   └── integrations/                        # External platform integrations
│   │       ├── __init__.py
│   │       ├── google_ads.py
│   │       └── meta_ads.py
│   │
│   ├── evaluation/                              # Evaluation framework
│   │   ├── __init__.py
│   │   ├── evaluator.py                         # Core evaluation logic
│   │   ├── metrics.py                           # Evaluation metrics
│   │   ├── llm_judge.py                         # LLM-as-judge
│   │   ├── golden_dataset.py                    # Golden dataset management
│   │   ├── simple_eval.py                       # Simple evaluation script
│   │   ├── run_golden_set.py                    # Golden set evaluation runner
│   │   └── check_threshold.py                   # Quality threshold checker
│   │
│   ├── api/                                     # REST API
│   │   ├── __init__.py
│   │   ├── main.py                              # FastAPI app
│   │   ├── dependencies.py                      # Dependency injection
│   │   ├── middleware.py                        # Custom middleware
│   │   ├── routers/                             # API route handlers
│   │   │   ├── __init__.py
│   │   │   ├── recommendations.py               # Recommendation endpoints
│   │   │   ├── campaigns.py                     # Campaign endpoints
│   │   │   ├── evaluations.py                   # Evaluation endpoints
│   │   │   └── health.py                        # Health check endpoints
│   │   └── schemas/                             # API request/response schemas
│   │       ├── __init__.py
│   │       ├── recommendations.py
│   │       └── common.py
│   │
│   ├── database/                                # Database layer
│   │   ├── __init__.py
│   │   ├── models.py                            # SQLModel/SQLAlchemy models
│   │   ├── connection.py                        # DB connection management
│   │   ├── repositories/                        # Repository pattern
│   │   │   ├── __init__.py
│   │   │   ├── base.py
│   │   │   ├── recommendations.py
│   │   │   └── evaluations.py
│   │   └── migrations/                          # Alembic migrations
│   │       ├── env.py
│   │       └── versions/
│   │           └── 001_initial_schema.py
│   │
│   ├── monitoring/                              # Observability
│   │   ├── __init__.py
│   │   ├── metrics.py                           # Prometheus metrics
│   │   ├── logging.py                           # Structured logging setup
│   │   ├── tracing.py                           # LangSmith tracing
│   │   └── cost_tracker.py                      # Cost tracking
│   │
│   ├── cli/                                     # Command-line interface
│   │   ├── __init__.py
│   │   ├── main.py                              # CLI entry point
│   │   ├── commands/
│   │   │   ├── __init__.py
│   │   │   ├── generate.py                      # Generate recommendation
│   │   │   ├── evaluate.py                      # Run evaluation
│   │   │   └── analyze.py                       # Analyze results
│   │   └── utils.py
│   │
│   ├── config/                                  # Configuration
│   │   ├── __init__.py
│   │   ├── settings.py                          # Pydantic settings
│   │   └── constants.py                         # Application constants
│   │
│   └── utils/                                   # Shared utilities
│       ├── __init__.py
│       ├── cache.py                             # Redis caching helpers
│       ├── retry.py                             # Retry logic
│       ├── validation.py                        # Input validation
│       └── formatting.py                        # Output formatting
│
├── tests/                                       # Test suite
│   ├── __init__.py
│   ├── conftest.py                              # Pytest fixtures
│   │
│   ├── unit/                                    # Unit tests
│   │   ├── __init__.py
│   │   ├── test_agent/
│   │   │   ├── test_workflow.py
│   │   │   ├── test_simple_agent.py
│   │   │   └── test_models.py
│   │   ├── test_data_collectors/
│   │   │   ├── test_base.py
│   │   │   ├── test_campaign_collector.py
│   │   │   └── test_context_builder.py
│   │   ├── test_evaluation/
│   │   │   ├── test_metrics.py
│   │   │   └── test_evaluator.py
│   │   └── test_api/
│   │       └── test_recommendations.py
│   │
│   ├── integration/                             # Integration tests
│   │   ├── __init__.py
│   │   ├── test_end_to_end.py                   # Full workflow tests
│   │   ├── test_api_integration.py              # API integration tests
│   │   └── test_data_collection.py              # Real API tests
│   │
│   ├── smoke/                                   # Smoke tests
│   │   ├── __init__.py
│   │   └── test_smoke.py                        # Basic health checks
│   │
│   └── fixtures/                                # Test data
│       ├── campaign_data.json
│       ├── creative_data.json
│       └── recommendations.json
│
├── test_data/                                   # Test datasets
│   ├── golden_cases.json                        # Golden dataset
│   ├── competitive_pressure_case.json
│   ├── creative_fatigue_case.json
│   └── README.md                                # Dataset documentation
│
├── prompts/                                     # Version-controlled prompts
│   ├── README.md                                # Prompt versioning guide
│   ├── signal_analysis/
│   │   ├── v1.yaml
│   │   ├── v2.yaml
│   │   └── latest.yaml -> v2.yaml
│   ├── recommendation_generation/
│   │   ├── v1.yaml
│   │   └── latest.yaml -> v1.yaml
│   └── critique/
│       ├── v1.yaml
│       └── latest.yaml -> v1.yaml
│
├── evaluation/                                  # Evaluation artifacts
│   ├── results/                                 # Evaluation results
│   │   ├── 2026-02-11_golden_set.json
│   │   └── 2026-02-11_llm_judge.json
│   ├── reports/                                 # Evaluation reports
│   │   └── monthly_report_2026-02.md
│   └── datasets/                                # Versioned datasets
│       ├── golden_v1.json
│       └── golden_v2.json
│
├── frontend/                                    # React frontend
│   ├── package.json
│   ├── tsconfig.json
│   ├── vite.config.ts
│   ├── public/
│   └── src/
│       ├── main.tsx
│       ├── App.tsx
│       ├── components/
│       │   ├── RecommendationCard.tsx
│       │   ├── ApprovalDialog.tsx
│       │   └── MetricsChart.tsx
│       ├── pages/
│       │   ├── Dashboard.tsx
│       │   ├── RecommendationDetail.tsx
│       │   └── History.tsx
│       ├── api/
│       │   └── client.ts
│       └── styles/
│           └── main.css
│
├── infrastructure/                              # Infrastructure as code
│   ├── docker/
│   │   ├── Dockerfile.backend
│   │   ├── Dockerfile.frontend
│   │   └── docker-compose.prod.yml
│   │
│   ├── k8s/                                     # Kubernetes manifests
│   │   ├── base/                                # Base configuration
│   │   │   ├── deployment.yaml
│   │   │   ├── service.yaml
│   │   │   ├── ingress.yaml
│   │   │   └── configmap.yaml
│   │   ├── staging/                             # Staging overrides
│   │   │   └── kustomization.yaml
│   │   ├── production/                          # Production overrides
│   │   │   ├── kustomization.yaml
│   │   │   └── hpa.yaml
│   │   └── canary/                              # Canary deployment
│   │       └── deployment.yaml
│   │
│   └── terraform/                               # Infrastructure provisioning
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── monitoring/                                  # Monitoring configuration
│   ├── prometheus.yml                           # Prometheus config
│   ├── alerting_rules.yml                       # Alert rules
│   ├── grafana/
│   │   ├── dashboards/
│   │   │   ├── business_overview.json
│   │   │   ├── quality_metrics.json
│   │   │   └── system_health.json
│   │   └── provisioning/
│   │       ├── dashboards.yml
│   │       └── datasources.yml
│   └── sentry/
│       └── config.yaml
│
├── scripts/                                     # Utility scripts
│   ├── setup_dev_env.sh                         # Development setup
│   ├── run_evaluation.sh                        # Run full evaluation
│   ├── deploy.sh                                # Deployment script
│   ├── backup_db.sh                             # Database backup
│   └── generate_test_data.py                    # Test data generator
│
├── docs/                                        # Additional documentation
│   ├── architecture/
│   │   ├── ADR-001-use-langgraph.md             # Architecture Decision Records
│   │   ├── ADR-002-evaluation-strategy.md
│   │   └── system-design.md
│   ├── api/
│   │   └── endpoints.md                         # API documentation
│   ├── guides/
│   │   ├── prompt-engineering.md
│   │   ├── adding-workflows.md
│   │   └── troubleshooting.md
│   ├── runbooks/
│   │   ├── incident-response.md
│   │   ├── deployment-checklist.md
│   │   └── common-issues.md
│   └── images/
│       ├── architecture-diagram.png
│       └── workflow-diagram.png
│
├── notebooks/                                   # Jupyter notebooks
│   ├── data_exploration.ipynb
│   ├── prompt_testing.ipynb
│   └── performance_analysis.ipynb
│
├── .github/                                     # GitHub configuration
│   ├── workflows/
│   │   ├── test.yml                             # Test workflow
│   │   ├── eval.yml                             # Evaluation workflow
│   │   ├── deploy.yml                           # Deployment workflow
│   │   └── quality-check.yml                    # Code quality
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   └── feature_request.md
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── dependabot.yml                           # Dependency updates
│
├── .vscode/                                     # VS Code configuration
│   ├── settings.json
│   ├── launch.json
│   └── extensions.json
│
└── logs/                                        # Application logs (gitignored)
    ├── app.log
    └── error.log
```

## Important Files

### Configuration Files

| File | Purpose |
|------|---------|
| `.env` | Environment variables (API keys, secrets) |
| `requirements.txt` | Python dependencies |
| `docker-compose.yml` | Local development services |
| `pyproject.toml` | Python project metadata |
| `alembic.ini` | Database migration settings |

### Core Application

| File | Purpose |
|------|---------|
| `src/agent/workflow.py` | Main agent workflow definition |
| `src/agent/prompts.py` | System prompts |
| `src/api/main.py` | FastAPI application entry point |
| `src/data_collectors/context_builder.py` | Data collection orchestration |

### Quality & Testing

| File | Purpose |
|------|---------|
| `tests/unit/` | Unit tests |
| `evaluation/` | Evaluation artifacts |
| `prompts/` | Version-controlled prompts |
| `test_data/golden_cases.json` | Golden test dataset |

### Infrastructure

| File | Purpose |
|------|---------|
| `infrastructure/k8s/` | Kubernetes manifests |
| `monitoring/prometheus.yml` | Monitoring configuration |
| `.github/workflows/` | CI/CD pipelines |

## Quick Navigation

**Starting development?** → `QUICK_START.md`  
**Need architecture details?** → `MARKETING_AGENT_IMPLEMENTATION_GUIDE.md`  
**Track progress?** → `IMPLEMENTATION_CHECKLIST.md`  
**Add a new workflow?** → `docs/guides/adding-workflows.md`  
**Debugging issues?** → `docs/runbooks/troubleshooting.md`

## Getting Started

1. Clone repository
2. Follow `QUICK_START.md` for setup
3. Refer to `PROJECT_STRUCTURE.md` (this file) for navigation
4. Use `IMPLEMENTATION_CHECKLIST.md` to track progress

## Directory Naming Conventions

- **Folders**: `snake_case`
- **Python files**: `snake_case.py`
- **Test files**: `test_*.py`
- **Config files**: `lowercase` or `kebab-case`
- **Documentation**: `UPPERCASE.md` or `kebab-case.md`

## Code Organization Principles

1. **Separation of Concerns**: Agent logic separate from API, data collection, evaluation
2. **Dependency Injection**: Use FastAPI's dependency system
3. **Type Hints**: All functions typed
4. **Documentation**: Docstrings on all public functions
5. **Testing**: Unit tests alongside implementation

## Next Steps

After understanding the structure:
1. Set up development environment (`QUICK_START.md`)
2. Start with Phase 0 tasks (`IMPLEMENTATION_CHECKLIST.md`)
3. Read full implementation guide (`MARKETING_AGENT_IMPLEMENTATION_GUIDE.md`)

---

**Last Updated:** February 11, 2026  
**Maintained By:** GenAI Engineering Team
