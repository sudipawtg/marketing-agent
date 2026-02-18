# CI/CD Quick Reference Guide

> **Quick access to common commands and workflows**

---

## Table of Contents

- [Docker Commands](#docker-commands)
- [Docker Compose](#docker-compose)
- [Kubernetes (kubectl)](#kubernetes-kubectl)
- [Terraform](#terraform)
- [Git Workflow](#git-workflow)
- [GitHub Actions](#github-actions)
- [Troubleshooting](#troubleshooting)

---

## Docker Commands

### Building Images

```bash
# Build image from Dockerfile
docker build -t my-image:v1.0 .

# Build with no cache
docker build --no-cache -t my-image:v1.0 .

# Build with build args
docker build --build-arg ENV=production -t my-image:v1.0 .

# Build from specific Dockerfile
docker build -f infrastructure/docker/Dockerfile.backend -t backend:v1.0 .
```

### Running Containers

```bash
# Run container
docker run my-image

# Run with port mapping
docker run -p 8000:8000 my-image

# Run in background (detached)
docker run -d -p 8000:8000 my-image

# Run with environment variables
docker run -e DATABASE_URL=postgresql://... my-image

# Run with volume mount
docker run -v $(pwd)/src:/app/src my-image

# Run and remove after exit
docker run --rm my-image

# Run with custom name
docker run --name my-container my-image

# Run interactively
docker run -it my-image bash
```

### Managing Containers

```bash
# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# Stop container
docker stop <container-id>

# Start stopped container
docker start <container-id>

# Restart container
docker restart <container-id>

# Remove container
docker rm <container-id>

# Remove all stopped containers
docker container prune

# Force remove running container
docker rm -f <container-id>
```

### Managing Images

```bash
# List images
docker images

# Remove image
docker rmi <image-id>

# Remove all unused images
docker image prune -a

# Tag image
docker tag my-image:latest my-image:v1.0

# Push to registry
docker push ghcr.io/myorg/my-image:v1.0

# Pull from registry
docker pull ghcr.io/myorg/my-image:v1.0
```

### Logs and Debugging

```bash
# View container logs
docker logs <container-id>

# Follow logs (like tail -f)
docker logs -f <container-id>

# Last 100 lines
docker logs --tail 100 <container-id>

# Execute command in running container
docker exec <container-id> ls /app

# Get interactive shell
docker exec -it <container-id> bash

# Inspect container details
docker inspect <container-id>

# View container resource usage
docker stats

# View container processes
docker top <container-id>
```

---

## Docker Compose

### Basic Commands

```bash
# Start all services
docker-compose up

# Start in background
docker-compose up -d

# Stop services
docker-compose stop

# Stop and remove containers
docker-compose down

# Stop and remove containers + volumes (⚠️ DATA LOSS)
docker-compose down -v

# Restart all services
docker-compose restart

# Restart specific service
docker-compose restart backend
```

### Building and Updating

```bash
# Build/rebuild services
docker-compose build

# Build without cache
docker-compose build --no-cache

# Build and start
docker-compose up --build

# Pull latest images
docker-compose pull

# Recreate containers
docker-compose up -d --force-recreate
```

### Logs and Debugging

```bash
# View logs from all services
docker-compose logs

# Follow logs
docker-compose logs -f

# Logs from specific service
docker-compose logs backend

# Last 100 lines
docker-compose logs --tail=100

# Logs with timestamps
docker-compose logs -t
```

### Service Management

```bash
# List running services
docker-compose ps

# List all services (including stopped)
docker-compose ps -a

# Run command in service
docker-compose exec backend python manage.py migrate

# Run command in new container
docker-compose run backend pytest

# Scale service
docker-compose up -d --scale backend=3

# View service configuration
docker-compose config
```

---

## Kubernetes (kubectl)

### Cluster Info

```bash
# Cluster information
kubectl cluster-info

# List nodes
kubectl get nodes

# Node details
kubectl describe node <node-name>

# Cluster version
kubectl version
```

### Pods

```bash
# List pods
kubectl get pods

# List pods in specific namespace
kubectl get pods -n staging

# List pods with more details
kubectl get pods -o wide

# Pod details
kubectl describe pod <pod-name>

# Pod logs
kubectl logs <pod-name>

# Follow logs
kubectl logs -f <pod-name>

# Logs from previous container instance
kubectl logs <pod-name> --previous

# Execute command in pod
kubectl exec <pod-name> -- ls /app

# Interactive shell
kubectl exec -it <pod-name> -- bash

# Delete pod
kubectl delete pod <pod-name>
```

### Deployments

```bash
# List deployments
kubectl get deployments

# Deployment details
kubectl describe deployment <deployment-name>

# Update deployment image
kubectl set image deployment/<name> container=new-image:tag

# Scale deployment
kubectl scale deployment/<name> --replicas=5

# Check rollout status
kubectl rollout status deployment/<name>

# Rollout history
kubectl rollout history deployment/<name>

# Rollback to previous version
kubectl rollout undo deployment/<name>

# Rollback to specific revision
kubectl rollout undo deployment/<name> --to-revision=2

# Restart deployment
kubectl rollout restart deployment/<name>

# Delete deployment
kubectl delete deployment <deployment-name>
```

### Services

```bash
# List services
kubectl get services

# Service details
kubectl describe service <service-name>

# Get service endpoints
kubectl get endpoints <service-name>

# Port forward to local machine
kubectl port-forward service/<service-name> 8080:80

# Delete service
kubectl delete service <service-name>
```

### ConfigMaps and Secrets

```bash
# List configmaps
kubectl get configmap

# View configmap
kubectl describe configmap <name>

# Create configmap from file
kubectl create configmap <name> --from-file=config.yaml

# List secrets
kubectl get secrets

# View secret (base64 encoded)
kubectl get secret <name> -o yaml

# Create secret
kubectl create secret generic <name> --from-literal=key=value
```

### Namespaces

```bash
# List namespaces
kubectl get namespaces

# Create namespace
kubectl create namespace staging

# Set default namespace
kubectl config set-context --current --namespace=staging

# Delete namespace (⚠️ deletes everything inside)
kubectl delete namespace staging
```

### Apply Manifests

```bash
# Apply configuration from file
kubectl apply -f deployment.yaml

# Apply all files in directory
kubectl apply -f ./k8s/

# Delete resources from file
kubectl delete -f deployment.yaml

# Dry run (preview without applying)
kubectl apply -f deployment.yaml --dry-run=client
```

### Troubleshooting

```bash
# Get events
kubectl get events --sort-by='.lastTimestamp'

# Events for specific namespace
kubectl get events -n staging

# Describe all pods (useful for issues)
kubectl describe pods

# Resource usage
kubectl top nodes
kubectl top pods

# Check pod readiness
kubectl get pods --field-selector=status.phase=Running

# Check failed pods
kubectl get pods --field-selector=status.phase=Failed
```

---

## Terraform

### Workflow

```bash
# Initialize (first time setup)
terraform init

# Validate configuration
terraform validate

# Format code
terraform fmt

# Plan changes
terraform plan

# Plan with output file
terraform plan -out=tfplan

# Apply changes
terraform apply

# Apply specific plan
terraform apply tfplan

# Apply without confirmation prompt
terraform apply -auto-approve

# Destroy all resources (⚠️ DANGER)
terraform destroy
```

### State Management

```bash
# List resources in state
terraform state list

# Show resource details
terraform state show <resource-name>

# Remove resource from state
terraform state rm <resource-name>

# Import existing resource
terraform import <resource-type>.<name> <resource-id>

# Refresh state
terraform refresh
```

### Workspaces

```bash
# List workspaces
terraform workspace list

# Create workspace
terraform workspace new staging

# Switch workspace
terraform workspace select staging

# Delete workspace
terraform workspace delete staging
```

### Outputs

```bash
# View all outputs
terraform output

# View specific output
terraform output database_url

# Output as JSON
terraform output -json
```

### Variables

```bash
# Set variable via command line
terraform apply -var="environment=production"

# Use variable file
terraform apply -var-file="prod.tfvars"

# Set multiple variables
terraform apply -var="env=prod" -var="region=us-east-1"
```

---

## Git Workflow

### Daily Workflow

```bash
# Check status
git status

# Create feature branch
git checkout -b feature/add-tags

# Stage changes
git add src/api/campaigns.py

# Commit with message
git commit -m "feat: add campaign tags"

# Push to remote
git push origin feature/add-tags

# Update branch with main
git checkout main
git pull
git checkout feature/add-tags
git merge main

# Squash commits
git rebase -i HEAD~3  # Squash last 3 commits
```

### Undoing Changes

```bash
# Discard unstaged changes
git checkout -- file.txt

# Unstage file
git reset HEAD file.txt

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1

# Revert commit (create new commit)
git revert <commit-hash>
```

### Tags (for releases)

```bash
# Create annotated tag
git tag -a v1.0.0 -m "Release version 1.0.0"

# Push tag to remote
git push origin v1.0.0

# Push all tags
git push --tags

# List tags
git tag

# Delete tag locally
git tag -d v1.0.0

# Delete tag remotely
git push origin :refs/tags/v1.0.0
```

---

## GitHub Actions

### Workflow Management

```bash
# Trigger workflow manually (via GitHub CLI)
gh workflow run cd.yml -f environment=staging

# List workflows
gh workflow list

# View workflow runs
gh run list

# View specific run
gh run view <run-id>

# Download artifacts
gh run download <run-id>

# Cancel running workflow
gh run cancel <run-id>

# Re-run failed jobs
gh run rerun <run-id> --failed
```

### Secrets Management

```bash
# Add secret (via GitHub CLI)
gh secret set OPENAI_API_KEY < key.txt

# List secrets
gh secret list

# Delete secret
gh secret delete OPENAI_API_KEY
```

### Viewing Logs

1. Go to GitHub repository
2. Click "Actions" tab
3. Click workflow run
4. Click job name
5. Expand step to see logs

---

## Troubleshooting

### Docker Issues

```bash
# Container won't start - check logs
docker logs <container-id>

# Container exits immediately
docker logs <container-id>
docker run -it <image> bash  # Run interactively

# Port already in use
sudo lsof -i :8000  # Find process using port
kill <PID>          # Kill process

# Permission denied
sudo docker ...     # Run with sudo (Linux)
# Or add user to docker group:
sudo usermod -aG docker $USER

# Out of disk space
docker system df                    # Check disk usage
docker system prune                 # Clean up
docker volume prune                 # Remove unused volumes

# Network issues
docker network ls                   # List networks
docker network inspect <network>    # Network details
docker network create my-network    # Create network
```

### Kubernetes Issues

```bash
# Pod stuck in Pending
kubectl describe pod <pod-name>
# Look for scheduling errors, resource constraints

# Pod stuck in ImagePullBackOff
kubectl describe pod <pod-name>
# Check image name, registry access

# Pod CrashLoopBackOff
kubectl logs <pod-name>
kubectl logs <pod-name> --previous
# Check application errors

# Service not accessible
kubectl get svc
kubectl describe svc <service-name>
kubectl get endpoints <service-name>
# Check selector labels match pod labels

# Can't connect to cluster
kubectl config view                    # View config
kubectl config get-contexts           # List contexts
kubectl config use-context <context>  # Switch context
```

### CI/CD Issues

```bash
# Workflow not triggering
# Check:
# - Branch name matches trigger
# - Path filters (if any)
# - Workflow file syntax (YAML)

# Job failing
# 1. View logs in Actions tab
# 2. Reproduce locally:
#    - Run same commands
#    - Use same environment
# 3. Fix and push again

# Deployment stuck
kubectl rollout status deployment/<name>
kubectl describe deployment <name>
kubectl get events
# If necessary, rollback:
kubectl rollout undo deployment/<name>

# Tests failing in CI but pass locally
# Check:
# - Python/Node version matches
# - Dependencies are pinned
# - Database schema is up-to-date
# - Environment variables set
```

---

## Common Workflows

### Deploy to Staging

```bash
# 1. Merge PR to main
git checkout main
git pull

# 2. CI runs automatically
# 3. CD deploys to staging automatically

# 4. Test in staging
curl https://staging.example.com/health

# 5. Check deployment
kubectl get pods -n staging
kubectl logs -f deployment/backend -n staging
```

### Deploy to Production

```bash
# 1. Create version tag
git tag -a v1.2.3 -m "Release 1.2.3"
git push origin v1.2.3

# 2. CD runs automatically
# - Builds images
# - Deploys to staging
# - Waits for approval (if configured)
# - Deploys to production

# 3. Verify production
curl https://example.com/health

# 4. Monitor
kubectl get pods -n production
kubectl logs -f deployment/backend -n production
```

### Rollback Deployment

```bash
# Option 1: Kubernetes rollback
kubectl rollout undo deployment/backend -n production

# Option 2: Deploy previous tag
git tag                  # Find previous tag
git push origin v1.2.2   # Re-push old tag (CD deploys it)

# Option 3: Revert pull request
git revert <commit-hash>
git push origin main
# CI/CD runs with reverted code
```

### Debug Production Issue

```bash
# 1. Check pod status
kubectl get pods -n production

# 2. View recent logs
kubectl logs -f deployment/backend -n production --tail=100

# 3. Check events
kubectl get events -n production --sort-by='.lastTimestamp'

# 4. Exec into pod
kubectl exec -it deployment/backend -n production -- bash

# 5. Check metrics (if using Prometheus)
# Open Grafana dashboard

# 6. If critical, rollback
kubectl rollout undo deployment/backend -n production
```

---

## Environment Variables

### Local Development (.env file)

```bash
# Create .env file
cat > .env << EOF
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/marketing_agent
REDIS_URL=redis://localhost:6379
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
ENVIRONMENT=development
LOG_LEVEL=DEBUG
EOF

# Add to .gitignore
echo ".env" >> .gitignore

# Docker Compose automatically loads .env
docker-compose up
```

### GitHub Actions Secrets

```bash
# Via GitHub UI:
# Settings → Secrets and variables → Actions → New repository secret

# Via GitHub CLI:
gh secret set OPENAI_API_KEY < api_key.txt
gh secret set DATABASE_URL -b"postgresql://..."

# Use in workflow:
env:
  OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
```

### Kubernetes Secrets

```bash
# Create from literal values
kubectl create secret generic app-secrets \
  --from-literal=database-url='postgresql://...' \
  --from-literal=redis-url='redis://...'

# Create from file
kubectl create secret generic app-secrets \
  --from-file=config.yaml

# Apply secret from YAML
kubectl apply -f secrets.yaml

# Use in deployment:
# containers:
#   - name: backend
#     envFrom:
#       - secretRef:
#           name: app-secrets
```

---

## Useful Aliases

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
# Docker
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias dim='docker images'
alias dlog='docker logs -f'
alias dex='docker exec -it'

# Kubernetes
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgd='kubectl get deployments'
alias kdp='kubectl describe pod'
alias klog='kubectl logs -f'
alias kex='kubectl exec -it'
alias kctx='kubectl config use-context'

# Terraform
alias tf='terraform'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfo='terraform output'

# Git
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias gco='git checkout'
alias gb='git branch'
alias glog='git log --oneline --graph --decorate'
```

---

## Resources

- **CI.yml (annotated)**: `.github/workflows/ci.yml`
- **CD.yml (annotated)**: `.github/workflows/cd.yml`
- **Docker Compose (annotated)**: `docker-compose.yml`
- **Complete Guide**: `docs/CI_CD_COMPLETE_GUIDE.md`

---

**Pro Tip**: Print this page and keep it near your workstation for quick reference!

 **Happy Deploying! 🚀**
