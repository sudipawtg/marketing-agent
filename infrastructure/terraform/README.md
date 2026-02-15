# Terraform Infrastructure Documentation

## Overview

This directory contains Infrastructure as Code (IaC) for deploying the Marketing Agent platform across multiple cloud providers (AWS, GCP, Azure). The infrastructure is designed to be production-ready with comprehensive monitoring, security, and scalability features.

## 📁 File Structure

```
infrastructure/terraform/
├── README.md          # This file
├── main.tf            # Root configuration, variables, outputs, backend
├── aws.tf             # AWS-specific resources (EKS, VPC, RDS, ElastiCache)
├── gcp.tf             # GCP-specific resources (GKE, Cloud SQL, Memorystore)
├── azure.tf           # Azure-specific resources (AKS, PostgreSQL, Redis)
├── iam.tf             # AWS IAM roles and policies
└── monitoring.tf      # Monitoring stack (Datadog, New Relic, Sumologic, Prometheus)
```

## 🎯 Architecture

### Multi-Cloud Design

The infrastructure supports three cloud providers with identical capabilities:

| Component | AWS | GCP | Azure |
|-----------|-----|-----|-------|
| **Kubernetes** | EKS 1.28 | GKE 1.28 | AKS 1.28 |
| **Database** | RDS PostgreSQL 15.4 | Cloud SQL PostgreSQL 15 | PostgreSQL Flexible Server 15 |
| **Cache** | ElastiCache Redis 7.0 | Memorystore Redis 7.0 | Azure Cache for Redis |
| **Container Registry** | ECR | Artifact Registry | ACR |
| **Networking** | VPC (10.0.0.0/16) | VPC with secondary ranges | Virtual Network |

### Resource Topology

```
┌─────────────────────────────────────────────────────┐
│                   Cloud Provider                     │
│  ┌───────────────────────────────────────────────┐  │
│  │         Kubernetes Cluster (EKS/GKE/AKS)      │  │
│  │  ┌──────────────┐  ┌──────────────┐          │  │
│  │  │   Backend    │  │   Frontend   │          │  │
│  │  │     Pods     │  │     Pods     │          │  │
│  │  └──────────────┘  └──────────────┘          │  │
│  │                                                │  │
│  │  ┌──────────────────────────────────────────┐ │  │
│  │  │     Monitoring Stack (Namespace)         │ │  │
│  │  │  Datadog • New Relic • Sumologic         │ │  │
│  │  │  Prometheus • Grafana                    │ │  │
│  │  └──────────────────────────────────────────┘ │  │
│  └───────────────────────────────────────────────┘  │
│                                                       │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────┐ │
│  │  PostgreSQL  │  │    Redis     │  │  Registry │ │
│  │   Database   │  │    Cache     │  │  (Images) │ │
│  └──────────────┘  └──────────────┘  └───────────┘ │
└─────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites

1. **Install required tools:**
   ```bash
   # Terraform
   brew install terraform  # macOS
   # or
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   
   # Cloud CLIs
   brew install awscli google-cloud-sdk azure-cli
   
   # Kubernetes tools
   brew install kubectl helm kustomize
   ```

2. **Authenticate with cloud providers:**
   ```bash
   # AWS
   aws configure
   export AWS_PROFILE=your-profile
   
   # GCP
   gcloud auth application-default login
   gcloud config set project YOUR_PROJECT_ID
   
   # Azure
   az login
   az account set --subscription YOUR_SUBSCRIPTION_ID
   ```

### Basic Deployment

1. **Initialize Terraform:**
   ```bash
   cd infrastructure/terraform
   terraform init
   ```

2. **Configure variables:**
   ```bash
   # Copy example and edit
   cat > terraform.tfvars <<EOF
   # Cloud configuration
   cloud_provider = "aws"  # or "gcp", "azure"
   environment    = "staging"
   
   # Cluster settings
   cluster_name     = "marketing-agent"
   aws_region       = "us-east-1"
   node_count       = 3
   node_machine_type = "t3.xlarge"
   
   # Database
   db_instance_class = "db.t3.medium"
   db_allocated_storage = 100
   
   # Redis
   redis_node_type = "cache.t3.medium"
   
   # Monitoring (optional)
   enable_datadog      = true
   enable_newrelic     = true
   enable_sumologic    = false
   
   # API Keys (use environment variables in production)
   datadog_api_key    = "your-datadog-api-key"
   newrelic_license   = "your-newrelic-license"
   EOF
   ```

3. **Plan deployment:**
   ```bash
   terraform plan -out=tfplan
   ```

4. **Apply configuration:**
   ```bash
   terraform apply tfplan
   ```

5. **Get cluster credentials:**
   ```bash
   # AWS
   aws eks update-kubeconfig --name marketing-agent --region us-east-1
   
   # GCP
   gcloud container clusters get-credentials marketing-agent --region us-central1
   
   # Azure
   az aks get-credentials --name marketing-agent --resource-group marketing-agent-rg
   ```

## 📋 Variables Reference

### Core Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `cloud_provider` | string | `"aws"` | Cloud provider: `aws`, `gcp`, or `azure` |
| `environment` | string | `"staging"` | Environment name: `staging`, `production` |
| `cluster_name` | string | `"marketing-agent"` | Kubernetes cluster name |
| `project_name` | string | `"marketing-agent"` | Project identifier |

### AWS-Specific Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `aws_region` | string | `"us-east-1"` | AWS region |
| `node_count` | number | `3` | Number of EKS nodes |
| `node_machine_type` | string | `"t3.xlarge"` | EC2 instance type |
| `db_instance_class` | string | `"db.t3.medium"` | RDS instance class |
| `db_allocated_storage` | number | `100` | RDS storage in GB |
| `redis_node_type` | string | `"cache.t3.medium"` | ElastiCache node type |

### GCP-Specific Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `gcp_project` | string | - | GCP project ID (required) |
| `gcp_region` | string | `"us-central1"` | GCP region |
| `gcp_zone` | string | `"us-central1-a"` | GCP zone |

### Azure-Specific Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `azure_location` | string | `"eastus"` | Azure region |
| `azure_sku_tier` | string | `"Standard"` | AKS SKU tier |

### Monitoring Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `enable_monitoring` | bool | `true` | Enable monitoring namespace |
| `enable_datadog` | bool | `false` | Deploy Datadog agents |
| `enable_newrelic` | bool | `false` | Deploy New Relic agents |
| `enable_sumologic` | bool | `false` | Deploy Sumologic collectors |
| `datadog_api_key` | string | - | Datadog API key (sensitive) |
| `newrelic_license` | string | - | New Relic license key (sensitive) |
| `sumologic_access_id` | string | - | Sumologic access ID (sensitive) |
| `sumologic_access_key` | string | - | Sumologic access key (sensitive) |

## 🔐 Security Best Practices

### 1. Secrets Management

**Never commit sensitive values to Git.** Use one of these methods:

#### Option A: Environment Variables
```bash
export TF_VAR_datadog_api_key="your-key"
export TF_VAR_newrelic_license="your-license"
export TF_VAR_openai_api_key="your-openai-key"
terraform apply
```

#### Option B: AWS Secrets Manager
```bash
# Store secrets
aws secretsmanager create-secret \
  --name marketing-agent/datadog-api-key \
  --secret-string "your-key"

