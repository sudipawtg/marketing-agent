################################################################################
# Terraform Configuration for Marketing Agent Multi-Cloud Infrastructure
################################################################################
#
# Purpose:
#   Root Terraform configuration supporting deployment to AWS, GCP, or Azure.
#   Provides production-ready Kubernetes clusters with managed databases,
#   caching, container registries, and optional monitoring integrations.
#
# Architecture:
#   - Kubernetes: EKS (AWS), GKE (GCP), or AKS (Azure) v1.28+
#   - Database: PostgreSQL 15+ with automated backups
#   - Cache: Redis 7.0+ with persistence
#   - Monitoring: Datadog, New Relic, Sumologic, Prometheus, Grafana
#
# Usage:
#   1. Configure variables in terraform.tfvars
#   2. terraform init
#   3. terraform plan -out=tfplan
#   4. terraform apply tfplan
#
# See README.md for complete documentation.
################################################################################

terraform {
  # Minimum Terraform version required for all provider features
  required_version = ">= 1.5.0"
  
  required_providers {
    # AWS Provider - for EKS, RDS, ElastiCache, VPC
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    
    # Google Cloud Provider - for GKE, Cloud SQL, Memorystore
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    
    # Azure Provider - for AKS, PostgreSQL, Redis Cache
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    
    # Kubernetes Provider - for namespace and resource management
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    
    # Helm Provider - for monitoring stack deployment
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }

  # Remote State Backend Configuration
  # IMPORTANT: Configure this backend before running terraform init
  # See README.md "Security Best Practices" section for setup instructions
  backend "s3" {
    bucket         = "marketing-agent-terraform-state"  # Change to your bucket
    key            = "infrastructure/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true                                # Encrypt state at rest
    dynamodb_table = "terraform-state-lock"              # Enable state locking
    
    # Optional: Use KMS for additional encryption
    # kms_key_id = "arn:aws:kms:us-east-1:ACCOUNT:key/KEY-ID"
  }
}

################################################################################
# Variables - Core Configuration
################################################################################

# ============================
# Environment Configuration
# ============================

variable "environment" {
  description = "Deployment environment (staging, production). Affects resource naming and tagging."
  type        = string
  default     = "staging"
  
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production."
  }
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "marketing-agent"
}

# ============================
# Cloud Provider Selection
# ============================

variable "cloud_provider" {
  description = <<-EOT
    Target cloud provider for infrastructure deployment.
    Options: 'aws', 'gcp', 'azure'
    Note: Only one provider can be active per deployment.
  EOT
  type        = string
  default     = "aws"
  
  validation {
    condition     = contains(["aws", "gcp", "azure"], var.cloud_provider)
    error_message = "Cloud provider must be aws, gcp, or azure."
  }
}

# ============================
# AWS Configuration
# ============================

variable "aws_region" {
  description = "AWS region for resource deployment (e.g., us-east-1, eu-west-1)"
  type        = string
  default     = "us-east-1"
}

# ============================
# GCP Configuration
# ============================

variable "gcp_project" {
  description = "GCP project ID (required when cloud_provider=gcp)"
  type        = string
  default     = ""
}

variable "gcp_region" {
  description = "GCP region for resource deployment (e.g., us-central1, europe-west1)"
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "GCP zone within the region (e.g., us-central1-a)"
  type        = string
  default     = "us-central1-a"
}

# ============================
# Azure Configuration
# ============================

variable "azure_location" {
  description = "Azure region for resource deployment (e.g., eastus, westeurope)"
  type        = string
  default     = "eastus"
}

# ============================
# Kubernetes Cluster Settings
# ============================

variable "cluster_name" {
  description = "Name of the Kubernetes cluster (EKS/GKE/AKS)"
  type        = string
  default     = "marketing-agent-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version (e.g., 1.28, 1.29). Check cloud provider for supported versions."
  type        = string
  default     = "1.28"
}

