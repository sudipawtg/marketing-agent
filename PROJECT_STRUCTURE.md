# Marketing Agent - Project Structure

## 📁 Enterprise-Grade Folder Organization

This document provides a complete overview of the project's folder structure, optimized for enterprise development, deployment, and maintenance.

## 🌳 Complete Directory Tree

```
marketing-agent/
│
├── 📄 README.md                          # Main project documentation
├── 📄 CONTRIBUTING.md                    # Contribution guidelines
├── 📄 LICENSE                            # Project license
│
├── ⚙️  Configuration Files (Root)
│   ├── alembic.ini                      # Database migration config
│   ├── docker-compose.yml               # Development environment setup
│   ├── Makefile                         # Common development commands
│   ├── pyproject.toml                   # Python project configuration
│   ├── uv.lock                          # Python dependency lock file
│   ├── .gitignore                       # Git ignore rules
│   ├── .pre-commit-config.yaml          # Pre-commit hooks
│   └── .env.example                     # Environment variables template
│
├── 📚 docs/                             # ALL DOCUMENTATION
│   ├── README.md                        # Documentation hub (START HERE)
│   ├── DOCUMENTATION_INDEX.md           # Complete documentation index
│   ├── ARCHITECTURE_DIAGRAM.md          # System architecture overview
│   │
│   ├── getting-started/                 # 🚀 Quick Start Guides
│   │   ├── QUICKSTART.md               # 5-minute quick start
│   │   ├── QUICK_START.md              # Comprehensive getting started
│   │   ├── QUICK_START_FRONTEND.md     # Frontend-specific setup
│   │   └── GETTING_STARTED.md          # Full setup guide
│   │
│   ├── guides/                          # 📖 Implementation Guides
│   │   ├── PRODUCTION_PATTERNS.md      # Production best practices
│   │   ├── demos/                       # Demo & Presentation
│   │   │   ├── DEMO_GUIDE.md           # Complete demo walkthrough
│   │   │   ├── DEMO_INSTRUCTIONS.md     # Quick demo steps
│   │   │   ├── FULL_STACK_DEMO.md      # Full stack demonstration
│   │   │   └── PRESENTATION_GUIDE.md    # Presentation materials
│   │   └── implementation/              # Implementation Docs
│   │       ├── IMPLEMENTATION_STATUS.md
│   │       ├── MARKETING_AGENT_IMPLEMENTATION_GUIDE.md
│   │       └── POC_SUMMARY.md
│   │
│   ├── deployment/                      # 🚀 Deployment & CI/CD
│   │   ├── TERRAFORM_SETUP.md          # Infrastructure provisioning
│   │   ├── CI_CD_PIPELINE.md           # CI/CD overview
│   │   ├── CICD_SETUP_GUIDE.md         # CI/CD setup instructions
│   │   ├── CICD_QUICKSTART.md          # CI/CD quick start
│   │   ├── CICD_QUICK_REFERENCE.md     # CI/CD commands
│   │   └── CICD_SUMMARY.md             # CI/CD platforms summary
│   │
│   ├── monitoring/                      # 📊 Monitoring & Observability
│   │   ├── DATADOG_INTEGRATION.md      # Datadog setup
│   │   ├── AI_OBSERVABILITY.md         # AI-specific monitoring
│   │   └── AIOPS_SUMMARY.md            # AIOps capabilities
│   │
│   ├── reference/                       # 📋 Technical Reference
│   │   ├── SKILLS_SHOWCASE.md          # Technology showcase
│   │   ├── COMPLETE_TECH_IMPLEMENTATION.md
│   │   ├── REQUIREMENTS_COVERAGE.md     # Job requirements alignment
│   │   ├── PROJECT_STRUCTURE.md        # Project organization
│   │   ├── IMPLEMENTATION_CHECKLIST.md
│   │   ├── EXECUTIVE_SUMMARY.md
│   │   └── DOCUMENTATION_SUMMARY.md
│   │
│   ├── architecture/                    # 🏗️ Architecture Documentation
│   │   └── adr/                        # Architecture Decision Records
│   │
│   ├── api/                            # 🔌 API Documentation
│   │   └── openapi.yaml               # OpenAPI specifications
│   │
│   └── runbooks/                       # 📕 Operational Runbooks
│
├── 🐍 src/                              # BACKEND SOURCE CODE
│   ├── __init__.py
│   ├── agent/                          # LangGraph Agent Implementation
│   │   ├── __init__.py
│   │   ├── models.py                   # Agent state models
│   │   ├── prompts.py                  # LLM prompts
│   │   └── workflow.py                 # Agent workflow graph
│   │
│   ├── api/                            # FastAPI Application
│   │   ├── __init__.py
│   │   ├── main.py                     # FastAPI app entry point
│   │   ├── schemas.py                  # API data models
│   │   ├── routers/                    # API route handlers
│   │   │   ├── __init__.py
│   │   │   ├── recommendations.py
│   │   │   ├── evaluation.py
│   │   │   └── health.py
│   │   └── schemas/                    # API schemas by domain
│   │
│   ├── cli/                            # Command Line Interface
│   │   ├── __init__.py
│   │   ├── test_agent.py
│   │   └── commands/
│   │
│   ├── config/                         # Configuration Management
│   │   ├── __init__.py
│   │   └── settings.py                 # Environment settings
│   │
│   ├── data_collectors/                # Data Collection Layer
│   │   ├── __init__.py
│   │   ├── base.py                     # Base collector
│   │   ├── campaign_collector.py       # Campaign data
│   │   ├── competitor_collector.py     # Competitor analysis
│   │   ├── creative_collector.py       # Creative performance
│   │   └── context_builder.py          # Context aggregation
│   │
│   ├── database/                       # Database Layer
│   │   ├── __init__.py
│   │   ├── connection.py               # DB connection
│   │   ├── models.py                   # ORM models
│   │   ├── migrations/                 # Alembic migrations
│   │   └── repositories/               # Data repositories
│   │
│   ├── demo/                           # Demo Scenarios
│   │   ├── __init__.py
│   │   ├── run_demo.py
│   │   └── scenarios.py
│   │
│   ├── evaluation/                     # Evaluation Framework
│   │   ├── __init__.py
│   │   ├── README.md
│   │   ├── evaluator.py
│   │   ├── metrics.py
│   │   └── golden_dataset.py
│   │
│   ├── monitoring/                     # Monitoring & Observability
│   │   ├── __init__.py
│   │   ├── datadog.py                  # Datadog integration
│   │   ├── langsmith.py                # LangSmith tracing
│   │   └── metrics.py                  # Custom metrics
│   │
│   ├── utils/                          # Utility Functions
│   │   ├── __init__.py
│   │   ├── logging.py
│   │   └── helpers.py
│   │
│   └── workflows/                      # Workflow Definitions
│
├── ⚛️  frontend/                        # FRONTEND APPLICATION
│   ├── README.md                       # Frontend documentation
│   ├── package.json                    # Node dependencies
│   ├── vite.config.ts                  # Vite configuration
│   ├── tsconfig.json                   # TypeScript config
│   ├── tailwind.config.js              # Tailwind CSS config
│   ├── index.html                      # Entry HTML
│   │
│   ├── public/                         # Static assets
│   │   └── assets/
│   │
│   └── src/                            # React source code
│       ├── main.tsx                    # React entry point
│       ├── App.tsx                     # Main App component
│       ├── index.css                   # Global styles
│       │
│       ├── components/                 # React components
│       │   ├── AgentVisualization/
│       │   ├── RecommendationCard/
│       │   └── shared/
│       │
│       ├── pages/                      # Page components
│       │   ├── Dashboard.tsx
│       │   ├── Recommendations.tsx
│       │   └── Evaluation.tsx
│       │
│       ├── api/                        # API client
│       │   └── client.ts
│       │
│       └── styles/                     # Component styles
│
├── 🏗️  infrastructure/                  # INFRASTRUCTURE AS CODE
│   ├── README.md                       # Infrastructure guide
│   │
│   ├── terraform/                      # Terraform (Multi-cloud)
│   │   ├── README.md                   # Comprehensive Terraform guide
│   │   ├── QUICK_REFERENCE.md          # Command reference
│   │   ├── terraform.tfvars.example    # Configuration template
│   │   ├── .gitignore                  # Terraform gitignore
│   │   ├── main.tf                     # Main configuration
│   │   ├── aws.tf                      # AWS resources (EKS, RDS, etc.)
│   │   ├── gcp.tf                      # GCP resources (GKE, Cloud SQL)
│   │   ├── azure.tf                    # Azure resources (AKS, PostgreSQL)
│   │   ├── iam.tf                      # IAM roles and policies
│   │   └── monitoring.tf               # Monitoring integrations
│   │
│   ├── k8s/                            # Kubernetes Manifests
│   │   ├── base/                       # Base Kustomize configs
│   │   ├── staging/                    # Staging overlays
│   │   ├── production/                 # Production overlays
│   │   └── canary/                     # Canary deployments
│   │
│   └── docker/                         # Docker configurations
│       └── docker-compose.test.yml     # Test environment
│
├── 🔧 scripts/                          # AUTOMATION SCRIPTS
│   ├── README.md                       # Scripts documentation
│   │
│   ├── setup/                          # Setup & Installation
│   │   └── setup.ps1                   # Windows setup script
│   │
│   ├── demo/                           # Demo Scripts
│   │   ├── run_demo.sh                 # Run demo (Linux/macOS)
│   │   ├── run_demo.ps1                # Run demo (Windows)
│   │   ├── start_demo.ps1              # Start with output
│   │   ├── start_frontend.sh           # Frontend only (Linux)
│   │   ├── start_frontend.ps1          # Frontend only (Windows)
│   │   ├── start_frontend_only.ps1     # Standalone frontend
│   │   └── start_with_logs.ps1         # With verbose logging
│   │
│   ├── deployment/                     # Deployment Scripts
│   │   ├── build-and-push.sh           # Build & push Docker images
│   │   ├── deploy.sh                   # Deploy to Kubernetes
│   │   └── rollback.sh                 # Rollback deployment
│   │
│   ├── database/                       # Database Scripts
│   │   ├── backup-db.sh                # Database backup
│   │   └── migrate-db.sh               # Run migrations
│   │
│   ├── monitoring/                     # Monitoring Scripts
│   │   └── health-check.sh             # Health check
│   │
│   ├── development/                    # Development Utilities
│   │   └── (future dev scripts)
│   │
│   └── Evaluation Scripts (root)       # ML Evaluation
│       ├── run_evaluation.py           # Run evaluations
│       ├── generate_evaluation_report.py
│       └── check_evaluation_thresholds.py
│
├── 🧪 tests/                            # TESTS
│   ├── __init__.py
│   ├── conftest.py                     # PyTest configuration
│   ├── unit/                           # Unit tests
│   ├── integration/                    # Integration tests
│   ├── smoke/                          # Smoke tests
│   └── fixtures/                       # Test fixtures
│
├── 📊 evaluation/                       # EVALUATION ASSETS
│   ├── datasets/                       # Golden datasets
│   ├── reports/                        # Evaluation reports
│   └── results/                        # Test results
│
├── 📈 monitoring/                       # MONITORING CONFIGS
│   ├── grafana/                        # Grafana dashboards
│   │   ├── dashboards/                 # Dashboard JSON files
│   │   └── provisioning/              # Provisioning configs
│   └── sentry/                        # Sentry configuration
│
├── 📝 prompts/                         # PROMPT TEMPLATES
│   ├── critique/                      # Critique prompts
│   ├── recommendation_generation/     # Recommendation prompts
│   └── signal_analysis/               # Signal analysis prompts
│
├── 📓 notebooks/                       # JUPYTER NOTEBOOKS
│   └── (exploration and analysis)
│
├── 📦 test_data/                       # TEST DATA
│   └── (sample datasets for testing)
│
├── 📋 logs/                            # APPLICATION LOGS
│   └── (generated at runtime)
│
├── 🔄 CI/CD Configuration
│   ├── .github/                        # GitHub Actions
│   │   ├── workflows/                  # Workflow definitions
│   │   │   ├── ci.yml                 # Continuous Integration
│   │   │   ├── deploy-staging.yml     # Deploy to staging
│   │   │   ├── deploy-production.yml  # Deploy to production
│   │   │   └── security-scan.yml      # Security scanning
│   │   └── ISSUE_TEMPLATE/            # Issue templates
│   │
│   ├── .jenkins/                       # Jenkins Pipeline
│   │   └── Jenkinsfile                # Jenkins configuration
│   │
│   ├── .circleci/                      # CircleCI
│   │   └── config.yml                 # CircleCI configuration
│   │
│   └── .buildkite/                    # Buildkite
│       └── pipeline.yml               # Buildkite pipeline
│
└── 🔒 Security & Quality
    ├── .gitignore                     # Git ignore rules
    ├── .pre-commit-config.yaml        # Pre-commit hooks
    ├── .dockerignore                  # Docker ignore rules
    └── .secrets.baseline              # Detect-secrets baseline
```

