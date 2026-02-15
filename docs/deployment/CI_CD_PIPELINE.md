# CI/CD Pipeline Documentation

## Overview

This document describes the complete CI/CD pipeline for the Marketing Agent Workflow project.

## Table of Contents

- [Pipeline Architecture](#pipeline-architecture)
- [Workflows](#workflows)
- [Deployment Environments](#deployment-environments)
- [Prerequisites](#prerequisites)
- [Setup Instructions](#setup-instructions)
- [Usage Guide](#usage-guide)
- [Troubleshooting](#troubleshooting)

## Pipeline Architecture

```
┌─────────────┐
│   Changes   │
│  (Git Push) │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────┐
│         CI Pipeline (ci.yml)         │
├─────────────────────────────────────┤
│ 1. Lint & Format Check              │
│ 2. Type Checking                     │
│ 3. Unit Tests                        │
│ 4. Integration Tests                 │
│ 5. Docker Build Test                 │
│ 6. Code Coverage                     │
└──────┬──────────────────────┬───────┘
       │                      │
       ▼                      ▼
┌──────────────┐      ┌──────────────────┐
│  PR Checks   │      │  Security Scan   │
│  (pr-checks) │      │  (security.yml)  │
└──────┬───────┘      └────────┬─────────┘
       │                       │
       │   ┌──────────────┐   │
       └───►   Approved   ◄───┘
           └──────┬───────┘
                  │
                  ▼
        ┌──────────────────┐
        │   Merge to Main  │
        └──────┬───────────┘
               │
               ▼
     ┌─────────────────────────────┐
     │   CD Pipeline (cd.yml)       │
     ├─────────────────────────────┤
     │ 1. Build Docker Images       │
     │ 2. Push to Registry          │
     │ 3. Deploy to Staging         │
     │ 4. Run Smoke Tests           │
     │ 5. Deploy to Production (*)  │
     └─────────────────────────────┘
               │
               ▼
        ┌──────────────┐
        │  Monitoring  │
        │  & Alerting  │
        └──────────────┘
```

(*) Production deployment only on version tags

## Workflows

### 1. CI Pipeline (`ci.yml`)

**Triggers:**

- Push to `main` or `develop` branches
- Pull request to `main` or `develop`

**Jobs:**

- **Backend Lint & Test**: Python code quality and testing
- **Frontend Lint & Build**: TypeScript/React build and linting
- **Docker Build Test**: Validates Docker images can be built
- **Smoke Tests**: Quick validation of core functionality

### 2. CD Pipeline (`cd.yml`)

**Triggers:**

- Push to `main` branch (deploys to staging)
- Version tags `v*.*.*` (deploys to production)
- Manual workflow dispatch

**Jobs:**

- **Build & Push**: Create and publish Docker images
- **Deploy Staging**: Automatic deployment to staging
- **Deploy Production**: Deployment to production (requires approval)
- **Deploy Canary**: Gradual rollout with traffic splitting

### 3. Security Scanning (`security.yml`)

**Triggers:**

- Push to main/develop
- Pull requests
- Daily scheduled scan (2 AM UTC)
- Manual dispatch

**Scans:**

- Dependency vulnerabilities (Safety, pip-audit, npm audit)
- SAST with CodeQL
- Secret scanning with TruffleHog
- Container image scanning with Trivy
- IaC scanning with Checkov
- License compliance

### 4. PR Checks (`pr-checks.yml`)

**Triggers:**

- Pull request events (opened, synchronized, reopened)

**Checks:**

- PR title validation (semantic commits)
- Merge conflict detection
- File size validation
- Code complexity analysis
- Test coverage requirements
- Changed files analysis
- Performance impact assessment
- Automated labeling

### 5. Release Workflow (`release.yml`)

**Triggers:**

- Version tags `v*.*.*`
- Manual workflow dispatch

**Actions:**

- Generate changelog
- Create GitHub release
- Build release artifacts
- Update documentation
- Send notifications

## Deployment Environments

### Local Development

- **Tools**: Docker Compose
- **Command**: `make dev`
- **URL**: http://localhost:8000 (backend), http://localhost:5173 (frontend)

### Staging

- **Purpose**: Pre-production testing
- **Trigger**: Automatic on merge to main
- **URL**: https://staging.marketing-agent.example.com
- **Database**: Isolated staging database
- **Replicas**: 2 backend, 1 frontend

### Production

- **Purpose**: Live production environment
- **Trigger**: Manual approval or version tags
- **URL**: https://marketing-agent.example.com
- **Database**: Production database with backups
- **Replicas**: 5 backend, 3 frontend
- **Features**: Auto-scaling, monitoring, alerting

### Canary

- **Purpose**: Gradual rollout testing
- **Trigger**: Manual workflow dispatch
- **Traffic**: 10% of production traffic
- **Duration**: 5 minutes monitoring before promotion

## Prerequisites

### ›Required Tools

- Docker & Docker Compose
- Kubernetes cluster (for deployments)
- kubectl with configured contexts
- Python 3.11+
- Node.js 18+
- Make

### Required Secrets

Configure these in GitHub repository settings:

#### Container Registry

- `GITHUB_TOKEN` (automatic)

#### Kubernetes

- `KUBE_CONFIG_STAGING` (base64 encoded kubeconfig)
- `KUBE_CONFIG_PRODUCTION` (base64 encoded kubeconfig)

#### API Keys

- `OPENAI_API_KEY`
- `ANTHROPIC_API_KEY`

#### Database

- `DATABASE_PASSWORD`

#### Notifications (optional)

- `SLACK_WEBHOOK_URL`

## Setup Instructions

### 1. Initial Setup

```bash
# Clone repository
git clone https://github.com/your-org/marketing-agent-workflow.git
cd marketing-agent-workflow

# Install dependencies
make install

# Install pre-commit hooks
make install-pre-commit
```

### 2. Configure Secrets

```bash
# Staging Kubernetes config
kubectl config view --flatten --minify --context=staging-cluster | base64 | pbcopy
# Paste in GitHub Secrets as KUBE_CONFIG_STAGING

# Production Kubernetes config
kubectl config view --flatten --minify --context=production-cluster | base64 | pbcopy
# Paste in GitHub Secrets as KUBE_CONFIG_PRODUCTION
```

### 3. Update Configuration

Edit the following files with your specific values:

- `.github/workflows/*.yml` - Update image registry and URLs
- `infrastructure/k8s/*/kustomization.yaml` - Update image names
- `infrastructure/k8s/base/ingress.yaml` - Update domain names

### 4. Test Locally

```bash
# Run tests
make test

# Start local environment
make dev

# Check health
make health-check ENVIRONMENT=local
```

## Usage Guide

### Development Workflow

1. **Create feature branch**

   ```bash
   git checkout -b feat/your-feature
   ```
2. **Make changes and commit**

   ```bash
   git add .
   git commit -m "feat: add new feature"
   ```

   Pre-commit hooks will run automatically
3. **Push and create PR**

   ```bash
   git push origin feat/your-feature
   ```
4. **CI runs automatically**

   - Linting and formatting
   - Tests
   - Security scans
   - PR checks
5. **Review and merge**

   - Address any CI failures
   - Get code review
   - Merge to main
6. **Automatic deployment**

   - Staging deployment triggers automatically
   - Monitor staging environment
   - For production, create version tag

### Manual Deployment

```bash
# Deploy to staging
make deploy-staging VERSION=v1.0.0

# Deploy to production (requires confirmation)
make deploy-production VERSION=v1.0.0

# Deploy canary
make deploy-canary VERSION=v1.0.0
```

### Database Operations

```bash
# Run migrations
make db-migrate

# Rollback migration
make db-rollback

# Backup database
make db-backup ENVIRONMENT=production
```

### Rollback Deployment

```bash
# Rollback to previous version
make rollback ENVIRONMENT=production

# Or use script directly
./scripts/rollback.sh production
```

### Health Checks

```bash
# Check all environments
make health-check ENVIRONMENT=local
make health-check ENVIRONMENT=staging
make health-check ENVIRONMENT=production
```

## Monitoring

### Kubernetes Dashboard

```bash
# Access Kubernetes dashboard
kubectl proxy
# Visit http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

### View Logs

```bash
# Backend logs
kubectl logs -f -l app=marketing-agent,component=backend -n production

# Frontend logs
kubectl logs -f -l app=marketing-agent,component=frontend -n production

# All logs
make k8s-logs ENVIRONMENT=production
```

### Metrics

Access Grafana dashboard:

- URL: https://grafana.example.com
- Dashboards in `monitoring/grafana/dashboards/`

## Troubleshooting

### CI Failures

**Linting errors:**

```bash
make format
git add .
git commit --amend --no-edit
```

**Test failures:**

```bash
make test-unit
make test-integration
```

**Docker build failures:**

```bash
make docker-build
docker-compose logs
```

### Deployment Issues

**Pod not starting:**

```bash
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>
```

**Database migration fails:**

```bash
./scripts/migrate-db.sh staging current
./scripts/migrate-db.sh staging history
```

**Rollback deployment:**

```bash
./scripts/rollback.sh production
```

### Security Scan Failures

**Known vulnerabilities:**

- Review the security report
- Update dependencies: `pip install --upgrade package-name`
- Create exemptions if necessary

**Secret detection:**

- Remove secrets from code
- Use environment variables
- Update `.secrets.baseline`

## Best Practices

1. **Never commit secrets** - Use environment variables and secret management
2. **Write tests** - Maintain >70% code coverage
3. **Use semantic commits** - Follow conventional commits format
4. **Review security scans** - Address security issues promptly
5. **Monitor deployments** - Watch logs and metrics after deployment
6. **Backup before production** - Database backups are automatic but verify
7. **Use feature flags** - For gradual feature rollout
8. **Document changes** - Update docs with significant changes

## Support

- **Documentation**: See `docs/` directory
- **Issues**: Create GitHub issue
- **Urgent**: Contact DevOps team

## Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
