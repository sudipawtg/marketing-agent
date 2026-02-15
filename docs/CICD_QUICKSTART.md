# CI/CD Pipeline Quick Start Guide

## 🚀 Quick Setup (5 minutes)

### Prerequisites Check

```bash
# Verify you have all required tools
python --version   # Should be 3.11+
node --version     # Should be 18+
docker --version   # Any recent version
kubectl version    # For deployments
make --version     # Should be available
```

## Step 1: Initial Setup

```bash
# Clone and setup
git clone <your-repo-url>
cd marketing-agent-workflow

# Install everything
make install
make install-pre-commit

# Verify setup
make test
```

## Step 2: Configure GitHub Secrets

Go to GitHub Repository Settings → Secrets and variables → Actions

Add these secrets:

### Required Secrets

```
OPENAI_API_KEY           # Your OpenAI API key
KUBE_CONFIG_STAGING      # Staging cluster config (base64)
KUBE_CONFIG_PRODUCTION   # Production cluster config (base64)
```

### Get Kubernetes Config (base64 encoded)

```bash
# Staging
kubectl config view --flatten --minify --context=staging | base64

# Production  
kubectl config view --flatten --minify --context=production | base64
```

## Step 3: Update Configuration

### 3.1 Update Image Registry

Edit these files and replace `ghcr.io/your-org` with your registry:

```bash
# GitHub workflows
.github/workflows/cd.yml
.github/workflows/ci.yml

# Kubernetes configs
infrastructure/k8s/*/kustomization.yaml
infrastructure/k8s/base/*-deployment.yaml
```

### 3.2 Update Domain Names

Edit `infrastructure/k8s/base/ingress.yaml`:

```yaml
# Replace:
marketing-agent.example.com 
# With your actual domain
```

### 3.3 Update Scripts

Edit `scripts/deploy.sh` and update cluster contexts:

```bash
# Line 23-33: Update context names to match your clusters
staging) CONTEXT="your-staging-cluster" ;;
production) CONTEXT="your-production-cluster" ;;
```

## Step 4: Test Locally

```bash
# Run local tests
make test

# Start local environment
make dev

# In another terminal, check health
make health-check ENVIRONMENT=local
```

## Step 5: First Deployment

### 5.1 Build and Push Images

```bash
# Build Docker images
make docker-build

# Push to registry (requires login)
make docker-push VERSION=v0.1.0
```

### 5.2 Deploy to Staging

```bash
# Option 1: Manual deployment
make deploy-staging VERSION=v0.1.0

# Option 2: Push to main branch (automatic)
git push origin main
```

### 5.3 Verify Deployment

```bash
# Check pods
kubectl get pods -n staging

# Check logs
make k8s-logs ENVIRONMENT=staging

# Run health check
make health-check ENVIRONMENT=staging
```

## Common Commands

### Development

```bash
make dev              # Start local development
make test             # Run all tests
make lint             # Check code quality
make format           # Format code
```

### Docker

```bash
make docker-build     # Build images
make docker-up        # Start containers
make docker-down      # Stop containers
make docker-logs      # View logs
```

### Deployment

```bash
make deploy-staging VERSION=v1.0.0
make deploy-production VERSION=v1.0.0
make rollback ENVIRONMENT=production
make health-check ENVIRONMENT=staging
```

### Database

```bash
make db-migrate       # Run migrations
make db-rollback      # Rollback migration
make db-backup ENVIRONMENT=staging
```

### Kubernetes

```bash
make k8s-pods ENVIRONMENT=staging
make k8s-logs ENVIRONMENT=staging
make k8s-describe ENVIRONMENT=staging
```

## Workflow Overview

### Development Flow

```
1. Create branch → 2. Make changes → 3. Commit (pre-commit runs)
                                             ↓
4. Push → 5. CI runs → 6. PR checks → 7. Review → 8. Merge
                                                        ↓
                              9. Deploy to Staging (automatic)
                                                        ↓
                            10. Create tag → Deploy to Production
```

### CI Pipeline (Automatic on Push/PR)

- ✓ Linting & formatting
- ✓ Type checking
- ✓ Unit tests
- ✓ Integration tests
- ✓ Security scans
- ✓ Docker build test

### CD Pipeline (Automatic on Merge)

- ✓ Build & push Docker images
- ✓ Deploy to staging
- ✓ Run smoke tests
- ✓ Deploy to production (on tags)

## Troubleshooting

### CI Fails with Linting Errors

```bash
make format
git add .
git commit --amend --no-edit
git push --force
```

### Tests Fail Locally

```bash
# Check services are running
docker-compose ps

# Restart services
make docker-down
make docker-up

# Run tests again
make test
```

### Deployment Fails

```bash
# Check pod status
kubectl get pods -n staging

# Check pod logs
kubectl logs <pod-name> -n staging

# Describe pod for events
kubectl describe pod <pod-name> -n staging

# Rollback if needed
make rollback ENVIRONMENT=staging
```

### Docker Build Fails

```bash
# Clean and rebuild
make clean
make docker-build

# Check Docker is running
docker info
```

## Next Steps

1. Read [CI/CD Pipeline Documentation](./docs/CI_CD_PIPELINE.md)
2. Review [Contributing Guidelines](./CONTRIBUTING.md)
3. Set up monitoring (Grafana/Prometheus)
4. Configure alerting (Slack/email)
5. Set up log aggregation

## Getting Help

- 📖 Full documentation: `docs/CI_CD_PIPELINE.md`
- 🐛 Report issues: GitHub Issues
- 💬 Questions: Create a discussion

## Checklist

Before going to production:

- [ ] All tests passing
- [ ] Security scans clean
- [ ] Secrets configured
- [ ] Domain names updated
- [ ] SSL certificates configured
- [ ] Monitoring set up
- [ ] Backups configured
- [ ] Rollback tested
- [ ] Documentation updated
- [ ] Team trained on deployment process

---

**Time to First Deployment:** ~15 minutes  
**Time to Production Ready:** ~1 hour