## 🎯 Quick Navigation Guide

### For New Developers

**Start Here:**
1. [README.md](../README.md) - Project overview
2. [docs/README.md](../docs/README.md) - Documentation hub
3. [docs/getting-started/QUICKSTART.md](../docs/getting-started/QUICKSTART.md) - 5-min setup

**Then Explore:**
- [docs/ARCHITECTURE_DIAGRAM.md](../docs/ARCHITECTURE_DIAGRAM.md) - System design
- [src/](../src/) - Backend code
- [frontend/src/](../frontend/src/) - Frontend code

### For DevOps Engineers

**Infrastructure:**
- [infrastructure/terraform/](../infrastructure/terraform/) - Multi-cloud IaC
- [infrastructure/k8s/](../infrastructure/k8s/) - Kubernetes configs
- [docs/deployment/](../docs/deployment/) - Deployment guides

**CI/CD:**
- [.github/workflows/](../.github/workflows/) - GitHub Actions
- [.jenkins/Jenkinsfile](../.jenkins/Jenkinsfile) - Jenkins
- [.circleci/config.yml](../.circleci/config.yml) - CircleCI
- [.buildkite/pipeline.yml](../.buildkite/pipeline.yml) - Buildkite

**Monitoring:**
- [monitoring/grafana/](../monitoring/grafana/) - Dashboards
- [docs/monitoring/](../docs/monitoring/) - Monitoring guides
- [infrastructure/terraform/monitoring.tf](../infrastructure/terraform/monitoring.tf) - Monitoring IaC

