# 🎯 Getting Started - Choose Your Path

Welcome! Choose your path based on what you want to accomplish:

---

## 🚀 I Want to Run the Demo

**Goal**: See the Marketing Agent in action with demo scenarios

**Time**: 15 minutes

**Steps**:
1. Install dependencies: `pip install -e .`
2. Add API key to `.env`: `OPENAI_API_KEY=sk-your-key`
3. Run demo: `python -m src.demo.run_demo`

**Documentation**:
- [DEMO_GUIDE.md](DEMO_GUIDE.md) - Presentation tips
- [POC_SUMMARY.md](POC_SUMMARY.md) - Feature walkthrough

---

## 💻 I Want to Develop Locally

**Goal**: Set up local development environment

**Time**: 30 minutes

**Steps**:
1. Follow [QUICK_START.md](docs/QUICK_START.md)
2. Start services: `docker-compose up -d`
3. Run tests: `make test`
4. Start dev server: `make dev`

**Documentation**:
- [QUICK_START.md](docs/QUICK_START.md) - Developer quick start
- [CONTRIBUTING.md](CONTRIBUTING.md) - Development guidelines
- [PROJECT_STRUCTURE.md](docs/PROJECT_STRUCTURE.md) - Code organization

---

## 🔧 I Want to Set Up CI/CD

**Goal**: Deploy complete CI/CD pipeline to production

**Time**: 2-3 hours

**Steps**:
1. Follow [CICD_SETUP_GUIDE.md](docs/CICD_SETUP_GUIDE.md)
2. Configure GitHub secrets
3. Set up Kubernetes cluster
4. Deploy to staging

**Documentation**:
- [**CICD_SETUP_GUIDE.md**](docs/CICD_SETUP_GUIDE.md) - Complete setup (START HERE!)
- [CICD_QUICK_REFERENCE.md](docs/CICD_QUICK_REFERENCE.md) - Command reference
- [CI_CD_PIPELINE.md](docs/CI_CD_PIPELINE.md) - Pipeline architecture

---

## 📊 I Want to Set Up Monitoring

**Goal**: Enable observability and evaluation

**Time**: 1-2 hours

**Steps**:
1. Follow [AI_OBSERVABILITY.md](docs/AI_OBSERVABILITY.md)
2. Set up LangSmith account
3. Deploy Prometheus + Grafana
4. Import Grafana dashboards

**Documentation**:
- [AI_OBSERVABILITY.md](docs/AI_OBSERVABILITY.md) - Monitoring setup
- [AIOPS_SUMMARY.md](docs/AIOPS_SUMMARY.md) - AI Ops overview
- [src/evaluation/README.md](src/evaluation/README.md) - Evaluation framework

---

## 🧪 I Want to Run Evaluations

**Goal**: Test AI quality with golden datasets

**Time**: 30 minutes

**Steps**:
1. Install evaluation dependencies: `pip install -e ".[evaluation]"`
2. Run evaluation: `python scripts/run_evaluation.py campaign_optimization`
3. Generate report: `python scripts/generate_evaluation_report.py`

**Documentation**:
- [src/evaluation/README.md](src/evaluation/README.md) - Evaluation guide
- [AIOPS_SUMMARY.md](docs/AIOPS_SUMMARY.md) - AI Ops overview

---

## 📚 I Want to Understand the System

**Goal**: Learn architecture and design decisions

**Time**: 2-3 hours reading

**Documentation Path**:
1. [README.md](README.md) - Project overview
2. [docs/EXECUTIVE_SUMMARY.md](docs/EXECUTIVE_SUMMARY.md) - High-level summary
3. [POC_SUMMARY.md](POC_SUMMARY.md) - Feature details
4. [MARKETING_AGENT_IMPLEMENTATION_GUIDE.md](docs/MARKETING_AGENT_IMPLEMENTATION_GUIDE.md) - Complete guide (73 pages)
5. [docs/architecture/](docs/architecture/) - Architecture diagrams

---

## 🔨 I Want to Build It From Scratch

**Goal**: Understand implementation step-by-step

**Time**: Multiple days

**Documentation Path**:
1. [MARKETING_AGENT_IMPLEMENTATION_GUIDE.md](docs/MARKETING_AGENT_IMPLEMENTATION_GUIDE.md) - Implementation guide
2. [IMPLEMENTATION_CHECKLIST.md](docs/IMPLEMENTATION_CHECKLIST.md) - Task checklist
3. [PROJECT_STRUCTURE.md](docs/PROJECT_STRUCTURE.md) - Code organization
4. [docs/api/](docs/api/) - API documentation

