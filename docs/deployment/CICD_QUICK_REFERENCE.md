# CI/CD Quick Reference

Quick command reference for daily CI/CD operations.

## 🚀 Quick Links

- **Setup Guide**: [CICD_SETUP_GUIDE.md](./CICD_SETUP_GUIDE.md) - Complete end-to-end setup
- **Pipeline Docs**: [CI_CD_PIPELINE.md](./CI_CD_PIPELINE.md) - Pipeline architecture
- **AI Ops**: [AIOPS_SUMMARY.md](./AIOPS_SUMMARY.md) - Evaluation & monitoring

---

## Common Commands

### Local Development

```bash
# Install dependencies
make install

# Run tests
make test

# Run linting
make lint

# Format code
make format

# Run locally
make dev
```

### Docker Operations

```bash
# Build images
make docker-build

# Push images
make docker-push

# Run locally with Docker
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### Deployment

```bash
# Deploy to staging
make deploy-staging

# Deploy to production
make deploy-production

# Deploy specific version
make deploy-staging VERSION=v1.2.3

# Check deployment status
make status-staging
make status-production
```

### Kubernetes

```bash
# Get pods
kubectl get pods -n marketing-agent-staging
kubectl get pods -n marketing-agent-production

# View logs
kubectl logs -f deployment/backend -n marketing-agent-staging
kubectl logs -f deployment/frontend -n marketing-agent-staging

# Get pod details
kubectl describe pod POD_NAME -n NAMESPACE

# Execute command in pod
kubectl exec -it POD_NAME -n NAMESPACE -- bash

# Port forward
kubectl port-forward svc/backend-service 8000:8000 -n marketing-agent-staging
```

### Rollback

```bash
# Quick rollback
make rollback-staging
make rollback-production

# Rollback to specific version
./scripts/rollback.sh production v1.2.2

# View rollout history
kubectl rollout history deployment/backend -n NAMESPACE

# Rollback to previous revision
kubectl rollout undo deployment/backend -n NAMESPACE
```

### Monitoring

```bash
# Port forward Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Open: http://localhost:3000

# Port forward Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Open: http://localhost:9090

# View metrics endpoint
kubectl port-forward svc/backend-service 8000:8000 -n NAMESPACE
curl http://localhost:8000/metrics
```

### Evaluation

```bash
# Run single evaluation
python scripts/run_evaluation.py campaign_optimization

# Run all evaluations
python scripts/run_evaluation.py --all

# Generate report
python scripts/generate_evaluation_report.py

# Check thresholds
python scripts/check_evaluation_thresholds.py
```

### Database

```bash
# Run migrations
make migrate-staging
make migrate-production

# Backup database
./scripts/backup-db.sh production

# Restore database
./scripts/restore-db.sh production backup-file.sql

# Connect to database
kubectl port-forward svc/postgres-service 5432:5432 -n NAMESPACE
psql -h localhost -U postgres -d marketing_agent
```

### Health Checks

```bash
# Check all services
make health-check

# Manual health check
curl http://localhost:8000/health
curl http://localhost:8000/api/v1/health

# Check readiness
kubectl get pods -n NAMESPACE
```

---

## GitHub Actions

### Trigger Workflows

```bash
# Push triggers CI
git push origin branch-name

# Merge to main triggers staging deployment
git checkout main
git merge feature-branch
git push

# Tag triggers production deployment
git tag v1.0.0
git push origin v1.0.0

# Manual trigger
# Go to: Actions → Select Workflow → Run workflow
```

### View Workflow Status

```bash
# Using GitHub CLI
gh run list
gh run view RUN_ID
gh run watch RUN_ID

# Or visit:
# https://github.com/YOUR_USERNAME/marketing-agent-workflow/actions
```

---

## Secrets Management

### GitHub Secrets

```bash
# Using GitHub CLI
gh secret set SECRET_NAME