variable "node_count" {
  description = <<-EOT
    Initial number of worker nodes in the cluster.
    Recommendation: 
    - Development: 1-2 nodes
    - Staging: 2-3 nodes  
    - Production: 3-5 nodes (with autoscaling)
  EOT
  type        = number
  default     = 3
}

variable "node_instance_type" {
  description = <<-EOT
    Instance type for worker nodes.
    AWS: t3.medium, t3.large, t3.xlarge, m5.large
    GCP: e2-medium, e2-standard-2, e2-standard-4
    Azure: Standard_B2s, Standard_D2s_v3, Standard_D4s_v3
  EOT
  type        = string
  default     = "t3.medium"
}

# ============================
# Database Configuration
# ============================

variable "db_instance_class" {
  description = "Database instance type (AWS: db.t3.medium, GCP: db-f1-micro, Azure: GP_Gen5_2)"
  type        = string
  default     = "db.t3.medium"
}

variable "db_allocated_storage" {
  description = "Database storage in GB (minimum 20GB, production recommended: 100GB+)"
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "marketing_agent"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "dbadmin"
  sensitive   = true
}

# ============================
# Redis Cache Configuration
# ============================

variable "redis_node_type" {
  description = "Redis instance type (AWS: cache.t3.medium, GCP: BASIC/STANDARD_HA, Azure: Basic/Standard)"
  type        = string
  default     = "cache.t3.medium"
}

# ============================
# Monitoring & Observability
# ============================

variable "enable_monitoring" {
  description = "Deploy Prometheus and Grafana monitoring stack"
  type        = bool
  default     = true
}

variable "enable_datadog" {
  description = "Enable Datadog APM, metrics, and logging integration"
  type        = bool
  default     = false
}

variable "enable_newrelic" {
  description = "Enable New Relic infrastructure and application monitoring"
  type        = bool
  default     = false
}

variable "enable_sumologic" {
  description = "Enable Sumologic log aggregation and analytics"
  type        = bool
  default     = false
}

# ============================
# API Keys & Secrets
# ============================
# IMPORTANT: Never commit these values to version control!
# Use environment variables: export TF_VAR_datadog_api_key="your-key"
# Or use a secrets management service (AWS Secrets Manager, etc.)

variable "datadog_api_key" {
  description = "Datadog API key for agent authentication (sensitive)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "datadog_app_key" {
  description = "Datadog Application key for API access (sensitive)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "newrelic_license_key" {
  description = "New Relic license key (sensitive)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "sumologic_access_id" {
  description = "Sumologic access ID (sensitive)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "sumologic_access_key" {
  description = "Sumologic access key (sensitive)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "openai_api_key" {
  description = "OpenAI API key for LLM access (sensitive, required)"
  type        = string
  sensitive   = true
}

variable "langsmith_api_key" {
  description = "LangSmith API key for LLM tracing (sensitive, optional)"
  type        = string
  sensitive   = true
  default     = ""
}

################################################################################
# Outputs - Infrastructure Access Information
################################################################################
#
# These outputs provide essential information for connecting to and managing
# the deployed infrastructure. Use 'terraform output <name>' to retrieve values.
#
# Security Note: Sensitive outputs are marked and won't display in logs by default.
# Use 'terraform output -json' for programmatic access.
################################################################################

# ============================
# Kubernetes Cluster Access
# ============================

output "cluster_endpoint" {
  description = "Kubernetes API server endpoint URL (use for kubectl configuration)"
  value = var.cloud_provider == "aws" ? (
    length(aws_eks_cluster.main) > 0 ? aws_eks_cluster.main[0].endpoint : ""
  ) : var.cloud_provider == "gcp" ? (
    length(google_container_cluster.main) > 0 ? "https://${google_container_cluster.main[0].endpoint}" : ""
  ) : (
    length(azurerm_kubernetes_cluster.main) > 0 ? azurerm_kubernetes_cluster.main[0].kube_config[0].host : ""
  )
  sensitive = true
}