---

## 🚨 I Have a Problem

**Goal**: Troubleshoot issues

**Quick Fixes**:

### Tests Failing
```bash
make test          # Run tests
make lint          # Check code quality
make format        # Fix formatting
```
See: [CONTRIBUTING.md](CONTRIBUTING.md#testing)

### Deployment Issues
```bash
kubectl get pods -n marketing-agent-staging
kubectl logs -f deployment/backend -n marketing-agent-staging
```
See: [CICD_SETUP_GUIDE.md - Troubleshooting](docs/CICD_SETUP_GUIDE.md#troubleshooting)

### Monitoring Not Working
```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```
See: [AI_OBSERVABILITY.md - Troubleshooting](docs/AI_OBSERVABILITY.md#troubleshooting)

### Low Evaluation Scores
```bash
python scripts/run_evaluation.py --all
python scripts/generate_evaluation_report.py
```
See: [src/evaluation/README.md - Troubleshooting](src/evaluation/README.md#troubleshooting)

---

## 📖 Complete Documentation Index

For a complete list of all documentation:
- [DOCUMENTATION_INDEX.md](docs/DOCUMENTATION_INDEX.md) - Complete index

---

## 🎓 Learning Paths

### Path 1: Quick Demo (1 hour)
1. Run demo → See it work → Understand capabilities
2. Files: README.md, DEMO_GUIDE.md, POC_SUMMARY.md

### Path 2: Developer (2-4 hours)
1. Quick start → Local development → Run tests → Make changes
2. Files: QUICK_START.md, CONTRIBUTING.md, PROJECT_STRUCTURE.md

### Path 3: DevOps Engineer (4-8 hours)
1. CI/CD setup → Deploy to staging → Monitor → Production
2. Files: CICD_SETUP_GUIDE.md, CICD_QUICK_REFERENCE.md, AI_OBSERVABILITY.md

### Path 4: AI/ML Engineer (3-6 hours)
1. Evaluation setup → Golden datasets → Monitoring → Optimization
2. Files: AIOPS_SUMMARY.md, AI_OBSERVABILITY.md, src/evaluation/README.md

### Path 5: Architect (8-16 hours)
1. Read everything → Understand design → Plan improvements
2. Files: All documentation + code review

---

## 🔗 Quick Links

| Task | Documentation | Time |
|------|---------------|------|
| Run demo | [DEMO_GUIDE.md](DEMO_GUIDE.md) | 15 min |
| Local dev setup | [QUICK_START.md](docs/QUICK_START.md) | 30 min |
| CI/CD setup | [CICD_SETUP_GUIDE.md](docs/CICD_SETUP_GUIDE.md) | 2-3 hours |
| Monitoring setup | [AI_OBSERVABILITY.md](docs/AI_OBSERVABILITY.md) | 1-2 hours |
| Run evaluations | [src/evaluation/README.md](src/evaluation/README.md) | 30 min |
| Understand architecture | [MARKETING_AGENT_IMPLEMENTATION_GUIDE.md](docs/MARKETING_AGENT_IMPLEMENTATION_GUIDE.md) | 2-3 hours |
| Command reference | [CICD_QUICK_REFERENCE.md](docs/CICD_QUICK_REFERENCE.md) | Reference |
| Troubleshooting | [CICD_SETUP_GUIDE.md#troubleshooting](docs/CICD_SETUP_GUIDE.md#troubleshooting) | As needed |

---

## 💡 Pro Tips

1. **Start small**: Run the demo first, then build up
2. **Use make commands**: `make test`, `make deploy-staging`, etc.
3. **Check logs**: Always check logs when something fails
4. **Read error messages**: They usually tell you exactly what's wrong
5. **Use quick reference**: Keep [CICD_QUICK_REFERENCE.md](docs/CICD_QUICK_REFERENCE.md) handy

---

## 🆘 Need Help?

1. **Check documentation** - It's comprehensive!
2. **Check logs** - `kubectl logs`, GitHub Actions logs
3. **Check monitoring** - Grafana dashboards, LangSmith traces
4. **Create an issue** - With logs and context

---

**Choose your path above and get started! 🚀**