# Reference in terraform.tfvars
datadog_api_key = data.aws_secretsmanager_secret_version.datadog.secret_string
```

#### Option C: Terraform Cloud Variables
```bash
# Mark as sensitive in Terraform Cloud UI
# Or use API:
terraform cloud workspace variables create \
  --workspace-id ws-xyz \
  --key datadog_api_key \
  --value "your-key" \
  --sensitive
```

### 2. State File Management

The state file contains sensitive data. Secure it properly:

```hcl
# main.tf backend configuration
backend "s3" {
  bucket         = "marketing-agent-terraform-state"
  key            = "infrastructure/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true              # Enable encryption at rest
  dynamodb_table = "terraform-lock"   # Enable state locking
  kms_key_id     = "arn:aws:kms:..."  # Use KMS encryption
}
```

Setup backend resources:
```bash
# Create S3 bucket
aws s3api create-bucket \
  --bucket marketing-agent-terraform-state \
  --region us-east-1 \
  --create-bucket-configuration LocationConstraint=us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket marketing-agent-terraform-state \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket marketing-agent-terraform-state \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Create DynamoDB table for locking
aws dynamodb create-table \
  --table-name terraform-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

### 3. Network Security

The infrastructure includes these security features:

- **VPC Isolation**: Private subnets for databases and caches
- **Security Groups**: Least-privilege firewall rules
- **Network Policies**: Kubernetes network segmentation
- **Private Endpoints**: Database accessible only from cluster
- **TLS/SSL**: Encryption in transit for all services

### 4. IAM Security

AWS IAM roles follow least-privilege principles:

```hcl
# EKS cluster role - only what's needed for K8s control plane
# Node role - only what's needed for nodes
# Pod execution role - IRSA (IAM Roles for Service Accounts)
```

