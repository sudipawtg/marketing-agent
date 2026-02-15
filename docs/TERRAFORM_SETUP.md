# Terraform Setup Guide

## Overview

This guide covers deploying the Marketing Agent platform infrastructure using Terraform across AWS, GCP, and Azure.

## Quick Start

```bash
# Clone repository
git clone <repo-url>
cd marketing-agent-workflow/infrastructure/terraform

# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var="cloud_provider=aws"

# Apply configuration
terraform apply -var="cloud_provider=aws"
```

---

## Prerequisites

### Tools Required

```bash
# Terraform 1.5+
brew install terraform

# Cloud CLI tools
brew install awscli      # AWS
brew install azure-cli   # Azure
gcloud components install # GCP

# kubectl for Kubernetes
brew install kubectl

# Kustomize
brew install kustomize

# Helm
brew install helm
```

### Cloud Authentication

#### AWS
```bash
# Configure AWS credentials
aws configure

# Or use environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

#### GCP
```bash
# Authenticate
gcloud auth login
gcloud auth application-default login

# Set project
gcloud config set project YOUR_PROJECT_ID
```

#### Azure
```bash
# Login
az login

# Select subscription
az account set --subscription="SUBSCRIPTION_ID"
```

---

## Configuration

### Environment Variables

Create `terraform.tfvars`:

```hcl
# Cloud Provider Selection
cloud_provider = "aws"  # Options: aws, gcp, azure

# Environment
environment = "production"

# Cluster Configuration
cluster_name   = "marketing-agent-cluster"
node_count     = 3
node_instance_type = "t3.medium"  # AWS

# AWS Specific
aws_region = "us-east-1"

# GCP Specific
gcp_project = "your-gcp-project-id"
gcp_region  = "us-central1"

# Azure Specific
azure_location = "eastus"

# Monitoring
enable_monitoring = true
enable_datadog    = true
enable_newrelic   = true

# API Keys (use environment variables for sensitive data)
# These should be set via ENV vars, not in tfvars
# export TF_VAR_openai_api_key="..."
# export TF_VAR_langsmith_api_key="..."
# export TF_VAR_datadog_api_key="..."
# export TF_VAR_newrelic_license_key="..."
```

### Remote State Configuration

For team collaboration, configure remote state:

#### S3 Backend (AWS)

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "marketing-agent-terraform-state"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

Create the S3 bucket and DynamoDB table:

```bash
# Create S3 bucket
aws s3api create-bucket \
  --bucket marketing-agent-terraform-state \
  --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket marketing-agent-terraform-state \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

#### GCS Backend (GCP)

```hcl
terraform {
  backend "gcs" {
    bucket = "marketing-agent-terraform-state"
    prefix = "infrastructure"
  }
}
```

#### Azure Backend

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "marketingagentstate"
    container_name       = "tfstate"
    key                  = "infrastructure.tfstate"
  }
}
```

---

## Deployment Workflows

### AWS Deployment

```bash
# Set variables
export TF_VAR_cloud_provider="aws"
export TF_VAR_aws_region="us-east-1"
export TF_VAR_openai_api_key="sk-..."
export TF_VAR_datadog_api_key="..."

# Initialize
terraform init

# Plan
terraform plan \
  -var-file="environments/production.tfvars" \
  -out=tfplan

# Review plan
terraform show tfplan

# Apply
terraform apply tfplan

# Get outputs
terraform output -json > outputs.json

# Configure kubectl
aws eks update-kubeconfig \
  --region us-east-1 \
  --name marketing-agent-cluster
```

### GCP Deployment

```bash
# Set variables
export TF_VAR_cloud_provider="gcp"
export TF_VAR_gcp_project="your-project-id"
export TF_VAR_gcp_region="us-central1"

# Deploy
terraform init
terraform apply -var-file="environments/production.tfvars"

# Configure kubectl
gcloud container clusters get-credentials marketing-agent-cluster \
  --region us-central1
```

### Azure Deployment

```bash
# Set variables
export TF_VAR_cloud_provider="azure"
export TF_VAR_azure_location="eastus"

# Deploy
terraform init
terraform apply -var-file="environments/production.tfvars"

# Configure kubectl
az aks get-credentials \
  --resource-group marketing-agent-cluster-rg \
  --name marketing-agent-cluster
```

---

## Module Structure

```
infrastructure/terraform/
├── main.tf              # Root configuration
├── aws.tf               # AWS resources
├── gcp.tf               # GCP resources
├── azure.tf             # Azure resources
├── iam.tf               # IAM roles (AWS focused)
├── monitoring.tf        # Monitoring integrations
├── variables.tf         # Variable definitions
├── outputs.tf           # Output definitions
├── versions.tf          # Provider versions
└── environments/
    ├── staging.tfvars
    └── production.tfvars