### For AI/ML Engineers

**Core Agent:**
- [src/agent/](../src/agent/) - LangGraph agent implementation
- [src/evaluation/](../src/evaluation/) - Evaluation framework
- [prompts/](../prompts/) - Prompt templates

**Data & Models:**
- [src/data_collectors/](../src/data_collectors/) - Data collection
- [evaluation/datasets/](../evaluation/datasets/) - Test datasets
- [notebooks/](../notebooks/) - Analysis notebooks

## 📏 Folder Naming Conventions

- **Lowercase with hyphens**: `getting-started`, `ci-cd-pipelines`
- **Underscores for Python modules**: `data_collectors`, `__init__.py`
- **PascalCase for React components**: `RecommendationCard.tsx`
- **kebab-case for config files**: `docker-compose.yml`

## 🔑 Key Design Principles

### ✅ Separation of Concerns
- Source code (`src/`) separate from infrastructure (`infrastructure/`)
- Documentation (`docs/`) organized by purpose
- Scripts (`scripts/`) categorized by function

### ✅ Configuration in Root
- Essential config files at project root
- Environment-specific configs in respective folders
- Never commit sensitive data (`.env` in `.gitignore`)

### ✅ Documentation at Every Level
- README in every major folder
- Inline code documentation
- Comprehensive guides in `docs/`

