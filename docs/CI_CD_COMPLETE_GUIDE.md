# Complete CI/CD Learning Guide

> **Purpose**: Comprehensive guide to understanding and using the CI/CD pipeline in this project

---

## Table of Contents

1. [What is CI/CD?](#what-is-cicd)
2. [Pipeline Overview](#pipeline-overview)
3. [Continuous Integration (CI)](#continuous-integration-ci)
4. [Continuous Deployment (CD)](#continuous-deployment-cd)
5. [Docker & Containerization](#docker--containerization)
6. [Kubernetes Deployment](#kubernetes-deployment)
7. [Infrastructure as Code (Terraform)](#infrastructure-as-code-terraform)
8. [Hands-On Tutorial](#hands-on-tutorial)
9. [Troubleshooting Guide](#troubleshooting-guide)
10. [Best Practices](#best-practices)

---

## What is CI/CD?

### CI/CD Definition

**CI (Continuous Integration)**
- Automatically build and test code on every commit
- Catch bugs early in development
- Ensure code quality through automated checks
- Maintain a working main branch

**CD (Continuous Deployment)**
- Automatically deploy code to staging/production
- Reduce manual deployment work
- Enable faster release cycles
- Minimize human error

### Why CI/CD Matters

| Without CI/CD | With CI/CD |
|---------------|------------|
| Manual testing (slow, error-prone) | Automated testing (fast, consistent) |
| Deploy at end of sprint | Deploy multiple times per day |
| Integration issues discovered late | Problems caught immediately |
| Stressful deployments | Confident deployments |
| Hours to deploy | Minutes to deploy |

---

## Pipeline Overview

### Complete Workflow

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         DEVELOPMENT WORKFLOW                             │
└──────────────────────────────────────────────────────────────────────────┘

Developer writes code
        ↓
    git commit
        ↓
    git push
        ↓
┌───────────────────────────────────────────────────────────────────────────┐
│                      CONTINUOUS INTEGRATION (CI)                          │
├───────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  1. Checkout code from Git                                              │
│  2. Install dependencies                                                │
│  3. Run linters (code style checks)                                     │
│  4. Run type checkers                                                    │
│  5. Run unit tests                                                       │
│  6. Run integration tests                                                │
│  7. Calculate code coverage                                              │
│  8. Build Docker images (test)                                           │
│  9. Run smoke tests                                                      │
│                                                                           │
│  ✅ All checks pass → Code is ready to merge                            │
│  ❌ Any check fails → Fix and push again                                │
│                                                                           │
└───────────────────────────────────────────────────────────────────────────┘
        ↓
    Merge to main
        ↓
┌───────────────────────────────────────────────────────────────────────────┐
│                   CONTINUOUS DEPLOYMENT (CD)                              │
├───────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  1. Build production Docker images                                      │
│  2. Push images to container registry                                    │
│  3. Deploy to STAGING environment                                        │
│     - Run database migrations                                            │
│     - Update Kubernetes deployments                                      │
│     - Health checks                                                      │
│     - Post-deployment tests                                              │
│  4. [Manual approval or wait time]                                       │
│  5. Deploy to PRODUCTION                                                 │
│     - Create database backup                                             │
│     - Run database migrations                                            │
│     - Rolling update (zero downtime)                                     │
│     - Health checks                                                      │
│     - Verification                                                       │
│     - Notify team                                                        │
│                                                                           │
│  ✅ Deployment successful → Users see new features                      │
│  ❌ Health checks fail → Automatic rollback                             │
│                                                                           │
└───────────────────────────────────────────────────────────────────────────┘
        ↓
    Users enjoy new features!
```

---

## Continuous Integration (CI)

### What is CI?

Continuous Integration automatically:
- **Validates** your code works
- **Tests** all functionality
- **Checks** code quality
- **Builds** deployable artifacts

### CI Pipeline Jobs

#### 1. Backend Lint and Test

**Purpose**: Ensure Python code is high quality

```yaml
# Located in: .github/workflows/ci.yml

Steps:
1. Setup Python environment
2. Install dependencies
3. Run Black (code formatter)
4. Run Ruff (linter)
5. Run MyPy (type checker)
6. Run unit tests with coverage
7. Run integration tests
8. Upload coverage to Codecov
```

**What each tool does:**

| Tool | Purpose | Example Check |
|------|---------|---------------|
| **Black** | Code formatting | Ensures consistent indentation |
| **Ruff** | Linting | Finds unused imports, undefined variables |
| **MyPy** | Type checking | Catches type mismatches |
| **Pytest** | Testing | Runs all tests, measures coverage |

#### 2. Frontend Lint and Build

**Purpose**: Ensure TypeScript/React code is correct

```yaml
Steps:
1. Setup Node.js environment
2. Install npm dependencies
3. Run ESLint (JavaScript/TypeScript linter)
4. Run TypeScript compiler (type check)
5. Build production bundle with Vite
6. Upload build artifacts
```

#### 3. Docker Build Test

**Purpose**: Verify application can be containerized

```yaml
Steps:
1. Setup Docker Buildx (multi-platform builds)
2. Build backend Docker image
3. Build frontend Docker image
4. Use caching for speed
```

**Why test Docker builds in CI?**
- Catches Dockerfile errors early
- Ensures all dependencies are included
- Validates multi-stage builds work
- Confirms images can be built consistently

#### 4. Smoke Tests

**Purpose**: Quick end-to-end sanity check

**What are smoke tests?**
- Fast tests of critical functionality
- Run against real database and cache
- Verify main features work
- Catch integration issues

**Example smoke tests:**
```python
def test_api_health():
    """API server responds to health check"""
    assert client.get("/health").status_code == 200

def test_database_connection():
    """Can connect to database"""
    assert db.execute("SELECT 1").scalar() == 1

def test_create_campaign():
    """Can create a campaign"""
    response = client.post("/campaigns", json={...})
    assert response.status_code == 201
```

### How to View CI Results

1. **Go to GitHub repository**
2. **Click "Actions" tab**
3. **See workflow runs:**
   - ✅ Green checkmark = passed
   - ❌ Red X = failed
   - 🟡 Yellow dot = running
4. **Click any workflow to see details**
5. **Click any job to see logs**

### When CI Fails

**Failed linting:**
```bash
# Fix locally
black src/ tests/
ruff check --fix src/ tests/

# Commit and push
git add .
git commit -m "fix: apply linting fixes"
git push
```

**Failed tests:**
```bash
# Run tests locally
pytest tests/unit/

# Fix the failing test
# Commit and push the fix
```

**Failed build:**
```bash
# Test Docker build locally
docker build -f infrastructure/docker/Dockerfile.backend .

# Fix Dockerfile issues
# Commit and push
```

---

## Continuous Deployment (CD)

### What is CD?

Continuous Deployment automatically:
- **Builds** production-ready images
- **Deploys** to staging and production
- **Monitors** deployment health
- **Rolls back** if issues detected

### Deployment Environments

| Environment | Purpose | When Deployed | URL |
|-------------|---------|---------------|-----|
| **Development** | Local development | Never (docker-compose) | localhost |
| **Staging** | Pre-production testing | Every merge to main | staging.example.com |
| **Production** | Live users | Version tags (v1.0.0) | example.com |
| **Canary** | Gradual rollout | Manual trigger | canary.example.com |

### CD Pipeline Jobs

#### 1. Build and Push

**Purpose**: Create production Docker images

```yaml
Steps:
1. Login to container registry (ghcr.io)
2. Extract metadata (generate tags)
3. Build multi-platform images:
   - linux/amd64 (Intel/AMD)
   - linux/arm64 (ARM/Graviton)
4. Push to registry
5. Output image tags for deployment jobs
```

**Image tagging strategy:**

For commit to main branch:
- `ghcr.io/myorg/backend:main`
- `ghcr.io/myorg/backend:main-abc123`
- `ghcr.io/myorg/backend:latest`

For version tag v1.2.3:
- `ghcr.io/myorg/backend:1.2.3`
- `ghcr.io/myorg/backend:1.2`
- `ghcr.io/myorg/backend:latest`

#### 2. Deploy to Staging

**Purpose**: Test in production-like environment

```yaml
Steps:
1. Setup kubectl (Kubernetes CLI)
2. Configure access to staging cluster
3. Run database migrations
4. Update backend deployment
5. Update frontend deployment
6. Wait for health checks
7. Run post-deployment tests
```

**Kubernetes Rolling Update:**

```
Before:                  During:                   After:
┌─────┐ ┌─────┐         ┌─────┐ ┌─────┐          ┌─────┐ ┌─────┐
│ v1.0│ │ v1.0│         │ v1.0│ │ v1.1│          │ v1.1│ │ v1.1│
│ Old │ │ Old │   →     │ Old │ │ New │    →     │ New │ │ New │
└─────┘ └─────┘         └─────┘ └─────┘          └─────┘ └─────┘

Step 1: Create new pod with v1.1
Step 2: Wait for health check ✅
Step 3: Route traffic to new pod
Step 4: Terminate old pod
Step 5: Repeat for remaining pods
```

**Zero Downtime!** Old pods stay running until new pods are healthy.

#### 3. Deploy to Production

**Purpose**: Make features available to users

**Safety mechanisms:**
1. **Requires staging success** - won't deploy if staging failed
2. **Creates database backup** - can restore if needed
3. **Health checks** - automatically rollback if unhealthy
4. **Manual approval** (optional) - human verification
5. **Verification step** - tests critical endpoints

```yaml
Production deployment steps:
1. Checkout code
2. Setup kubectl
3. ⚠️  CREATE DATABASE BACKUP ⚠️
4. Run database migrations
5. Update backend (rolling update)
6. Update frontend (rolling update)
7. Health checks (wait for ready)
8. Verify deployment (curl health endpoint)
9. Notify team (Slack, email, etc.)
```

**Production deployment checklist:**
- [ ] All CI checks passed
- [ ] Staging deployment successful
- [ ] QA team tested staging
- [ ] Database backup created
- [ ] Rollback plan ready
- [ ] Team notified

#### 4. Canary Deployment

**Purpose**: Test with small percentage of real users

**Canary strategy:**

```
┌──────────────────────┐
│   Load Balancer      │
└──────┬───────────────┘
       │
  ┌────┴─────┬─────────┐
  │ 90%      │ 10%     │
  │          │         │
┌─▼───┐   ┌──▼──┐
│Stable│   │Canary│
│ v1.0 │   │ v1.1 │
└─────┘   └─────┘

90% of users see stable version
10% of users see new version

Monitor metrics:
- Error rate
- Response time
- User feedback

If good → Increase to 25%, 50%, 100%
If bad → Rollback to 100% stable
```

**When to use canary:**
- Risky changes (major refactoring)
- New features (unproven in production)
- Performance changes
- Third-party integrations

---

## Docker & Containerization

### What is Docker?

Docker packages your application with all dependencies into a "container" - a lightweight, portable unit that runs anywhere.

### Why Use Docker?

| Problem | Docker Solution |
|---------|----------------|
| "Works on my machine" | Same environment everywhere |
| Complex setup process | One command to run |
| Dependency conflicts | Isolated containers |
| Scaling is hard | Spin up more containers |

### Docker Concepts

#### Images

A **Docker image** is a template containing:
- Operating system (Alpine Linux)
- Runtime (Python, Node.js)
- Application code
- Dependencies
- Configuration

```dockerfile
# Example Dockerfile
FROM python:3.11-alpine              # Base image
WORKDIR /app                         # Working directory
COPY requirements.txt .              # Copy dependency list
RUN pip install -r requirements.txt  # Install dependencies
COPY src/ ./src/                     # Copy application code
CMD ["python", "src/main.py"]        # Command to run
```

#### Containers

A **Docker container** is a running instance of an image.

```bash
# Create container from image
docker run -p 8000:8000 my-backend-image

# Container is isolated:
# - Own filesystem
# - Own network
# - Own processes
# - Can't affect host system
```

#### Registry

A **Docker registry** stores images.

Popular registries:
- **Docker Hub** - docker.io (public)
- **GitHub Container Registry** - ghcr.io (we use this!)
- **Amazon ECR** - AWS
- **Google Container Registry** - GCP

```bash
# Push image to registry
docker push ghcr.io/myorg/backend:v1.0.0

# Pull image from registry
docker pull ghcr.io/myorg/backend:v1.0.0

# Now anyone can run your app:
docker run ghcr.io/myorg/backend:v1.0.0
```

### Docker Compose

**Docker Compose** runs multiple containers together.

```yaml
# docker-compose.yml
services:
  backend:      # Container 1
    image: my-backend
    ports:
      - "8000:8000"
  
  postgres:     # Container 2
    image: postgres:15
    ports:
      - "5432:5432"
  
  redis:        # Container 3
    image: redis:7
    ports:
      - "6379:6379"
```

```bash
# Start all services
docker-compose up

# One command runs:
# - Backend API
# - PostgreSQL database
# - Redis cache
# All connected and ready!
```

### Docker Commands Cheat Sheet

```bash
# BUILD
docker build -t my-image .                    # Build image from Dockerfile
docker build -t my-image --no-cache .         # Build without cache

# RUN
docker run my-image                           # Run container
docker run -d my-image                        # Run in background
docker run -p 8000:8000 my-image             # Expose port
docker run -e ENV=prod my-image              # Set environment variable
docker run -v $(pwd):/app my-image           # Mount volume

# LIST
docker ps                                     # List running containers
docker ps -a                                  # List all containers
docker images                                 # List images

# LOGS
docker logs <container-id>                    # View logs
docker logs -f <container-id>                 # Follow logs

# EXEC
docker exec <container-id> <command>          # Run command in container
docker exec -it <container-id> bash           # Interactive shell

# STOP/REMOVE
docker stop <container-id>                    # Stop container
docker rm <container-id>                      # Remove container
docker rmi <image-id>                         # Remove image

# COMPOSE
docker-compose up                             # Start services
docker-compose up -d                          # Start in background
docker-compose down                           # Stop services
docker-compose logs -f                        # View logs
docker-compose ps                             # List services
docker-compose restart                        # Restart services
```

---

## Kubernetes Deployment

### What is Kubernetes?

**Kubernetes** (k8s) orchestrates containers across multiple servers.

Think of it as "Docker Compose for production":
- Runs containers on many servers
- Automatically restarts failed containers
- Scales up/down based on load
- Performs zero-downtime deployments
- Provides load balancing
- Manages secrets and configuration

### Kubernetes Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      KUBERNETES CLUSTER                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────┐  ┌──────────────────┐  ┌─────────────┐  │
│  │   Control Plane   │  │      Node 1      │  │   Node 2    │  │
│  │                   │  │                  │  │             │  │
│  │  - API Server     │  │  ┌────────────┐  │  │ ┌─────────┐ │  │
│  │  - Scheduler      │  │  │ Backend Pod│  │  │ │Backend  │ │  │
│  │  - Controller     │  │  │  (v1.2.3)  │  │  │ Pod     │ │  │
│  │                   │  │  └────────────┘  │  │ (v1.2.3)│ │  │
│  └──────────────────┘  │                  │  │ └─────────┘ │  │
│                        │  ┌────────────┐  │  │             │  │
│                        │  │Frontend Pod│  │  │ ┌─────────┐ │  │
│                        │  │  (v2.1.0)  │  │  │ │Database │ │  │
│                        │  └────────────┘  │  │ │ Pod     │ │  │
│                        └──────────────────┘  │ └─────────┘ │  │
│                                              └─────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Kubernetes Resources

#### Pods

**Pod** = smallest unit in Kubernetes, wraps 1+ containers

```yaml
# Pod with one container
apiVersion: v1
kind: Pod
metadata:
  name: backend-pod
spec:
  containers:
  - name: backend
    image: ghcr.io/myorg/backend:v1.0.0
    ports:
    - containerPort: 8000
```

#### Deployments

**Deployment** = manages multiple pod replicas

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-deployment
spec:
  replicas: 3  # Run 3 pod copies
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: ghcr.io/myorg/backend:v1.0.0
        ports:
        - containerPort: 8000
        livenessProbe:           # Health check
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
```

**What deployments do:**
- Maintain desired replica count
- Perform rolling updates
- Enable rollbacks
- Replace failed pods automatically

#### Services

**Service** = stable network endpoint for pods

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 8000
  type: LoadBalancer  # External IP
```

**Why services?**
- Pods get deleted/recreated (IPs change)
- Service provides stable endpoint
- Load balances across pod replicas

#### Ingress

**Ingress** = HTTP(S) router to services

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: main-ingress
spec:
  rules:
  - host: example.com
    http:
      paths:
      - path: /api
        backend:
          service:
            name: backend-service
            port: 80
      - path: /
        backend:
          service:
            name: frontend-service
            port: 80
```

### kubectl Commands

```bash
# CLUSTER INFO
kubectl cluster-info              # Cluster details
kubectl get nodes                 # List servers

# PODS
kubectl get pods                  # List pods
kubectl get pods -n staging       # Pods in namespace
kubectl describe pod <name>       # Pod details
kubectl logs <pod-name>           # View logs
kubectl logs -f <pod-name>        # Follow logs
kubectl exec -it <pod> -- bash    # Shell into pod

# DEPLOYMENTS
kubectl get deployments           # List deployments
kubectl describe deployment <name>  # Deployment details
kubectl scale deployment <name> --replicas=5  # Scale to 5 pods
kubectl rollout status deployment/<name>      # Check rollout
kubectl rollout undo deployment/<name>        # Rollback

# SERVICES
kubectl get services              # List services
kubectl describe service <name>   # Service details

# UPDATE
kubectl set image deployment/<name> \
  container=<new-image>           # Update image
kubectl apply -f manifest.yaml    # Apply YAML config

# DELETE
kubectl delete pod <name>         # Delete pod
kubectl delete deployment <name>  # Delete deployment
```

---

## Infrastructure as Code (Terraform)

### What is Terraform?

**Terraform** creates cloud infrastructure using code, not clicks.

**Traditional approach:**
1. Login to AWS console
2. Click "Create VPC"
3. Click "Create subnet"
4. Click "Create EC2 instance"
5. ... 50 more clicks ...
6. Document what you did
7. Repeat for staging and production

**Terraform approach:**
1. Write infrastructure as code
2. `terraform apply`
3. Everything created automatically
4. Reproducible and version controlled

### Why Terraform?

| Benefit | Description |
|---------|-------------|
| **Reproducible** | Same code = same infrastructure |
| **Version controlled** | Infrastructure changes tracked in Git |
| **Documentation** | Code IS documentation |
| **Multi-cloud** | Works with AWS, GCP, Azure, etc. |
| **Automated** | No manual clicking |
| **Safe** | Preview changes before applying |

### Terraform Workflow

```bash
# 1. INITIALIZE
terraform init
# Downloads providers (AWS, GCP, etc.)
# Sets up backend (where state is stored)

# 2. PLAN
terraform plan -out=tfplan
# Shows what will be created/changed/destroyed
# Saves plan to file

# 3. APPLY
terraform apply tfplan
# Creates/updates infrastructure
# Updates state file

# 4. DESTROY (when needed)
terraform destroy
# Deletes all managed infrastructure
```

### Terraform File Structure

```
infrastructure/terraform/
├── main.tf             # Main configuration
├── variables.tf        # Input variables
├── outputs.tf          # Output values
├── terraform.tfvars    # Variable values
├── aws.tf             # AWS resources
├── gcp.tf             # GCP resources
├── azure.tf           # Azure resources
├── iam.tf             # IAM roles and policies
└── monitoring.tf      # Monitoring setup
```

### Example: Creating AWS Resources

```hcl
# infrastructure/terraform/aws.tf

# CREATE VPC (Virtual Private Cloud)
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
  }
}

# CREATE SUBNET
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  
  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

# CREATE KUBERNETES CLUSTER (EKS)
resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-${var.environment}"
  role_arn = aws_iam_role.cluster.arn
  
  vpc_config {
    subnet_ids = [aws_subnet.public.id]
  }
}

# CREATE RDS DATABASE
resource "aws_db_instance" "postgres" {
  identifier        = "${var.project_name}-db"
  engine            = "postgres"
  engine_version    = "15.4"
  instance_class    = "db.t3.medium"
  allocated_storage = 100
  
  db_name  = "marketing_agent"
  username = "postgres"
  password = var.db_password  # From variables
  
  backup_retention_period = 7
  skip_final_snapshot     = false
}
```

### Terraform State

**State file** tracks what Terraform has created.

```
Without state file:
- Terraform doesn't know what exists
- Can't update or destroy resources
- Would try to recreate everything

With state file:
- Tracks all managed resources
- Enables updates and deletions
- Provides audit trail
```

**State file security:**
```hcl
# Store state in S3 (remote backend)
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

**Why remote state?**
- Team collaboration (shared state)
- State locking (prevent conflicts)
- Encryption (security)
- Versioning (rollback)
- Backup (disaster recovery)

### Terraform Variables

```hcl
# variables.tf
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Must be dev, staging, or prod"
  }
}

variable "instance_count" {
  description = "Number of instances"
  type        = number
  default     = 3
}

# terraform.tfvars
environment    = "production"
instance_count = 5
region         = "us-east-1"

# Use in resources
resource "aws_instance" "app" {
  count         = var.instance_count
  instance_type = var.environment == "production" ? "t3.large" : "t3.medium"
}
```

---

## Hands-On Tutorial

### Tutorial 1: Running the Application Locally

**Goal**: Run the full application on your machine

```bash
# Step 1: Clone repository
git clone https://github.com/yourusername/marketing-agent.git
cd marketing-agent

# Step 2: Create .env file
cat > .env << EOF
OPENAI_API_KEY=your_key_here
ANTHROPIC_API_KEY=your_key_here
EOF

# Step 3: Start all services
docker-compose up

# Step 4: Wait for services to be ready
# Look for these log messages:
# ✅ postgres  | database system is ready
# ✅ redis     | Ready to accept connections
# ✅ backend   | Started server on 0.0.0.0:8000
# ✅ frontend  | ready - localhost:4173

# Step 5: Access the application
# Frontend: http://localhost
# Backend API: http://localhost:8000
# API Docs: http://localhost:8000/docs

# Step 6: Test the application
# - Open browser to http://localhost
# - Create a campaign
# - View analytics

# Step 7: View logs
docker-compose logs -f backend    # Backend logs
docker-compose logs -f postgres   # Database logs

# Step 8: Stop services
docker-compose down              # Stop and remove containers
docker-compose down -v           # Also delete database data
```

**Troubleshooting:**

```bash
# Port already in use?
sudo lsof -i :8000               # Find process using port 8000
kill <PID>                       # Kill the process

# Permission denied?
sudo docker-compose up           # Run with sudo (Linux only)

# Service won't start?
docker-compose logs <service>    # Check logs
docker-compose restart <service>  # Restart specific service
docker-compose up --build        # Rebuild images
```

### Tutorial 2: Making a Code Change

**Goal**: Modify code and see it deployed

```bash
# Step 1: Create a feature branch
git checkout -b feature/add-campaign-tags

# Step 2: Make code changes
# Edit: src/api/campaigns.py
# Add new feature or fix bug

# Step 3: Test locally
docker-compose up
# Test your changes in browser

# Step 4: Run tests
pytest tests/unit/

# Step 5: Commit changes
git add src/api/campaigns.py tests/unit/test_campaigns.py
git commit -m "feat: add tags to campaigns"

# Step 6: Push to GitHub
git push origin feature/add-campaign-tags

# Step 7: Create Pull Request
# Go to GitHub
# Click "New Pull Request"
# Select your branch
# Fill in description
# Click "Create Pull Request"

# Step 8: Watch CI run
# Go to "Actions" tab
# Watch your PR being checked
# ✅ All checks should pass

# Step 9: Get code review
# Request review from teammate
# Address feedback
# Push new commits

# Step 10: Merge to main
# Click "Merge pull request"
# CI runs again on main branch
# CD automatically deploys to staging!

# Step 11: Test in staging
# Go to https://staging.marketing-agent.example.com
# Verify your changes work

# Step 12: Deploy to production
git tag v1.0.1
git push origin v1.0.1
# CD automatically deploys to production!

# Step 13: Verify production
# Go to https://marketing-agent.example.com
# Verify your changes work for users
```

### Tutorial 3: Deploying Infrastructure with Terraform

**Goal**: Create cloud infrastructure

```bash
# Step 1: Navigate to Terraform directory
cd infrastructure/terraform

# Step 2: Create tfvars file
cat > terraform.tfvars << EOF
cloud_provider = "aws"
environment    = "staging"
region         = "us-east-1"
cluster_name   = "marketing-agent-staging"
project_name   = "marketing-agent"
EOF

# Step 3: Initialize Terraform
terraform init
# Downloads AWS provider
# Configures S3 backend

# Step 4: Validate configuration
terraform validate
# Checks syntax
# ✅ Success! The configuration is valid.

# Step 5: Plan infrastructure
terraform plan -out=tfplan
# Shows what will be created:
# + aws_vpc.main
# + aws_subnet.public
# + aws_subnet.private
# + aws_eks_cluster.main
# + aws_db_instance.postgres
# + aws_elasticache_cluster.redis
# ... and more ...
# 
# Plan: 45 to add, 0 to change, 0 to destroy

# Step 6: Review the plan carefully
# Check resource names
# Verify configurations
# Ensure costs are acceptable

# Step 7: Apply the plan
terraform apply tfplan
# Creates all resources
# Takes 10-15 minutes

# Step 8: Save outputs
terraform output > outputs.txt
# Saves important values:
# - Cluster endpoint
# - Database endpoint
# - Load balancer URL

# Step 9: Configure kubectl
aws eks update-kubeconfig --name marketing-agent-staging

# Step 10: Verify cluster
kubectl get nodes
# Should show EKS worker nodes

# Step 11: Deploy application
kubectl apply -f ../k8s/base/
kubectl apply -f ../k8s/staging/

# Step 12: Get load balancer URL
kubectl get ingress
# Access application at the URL

# Cleanup (when done testing)
terraform destroy
# Deletes all resources
# Type 'yes' to confirm
```

---

## Troubleshooting Guide

### CI Pipeline Issues

#### "Tests are failing"

```bash
# Run tests locally to reproduce
pytest tests/unit/ -v

# Common causes:
# 1. Missing dependency
pip install -e ".[dev]"

# 2. Environment variable not set
export DATABASE_URL="postgresql://localhost/test_db"

# 3. Database not running
docker-compose up postgres redis

# 4. Flaky test (intermittent failures)
pytest tests/unit/test_flaky.py --count=10  # Run 10 times
```

#### "Docker build failing"

```bash
# Test build locally
docker build -f infrastructure/docker/Dockerfile.backend .

# Common causes:
# 1. Missing file
# Check COPY commands in Dockerfile

# 2. Wrong base image
# Verify FROM line

# 3. Build context issues
# Ensure build context includes needed files

# 4. Cache issues
docker build --no-cache .  # Build without cache
```

#### "black formatting check failed"

```bash
# View what needs formatting
black --check src/ tests/

# Auto-fix formatting
black src/ tests/

# Commit format changes
git add src/ tests/
git commit -m "style: apply black formatting"
git push
```

### CD Pipeline Issues

#### "Deployment stuck"

```bash
# Check deployment status
kubectl rollout status deployment/marketing-agent-backend -n staging

# Check pod events
kubectl describe pod <pod-name> -n staging

# Common causes:
# 1. Image pull error
kubectl describe pod <pod-name> | grep -A 5 "Events:"

# 2. Health check failing
kubectl logs <pod-name> -n staging

# 3. Resource limits
kubectl top pods -n staging

# Rollback
kubectl rollout undo deployment/marketing-agent-backend -n staging
```

#### "Database migration failed"

```bash
# Connect to pod
kubectl exec -it deployment/marketing-agent-backend -n staging -- bash

# Check migration status
alembic current

# Run migrations manually
alembic upgrade head

# If migration is broken:
alembic downgrade -1    # Rollback one migration
# Fix migration file
# Try again
```

#### "Health check timeout"

```bash
# Check what's failing
kubectl get pods -n staging

# Get pod logs
kubectl logs <pod-name> -n staging --tail=100

# Common causes:
# 1. Application crashing
# Check logs for errors

# 2. Health endpoint not responding
# Test: curl http://pod-ip:8000/health

# 3. Slow startup
# Increase initialDelaySeconds in deployment

# 4. Port mismatch
# Verify containerPort matches livenessProbe port
```

### Docker Issues

#### "Port already in use"

```bash
# Find process using port
sudo lsof -i :8000

# Kill process
kill <PID>

# Or change port in docker-compose.yml
ports:
  - "8001:8000"  # Use 8001 on host instead
```

#### "Permission denied"

```bash
# Linux: Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Or run with sudo
sudo docker-compose up
```

#### "Volume mount not working"

```bash
# Windows: Enable file sharing
# Docker Desktop → Settings → Resources → File Sharing
# Add your project directory

# Linux: Check permissions
ls -la $(pwd)
chmod +r src/

# Mac: Grant Docker access
# System Preferences → Security → Files and Folders → Docker
```

### Kubernetes Issues

#### "kubectl: command not found"

```bash
# Install kubectl
# Mac:
brew install kubectl

# Windows:
choco install kubernetes-cli

# Linux:
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

#### "Error: Unauthorized"

```bash
# Update kubeconfig
aws eks update-kubeconfig --name my-cluster --region us-east-1

# Or manually set context
kubectl config use-context my-cluster

# Verify
kubectl cluster-info
```

#### "ImagePullBackOff"

```bash
# Describe pod to see error
kubectl describe pod <pod-name>

# Common causes:
# 1. Image doesn't exist
docker pull <image-name>  # Test locally

# 2. Wrong image name/tag
# Check deployment manifest

# 3. Registry authentication
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=<username> \
  --docker-password=<token>
```

---

## Best Practices

### Code Quality

#### Write Good Commit Messages

```bash
# ✅ Good commit messages
git commit -m "feat: add campaign tags feature"
git commit -m "fix: resolve database connection timeout"
git commit -m "docs: update API documentation"

# ❌ Bad commit messages
git commit -m "update"
git commit -m "fix bug"
git commit -m "asdf"
```

**Conventional Commits format:**
```
<type>: <description>

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting
- `refactor`: Code restructuring
- `test`: Testing
- `chore`: Maintenance

#### Write Tests First

```python
# TDD: Test-Driven Development

# 1. Write failing test
def test_create_campaign():
    response = client.post("/campaigns", json={
        "name": "Summer Sale",
        "budget": 10000
    })
    assert response.status_code == 201
    assert response.json()["name"] == "Summer Sale"

# 2. Run test (should fail)
pytest tests/unit/test_campaigns.py::test_create_campaign
# ❌ FAILED

# 3. Implement feature
def create_campaign(campaign: CampaignCreate):
    db_campaign = Campaign(**campaign.dict())
    db.add(db_campaign)
    db.commit()
    return db_campaign

# 4. Run test (should pass)
pytest tests/unit/test_campaigns.py::test_create_campaign
# ✅ PASSED
```

#### Keep Functions Small

```python
# ❌ Bad: Long, complex function
def process_campaign(campaign_id):
    campaign = db.query(Campaign).get(campaign_id)
    if not campaign:
        raise NotFound()
    if campaign.status != "draft":
        raise InvalidStatus()
    ad_groups = db.query(AdGroup).filter_by(campaign_id=campaign_id).all()
    for ad_group in ad_groups:
        ads = db.query(Ad).filter_by(ad_group_id=ad_group.id).all()
        for ad in ads:
            if ad.status == "paused":
                ad.status = "active"
                db.add(ad)
    campaign.status = "active"
    db.add(campaign)
    db.commit()
    send_notification(campaign.user_id, "Campaign activated")
    log_event("campaign_activated", campaign_id)
    return campaign

# ✅ Good: Small, focused functions
def activate_campaign(campaign_id: int) -> Campaign:
    """Activate a campaign and all its ads."""
    campaign = get_campaign_or_404(campaign_id)
    validate_campaign_can_be_activated(campaign)
    activate_campaign_ads(campaign)
    update_campaign_status(campaign, "active")
    notify_and_log_activation(campaign)
    return campaign

def validate_campaign_can_be_activated(campaign: Campaign):
    """Ensure campaign is eligible for activation."""
    if campaign.status != "draft":
        raise InvalidStatus(f"Cannot activate {campaign.status} campaign")

def activate_campaign_ads(campaign: Campaign):
    """Activate all paused ads in the campaign."""
    ad_groups = get_campaign_ad_groups(campaign.id)
    for ad_group in ad_groups:
        activate_ad_group_ads(ad_group)
```

### CI/CD Best Practices

#### Fast Feedback

```yaml
# ✅ Good: Fast tests first
jobs:
  quick-checks:
    - lint (2 mins)
    - type-check (1 min)
    - unit tests (3 mins)
  
  slow-checks:
    needs: quick-checks
    - integration tests (10 mins)
    - e2e tests (20 mins)

# Developers get feedback in 6 minutes instead of 36!
```

#### Fail Fast

```yaml
# ✅ Stop on first failure
- name: Run tests
  run: pytest --exitfirst  # Stop at first failure

# ❌ Don't run all tests if early ones fail
# Wastes time and CI resources
```

#### Cache Dependencies

```yaml
# ✅ Cache pip packages
- uses: actions/setup-python@v5
  with:
    cache: 'pip'

# ✅ Cache npm packages
- uses: actions/setup-node@v4
  with:
    cache: 'npm'

# ✅ Cache Docker layers
- uses: docker/build-push-action@v5
  with:
    cache-from: type=gha
    cache-to: type=gha,mode=max

# Reduces build time by 70%!
```

### Deployment Best Practices

#### Blue-Green Deployment

```
Blue-Green Strategy:

Current (Blue):        New (Green):
┌─────────┐           ┌─────────┐
│ v1.0.0  │           │ v1.1.0  │
│ Active  │           │ Standby │
└────┬────┘           └────┬────┘
     │                     │
     └──────────┬──────────┘
                ▼
          Load Balancer
                ▼
              Users

1. Deploy v1.1.0 to Green environment
2. Test Green thoroughly
3. Switch load balancer to Green
4. Blue becomes new standby
5. If issues, switch back to Blue (instant rollback)
```

#### Database Migrations

```python
# ✅ Good: Backward compatible migration

# Step 1: Add new column (nullable)
def upgrade():
    op.add_column('campaigns',
        sa.Column('tags', sa.ARRAY(sa.String), nullable=True))

# Step 2: Deploy code that uses new column
# (Old code ignores it, new code uses it)

# Step 3: Backfill data
def upgrade():
    op.execute("UPDATE campaigns SET tags = '{}' WHERE tags IS NULL")

# Step 4: Make column non-nullable
def upgrade():
    op.alter_column('campaigns', 'tags', nullable=False)

# Each step is independently deployable!


# ❌ Bad: Breaking migration
def upgrade():
    op.drop_column('campaigns', 'old_field')  # Old code breaks!
    op.add_column('campaigns', 'new_field')    # Can't roll back!
```

#### Feature Flags

```python
# Control features without deployment

# flagsmith.py
import flagsmith

flags = flagsmith.Flagsmith(environment_key=FLAGSMITH_KEY)

# api/campaigns.py
def create_campaign(campaign: CampaignCreate):
    campaign = save_campaign(campaign)
    
    # Only run new feature if flag enabled
    if flags.is_feature_enabled("ai-optimization"):
        optimize_campaign_with_ai(campaign)
    
    return campaign

# Benefits:
# ✅ Test in production with small user group
# ✅ Instant rollback (no deployment)
# ✅ Gradual rollout (5% → 25% → 100%)
# ✅ A/B testing built-in
```

#### Monitoring and Alerts

```python
# Monitor everything!

from prometheus_client import Counter, Histogram
import logging

# Metrics
request_count = Counter('http_requests_total', 'Total HTTP requests')
request_duration = Histogram('http_request_duration_seconds', 'HTTP request duration')

@app.post("/campaigns")
@request_duration.time()  # Measure duration
def create_campaign(campaign: CampaignCreate):
    request_count.inc()  # Count request
    
    try:
        result = save_campaign(campaign)
        logging.info(f"Campaign created: {result.id}")
        return result
    except Exception as e:
        logging.error(f"Campaign creation failed: {e}", exc_info=True)
        # Alert on-call engineer
        send_alert("Campaign creation failing", severity="high")
        raise

# Set up alerts:
# - Response time > 500ms
# - Error rate > 1%
# - Deployment failures
# - Database connection errors
```

### Security Best Practices

#### Secrets Management

```yaml
# ❌ NEVER commit secrets to Git
api_key: "sk_live_abc123xyz..."

# ✅ Use environment variables
api_key: ${OPENAI_API_KEY}

# ✅ Use secrets management
# GitHub Secrets, AWS Secrets Manager, HashiCorp Vault

# ✅ Use .env for local development (add to .gitignore)
echo "OPENAI_API_KEY=your_key" > .env
echo ".env" >> .gitignore
```

#### Least Privilege

```yaml
# ❌ Bad: Too much access
permissions:
  contents: write
  packages: write
  security-events: write

# ✅ Good: Only what's needed
permissions:
  contents: read     # Read code
  packages: write    # Push images
```

#### Dependency Scanning

```yaml
# GitHub Actions: Dependabot
# Automatically checks for vulnerable dependencies
# Creates PRs to update them

# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "pip"
    directory: "/"
    schedule:
      interval: "weekly"
```

---

## Conclusion

You now have a comprehensive understanding of:

✅ **Continuous Integration** - Automated testing and validation
✅ **Continuous Deployment** - Automated deployments to multiple environments
✅ **Docker** - Containerization for consistent environments
✅ **Kubernetes** - Container orchestration at scale
✅ **Terraform** - Infrastructure as code
✅ **Best Practices** - Code quality, security, monitoring

### What's Next?

1. **Practice** - Run through the tutorials
2. **Experiment** - Make changes and deploy them
3. **Read** - Study the commented workflow files
4. **Build** - Create your own CI/CD pipelines
5. **Share** - Teach others what you've learned

### Additional Resources

**Documentation:**
- GitHub Actions: https://docs.github.com/en/actions
- Docker: https://docs.docker.com/
- Kubernetes: https://kubernetes.io/docs/
- Terraform: https://www.terraform.io/docs/

**Tutorials:**
- GitHub Learning Lab: https://lab.github.com/
- Docker Getting Started: https://www.docker.com/get-started
- Kubernetes Tutorials: https://kubernetes.io/docs/tutorials/
- Terraform Tutorials: https://learn.hashicorp.com/terraform

**Books:**
- "Continuous Delivery" by Jez Humble
- "The DevOps Handbook" by Gene Kim
- "Site Reliability Engineering" by Google
- "Infrastructure as Code" by Kief Morris

---

**Questions?** Check the troubleshooting section or refer to the commented workflow files!

**Happy Learning! 🚀**
