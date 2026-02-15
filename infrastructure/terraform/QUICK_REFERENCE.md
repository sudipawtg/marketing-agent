# Terraform Quick Reference Guide

A concise command reference for managing the Marketing Agent infrastructure.

## 📋 Initial Setup

```bash
# Navigate to terraform directory
cd infrastructure/terraform

# Initialize Terraform (first time only)
terraform init

# Initialize with backend reconfiguration
terraform init -reconfigure

# Upgrade providers to latest versions
terraform init -upgrade
```

## 🔍 Pre-Deployment Validation

```bash
# Format code (auto-fix formatting issues)
terraform fmt -recursive

# Validate configuration syntax
terraform validate

# Check what will be created/modified
terraform plan

# Save plan to file for review
terraform plan -out=tfplan

# Show plan in JSON format
terraform show -json tfplan | jq '.'
```

## 🚀 Deployment

```bash
# Apply saved plan
terraform apply tfplan

# Apply with auto-approval (use with caution!)
terraform apply -auto-approve

# Apply specific target resource only
terraform apply -target=aws_eks_cluster.main

# Apply with variable overrides
terraform apply -var="node_count=5" -var="environment=production"

# Apply with custom tfvars file
terraform apply -var-file="production.tfvars"
```

## 📊 Information & Inspection

```bash
# List all resources in state
terraform state list

# Show specific resource details
terraform state show aws_eks_cluster.main

# Show all outputs
terraform output

# Show specific output
terraform output cluster_endpoint

# Show output in raw format (no quotes)
terraform output -raw kubeconfig_command

# Export all outputs to JSON
terraform output -json > outputs.json

# Show current state
terraform show

# Show terraform version
terraform version
```

## 🔄 State Management

```bash
# Refresh state from actual infrastructure
terraform refresh

# Pull remote state to local file
terraform state pull > backup.tfstate

# Push local state to remote
terraform state push backup.tfstate

# Remove resource from state (doesn't destroy actual resource)
terraform state rm aws_eks_cluster.main

# Import existing resource into state
terraform import aws_eks_cluster.main marketing-agent-cluster

# Move resource to new address
terraform state mv aws_eks_cluster.main aws_eks_cluster.primary

# List all workspaces
terraform workspace list

# Create new workspace
terraform workspace new staging

# Switch workspace
terraform workspace select production

# Delete workspace
terraform workspace delete staging
```

## 🔐 Secrets Management

```bash
# Set sensitive variables via environment
export TF_VAR_openai_api_key="sk-..."
export TF_VAR_datadog_api_key="..."
export TF_VAR_newrelic_license_key="..."

# View sensitive output (will be revealed)
terraform output -json | jq '.database_endpoint.value'

# Mark outputs as sensitive in state
terraform apply -refresh-only
```

## 🛠️ Troubleshooting

```bash
# Enable debug logging
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform-debug.log
terraform apply

# Disable logging
unset TF_LOG
unset TF_LOG_PATH

# Check for state drift
terraform plan -detailed-exitcode
# Exit codes: 0=no changes, 1=error, 2=changes detected

# Force unlock state (if locked due to crash)
terraform force-unlock LOCK_ID

# Manually mark resource as tainted (will be recreated)
terraform taint aws_instance.example

# Remove taint
terraform untaint aws_instance.example

# Recalculate dependencies
terraform graph | dot -Tsvg > graph.svg
```

## 🔧 Configuration Changes

```bash
# Scale node count
terraform apply -var="node_count=5"

# Change instance type
terraform apply -var="node_instance_type=t3.xlarge"

# Enable monitoring
terraform apply -var="enable_datadog=true"

# Switch cloud provider (requires destroy/recreate)
terraform apply -var="cloud_provider=gcp"

# Update Kubernetes version
terraform apply -var="cluster_version=1.29"
```

## 📦 Resource Management

```bash
# Destroy specific resource
terraform destroy -target=aws_eks_node_group.main

# Destroy entire infrastructure (DANGEROUS!)
terraform destroy

# Destroy with auto-approval (VERY DANGEROUS!)
terraform destroy -auto-approve

# Destroy with specific var file
terraform destroy -var-file="staging.tfvars"
```

## 🌍 Multi-Cloud Quick Switch

```bash
# Deploy to AWS
terraform apply -var="cloud_provider=aws" -var="aws_region=us-east-1"

# Deploy to GCP
terraform apply -var="cloud_provider=gcp" -var="gcp_project=my-project"

# Deploy to Azure
terraform apply -var="cloud_provider=azure" -var="azure_location=eastus"
```

## 🎯 Common Workflows

### First Time Deployment

```bash
# 1. Copy and configure variables
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars

# 2. Set API keys via environment
export TF_VAR_openai_api_key="sk-..."

# 3. Initialize and validate
terraform init
terraform validate
terraform fmt -recursive

# 4. Plan and review
terraform plan -out=tfplan

# 5. Apply
terraform apply tfplan

# 6. Save outputs
terraform output -json > outputs.json

# 7. Configure kubectl
$(terraform output -raw kubeconfig_command)
kubectl get nodes
```