# Or via web:
# Settings → Secrets and variables → Actions → New repository secret
```

### Kubernetes Secrets

```bash
# Create secret
kubectl create secret generic SECRET_NAME \
  --from-literal=key=value \
  -n NAMESPACE

# Update secret
kubectl delete secret SECRET_NAME -n NAMESPACE
kubectl create secret generic SECRET_NAME \
  --from-literal=key=new-value \
  -n NAMESPACE

# View secret (base64 encoded)
kubectl get secret SECRET_NAME -n NAMESPACE -o yaml

# Decode secret
kubectl get secret SECRET_NAME -n NAMESPACE -o jsonpath='{.data.key}' | base64 -d
```

---

## Troubleshooting

### Check Pod Logs

```bash
# Current logs
kubectl logs POD_NAME -n NAMESPACE

# Previous crashed pod logs
kubectl logs POD_NAME -n NAMESPACE --previous

# Follow logs
kubectl logs -f POD_NAME -n NAMESPACE

# All pods in deployment
kubectl logs -f deployment/backend -n NAMESPACE
```

### Check Events

```bash
# Recent events
kubectl get events -n NAMESPACE --sort-by='.lastTimestamp'

# All events in cluster
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# Describe resource for events
kubectl describe pod POD_NAME -n NAMESPACE
```

### Debug Pod

```bash
# Execute shell in pod
kubectl exec -it POD_NAME -n NAMESPACE -- /bin/bash

# Run single command
kubectl exec POD_NAME -n NAMESPACE -- env

# Copy files from pod
kubectl cp NAMESPACE/POD_NAME:/path/to/file ./local-file

# Copy files to pod
kubectl cp ./local-file NAMESPACE/POD_NAME:/path/to/file
```

### Check Resource Usage

```bash
# Node resources
kubectl top nodes

# Pod resources
kubectl top pods -n NAMESPACE

# Describe node
kubectl describe node NODE_NAME
```

---

## Scaling

### Manual Scaling

```bash
# Scale deployment
kubectl scale deployment/backend --replicas=5 -n NAMESPACE

# Scale via patch
kubectl patch deployment backend -n NAMESPACE -p '{"spec":{"replicas":5}}'
```

### Autoscaling

```bash
# View HPA status
kubectl get hpa -n NAMESPACE

# Describe HPA
kubectl describe hpa backend-hpa -n NAMESPACE

# Edit HPA
kubectl edit hpa backend-hpa -n NAMESPACE

# Create HPA
kubectl autoscale deployment backend \
  --min=2 --max=10 \
  --cpu-percent=80 \
  -n NAMESPACE
```

---

## Security

### Security Scanning

```bash
# Scan Docker image
docker scan YOUR_IMAGE:TAG

# Trivy scan
trivy image YOUR_IMAGE:TAG

# Check vulnerabilities in dependencies
pip-audit
npm audit
```

### Update Dependencies

```bash
# Python
pip install --upgrade -r requirements.txt
pip-compile --upgrade requirements.in

# Node.js
npm update
npm audit fix

# Commit updates
git add requirements.txt package-lock.json
git commit -m "chore: update dependencies"
```

---

## Backup & Restore

### Backup

```bash
# Backup database
./scripts/backup-db.sh production

# Backup Kubernetes resources
kubectl get all -n NAMESPACE -o yaml > backup-k8s.yaml

# Backup secrets
kubectl get secrets -n NAMESPACE -o yaml > backup-secrets.yaml

# Backup ConfigMaps
kubectl get configmaps -n NAMESPACE -o yaml > backup-configmaps.yaml
```

### Restore

```bash
# Restore database
./scripts/restore-db.sh production backup.sql

# Restore Kubernetes resources
kubectl apply -f backup-k8s.yaml

# Restore secrets
kubectl apply -f backup-secrets.yaml
```

---

## Monitoring Queries

### Prometheus Queries

```promql
# Request rate
rate(marketing_agent_requests_total[5m])