```

---

## Monitoring Integration

The Terraform configuration automatically deploys monitoring agents:

### Datadog

```hcl
variable "enable_datadog" {
  default = true
}

variable "datadog_api_key" {
  type      = string
  sensitive = true
}
```

Deployed via Helm in `monitoring.tf`.

### New Relic

```hcl
variable "enable_newrelic" {
  default = true
}

variable "newrelic_license_key" {
  type      = string
  sensitive = true
}
```

### Prometheus & Grafana

Always deployed when `enable_monitoring = true`.

---

## Cost Optimization

### Right-Sizing Instances

```hcl
# Development
node_instance_type = "t3.small"   # AWS
node_count = 2

# Staging
node_instance_type = "t3.medium"
node_count = 3

# Production
node_instance_type = "t3.large"
node_count = 5
```

### Spot Instances (AWS)

```hcl
resource "aws_eks_node_group" "spot" {
  capacity_type = "SPOT"
  
  scaling_config {
    desired_size = 3
    max_size     = 10
    min_size     = 1
  }
}
```

### Autoscaling

```hcl
# Enable cluster autoscaler
resource "kubernetes_deployment" "cluster_autoscaler" {
  # Automatically scale nodes based on pod demand
}
```

---

## Security Best Practices

### 1. Secrets Management

**Never commit secrets to Git!**

```bash
# Use environment variables
export TF_VAR_openai_api_key=$(cat ~/.secrets/openai_key)

# Or use secret managers
export TF_VAR_openai_api_key=$(aws secretsmanager get-secret-value \
  --secret-id openai-api-key \
  --query SecretString \
  --output text)
```

### 2. Encryption

All deployed resources use encryption:
- RDS: Encryption at rest enabled
- S3: Server-side encryption
- EBS: Encrypted volumes
- Secrets: Kubernetes secrets encrypted

### 3. Network Security

```hcl
# Private subnets for databases
resource "aws_subnet" "private" {
  map_public_ip_on_launch = false
  # ...
}

# Security groups with minimal access
resource "aws_security_group" "rds" {
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [vpc_cidr]  # Only from VPC
  }
}
```

---

## Maintenance & Updates

### Updating Infrastructure

```bash
# Pull latest changes
git pull origin main

# Check what will change
terraform plan

# Apply updates
terraform apply

# Rolling update nodes (zero downtime)
# Kubernetes will handle this automatically
```

### Destroying Resources

```bash
# Destroy specific resource
terraform destroy -target=aws_eks_cluster.main

# Destroy everything (CAUTION!)
terraform destroy

# Before destroying production:
# 1. Export database
# 2. Backup persistent volumes
# 3. Notify team
```

---

## Troubleshooting

### Common Issues

#### 1. State Lock Error

```bash
# Force unlock (use carefully!)
terraform force-unlock LOCK_ID
```

#### 2. Resource Already Exists

```bash
# Import existing resource
terraform import aws_eks_cluster.main marketing-agent-cluster
```

#### 3. Provider Authentication

```bash
# Verify AWS credentials
aws sts get-caller-identity

# Verify GCP
gcloud auth list

# Verify Azure
az account show
```

#### 4. Terraform Version Mismatch

```bash
# Use tfenv for version management
tfenv install 1.5.0
tfenv use 1.5.0
```

---

## CI/CD Integration

### GitHub Actions

```yaml
name: Terraform Deploy

on:
  push:
    branches: [main]
    paths:
      - 'infrastructure/terraform/**'

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0
      
      - name: Terraform Init
        run: terraform init
        working-directory: infrastructure/terraform
      
      - name: Terraform Plan
        run: terraform plan
        env:
          TF_VAR_openai_api_key: ${{ secrets.OPENAI_API_KEY }}
      
      - name: Terraform Apply
        if: github.ref == 'refs/heads/main'
        run: terraform apply -auto-approve
```

---

## Outputs & Next Steps

After successful deployment:

```bash
# View all outputs
terraform output

# Get specific values
CLUSTER_ENDPOINT=$(terraform output -raw cluster_endpoint)
REGISTRY_URL=$(terraform output -raw registry_url)
DATABASE_ENDPOINT=$(terraform output -raw database_endpoint)

# Configure kubectl
terraform output -raw kubeconfig_command | bash

# Deploy application
cd ../k8s/production
kustomize build . | kubectl apply -f -
```

---

## Additional Resources

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

---

**Next Steps**: [Deploy Application](CICD_SETUP_GUIDE.md) | [Configure Monitoring](DATADOG_INTEGRATION.md)