### Update Existing Infrastructure

```bash
# 1. Pull latest code
git pull origin main

# 2. Check for changes
terraform plan

# 3. Apply if acceptable
terraform apply

# 4. Verify
kubectl get pods --all-namespaces
```

### Scaling Operations

```bash
# Scale up
terraform apply -var="node_count=5"
kubectl get nodes -w

# Scale down
terraform apply -var="node_count=2"

# Upgrade instance type
terraform apply -var="node_instance_type=t3.xlarge"
```

### Disaster Recovery

```bash
# 1. Backup current state
terraform state pull > backup-$(date +%Y%m%d-%H%M%S).tfstate

# 2. If state corrupted, restore
terraform state push backup-20260215-143000.tfstate

# 3. Recreate infrastructure
terraform apply -auto-approve

# 4. Verify
kubectl get nodes
kubectl get pods --all-namespaces
```

### Cost Optimization

```bash
# Check current resource summary
terraform output resource_summary

# Check estimated costs
terraform output estimated_monthly_cost

# Reduce to minimum viable (staging)
terraform apply \
  -var="node_count=2" \
  -var="node_instance_type=t3.medium" \
  -var="db_instance_class=db.t3.small" \
  -var="redis_node_type=cache.t3.small"

# Scale up for production
terraform apply \
  -var="node_count=5" \
  -var="node_instance_type=t3.xlarge" \
  -var="db_instance_class=db.r5.large" \
  -var="redis_node_type=cache.m5.large"
```

## 🔒 Security Best Practices

```bash
# Never commit sensitive files
echo "*.tfvars" >> .gitignore
echo "*.tfstate" >> .gitignore
echo ".terraform/" >> .gitignore

# Use environment variables for secrets
export TF_VAR_datadog_api_key="$(aws secretsmanager get-secret-value --secret-id datadog-key --query SecretString --output text)"

# Encrypt state file
# Configure in backend block:
# backend "s3" {
#   encrypt = true
#   kms_key_id = "arn:aws:kms:..."
# }

# Rotate API keys regularly
# Update in secrets manager/vault, then:
terraform apply -replace=kubernetes_secret.datadog_api_key
```

## 📈 Monitoring Commands

```bash
# Check Grafana dashboard
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
# Visit: http://localhost:3000 (admin / prom-operator)

# Check Datadog agent status
kubectl exec -n monitoring -it daemonset/datadog-agent -- agent status

# Check New Relic status
kubectl get pods -n monitoring -l app=newrelic

# Check Prometheus metrics
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# Visit: http://localhost:9090

# View logs
kubectl logs -n monitoring deployment/datadog-cluster-agent
```

## 🧪 Testing & Validation

```bash
# Validate all files
terraform validate

# Check formatting
terraform fmt -check -recursive

# Security scan (requires tfsec)
tfsec .

# Cost estimation (requires infracost)
infracost breakdown --path .

# Generate documentation (requires terraform-docs)
terraform-docs markdown table . > TERRAFORM_DOCS.md

# Dependency graph
terraform graph | dot -Tpng > graph.png
```

## 🆘 Emergency Procedures

### State Lock Is Stuck
```bash
terraform force-unlock LOCK_ID
```

### Apply Failed Midway
```bash
# Check state
terraform state list

# Refresh state
terraform refresh

# Try again
terraform apply
```

### Need to Rollback
```bash
# List state backups
aws s3 ls s3://marketing-agent-terraform-state/ --recursive

# Download previous state
aws s3 cp s3://marketing-agent-terraform-state/terraform.tfstate.backup ./

# Push to replace current
terraform state push terraform.tfstate.backup
```

### Resource Exists Error
```bash
# Import it
terraform import aws_eks_cluster.main marketing-agent-cluster

# Or remove from state and recreate
terraform state rm aws_eks_cluster.main
```

## 📚 Additional Resources

- Full Documentation: [README.md](README.md)
- Setup Guide: [../../docs/TERRAFORM_SETUP.md](../../docs/TERRAFORM_SETUP.md)
- Monitoring Integration: [../../docs/DATADOG_INTEGRATION.md](../../docs/DATADOG_INTEGRATION.md)
- Production Patterns: [../../docs/PRODUCTION_PATTERNS.md](../../docs/PRODUCTION_PATTERNS.md)
- Terraform Docs: <https://www.terraform.io/docs>
- AWS Provider: <https://registry.terraform.io/providers/hashicorp/aws>
- GCP Provider: <https://registry.terraform.io/providers/hashicorp/google>
- Azure Provider: <https://registry.terraform.io/providers/hashicorp/azurerm>

---

**Pro Tip:** Create aliases for common commands:
```bash
# Add to ~/.bashrc or ~/.zshrc
alias tf='terraform'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfo='terraform output'
alias tfs='terraform state list'
```