## 💰 Cost Optimization

### Estimated Monthly Costs

| Cloud | Staging | Production | Notes |
|-------|---------|------------|-------|
| **AWS** | $450-600 | $1,200-1,800 | EKS: $73, Nodes: $150-300, RDS: $100-200, Data transfer: $50-100 |
| **GCP** | $400-550 | $1,100-1,600 | GKE: Free, Nodes: $150-300, Cloud SQL: $90-180, Data transfer: $40-90 |
| **Azure** | $480-630 | $1,250-1,900 | AKS: Free, Nodes: $160-320, PostgreSQL: $110-220, Data transfer: $50-110 |

### Cost Reduction Strategies

1. **Right-size instances:**
   ```hcl
   # Staging
   node_machine_type    = "t3.medium"   # AWS
   node_count           = 2
   db_instance_class    = "db.t3.small"
   
   # Production
   node_machine_type    = "t3.xlarge"
   node_count           = 3-5
   db_instance_class    = "db.r5.large"
   ```

2. **Use spot instances** (non-production):
   ```hcl
   # Add to aws.tf
   resource "aws_eks_node_group" "spot" {
     capacity_type = "SPOT"
     # 70% cost savings
   }
   ```

3. **Enable autoscaling:**
   ```hcl
   scaling_config {
     min_size     = 2
     max_size     = 10
     desired_size = 3
   }
   ```

4. **Schedule non-production shutdowns:**
   ```bash
   # Automated scripts to stop staging at night
   # See: scripts/cost-optimization/auto-shutdown.sh
   ```

5. **Use reserved instances** (production):
   - AWS: 1-year reserved = 40% savings
   - GCP: Committed use = 37% savings
   - Azure: Reserved VMs = 40% savings

## 🔄 Deployment Workflows

### Development → Staging → Production

```bash
# 1. Development (local/minikube)
terraform workspace new development
terraform apply -var="environment=development" -var="node_count=1"

# 2. Staging
terraform workspace new staging
terraform apply -var="environment=staging" -auto-approve=false

# 3. Production (with approval)
terraform workspace new production
terraform apply -var="environment=production"
```

### Blue-Green Deployment

```bash
# Create green environment
terraform workspace new production-green
terraform apply -var="environment=production-green"

# Test green environment
kubectl --context=green run tests

# Switch traffic (update DNS/load balancer)
# ...

# Destroy blue environment
terraform workspace select production-blue
terraform destroy
```

### Disaster Recovery

```bash
# Backup current state
terraform state pull > backup-$(date +%Y%m%d).tfstate

# Restore from backup if needed
terraform state push backup-20260215.tfstate

# Database backups (automated by RDS/Cloud SQL/Azure)
# RDS: 7-day retention, point-in-time recovery
# Cloud SQL: 7 automated backups
# Azure: 7-day retention
```

## 🔧 Maintenance

### Updating Kubernetes Version

```bash
# Check available versions
aws eks describe-addon-versions --kubernetes-version 1.29

# Update cluster
terraform apply -var="cluster_version=1.29"

# Update node groups (rolling update)
terraform apply -var="node_group_version=1.29"
```

### Scaling Resources

```bash
# Horizontal scaling (add nodes)
terraform apply -var="node_count=5"

# Vertical scaling (larger instances)
terraform apply -var="node_machine_type=t3.2xlarge"

# Database scaling
terraform apply -var="db_instance_class=db.r5.xlarge"
```

### Monitoring Infrastructure

```bash
# Check Terraform state
terraform show

# Validate configuration
terraform validate

# Check drift
terraform plan -detailed-exitcode
# Exit code 2 = drift detected

# Refresh state
terraform refresh
```

## 📊 Outputs Reference

After `terraform apply`, you'll get these outputs:

| Output | Description | Example |
|--------|-------------|---------|
| `cluster_endpoint` | Kubernetes API endpoint | `https://ABC123.eks.amazonaws.com` |
| `cluster_name` | Cluster name | `marketing-agent` |
| `kubeconfig_command` | Command to configure kubectl | `aws eks update-kubeconfig...` |
| `registry_url` | Container registry URL | `123456789.dkr.ecr.us-east-1.amazonaws.com` |
| `database_endpoint` | PostgreSQL endpoint | `marketing-agent.abc123.us-east-1.rds.amazonaws.com:5432` |
| `redis_endpoint` | Redis endpoint | `marketing-agent.abc123.cache.amazonaws.com:6379` |
| `load_balancer_ip` | Ingress load balancer IP | `52.1.2.3` |
| `monitoring_dashboard_url` | Grafana dashboard URL | `http://monitoring.example.com` |