output "cluster_name" {
  description = "Name of the deployed Kubernetes cluster"
  value       = var.cluster_name
}

output "cluster_version" {
  description = "Kubernetes version running on the cluster"
  value = var.cloud_provider == "aws" ? (
    length(aws_eks_cluster.main) > 0 ? aws_eks_cluster.main[0].version : ""
  ) : var.cloud_provider == "gcp" ? (
    length(google_container_cluster.main) > 0 ? google_container_cluster.main[0].master_version : ""
  ) : (
    length(azurerm_kubernetes_cluster.main) > 0 ? azurerm_kubernetes_cluster.main[0].kubernetes_version : ""
  )
}

output "kubeconfig_command" {
  description = "Command to configure kubectl for cluster access"
  value       = var.cloud_provider == "aws" ? "aws eks update-kubeconfig --region ${var.aws_region} --name ${var.cluster_name}" : var.cloud_provider == "gcp" ? "gcloud container clusters get-credentials ${var.cluster_name} --region ${var.gcp_region} --project ${var.gcp_project}" : "az aks get-credentials --resource-group ${var.cluster_name}-rg --name ${var.cluster_name}"
}

# ============================
# Container Registry
# ============================

output "registry_url" {
  description = "Container registry URL for pushing/pulling Docker images"
  value = var.cloud_provider == "aws" ? (
    length(aws_ecr_repository.backend) > 0 ? aws_ecr_repository.backend[0].repository_url : ""
  ) : var.cloud_provider == "gcp" ? (
    length(google_artifact_registry_repository.main) > 0 ? "${var.gcp_region}-docker.pkg.dev/${var.gcp_project}/${google_artifact_registry_repository.main[0].name}" : ""
  ) : (
    length(azurerm_container_registry.main) > 0 ? azurerm_container_registry.main[0].login_server : ""
  )
}

output "registry_login_command" {
  description = "Command to authenticate with container registry"
  value = var.cloud_provider == "aws" ? "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin $(terraform output -raw registry_url)" : var.cloud_provider == "gcp" ? "gcloud auth configure-docker ${var.gcp_region}-docker.pkg.dev" : "az acr login --name ${replace(var.cluster_name, "-", "")}"
}

# ============================
# Database Connection
# ============================

output "database_endpoint" {
  description = "PostgreSQL database connection endpoint (host:port)"
  value = var.cloud_provider == "aws" ? (
    length(aws_db_instance.main) > 0 ? aws_db_instance.main[0].endpoint : ""
  ) : var.cloud_provider == "gcp" ? (
    length(google_sql_database_instance.main) > 0 ? google_sql_database_instance.main[0].connection_name : ""
  ) : (
    length(azurerm_postgresql_flexible_server.main) > 0 ? azurerm_postgresql_flexible_server.main[0].fqdn : ""
  )
  sensitive = true
}

output "database_name" {
  description = "Name of the created database"
  value       = var.db_name
}

output "database_connection_string" {
  description = "PostgreSQL connection string (without password)"
  value = var.cloud_provider == "aws" ? (
    length(aws_db_instance.main) > 0 ? "postgresql://${var.db_username}@${aws_db_instance.main[0].endpoint}/${var.db_name}" : ""
  ) : var.cloud_provider == "gcp" ? (
    length(google_sql_database_instance.main) > 0 ? "postgresql://${var.db_username}@/${var.db_name}?host=/cloudsql/${google_sql_database_instance.main[0].connection_name}" : ""
  ) : (
    length(azurerm_postgresql_flexible_server.main) > 0 ? "postgresql://${var.db_username}@${azurerm_postgresql_flexible_server.main[0].fqdn}:5432/${var.db_name}" : ""
  )
  sensitive = true
}

# ============================
# Redis Cache
# ============================

