# 🚀 Marketing Agent - Production AI Engineering Platform

[![Python](https://img.shields.io/badge/Python-3.11+-blue.svg)](https://www.python.org/downloads/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.100+-green.svg)](https://fastapi.tiangolo.com/)
[![Terraform](https://img.shields.io/badge/Terraform-1.5+-purple.svg)](https://www.terraform.io/)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-Multi--Platform-orange.svg)](#-cicd-platforms)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A **production-grade GenAI platform** demonstrating enterprise-level AI engineering with agentic workflows, multi-cloud infrastructure, and comprehensive observability. Built to showcase **every technology** in modern AI Engineering.

---

## 🎯 What Makes This Special

This isn't just another AI agent. This is a **complete production system** showcasing:

### AI Engineering Excellence
- ✅ **Agentic Architecture** - LangGraph workflows with state management
- ✅ **Production MLOps** - Golden datasets, automated evaluation, CI/CD integration
- ✅ **Observability First** - LangSmith tracing, Prometheus metrics, Grafana dashboards
- ✅ **Cost Engineering** - Token tracking, model selection, caching strategies
- ✅ **Evaluation as a Service** - 5 custom evaluators, automated regression testing

### Infrastructure & DevOps
- ✅ **Multi-Cloud IaC** - Terraform for AWS, GCP, Azure (2000+ lines)
- ✅ **4 CI/CD Platforms** - GitHub Actions, Jenkins, CircleCI, Buildkite
- ✅ **Enterprise Monitoring** - Datadog, New Relic, Sumologic, Prometheus, Grafana
- ✅ **Kubernetes Production** - Multi-environment (staging, production, canary)
- ✅ **Security First** - PII redaction, vulnerability scanning, secrets management

> 💡 **15,000+ lines of production code | 8,000+ lines of documentation | 85%+ test coverage**

---

## 💼 Technology Stack

###  Core Technologies
| Category | Technologies |
|----------|-------------|
| **Languages** | Python 3.11+ (async, type hints), TypeScript, Bash |
| **AI/ML** | LangChain, LangGraph, LangSmith, OpenAI GPT-4 |
| **Backend** | FastAPI, Pydantic, SQLAlchemy, Alembic |
| **Frontend** | React 18, TypeScript, Vite, TailwindCSS |
| **Databases** | PostgreSQL 15, Redis 7 |
| **Containers** | Docker (multi-stage), Docker Compose |

### ☁️ Cloud & Infrastructure
| Category | Technologies |
|----------|-------------|
| **Cloud Providers** | AWS (EKS, ECR, RDS, ElastiCache), GCP (GKE, Cloud SQL), Azure (AKS, ACR) |
| **IaC** | **Terraform** (2000+ lines), Kustomize, Helm |
| **Orchestration** | Kubernetes 1.28+, kubectl, K9s |
| **Networking** | VPC, Security Groups, Load Balancers, Ingress |

### 🔄 CI/CD Platforms
| Platform | Features | Status |
|----------|----------|--------|
| **GitHub Actions** | 6 workflows (CI, CD, Evaluation, Security, PR, Release) | ✅ |
| **Jenkins** | Kubernetes-native, parallel execution | ✅ |
| **CircleCI** | Orb-based, test parallelism (4x) | ✅ |
| **Buildkite** | Dynamic pipelines, GPU support | ✅ |

### 📊 Monitoring & Observability
| Tool | Purpose | Integration |
|------|---------|-------------|
| **Datadog** | APM, distributed tracing, logs, custom metrics | ✅ Full |
| **New Relic** | Infrastructure monitoring, APM | ✅ Full |
| **Sumologic** | Log aggregation, analysis | ✅ Full |
| **Prometheus** | Metrics collection, alerting | ✅ Full |
| **Grafana** | Custom dashboards (9 panels) | ✅ Full |
| **LangSmith** | LLM execution tracing | ✅ Full |

---

## 🤖 What It Does (The Business Problem)

The agent replaces manual marketing decision-making with AI-powered reasoning:

### Real-World Use Case
```
📊 Input: Campaign performance drops 32%
🤖 Analysis: 
   - Creative CTR stable (no Creative Fatigue)
   - 3 new competitors entered market
   - Competitor bids increased 28%
   
🎯 Recommendation: Increase bids 15-20% (NOT Creative refresh)
📈 Confidence: 82% | Risk: MEDIUM
🚦 Action Required: [Approve] [Reject] ← Human-in-the-Loop
```

### Key Capabilities
1. **Campaign Analysis** - Performance metrics, trend detection
2. **Competitor Intelligence** - Market positioning, bid strategies
3. **Creative Performance** - Engagement, fatigue detection
4. **Root Cause Analysis** - Multi-signal reasoning
5. **Actionable Recommendations** - Specific workflow actions
6. **Human Approval** - Every decision requires oversight

---

## 📊 Key Features

### 1. Production Agentic System
```python
# Multi-agent architecture with LangGraph
from langgraph.graph import StateGraph

workflow = StateGraph(MarketingState)
workflow.add_node("campaign_collector", collect_campaign_data)
workflow.add_node("competitor_analyzer", analyze_competitors)
workflow.add_node("creative_evaluator", evaluate_creatives)
workflow.add_node("context_builder", build_context)
workflow.add_node("decision_maker", make_recommendation)
```

**Features:**
- State machine orchestration
- Function calling with structured outputs (Pydantic)
- Context window management (intelligent chunking)
- Error recovery with retry logic
- Multi-model support (GPT-4, GPT-3.5, Claude)

### 2. AI Evaluation Framework

**Golden Datasets:**
- 8 comprehensive test cases
- Campaign optimization scenarios
- Creative performance tests
- Expected outputs with confidence thresholds

**5 Custom Evaluators:**
1. **Relevance** - Does output address the question?
2. **Accuracy** - Are facts and numbers correct?
3. **Completeness** - Are all key points covered?
4. **Coherence** - Is the reasoning logical?
5. **Safety** - Does it avoid harmful recommendations?

**CI/CD Integration:**
```yaml
# Automated evaluation in every PR
- name: AI Evaluation
  run: |
    python scripts/run_evaluation.py \
      --dataset evaluation/datasets/golden/*.json
    python scripts/check_evaluation_thresholds.py
    # Fails build if quality degrades
```

### 3. Complete Observability

**What We Track:**
- 📊 **LLM Calls** - Every invocation with model, tokens, cost
- ⏱️ **Latency** - P50, P95, P99 for each endpoint
- 💰 **Cost** - Per-request and daily spend tracking
- 🔍 **Traces** - Full execution chains in LangSmith
- 📝 **Logs** - Structured JSON with trace IDs
- 🚨 **Errors** - Categorized with automatic alerts

**Grafana Dashboard (9 Panels):**
1. Request Rate (requests/second)
2. Average Latency
3. Token Usage (prompt + completion)
4. Cost per Request ($)
5. Model Distribution
6. Evaluation Scores (trend)
7. Error Rate by Type
8. Cache Hit Ratio
9. Agent Success Rate

### 4. Multi-Cloud Infrastructure (Terraform)

**AWS Deployment:**
```bash
terraform apply -var="cloud_provider=aws"
# Creates: EKS cluster, RDS PostgreSQL, ElastiCache Redis
# Network: VPC with public/private subnets, NAT Gateway
# Security: IAM roles, security groups, encryption
```

**GCP Deployment:**
```bash
terraform apply -var="cloud_provider=gcp"
# Creates: GKE cluster, Cloud SQL, Memorystore
```

**Azure Deployment:**
```bash
terraform apply -var="cloud_provider=azure"
# Creates: AKS cluster, PostgreSQL Flexible Server, Redis Cache
```

**Infrastructure Includes:**
- Kubernetes cluster (3+ nodes, autoscaling)
- Managed databases (PostgreSQL 15)
- Cache layer (Redis 7)
- Container registry (ECR/GCR/ACR)
- Load balancers and ingress
- Monitoring agent deployments
- Secrets management

---

## 🚀 Quick Start (Choose Your Path)

### Option 1: Demo the AI Agent (5 minutes)
```bash
# 1. Install dependencies
pip install -e .

# 2. Add API key to .env
cp .env.example .env
echo "OPENAI_API_KEY=sk-your-key" >> .env

# 3. Run demo with UI
./scripts/demo/run_demo.sh
# Opens http://localhost:3000

# Or CLI demo
python -m src.demo.run_demo
```

### Option 2: Deploy Full Stack Locally (15 minutes)
```bash
# Start all services with Docker Compose
docker-compose up

# Includes: Backend, Frontend, PostgreSQL, Redis, Prometheus, Grafana
# Access:
# - Frontend: http://localhost:3000
# - Backend API: http://localhost:8000/docs
# - Grafana: http://localhost:3001 (admin/admin)
```

### Option 3: Deploy to Cloud (Production)

**Using Terraform:**
```bash
cd infrastructure/terraform

# AWS
terraform init
terraform apply -var="cloud_provider=aws" \
  -var-file="environments/production.tfvars"

# Get kubectl config
aws eks update-kubeconfig --name marketing-agent-cluster

# Deploy application
cd ../k8s/production
kustomize build . | kubectl apply -f -
```

**Using CI/CD:**
```bash
# GitHub Actions (automatic on push to main)
git push origin main

# Jenkins
jenkins-cli build marketing-agent-deploy

# CircleCI (automatic)
# Configured via .circleci/config.yml

# Buildkite (automatic)
# Configured via .buildkite/pipeline.yml
```

---

## 📚 Comprehensive Documentation

### 🎓 Getting Started
| Document | Purpose | Time |
|----------|---------|------|
| [**SKILLS_SHOWCASE.md**](docs/reference/SKILLS_SHOWCASE.md) | **⭐ START HERE** - Complete overview | 20 min |
| [GETTING_STARTED.md](docs/getting-started/GETTING_STARTED.md) | Choose your path | 5 min |
| [POC_SUMMARY.md](docs/guides/implementation/POC_SUMMARY.md) | Feature walkthrough | 15 min |
| [DEMO_GUIDE.md](docs/guides/demos/DEMO_GUIDE.md) | Presentation script | 10 min |

### 🏗️ Infrastructure & Deployment
| Document | Purpose | Difficulty |
|----------|---------|-----------|
| [**Terraform Setup**](docs/deployment/TERRAFORM_SETUP.md) | Multi-cloud provisioning | ⭐⭐⭐ |
| [CI/CD Setup Guide](docs/deployment/CICD_SETUP_GUIDE.md) | End-to-end pipelines | ⭐⭐⭐ |
| [Quick Reference](docs/deployment/CICD_QUICK_REFERENCE.md) | Common commands | ⭐ |

### 🤖 AI Engineering
| Document | Purpose | Level |
|----------|---------|-------|
| [**Production Patterns**](docs/guides/PRODUCTION_PATTERNS.md) | Best practices | Advanced |
| [AI Observability](docs/monitoring/AI_OBSERVABILITY.md) | Tracing & monitoring | Intermediate |
| [Evaluation README](src/evaluation/README.md) | Testing framework | Intermediate |

### 📊 Monitoring Integration
| Platform | Documentation | Setup Time |
|----------|--------------|------------|
| **Datadog** | [Integration Guide](docs/monitoring/DATADOG_INTEGRATION.md) | 30 min |
| **Prometheus + Grafana** | [Built-in](monitoring/grafana/dashboards/) | 15 min |
| **LangSmith** | [AI Observability](docs/monitoring/AI_OBSERVABILITY.md) | 10 min |

### 🔄 CI/CD Platforms
| Platform | Configuration | Features |
|----------|--------------|----------|
| GitHub Actions | [.github/workflows/](.github/workflows/) | 6 workflows |
| Jenkins | [.jenkins/Jenkinsfile](.jenkins/Jenkinsfile) | K8s-native |
| CircleCI | [.circleci/config.yml](.circleci/config.yml) | Parallelism |
| Buildkite | [.buildkite/pipeline.yml](.buildkite/pipeline.yml) | Dynamic |

---

## 🏛️ Architecture

### High-Level System Architecture
```
┌──────────────┐     HTTPS      ┌─────────────────┐
│   React UI   │◄──────────────►│  FastAPI Backend│
│  TypeScript  │                │   (Async)       │
└──────────────┘                └─────────────────┘
                                        │
          ┌─────────────────────────────┼─────────────────────────────┐
          │                             │                             │
          ▼                             ▼                             ▼
┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐
│  Campaign Data  │         │  Competitor     │         │   Creative      │
│    Collector    │         │    Analyzer     │         │   Evaluator     │
│   (Agent 1)     │         │   (Agent 2)     │         │   (Agent 3)     │
└─────────────────┘         └─────────────────┘         └─────────────────┘
          │                             │                             │
          └─────────────────────────────┼─────────────────────────────┘
                                        ▼
                              ┌─────────────────┐
                              │  LangGraph      │
                              │  State Machine  │
                              │  Orchestrator   │
                              └─────────────────┘
                                        │
          ┌─────────────────────────────┼─────────────────────────────┐
          ▼                             ▼                             ▼
┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐
│   LangSmith     │         │    Datadog      │         │   Prometheus    │
│    Tracing      │         │   APM + Logs    │         │    Metrics      │
└─────────────────┘         └─────────────────┘         └─────────────────┘
```

### Multi-Agent Workflow
1. **Campaign Collector** → Fetch performance metrics
2. **Competitor Analyzer** → Analyze market signals
3. **Creative Evaluator** → Assess creative performance
4. **Context Builder** → Synthesize multi-source data
5. **LangGraph Orchestrator** → Manage state & flow
6. **Decision Engine** → Generate recommendations
7. **Human Approval** → HITL verification

---

## 💻 Development

### Prerequisites
- Python 3.11+
- Node.js 20+
- Docker Desktop
- kubectl, helm, terraform (for cloud deployment)

### Local Development Setup
```bash
# Backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -e ".[dev]"
uvicorn src.api.main:app --reload

# Frontend
cd frontend
npm install
npm run dev

# Database & Cache (Docker)
docker-compose up postgres redis
```

### Testing
```bash
# Unit tests with coverage
pytest tests/unit/ --cov=src --cov-report=html

# AI evaluation
python scripts/run_evaluation.py \
  --dataset evaluation/datasets/golden/campaign_optimization.json

# Integration tests
pytest tests/integration/ --base-url=http://localhost:8000

# Load testing
locust --headless --users 100 --spawn-rate 10 --run-time 5m

# Frontend tests
cd frontend && npm run test
```

### Code Quality
```bash
# Auto-format
black src/ tests/
isort src/ tests/

# Lint
flake8 src/ tests/ --max-line-length=100
pylint src/ --disable=C0111,C0103

# Type checking
mypy src/ --ignore-missing-imports --strict

# Security scanning
bandit -r src/ -f json -o security-report.json
safety check --json > vulnerability-report.json
```

---

## 📊 Project Statistics

| Metric | Value |
|--------|-------|
| **Lines of Code** | 15,000+ |
| **Documentation** | 8,000+ lines |
| **Terraform IaC** | 2,000+ lines |
| **Test Coverage** | 85%+ |
| **CI/CD Platforms** | 4 (GitHub Actions, Jenkins, CircleCI, Buildkite) |
| **Monitoring Tools** | 6 (Datadog, New Relic, Sumologic, Prometheus, Grafana, LangSmith) |
| **Cloud Providers** | 3 (AWS, GCP, Azure) |
| **Golden Test Cases** | 8 scenarios |
| **Custom Evaluators** | 5 metrics |
| **Grafana Panels** | 9 visualizations |

---

## 🎯 Skills Demonstrated

### AI Engineering ✅
- Agentic system architecture (LangGraph)
- Production RAG with hybrid search
- Structured data extraction (Pydantic)
- Context window management
- Prompt engineering as code
- Evaluation frameworks with golden datasets
- LLM observability (LangSmith)
- Cost & latency optimization
- Token usage tracking
- Multi-model orchestration

### Backend Engineering ✅
- FastAPI async endpoints
- Pydantic data validation
- Async/await patterns throughout
- Type hints & mypy compliance
- Dependency injection
- Database migrations (Alembic)
- Caching strategies (Redis)
- API versioning
- Error handling & retries
- Rate limiting

### DevOps & Infrastructure ✅
- Terraform multi-cloud IaC
- Kubernetes orchestration
- Docker multi-stage builds
- Kustomize for config management
- Helm for package management
- GitOps workflows
- Blue/Green deployments
- Canary releases
- Rolling updates
- Automated rollbacks

### CI/CD ✅
- GitHub Actions workflows
- Jenkins Kubernetes pipelines
- CircleCI with orbs & parallelism
- Buildkite dynamic pipelines
- Parallel test execution
- Security scanning (Trivy, Bandit, Safety)
- Image vulnerability scanning
- Automated deployments
- Approval gates
- Notification integration (Slack, Datadog)

### Monitoring & Observability ✅
- Datadog APM & distributed tracing
- New Relic infrastructure monitoring
- Sumologic log aggregation
- Prometheus custom metrics
- Grafana dashboards
- LangSmith LLM tracing
- Custom metric instrumentation
- Distributed tracing
- Alert management
- SLO/SLA tracking

---

## 🎓 Learning Resources

### For Beginners
1. Start with [GETTING_STARTED.md](docs/getting-started/GETTING_STARTED.md)
2. Run the demo: `./scripts/demo/run_demo.sh`
3. Read [POC_SUMMARY.md](docs/guides/implementation/POC_SUMMARY.md)

### For Developers
1. Read [Production Patterns](docs/guides/PRODUCTION_PATTERNS.md)
2. Explore [src/agent/workflow.py](src/agent/workflow.py)
3. Review [evaluation framework](src/evaluation/)

### For DevOps Engineers
1. Study [Terraform Setup](docs/deployment/TERRAFORM_SETUP.md)
2. Review [CI/CD Setup Guide](docs/deployment/CICD_SETUP_GUIDE.md)
3. Explore [monitoring configs](infrastructure/terraform/monitoring.tf)

### For AI/ML Engineers
1. Read [AI Observability](docs/monitoring/AI_OBSERVABILITY.md)
2. Study [evaluator implementation](src/evaluation/evaluator.py)
3. Review [golden datasets](evaluation/datasets/golden/)

---

## 🤝 Contributing

Contributions welcome! This is a demonstration project, but improvements are appreciated.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests and linting
5. Commit changes (`git commit -m 'Add amazing feature'`)
6. Push to branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

---

## 📄 License

MIT License - See [LICENSE](LICENSE) for details.

---

## 🙏 Acknowledgments

Built with amazing open-source technologies:

- [LangChain](https://www.langchain.com/) - LLM framework
- [LangGraph](https://langchain-ai.github.io/langgraph/) - Agent orchestration
- [FastAPI](https://fastapi.tiangolo.com/) - Web framework
- [React](https://reactjs.org/) - UI library
- [Terraform](https://www.terraform.io/) - Infrastructure as Code
- [Kubernetes](https://kubernetes.io/) - Container orchestration
- [Prometheus](https://prometheus.io/) - Monitoring
- [Grafana](https://grafana.com/) - Visualization

And many more... see [pyproject.toml](pyproject.toml) for complete dependency list.

---

## 🌟 Star History

If you find this valuable for learning production AI engineering:
- ⭐ **Star this repo**
- 🔀 **Fork it**
- 📣 **Share it**

---

## 📞 Contact & Support

- **Issues**: [GitHub Issues](../../issues)
- **Discussions**: [GitHub Discussions](../../discussions)
- **Documentation**: Start with [SKILLS_SHOWCASE.md](docs/reference/SKILLS_SHOWCASE.md)

---

<div align="center">

**🚀 Built to demonstrate real-world production AI engineering**

[Getting Started](docs/getting-started/GETTING_STARTED.md) • [Skills Showcase](docs/reference/SKILLS_SHOWCASE.md) • [Documentation](docs/) • [CI/CD](.github/workflows/)

</div>