### Using Outputs

```bash
# Get specific output
terraform output cluster_endpoint

# Get all outputs as JSON
terraform output -json > outputs.json

# Use in scripts
CLUSTER=$(terraform output -raw cluster_name)
kubectl --context=$CLUSTER get pods
```

## 🐛 Troubleshooting

### Common Issues

#### 1. State Lock Error
```
Error: Error acquiring the state lock
```

**Solution:**
```bash
# Force unlock (use with caution)
terraform force-unlock LOCK_ID

# Or delete DynamoDB lock item
aws dynamodb delete-item \
  --table-name terraform-lock \
  --key '{"LockID":{"S":"marketing-agent-terraform-state/infrastructure/terraform.tfstate"}}'
```

#### 2. Resource Already Exists
```
Error: resource already exists
```

**Solution:**
```bash
# Import existing resource
terraform import aws_eks_cluster.main marketing-agent

# Or remove from state
terraform state rm aws_eks_cluster.main
```

#### 3. Authentication Errors
```
Error: error configuring Terraform AWS Provider: no valid credential sources
```

**Solution:**
```bash
# Check credentials
aws sts get-caller-identity
gcloud auth list
az account show

# Re-authenticate
aws configure
gcloud auth application-default login
az login
```

#### 4. Insufficient Permissions
```
Error: UnauthorizedOperation: You are not authorized
```

**Solution:**
```bash
# Check required permissions
# AWS: EKS, EC2, RDS, ElastiCache, IAM, VPC
# GCP: Compute, GKE, Cloud SQL, IAM
# Azure: Compute, AKS, Database, Network

# Attach required policies
aws iam attach-user-policy \
  --user-name terraform-user \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

#### 5. Timeout Errors
```
Error: timeout while waiting for state to become 'ACTIVE'
```

**Solution:**
```bash
# Increase timeout
terraform apply -parallelism=10 -refresh=false

# Or manually wait and retry
aws eks describe-cluster --name marketing-agent
terraform apply
```

## 🧪 Testing

### Validate Configuration
```bash
# Syntax check
terraform fmt -check -recursive

# Validate configuration
terraform validate

# Plan with validation
terraform plan -out=tfplan
```

### Test in Isolated Environment
```bash
# Create test workspace
terraform workspace new test

# Deploy minimal configuration
terraform apply -var="node_count=1" -var="db_instance_class=db.t3.micro"

# Run tests
kubectl get nodes
kubectl get pods --all-namespaces

# Cleanup
terraform destroy
terraform workspace delete test
```

### Automated Testing
```bash
# Using Terratest (Go)
cd tests/terraform
go test -v -timeout 30m

# Using kitchen-terraform
kitchen test
```

## 📚 Additional Resources

- [Terraform AWS Setup Guide](../../docs/TERRAFORM_SETUP.md) - Detailed setup instructions
- [Datadog Integration](../../docs/DATADOG_INTEGRATION.md) - Monitoring setup
- [Production Patterns](../../docs/PRODUCTION_PATTERNS.md) - Best practices
- [Architecture Decision Records](../../docs/architecture/adr/) - Design decisions

## 🤝 Contributing

When modifying Terraform code:

1. **Format code:**
   ```bash
   terraform fmt -recursive
   ```

2. **Update documentation:**
   - Add comments for complex resources
   - Update this README for new variables
   - Document outputs

3. **Test changes:**
   ```bash
   terraform validate
   terraform plan
   ```

4. **Submit PR with:**
   - Description of changes
   - Cost impact analysis
   - Testing performed

## 📝 Module Design Principles

This Terraform configuration follows these principles:

1. **Modularity**: Cloud-specific resources in separate files
2. **Reusability**: Variables and outputs for flexibility
3. **Security**: Encrypted storage, private networks, IAM roles
4. **Observability**: Built-in monitoring integrations
5. **Cost-awareness**: Right-sizing and autoscaling
6. **Reliability**: Multi-AZ deployments, automated backups
7. **Maintainability**: Clear naming, comprehensive comments

## 🔗 Related Documentation

- [Infrastructure Setup](../../docs/TERRAFORM_SETUP.md)
- [Kubernetes Setup](../k8s/README.md)
- [Monitoring Setup](../../docs/DATADOG_INTEGRATION.md)
- [CI/CD Integration](../../.github/workflows/README.md)

---

**Last Updated:** February 2026  
**Maintained By:** Platform Engineering Team  
**Questions?** See [CONTRIBUTING.md](../../CONTRIBUTING.md) or open an issue
