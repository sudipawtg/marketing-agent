# CI/CD Pipeline - Complete Setup Guide

This guide provides detailed, step-by-step instructions to set up the complete end-to-end CI/CD pipeline for the Marketing Agent platform.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Architecture](#architecture)
4. [Step 1: Repository Setup](#step-1-repository-setup)
5. [Step 2: Docker Registry Setup](#step-2-docker-registry-setup)
6. [Step 3: Kubernetes Cluster Setup](#step-3-kubernetes-cluster-setup)
7. [Step 4: Database Setup](#step-4-database-setup)
8. [Step 5: GitHub Secrets Configuration](#step-5-github-secrets-configuration)
9. [Step 6: LangSmith & API Keys Setup](#step-6-langsmith--api-keys-setup)
10. [Step 7: Monitoring Stack Setup](#step-7-monitoring-stack-setup)
11. [Step 8: Testing the Pipeline](#step-8-testing-the-pipeline)
12. [Step 9: First Deployment](#step-9-first-deployment)
13. [Step 10: Verify Everything Works](#step-10-verify-everything-works)
14. [Troubleshooting](#troubleshooting)
15. [Maintenance & Operations](#maintenance--operations)

---

## Overview

The CI/CD pipeline automates:

- **Continuous Integration**: Code quality, testing, security scanning
- **Continuous Deployment**: Multi-environment deployment with rollback
- **AI Evaluation**: Automated quality checks with golden datasets
- **Monitoring**: Real-time observability with Grafana dashboards

**Total Setup Time**: 2-3 hours (depending on cloud provider)

---

## Prerequisites

### Required Tools

Install these on your local machine:

```bash
# macOS
brew install git kubectl docker docker-compose helm terraform

# Verify installations
git --version          # >= 2.30
kubectl version        # >= 1.25
docker --version       # >= 20.10
helm version          # >= 3.10
terraform --version   # >= 1.5
```

### Required Accounts

1. **GitHub**: Repository host and CI/CD platform
2. **Cloud Provider**: Choose one:
   - AWS (EKS)
   - Google Cloud (GKE)
   - Azure (AKS)
   - DigitalOcean (DOKS)
3. **Docker Hub** or **Container Registry**: For Docker images
4. **LangSmith**: For AI observability (https://smith.langchain.com/)
5. **OpenAI**: For LLM API (https://platform.openai.com/)

### Access Requirements

- GitHub repository with admin access
- Kubernetes cluster (or ability to create one)
- Container registry credentials
- Domain name (optional, for ingress)

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      GitHub Repository                       │
│  ┌────────────┐  ┌────────────┐  ┌────────────────────┐   │
│  │  ci.yml    │  │  cd.yml    │  │  evaluation.yml    │   │
│  │ (Testing)  │  │ (Deploy)   │  │ (AI Quality)       │   │
│  └────────────┘  └────────────┘  └────────────────────┘   │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
        ┌────────────────────────┐
        │   Docker Registry      │
        │   (Docker Hub/ECR)     │
        └────────┬───────────────┘
                 │
                 ▼
┌────────────────────────────────────────────────────────┐
│              Kubernetes Cluster                         │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────┐ │
│  │   Staging     │  │  Production   │  │  Canary   │ │
│  │  Namespace    │  │   Namespace   │  │ Namespace │ │
│  └───────────────┘  └───────────────┘  └───────────┘ │
│  ┌─────────────────────────────────────────────────┐  │
│  │         PostgreSQL + Redis + Monitoring         │  │
│  └─────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────┘
                     │
                     ▼
        ┌────────────────────────┐
        │   Monitoring Stack     │
        │  Prometheus + Grafana  │
        │  LangSmith + Sentry    │
        └────────────────────────┘
```

---

## Step 1: Repository Setup

### 1.1 Clone the Repository

```bash
# Clone your fork/repository
git clone https://github.com/YOUR_USERNAME/marketing-agent-workflow.git
cd marketing-agent-workflow

# Verify structure
ls -la .github/workflows/
# Should see: ci.yml, cd.yml, evaluation.yml, security.yml, pr-checks.yml, release.yml
```

### 1.2 Branch Protection Rules

Configure in GitHub: **Settings → Branches → Add rule**

**For `main` branch:**

```yaml
Branch name pattern: main

Protections:
☑ Require pull request reviews before merging
  - Required approvals: 1
☑ Require status checks to pass before merging
  - Required checks:
    ✓ Backend Lint & Test
    ✓ Frontend Lint & Build
    ✓ Docker Build Test
    ✓ Security Scan
☑ Require conversation resolution before merging
☑ Require linear history
☑ Include administrators
```

**For `develop` branch:** Same rules but with 0 required approvals

### 1.3 GitHub Actions Permissions

**Settings → Actions → General:**

```
Workflow permissions:
⦿ Read and write permissions
☑ Allow GitHub Actions to create and approve pull requests
```

---

## Step 2: Docker Registry Setup

Choose **one** of the following options:

### Option A: Docker Hub (Recommended for simplicity)

1. **Create account**: https://hub.docker.com/signup

2. **Create access token**:
   - Account Settings → Security → New Access Token
   - Name: `marketing-agent-cicd`
   - Permissions: Read, Write, Delete
   - Save the token securely

3. **Create repositories**:
   ```
   YOUR_USERNAME/marketing-agent-backend
   YOUR_USERNAME/marketing-agent-frontend
   ```

4. **Test login locally**:
   ```bash
   docker login -u YOUR_USERNAME
   # Enter token as password
   ```

### Option B: AWS ECR

```bash
# Create ECR repositories
aws ecr create-repository --repository-name marketing-agent-backend --region us-east-1
aws ecr create-repository --repository-name marketing-agent-frontend --region us-east-1

# Get login token
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
```

### Option C: Google Container Registry (GCR)

```bash
# Enable Container Registry API
gcloud services enable containerregistry.googleapis.com

# Configure Docker
gcloud auth configure-docker

# Registry URL will be: gcr.io/YOUR_PROJECT_ID
```

### Option D: GitHub Container Registry (GHCR)

```bash
# Create Personal Access Token with packages scopes
# Use token to login
echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin

# Registry URL will be: ghcr.io/YOUR_USERNAME
```

---

## Step 3: Kubernetes Cluster Setup

Choose **one** platform:

### Option A: AWS EKS (Recommended for production)

```bash
# Install eksctl
brew install eksctl

# Create cluster (takes ~15 minutes)
eksctl create cluster \
  --name marketing-agent-cluster \
  --region us-east-1 \
  --nodes 3 \
  --node-type t3.medium \
  --managed

# Verify
kubectl get nodes
```

### Option B: Google GKE

```bash
# Create cluster
gcloud container clusters create marketing-agent-cluster \
  --region us-central1 \
  --num-nodes 3 \
  --machine-type n1-standard-2 \
  --enable-autoscaling \
  --min-nodes 2 \
  --max-nodes 5

# Get credentials
gcloud container clusters get-credentials marketing-agent-cluster \
  --region us-central1

# Verify
kubectl get nodes
```

### Option C: Azure AKS

```bash
# Create resource group
az group create --name marketing-agent-rg --location eastus

# Create cluster
az aks create \
  --resource-group marketing-agent-rg \
  --name marketing-agent-cluster \
  --node-count 3 \
  --node-vm-size Standard_D2s_v3 \
  --enable-managed-identity \
  --generate-ssh-keys

# Get credentials
az aks get-credentials \
  --resource-group marketing-agent-rg \
  --name marketing-agent-cluster

# Verify
kubectl get nodes
```

### Option D: DigitalOcean (Budget-friendly)

```bash
# Install doctl
brew install doctl

# Authenticate
doctl auth init

# Create cluster
doctl kubernetes cluster create marketing-agent-cluster \
  --region nyc1 \
  --version 1.28 \
  --count 3 \
  --size s-2vcpu-4gb

# Get credentials (automatic)
kubectl get nodes
```

### Option E: Local Kubernetes (Development only)

```bash
# Using kind (Kubernetes in Docker)
brew install kind

# Create cluster
kind create cluster --name marketing-agent

# Or using minikube
brew install minikube
minikube start --cpus=4 --memory=8192
```

### 3.1 Verify Cluster Access

```bash
# Check cluster info
kubectl cluster-info

# Check namespaces
kubectl get namespaces

# Check you have admin access
kubectl auth can-i create deployments --all-namespaces
# Should output: yes
```

---

## Step 4: Database Setup

### Option A: Kubernetes-Managed Databases (Quick Start)

Already configured in `infrastructure/k8s/base/databases.yaml`

```bash
# Deploy databases
kubectl apply -f infrastructure/k8s/base/namespace.yaml
kubectl apply -f infrastructure/k8s/base/databases.yaml

# Verify
kubectl get pods -n marketing-agent-staging
kubectl get pods -n marketing-agent-production

# Wait for ready
kubectl wait --for=condition=ready pod -l app=postgres -n marketing-agent-staging --timeout=300s
kubectl wait --for=condition=ready pod -l app=redis -n marketing-agent-staging --timeout=300s
```

### Option B: Cloud-Managed Databases (Production)

#### AWS RDS (PostgreSQL) + ElastiCache (Redis)

```bash
# PostgreSQL
aws rds create-db-instance \
  --db-instance-identifier marketing-agent-db \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --master-username postgres \
  --master-user-password "YOUR_SECURE_PASSWORD" \
  --allocated-storage 20 \
  --vpc-security-group-ids sg-xxxxx

# Redis
aws elasticache create-cache-cluster \
  --cache-cluster-id marketing-agent-cache \
  --cache-node-type cache.t3.micro \
  --engine redis \
  --num-cache-nodes 1
```

#### Google Cloud SQL + Memorystore

```bash
# PostgreSQL
gcloud sql instances create marketing-agent-db \
  --database-version=POSTGRES_15 \
  --tier=db-f1-micro \
  --region=us-central1

# Redis
gcloud redis instances create marketing-agent-cache \
  --size=1 \
  --region=us-central1 \
  --redis-version=redis_7_0
```

### 4.1 Create Kubernetes Secrets for Database

```bash
# For Kubernetes-managed databases
kubectl create secret generic database-credentials \
  -n marketing-agent-staging \
  --from-literal=POSTGRES_HOST=postgres-service \
  --from-literal=POSTGRES_PORT=5432 \
  --from-literal=POSTGRES_DB=marketing_agent \
  --from-literal=POSTGRES_USER=postgres \
  --from-literal=POSTGRES_PASSWORD=changeme \
  --from-literal=REDIS_HOST=redis-service \
  --from-literal=REDIS_PORT=6379

# Repeat for production namespace
kubectl create secret generic database-credentials \
  -n marketing-agent-production \
  --from-literal=POSTGRES_HOST=postgres-service \
  --from-literal=POSTGRES_PORT=5432 \
  --from-literal=POSTGRES_DB=marketing_agent \
  --from-literal=POSTGRES_USER=postgres \
  --from-literal=POSTGRES_PASSWORD=changeme \
  --from-literal=REDIS_HOST=redis-service \
  --from-literal=REDIS_PORT=6379
```

---

## Step 5: GitHub Secrets Configuration

### 5.1 Access GitHub Secrets

Navigate to: **GitHub Repository → Settings → Secrets and variables → Actions**

### 5.2 Required Secrets

Click **"New repository secret"** for each:

#### Container Registry Secrets

**For Docker Hub:**
```
Name: DOCKER_USERNAME
Value: your-dockerhub-username

Name: DOCKER_PASSWORD
Value: your-dockerhub-token (from Step 2)

Name: DOCKER_REGISTRY
Value: docker.io
```

**For AWS ECR:**
```
Name: AWS_ACCESS_KEY_ID
Value: your-aws-access-key

Name: AWS_SECRET_ACCESS_KEY
Value: your-aws-secret-key

Name: AWS_REGION
Value: us-east-1

Name: ECR_REGISTRY
Value: YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
```

**For GCR:**
```
Name: GCP_PROJECT_ID
Value: your-gcp-project-id

Name: GCP_SA_KEY
Value: (paste entire service account JSON key)

Name: GCR_REGISTRY
Value: gcr.io
```

#### Kubernetes Secrets

```bash
# Get your kubeconfig
kubectl config view --minify --flatten > /tmp/kubeconfig.yaml

# Copy the contents and create secret in GitHub
```

```
Name: KUBE_CONFIG
Value: (paste entire kubeconfig.yaml contents)

Name: KUBE_NAMESPACE_STAGING
Value: marketing-agent-staging

Name: KUBE_NAMESPACE_PRODUCTION
Value: marketing-agent-production
```

#### Application Secrets

```
Name: OPENAI_API_KEY
Value: sk-your-openai-api-key

Name: LANGCHAIN_API_KEY
Value: your-langsmith-api-key

Name: SENTRY_DSN
Value: https://your-sentry-dsn@sentry.io/project-id (optional)

Name: DATABASE_URL_STAGING
Value: postgresql://postgres:changeme@postgres-service:5432/marketing_agent

Name: DATABASE_URL_PRODUCTION
Value: postgresql://postgres:changeme@postgres-service:5432/marketing_agent

Name: REDIS_URL_STAGING
Value: redis://redis-service:6379/0

Name: REDIS_URL_PRODUCTION
Value: redis://redis-service:6379/0
```

### 5.3 Verify Secrets

Go to: **Actions → Secrets** and verify all secrets are listed.

---

## Step 6: LangSmith & API Keys Setup

### 6.1 LangSmith Setup

1. **Create account**: https://smith.langchain.com/

2. **Create API key**:
   - Settings → API Keys → Create API Key
   - Name: `marketing-agent-cicd`
   - Copy the key

3. **Create project**:
   - Projects → New Project
   - Name: `marketing-agent-production`
   - Copy project name

4. **Add to GitHub secrets** (already done in Step 5):
   ```
   LANGCHAIN_API_KEY=your-key
   ```

### 6.2 OpenAI Setup

1. **Create account**: https://platform.openai.com/

2. **Create API key**:
   - API Keys → Create new secret key
   - Name: `marketing-agent`
   - Copy the key

3. **Set usage limits** (recommended):
   - Billing → Usage limits
   - Set monthly limit: $100

4. **Add to GitHub secrets** (already done in Step 5)

### 6.3 Sentry Setup (Optional)

1. **Create account**: https://sentry.io/

2. **Create project**:
   - Projects → Create Project
   - Platform: Python
   - Name: `marketing-agent`

3. **Get DSN**:
   - Project Settings → Client Keys (DSN)
   - Copy DSN

4. **Add to GitHub secrets** (already done in Step 5)

---

## Step 7: Monitoring Stack Setup

### 7.1 Install Prometheus + Grafana

```bash
# Add Helm repositories
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Create monitoring namespace
kubectl create namespace monitoring

# Install Prometheus
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false

# Install Grafana (if not included)
helm install grafana grafana/grafana \
  --namespace monitoring \
  --set adminPassword='admin123'

# Verify
kubectl get pods -n monitoring
```

### 7.2 Configure Service Monitors

```bash
# Apply service monitor for marketing agent
cat <<EOF | kubectl apply -f -
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: marketing-agent
  namespace: marketing-agent-staging
spec:
  selector:
    matchLabels:
      app: backend
  endpoints:
  - port: http
    path: /metrics
    interval: 30s
EOF
```

### 7.3 Import Grafana Dashboard

```bash
# Port forward Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Open browser: http://localhost:3000
# Username: admin
# Password: admin123 (or from secret)

# Import dashboard:
# 1. Go to Dashboards → Import
# 2. Upload: monitoring/grafana/dashboards/marketing-agent-aiops.json
# 3. Select Prometheus datasource
# 4. Click Import
```

### 7.4 Access Monitoring

```bash
# Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Open: http://localhost:9090

# Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Open: http://localhost:3000

# AlertManager (optional)
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093
# Open: http://localhost:9093
```

---

## Step 8: Testing the Pipeline

### 8.1 Test CI Pipeline

```bash
# Create a test branch
git checkout -b test-ci-pipeline

# Make a small change
echo "# Test CI" >> README.md
git add README.md
git commit -m "test: trigger CI pipeline"
git push origin test-ci-pipeline

# Create pull request on GitHub
# Watch the Actions tab for workflow execution
```

**Expected results:**
- ✅ Backend Lint & Test passes
- ✅ Frontend Lint & Build passes
- ✅ Docker Build Test passes
- ✅ Security Scan passes

### 8.2 Test CD Pipeline (Staging)

```bash
# Merge PR to main
git checkout main
git merge test-ci-pipeline
git push origin main

# Watch Actions tab - CD pipeline should trigger
# Check deployment
kubectl get pods -n marketing-agent-staging

# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app=backend -n marketing-agent-staging --timeout=300s

# Check logs
kubectl logs -f deployment/backend -n marketing-agent-staging
```

### 8.3 Test Evaluation Pipeline

```bash
# Trigger manually
# Go to Actions → AI Evaluation → Run workflow

# Or trigger via commit
git checkout -b test-evaluation
echo "# Trigger eval" >> src/evaluation/README.md
git add src/evaluation/README.md
git commit -m "test: trigger evaluation"
git push origin test-evaluation

# Create PR and watch evaluation run
```

---

## Step 9: First Deployment

### 9.1 Deploy Infrastructure

```bash
# Apply base Kubernetes resources
kubectl apply -k infrastructure/k8s/base/

# Verify namespaces
kubectl get namespaces | grep marketing-agent

# Apply staging environment
kubectl apply -k infrastructure/k8s/staging/

# Check deployments
kubectl get deployments -n marketing-agent-staging
```

### 9.2 Build and Push Docker Images

```bash
# Build images locally first
docker build -f infrastructure/docker/Dockerfile.backend -t YOUR_REGISTRY/marketing-agent-backend:latest .
docker build -f infrastructure/docker/Dockerfile.frontend -t YOUR_REGISTRY/marketing-agent-frontend:latest ./frontend

# Test locally
docker-compose up -d

# Verify services
curl http://localhost:8000/health
curl http://localhost:3000

# Stop local services
docker-compose down

# Push to registry
docker push YOUR_REGISTRY/marketing-agent-backend:latest
docker push YOUR_REGISTRY/marketing-agent-frontend:latest
```

### 9.3 Deploy to Staging

```bash
# Using make (recommended)
make deploy-staging

# Or manually
./scripts/deploy.sh staging

# Or using kubectl
kubectl set image deployment/backend \
  backend=YOUR_REGISTRY/marketing-agent-backend:latest \
  -n marketing-agent-staging

kubectl set image deployment/frontend \
  frontend=YOUR_REGISTRY/marketing-agent-frontend:latest \
  -n marketing-agent-staging

# Wait for rollout
kubectl rollout status deployment/backend -n marketing-agent-staging
kubectl rollout status deployment/frontend -n marketing-agent-staging
```

### 9.4 Run Database Migrations

```bash
# Port forward to PostgreSQL
kubectl port-forward svc/postgres-service 5432:5432 -n marketing-agent-staging

# Run migrations locally
export DATABASE_URL="postgresql://postgres:changeme@localhost:5432/marketing_agent"
alembic upgrade head

# Or run migrations in cluster
kubectl exec -it deployment/backend -n marketing-agent-staging -- alembic upgrade head
```

### 9.5 Verify Staging Deployment

```bash
# Check pod status
kubectl get pods -n marketing-agent-staging

# Check logs
kubectl logs -f deployment/backend -n marketing-agent-staging
kubectl logs -f deployment/frontend -n marketing-agent-staging

# Port forward to test
kubectl port-forward svc/backend-service 8000:8000 -n marketing-agent-staging
kubectl port-forward svc/frontend-service 3000:80 -n marketing-agent-staging

# Test endpoints
curl http://localhost:8000/health
curl http://localhost:8000/api/v1/health
open http://localhost:3000
```

### 9.6 Deploy to Production

```bash
# Tag a release
git tag v1.0.0
git push origin v1.0.0

# This triggers CD workflow for production
# Watch Actions tab

# Or deploy manually
make deploy-production

# Verify
kubectl get pods -n marketing-agent-production
kubectl get ingress -n marketing-agent-production
```

---

## Step 10: Verify Everything Works

### 10.1 Verify CI/CD Pipeline

**Check GitHub Actions:**
```bash
# Go to: https://github.com/YOUR_USERNAME/marketing-agent-workflow/actions

# Verify workflows:
✅ CI Pipeline (ci.yml) - Green checkmark
✅ CD Pipeline (cd.yml) - Green checkmark
✅ Security Scan (security.yml) - Green checkmark
✅ Evaluation (evaluation.yml) - Green checkmark
```

### 10.2 Verify Kubernetes Deployments

```bash
# Check all namespaces
kubectl get all -n marketing-agent-staging
kubectl get all -n marketing-agent-production

# Expected output:
# - 2+ backend pods running
# - 2+ frontend pods running
# - 1 postgres pod running
# - 1 redis pod running
# - All services created
# - Ingress configured
```

### 10.3 Verify Application Health

```bash
# Backend health check
kubectl port-forward -n marketing-agent-staging svc/backend-service 8000:8000
curl http://localhost:8000/health

# Expected: {"status": "healthy"}

# API documentation
open http://localhost:8000/docs

# Frontend
kubectl port-forward -n marketing-agent-staging svc/frontend-service 3000:80
open http://localhost:3000
```

### 10.4 Verify Monitoring

```bash
# Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Query: marketing_agent_requests_total

# Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Dashboard: Marketing Agent - AI Operations
```

### 10.5 Verify Evaluation Framework

```bash
# Install dependencies locally
pip install -e ".[dev,evaluation]"

# Run evaluation
python scripts/run_evaluation.py campaign_optimization

# Expected:
# - Evaluation completes
# - Results saved
# - All checks pass
```

### 10.6 Verify LangSmith Tracing

```bash
# Set environment
export LANGCHAIN_API_KEY="your-key"
export LANGCHAIN_TRACING_V2="true"

# Run a test request
python scripts/run_evaluation.py campaign_optimization

# Check LangSmith:
# 1. Go to: https://smith.langchain.com/
# 2. Select project: marketing-agent-production
# 3. View traces
```

---

## Troubleshooting

### Common Issues

#### 1. CI Pipeline Fails

**Symptoms:** Tests fail, linting errors

**Solutions:**
```bash
# Run locally first
make test
make lint

# Fix issues
black src/ tests/
ruff check --fix src/ tests/

# Commit and push
git add .
git commit -m "fix: linting issues"
git push
```

#### 2. Docker Build Fails

**Symptoms:** "Cannot build image"

**Solutions:**
```bash
# Build locally with verbose output
docker build -f infrastructure/docker/Dockerfile.backend -t test:latest . --progress=plain

# Check logs
docker logs $(docker ps -lq)

# Common fixes:
# - Update requirements.txt
# - Check Dockerfile syntax
# - Ensure .dockerignore is correct
```

#### 3. Kubernetes Deployment Fails

**Symptoms:** Pods in CrashLoopBackOff, ImagePullBackOff

**Solutions:**
```bash
# Check pod status
kubectl describe pod POD_NAME -n NAMESPACE

# Check events
kubectl get events -n NAMESPACE --sort-by='.lastTimestamp'

# Check logs
kubectl logs POD_NAME -n NAMESPACE --previous

# Common fixes:
# ImagePullBackOff: Wrong registry or missing credentials
# CrashLoopBackOff: Application error, check logs
# Pending: Insufficient resources, check nodes
```

#### 4. Database Connection Fails

**Symptoms:** "connection refused", "timeout"

**Solutions:**
```bash
# Check database pod
kubectl get pods -n NAMESPACE | grep postgres

# Check database logs
kubectl logs POD_NAME -n NAMESPACE

# Test connection from app pod
kubectl exec -it POD_NAME -n NAMESPACE -- bash
psql -h postgres-service -U postgres -d marketing_agent

# Verify secrets
kubectl get secret database-credentials -n NAMESPACE -o yaml
```

#### 5. Ingress Not Working

**Symptoms:** 404, 502, Gateway Timeout

**Solutions:**
```bash
# Check ingress
kubectl describe ingress -n NAMESPACE

# Check ingress controller
kubectl get pods -n ingress-nginx

# Install nginx ingress controller if missing
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace

# Test services directly
kubectl port-forward svc/backend-service 8000:8000 -n NAMESPACE
```

#### 6. Monitoring Not Showing Data

**Symptoms:** Empty Grafana dashboards

**Solutions:**
```bash
# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Go to: http://localhost:9090/targets

# Check service monitors
kubectl get servicemonitor -n NAMESPACE

# Verify metrics endpoint
kubectl port-forward -n NAMESPACE svc/backend-service 8000:8000
curl http://localhost:8000/metrics
```

#### 7. Secrets Not Found

**Symptoms:** "secret not found", "missing environment variable"

**Solutions:**
```bash
# List secrets
kubectl get secrets -n NAMESPACE

# Recreate secret
kubectl delete secret SECRET_NAME -n NAMESPACE
kubectl create secret generic SECRET_NAME \
  --from-literal=KEY=VALUE \
  -n NAMESPACE

# Verify in pod
kubectl exec -it POD_NAME -n NAMESPACE -- env | grep KEY
```

#### 8. CI/CD Workflow Not Triggering

**Symptoms:** Push doesn't trigger workflow

**Solutions:**
```bash
# Check workflow files
cat .github/workflows/ci.yml

# Verify triggers
# - on: push: branches: [main, develop]

# Check GitHub Actions settings
# Settings → Actions → Actions permissions
# Should be: "Allow all actions and reusable workflows"

# Re-push
git commit --amend --no-edit
git push --force
```

### Getting Help

**Check logs in order:**
1. GitHub Actions logs
2. Kubectl pod logs
3. Prometheus/Grafana
4. LangSmith traces

**Useful debugging commands:**
```bash
# Full cluster status
kubectl get all --all-namespaces

# Events across cluster
kubectl get events --all-namespaces --sort-by='.lastTimestamp' | tail -20

# Resource usage
kubectl top nodes
kubectl top pods -n NAMESPACE

# Describe everything
kubectl describe deployment DEPLOYMENT_NAME -n NAMESPACE
kubectl describe pod POD_NAME -n NAMESPACE
kubectl describe service SERVICE_NAME -n NAMESPACE
```

---

## Maintenance & Operations

### Daily Operations

```bash
# Check application health
make health-check

# View logs
make logs-staging  # or logs-production

# Check resource usage
kubectl top pods -n marketing-agent-staging
```

### Weekly Operations

```bash
# Review monitoring dashboards
# - Check error rates
# - Review latency metrics
# - Verify cost tracking

# Run manual evaluation
python scripts/run_evaluation.py --all
python scripts/generate_evaluation_report.py

# Review security scan results
# Check GitHub → Security → Dependabot alerts
```

### Monthly Operations

```bash
# Update dependencies
pip-compile requirements.in
npm update

# Rotate secrets
# - Generate new API keys
# - Update GitHub secrets
# - Update Kubernetes secrets

# Review and optimize costs
# - Check cloud provider bills
# - Optimize resource requests/limits
# - Review API usage (OpenAI, LangSmith)

# Backup databases
./scripts/backup-db.sh production
```

### Scaling Operations

```bash
# Scale deployments manually
kubectl scale deployment/backend --replicas=5 -n NAMESPACE

# Or update HPA
kubectl edit hpa backend-hpa -n NAMESPACE

# Add more nodes (varies by provider)
# AWS: Update Auto Scaling Group
# GKE: gcloud container clusters resize
# AKS: az aks scale
```

### Rollback Procedures

```bash
# Quick rollback
make rollback-staging  # or rollback-production

# Manual rollback
kubectl rollout undo deployment/backend -n NAMESPACE
kubectl rollout undo deployment/frontend -n NAMESPACE

# Rollback to specific revision
kubectl rollout history deployment/backend -n NAMESPACE
kubectl rollout undo deployment/backend --to-revision=2 -n NAMESPACE

# Using deployment script
./scripts/rollback.sh production
```

### Disaster Recovery

```bash
# Backup everything
./scripts/backup-db.sh production
kubectl get all -n marketing-agent-production -o yaml > backup-k8s.yaml
helm list --all-namespaces -o yaml > backup-helm.yaml

# Store backups securely
aws s3 cp backup-db.sql s3://backups/$(date +%Y%m%d)/
# Or: gsutil cp backup-db.sql gs://backups/$(date +%Y%m%d)/

# Restore database
./scripts/restore-db.sh production backup-db.sql

# Re-deploy from scratch
kubectl apply -k infrastructure/k8s/base/
kubectl apply -k infrastructure/k8s/production/
```

---

## Next Steps

After completing this setup:

1. **Configure custom domain**:
   ```bash
   # Update ingress with your domain
   kubectl edit ingress -n marketing-agent-production
   # Add TLS certificate (cert-manager)
   ```

2. **Set up alerting**:
   ```bash
   # Configure AlertManager
   # Add PagerDuty/Slack integration
   # Set up alert rules
   ```

3. **Enable autoscaling**:
   ```bash
   # HPA is already configured
   # Verify metrics server is running
   kubectl get hpa -n marketing-agent-production
   ```

4. **Optimize costs**:
   - Review resource requests/limits
   - Setup spot instances/preemptible nodes
   - Configure pod disruption budgets

5. **Enhance security**:
   - Enable network policies
   - Setup pod security policies
   - Configure RBAC properly
   - Rotate secrets regularly

6. **Improve observability**:
   - Add custom Grafana dashboards
   - Configure log aggregation (ELK/Loki)
   - Setup distributed tracing
   - Add business metrics

---

## Summary

You now have:

✅ **Complete CI/CD pipeline** with automated testing and deployment  
✅ **Multi-environment setup** (staging, production, canary)  
✅ **AI evaluation framework** with quality gates  
✅ **Monitoring stack** with Prometheus and Grafana  
✅ **Observability** with LangSmith tracing  
✅ **Security scanning** with automated checks  
✅ **Rollback capabilities** for quick recovery  
✅ **Documentation** for operations and maintenance  

**Total Infrastructure:**
- 6 GitHub Actions workflows
- 3 Kubernetes environments
- 10+ deployment scripts
- Full monitoring stack
- Automated evaluation pipeline

**Time to deploy a change:** < 10 minutes  
**Time to rollback:** < 2 minutes  
**Evaluation runs:** Automatic on every PR  
**Monitoring coverage:** 100%  

🎉 **Your CI/CD pipeline is production-ready!**

---

## Support & Resources

- **Documentation**: `/docs` folder in repository
- **Runbooks**: `/docs/runbooks` for common tasks
- **Architecture**: `/docs/architecture` for system design
- **API Docs**: `http://YOUR_DOMAIN/docs` (Swagger)
- **Monitoring**: `http://YOUR_DOMAIN/grafana`

For questions or issues:
1. Check troubleshooting section
2. Review GitHub Actions logs
3. Check Kubernetes events
4. Review monitoring dashboards
5. Create an issue in the repository

**Happy deploying! 🚀**