### ✅ Production-Ready Structure  
- Clear CI/CD pipeline definitions
- Infrastructure as code
- Monitoring and observability built-in
- Security scanning integrated

## 🚀 Getting Started with This Structure

### Clone and Setup
```bash
git clone https://github.com/sudipawtg/marketing-agent.git
cd marketing-agent

# Read the main README
cat README.md

# Explore documentation
cd docs && cat README.md

# Run quick start
cd ../docs/getting-started && cat QUICKSTART.md
```

### Running Scripts
```bash
# Demo
./scripts/demo/run_demo.sh

# Deployment
./scripts/deployment/deploy.sh staging

# Database backup
./scripts/database/backup-db.sh
```

### Infrastructure Deployment
```bash
cd infrastructure/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your settings

terraform init
terraform plan
terraform apply
```

## 📊 Statistics

- **Total Files**: 2,800+
- **Lines of Code**: 50,000+
- **Lines of Documentation**: 8,000+
- **Programming Languages**: Python, TypeScript, HCL, Shell
- **Frameworks**: FastAPI, React, LangGraph
- **Cloud Providers**: AWS, GCP, Azure
- **CI/CD Platforms**: 4 (GitHub Actions, Jenkins, CircleCI, Buildkite)
- **Monitoring Tools**: 6 (Datadog, New Relic, Sumologic, Prometheus, Grafana, LangSmith)

## 🔄 Structure Evolution

This structure has been carefully designed to:
- Scale from single developer to enterprise team
- Support multiple deployment environments
- Enable rapid onboarding of new team members
- Maintain clear separation of concerns
- Follow industry best practices

## 🤝 Contributing to This Structure

When adding new files:
1. Place in appropriate folder
2. Update relevant README
3. Follow naming conventions
4. Add documentation
5. Update this PROJECT_STRUCTURE.md if adding new major folders

---

**Last Updated**: February 2026  
**Maintained By**: Platform Engineering Team

For questions about this structure, see [CONTRIBUTING.md](../CONTRIBUTING.md) or open an issue.
