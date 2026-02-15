# Infrastructure

Multi-cloud infrastructure as code (IaC) and Kubernetes configurations for the Marketing Agent platform.

## 📁 Structure

```
infrastructure/
├── README.md (this file)
├── docker/                 # Docker-related configurations
├── k8s/                    # Kubernetes manifests
│   ├── base/              # Base Kustomize configs
│   ├── staging/           # Staging overlays
│   ├── production/        # Production overlays
│   └── canary/            # Canary deployment configs
├── terraform/             # Terraform IaC for multi-cloud
│   ├── README.md          # Comprehensive Terraform guide
│   ├── QUICK_REFERENCE.md # Terraform commands reference
│   ├── main.tf            # Main configuration
│   ├── aws.tf             # AWS resources
│   ├── gcp.tf             # GCP resources
│   ├── azure.tf           # Azure resources
│   ├── iam.tf             # IAM roles and policies
│   ├── monitoring.tf      # Monitoring stack
│   └── terraform.tfvars.example  # Configuration template
└── README.md              # This file
```

## 🏗️ Terraform - Multi-Cloud Infrastructure

Deploy to **AWS**, **GCP**, or **Azure** with enterprise-grade infrastructure.

### Quick Start

```bash
cd infrastructure/terraform

# 1. Configure variables
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars

# 2. Initialize
terraform init

# 3. Plan
terraform plan -out=tfplan

# 4. Deploy
terraform apply tfplan
```

### What Gets Deployed

**Kubernetes Cluster:**
- AWS: EKS 1.28
- GCP: GKE 1.28  
- Azure: AKS 1.28

**Database:**
- PostgreSQL 15+ with automated backups
- Multi-AZ for high availability

**Caching:**
- Redis 7.0+ with persistence

**Monitoring (Optional):**
- Datadog APM
- New Relic Infrastructure
- Sumologic Log Aggregation
- Prometheus + Grafana

**Networking:**
- VPC with public/private subnets
- Load balancers
- Security groups
- Private database endpoints

### Documentation

- **Complete Guide**: [terraform/README.md](terraform/README.md)
- **Setup Instructions**: [../docs/deployment/TERRAFORM_SETUP.md](../docs/deployment/TERRAFORM_SETUP.md)
- **Quick Reference**: [terraform/QUICK_REFERENCE.md](terraform/QUICK_REFERENCE.md)

### Cost Estimates

| Environment | AWS | GCP | Azure |
|-------------|-----|-----|-------|
| **Staging** | $450-600/mo | $400-550/mo | $480-630/mo |
| **Production** | $1,200-1,800/mo | $1,100-1,600/mo | $1,250-1,900/mo |

## ☸️ Kubernetes Configurations

Production-ready Kubernetes manifests with Kustomize overlays.

### Structure

- **base/**: Base configurations (deployments, services, configmaps)
- **staging/**: Staging environment overlays
- **production/**: Production environment overlays
- **canary/**: Canary deployment configurations

### Deployment

```bash
# Deploy to staging
kubectl apply -k infrastructure/k8s/staging/

# Deploy to production
kubectl apply -k infrastructure/k8s/production/

# Deploy canary
kubectl apply -k infrastructure/k8s/canary/
```

### Features

- **Autoscaling**: HPA configured for backend/frontend
- **Health Checks**: Liveness and readiness probes
- **Resource Limits**: CPU and memory constraints
- **Secrets Management**: Kubernetes secrets for sensitive data
- **ConfigMaps**: Environment-specific configuration
- **Network Policies**: Pod-to-pod communication restrictions
- **Ingress**: NGINX ingress controller with TLS

### Documentation

- **Kubernetes Setup**: [../docs/deployment/](../docs/deployment/)
- **Architecture**: [../docs/ARCHITECTURE_DIAGRAM.md](../docs/ARCHITECTURE_DIAGRAM.md)

## 🐳 Docker

Docker and docker-compose configurations.

### Files

- **../docker-compose.yml**: Development environment
- **docker/**: Additional Docker configurations

### Usage

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

## 🔐 Security

### Best Practices Implemented

- [x] Private subnets for databases
- [x] Security groups with least-privilege rules
- [x] Encrypted storage (EBS, Cloud Storage, Azure Disks)
- [x] Encrypted databases (RDS encryption)
- [x] IAM roles for service accounts (IRSA)
- [x] Secrets management (Kubernetes secrets)
- [x] Network policies for pod isolation
- [x] TLS/SSL for all external traffic

### Secrets Management

**Never commit secrets!** Use:
- Environment variables: `export TF_VAR_api_key="..."`
- AWS Secrets Manager / GCP Secret Manager / Azure Key Vault
- Kubernetes secrets: `kubectl create secret`
- Terraform Cloud variables (marked as sensitive)

## 📊 Monitoring

### Monitoring Stack (Optional)

Deploy via Terraform by enabling in `terraform.tfvars`:

```hcl
enable_datadog = true
enable_newrelic = true
enable_sumologic = true
```

### Metrics Collected

- **Application**: Request rate, latency, errors
- **Infrastructure**: CPU, memory, disk, network
- **Business**: LLM costs, recommendation quality
- **Kubernetes**: Pod health, node status, events

### Dashboards

- Grafana: Port-forward to access
- Datadog: https://app.datadoghq.com
- New Relic: https://one.newrelic.com

See [Monitoring Documentation](../docs/monitoring/) for details.

## 🚀 Deployment Strategies

### Blue-Green Deployment

```bash
# Deploy green environment
terraform workspace new production-green
terraform apply

# Test green
# ... run tests ...

# Switch traffic
# Update DNS or load balancer
```

### Canary Deployment

```bash
# Deploy canary
kubectl apply -k infrastructure/k8s/canary/

# Monitor metrics
# Gradually increase traffic

# Promote or rollback
```

### Rolling Update

```bash
# Kubernetes rolling update (default)
kubectl set image deployment/backend backend=new-image:tag
kubectl rollout status deployment/backend
```

## 🔄 Disaster Recovery

### Backup Strategy

- **Database**: Automated daily backups (7-day retention)
- **Terraform State**: S3 with versioning enabled
- **Kubernetes Configs**: Version controlled in Git
- **Docker Images**: Tagged and stored in registries

### Recovery Procedures

```bash
# Restore from Terraform state backup
terraform state push backup.tfstate

# Restore database (AWS example)
aws rds restore-db-instance-from-db-snapshot

# Redeploy Kubernetes
kubectl apply -k infrastructure/k8s/production/
```

## 🧪 Testing Infrastructure

```bash
# Validate Terraform
terraform validate

# Plan without applying
terraform plan

# Test Kubernetes configs
kubectl apply --dry-run=client -k infrastructure/k8s/staging/

# Lint YAML
yamllint infrastructure/k8s/
```

## 📚 Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [GCP GKE Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices)
- [Azure AKS Best Practices](https://docs.microsoft.com/en-us/azure/aks/best-practices)

## 🤝 Contributing

When modifying infrastructure:

1. **Test locally**: Use `terraform plan` before applying
2. **Document changes**: Update relevant README files
3. **Follow conventions**: Use consistent naming and tagging
4. **Security first**: Never commit secrets or sensitive data
5. **Cost awareness**: Consider cost impact of changes

---

**Questions?** See [main documentation](../docs/README.md) or open an issue.