# Error rate
rate(marketing_agent_requests_total{status="error"}[5m])

# P95 latency
histogram_quantile(0.95, rate(marketing_agent_request_latency_seconds_bucket[5m]))

# Token usage
increase(marketing_agent_tokens_total[1h])

# Cost
increase(marketing_agent_cost_usd_total[24h])
```

### Common Grafana Queries

- Request rate by status
- Latency percentiles (p50, p95, p99)
- Error rate
- Token usage over time
- Cost tracking
- Evaluation scores

---

## Useful Aliases

Add to your `.bashrc` or `.zshrc`:

```bash
# Kubernetes
alias k='kubectl'
alias kg='kubectl get'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias kx='kubectl exec -it'
alias kpf='kubectl port-forward'

# Namespaces
alias kgs='kubectl get pods -n marketing-agent-staging'
alias kgp='kubectl get pods -n marketing-agent-production'
alias kls='kubectl logs -f -n marketing-agent-staging'
alias klp='kubectl logs -f -n marketing-agent-production'

# Docker
alias dc='docker-compose'
alias dcup='docker-compose up -d'
alias dcdown='docker-compose down'
alias dclogs='docker-compose logs -f'

# Project
alias mktg='cd ~/marketing-agent-workflow'
alias mktg-test='make test'
alias mktg-deploy='make deploy-staging'
```

---

## Emergency Procedures

### Service Down

```bash
# 1. Check pod status
kubectl get pods -n NAMESPACE

# 2. Check logs
kubectl logs -f deployment/backend -n NAMESPACE --tail=100

# 3. Check events
kubectl get events -n NAMESPACE --sort-by='.lastTimestamp' | tail -20

# 4. Quick fix: Restart deployment
kubectl rollout restart deployment/backend -n NAMESPACE

# 5. If persistent: Rollback
make rollback-production
```

### High Latency

```bash
# 1. Check Grafana dashboards
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# 2. Check resource usage
kubectl top pods -n NAMESPACE

# 3. Scale up if needed
kubectl scale deployment/backend --replicas=10 -n NAMESPACE

# 4. Check database performance
kubectl exec -it deployment/backend -n NAMESPACE -- python -m src.cli.health_check
```

### Database Issues

```bash
# 1. Check database pod
kubectl get pods -n NAMESPACE | grep postgres

# 2. Check database logs
kubectl logs postgres-POD_NAME -n NAMESPACE

# 3. Connect to database
kubectl port-forward svc/postgres-service 5432:5432 -n NAMESPACE
psql -h localhost -U postgres -d marketing_agent

# 4. Check connections
SELECT count(*) FROM pg_stat_activity;

# 5. Restart if needed
kubectl delete pod postgres-POD_NAME -n NAMESPACE
```

---

## Resources

- **Full Setup Guide**: [CICD_SETUP_GUIDE.md](./CICD_SETUP_GUIDE.md)
- **Pipeline Documentation**: [CI_CD_PIPELINE.md](./CI_CD_PIPELINE.md)
- **AI Ops Guide**: [AIOPS_SUMMARY.md](./AIOPS_SUMMARY.md)
- **Project Structure**: [PROJECT_STRUCTURE.md](./PROJECT_STRUCTURE.md)
- **Contributing**: [../CONTRIBUTING.md](../CONTRIBUTING.md)

---

## Support

**First check:**
1. GitHub Actions logs
2. Pod logs (`kubectl logs`)
3. Events (`kubectl get events`)
4. Grafana dashboards
5. LangSmith traces

**Getting help:**
- Check troubleshooting sections in documentation
- Review error messages carefully
- Check recent changes in git history
- Create detailed issue with logs and context

---

**Quick Start**: New to the project? Start with [CICD_SETUP_GUIDE.md](./CICD_SETUP_GUIDE.md)

**Need Help?** Check the troubleshooting section or create an issue.