output "redis_endpoint" {
  description = "Redis cache endpoint (host:port)"
  value = var.cloud_provider == "aws" ? (
    length(aws_elasticache_cluster.main) > 0 ? "${aws_elasticache_cluster.main[0].cache_nodes[0].address}:${aws_elasticache_cluster.main[0].cache_nodes[0].port}" : ""
  ) : var.cloud_provider == "gcp" ? (
    length(google_redis_instance.main) > 0 ? "${google_redis_instance.main[0].host}:${google_redis_instance.main[0].port}" : ""
  ) : (
    length(azurerm_redis_cache.main) > 0 ? "${azurerm_redis_cache.main[0].hostname}:${azurerm_redis_cache.main[0].ssl_port}" : ""
  )
  sensitive = true
}

# ============================
# Networking & Load Balancing
# ============================

output "vpc_id" {
  description = "VPC/Virtual Network ID"
  value = var.cloud_provider == "aws" ? (
    length(aws_vpc.main) > 0 ? aws_vpc.main[0].id : ""
  ) : var.cloud_provider == "gcp" ? (
    length(google_compute_network.main) > 0 ? google_compute_network.main[0].id : ""
  ) : (
    length(azurerm_virtual_network.main) > 0 ? azurerm_virtual_network.main[0].id : ""
  )
}

output "load_balancer_ip" {
  description = "Load balancer IP or DNS for application access"
  value       = "Available after service deployment - check with: kubectl get svc -n default"
}

# ============================
# Monitoring & Observability
# ============================

output "monitoring_enabled" {
  description = "List of enabled monitoring integrations"
  value = compact([
    var.enable_monitoring ? "Prometheus/Grafana" : "",
    var.enable_datadog ? "Datadog" : "",
    var.enable_newrelic ? "New Relic" : "",
    var.enable_sumologic ? "Sumologic" : "",
  ])
}

output "monitoring_dashboard_url" {
  description = "Monitoring dashboard access URL (available after ingress setup)"
  value       = var.enable_monitoring ? "Run 'kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80' then visit http://localhost:3000" : "Monitoring not enabled"
}

output "grafana_admin_password" {
  description = "Grafana admin password (default, should be changed)"
  value       = "prom-operator"
  sensitive   = true
}

# ============================
# Cost & Resource Summary
# ============================

output "resource_summary" {
  description = "Summary of deployed resources"
  value = {
    cloud_provider    = var.cloud_provider
    environment       = var.environment
    cluster_nodes     = var.node_count
    node_type         = var.node_instance_type
    database_instance = var.db_instance_class
    redis_instance    = var.redis_node_type
    monitoring_stack  = var.enable_monitoring
  }
}

output "estimated_monthly_cost" {
  description = "Estimated monthly infrastructure cost (USD, approximate)"
  value = var.cloud_provider == "aws" ? (
    var.environment == "production" ? "$1,200 - $1,800" : "$450 - $600"
  ) : var.cloud_provider == "gcp" ? (
    var.environment == "production" ? "$1,100 - $1,600" : "$400 - $550"
  ) : (
    var.environment == "production" ? "$1,250 - $1,900" : "$480 - $630"
  )
}

# ============================
# Next Steps
# ============================

output "next_steps" {
  description = "Post-deployment instructions"
  value = <<-EOT
    ✅ Infrastructure deployed successfully!
    
    Next steps:
    1. Configure kubectl:
       ${var.cloud_provider == "aws" ? "aws eks update-kubeconfig --region ${var.aws_region} --name ${var.cluster_name}" : var.cloud_provider == "gcp" ? "gcloud container clusters get-credentials ${var.cluster_name} --region ${var.gcp_region}" : "az aks get-credentials --resource-group ${var.cluster_name}-rg --name ${var.cluster_name}"}
    
    2. Verify cluster access:
       kubectl get nodes
       kubectl get namespaces
    
    3. Deploy application:
       kubectl apply -k infrastructure/k8s/base/
    
    4. Access monitoring:
       kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
       Open http://localhost:3000 (admin/prom-operator)
    
    5. View full outputs:
       terraform output -json > outputs.json
    
    📚 Documentation: See infrastructure/terraform/README.md
  EOT
}
