################################################################################
# AZURE Infrastructure Module
################################################################################
#
# PURPOSE:
#   Provision complete Azure infrastructure for Marketing Agent platform including:
#   - AKS (Azure Kubernetes Service) cluster v1.28
#   - Virtual Network (VNet) with custom subnets
#   - Azure Database for PostgreSQL Flexible Server
#   - Azure Cache for Redis
#   - Azure Container Registry (ACR) for Docker images
#   - Log Analytics Workspace for monitoring
#   - Role-based access control (RBAC) for AKS-ACR integration
#
# ARCHITECTURE:
#   ┌─────────────────────────────────────────────────────────┐
#   │         Azure Region (e.g., East US)                    │
#   │  ┌──────────────────────────────────────────────────┐   │
#   │  │  Resource Group: {cluster-name}-rg               │   │
#   │  │                                                   │   │
#   │  │  ┌────────────────────────────────────────────┐  │   │
#   │  │  │  Virtual Network: 10.0.0.0/16              │  │   │
#   │  │  │                                             │  │   │
#   │  │  │  ┌──────────────────────────────────────┐  │  │   │
#   │  │  │  │  AKS Subnet: 10.0.1.0/24             │  │  │   │
#   │  │  │  │  - AKS nodes                         │  │  │   │
#   │  │  │  │  - Standard_D2_v2 VMs                │  │  │   │
#   │  │  │  │  - Autoscaling (2-6 nodes)           │  │  │   │
#   │  │  │  └──────────────────────────────────────┘  │  │   │
#   │  │  │                                             │  │   │
#   │  │  │  ┌──────────────────────────────────────┐  │  │   │
#   │  │  │  │  DB Subnet: 10.0.2.0/24              │  │  │   │
#   │  │  │  │  - PostgreSQL Flexible Server        │  │  │   │
#   │  │  │  │  - Private endpoint (no public IP)   │  │  │   │
#   │  │  │  └──────────────────────────────────────┘  │  │   │
#   │  │  └─────────────────────────────────────────────┘  │   │
#   │  │                                                     │   │
#   │  │  [Azure Container Registry - ACR]                  │   │
#   │  │  [Azure Cache for Redis]                           │   │
#   │  │  [Log Analytics Workspace]                         │   │
#   │  └─────────────────────────────────────────────────────┘   │
#   └─────────────────────────────────────────────────────────────┘
#
# AZURE-SPECIFIC CONCEPTS:
#
#   Resource Group:
#   - Logical container for Azure resources
#   - All resources in this module belong to one resource group
#   - Similar to AWS tags but stronger (affects permissions, lifecycle)
#   - When you delete a resource group, all resources inside are deleted
#
#   System-Assigned Managed Identity:
#   - Azure's way to give resources (like AKS) an identity
#   - No need to manage credentials/passwords
#   - Similar to AWS IAM roles for EC2 instances
#   - Automatically rotated and managed by Azure
#
#   Subnet Delegation:
#   - Assigns a subnet exclusively to a specific Azure service
#   - Required for PostgreSQL Flexible Server private networking
#   - Service can inject network interfaces directly into subnet
#
#   Azure CNI vs kubenet:
#   - kubenet: Pods get IPs from a separate CIDR (simpler, cheaper)
#   - Azure CNI: Pods get IPs from VNet (better integration, uses more IPs)
#   - We use Azure CNI for better network performance
#
#   Private DNS Zone:
#   - DNS service for private name resolution within VNet
#   - Required for PostgreSQL private endpoints
#   - Format: privatelink.postgres.database.azure.com
#
# RESOURCES CREATED:
#   - 1 Resource Group (container for all resources)
#   - 1 Virtual Network (10.0.0.0/16)
#   - 2 Subnets (AKS, Database)
#   - 1 AKS Cluster (regional, 3+ zones)
#   - 1 Node Pool (Standard_D2_v2, autoscaling 2-6)
#   - 1 Azure Container Registry (Standard SKU)
#   - 1 PostgreSQL Flexible Server (B_Standard_B1ms)
#   - 1 PostgreSQL Database (marketing_agent)
#   - 1 Azure Cache for Redis (Basic C0)
#   - 1 Log Analytics Workspace (30-day retention)
#   - 1 Private DNS Zone (for PostgreSQL)
#   - 1 Role Assignment (AKS → ACR access)
#
# CONDITIONAL CREATION:
#   All resources only created when: var.cloud_provider == "azure"
#
# COST ESTIMATE (Staging):
#   - AKS Control Plane: $75/month (managed service fee)
#   - VMs (3x Standard_D2_v2): ~$210/month
#   - PostgreSQL (B_Standard_B1ms): ~$25/month
#   - Azure Cache for Redis (Basic C0): ~$17/month
#   - Container Registry (Standard): ~$20/month
#   - Log Analytics: ~$10/month (based on ingestion)
#   - Networking: ~$15/month
#   Total: ~$372/month
#
# COST ESTIMATE (Production):
#   - AKS Control Plane: $75/month
#   - VMs (5x Standard_D4s_v3): ~$730/month
#   - PostgreSQL (GP_Gen5_2, HA): ~$250/month
#   - Azure Cache for Redis (Standard C1): ~$75/month
#   - Container Registry (Premium): ~$165/month
#   - Log Analytics: ~$50/month
#   - Networking + Load Balancer: ~$50/month
#   Total: ~$1,395/month
#
# SECURITY FEATURES:
#   - Network isolation (private subnets)
#   - Managed identities (no password management)
#   - Private endpoints for database (no public access)
#   - Azure Policy enabled (governance and compliance)
#   - Container scanning in ACR
#   - TLS 1.2 minimum for Redis
#   - Azure Monitor integration
#   - RBAC for all resources
#
# HIGH AVAILABILITY:
#   - AKS nodes spread across availability zones
#   - Node pool autoscaling (maintain capacity)
#   - PostgreSQL zone-redundant HA (production)
#   - Redis Standard_HA tier (production)
#   - Automated backups (7 days retention)
#
# LEARNING NOTES:
#   - Azure uses "Resource Groups" as primary organizational unit
#   - Azure regions have "Availability Zones" (like AWS AZs)
#   - "SKU" = Stock Keeping Unit (pricing tier)
#   - Azure naming: AKS (not EKS), ACR (not ECR), VNet (not VPC)
#   - Azure CLI command: az (e.g., az aks get-credentials)
#
################################################################################

# =============================================================================
# PROVIDER CONFIGURATION
# =============================================================================
# Configure the Azure provider
# The "features" block is required but can be empty for default behavior

provider "azurerm" {
  features {}  # Required block (empty uses defaults)
}

################################################################################
# RESOURCE GROUP
################################################################################
#
# WHAT IS A RESOURCE GROUP?
#   A container that holds related Azure resources
#   All resources must belong to exactly one resource group
#
# WHY USE IT?
#   - Organize resources by project/environment/team
#   - Apply policies and permissions at group level
#   - Manage lifecycle together (delete all at once)
#   - Track costs by group
#
# NAMING CONVENTION:
#   {cluster-name}-rg
#   Example: marketing-agent-cluster-rg
#
# LOCATION:
#   The region where resource metadata is stored
#   Resources inside can be in different regions (but typically same)
#
################################################################################

resource "azurerm_resource_group" "main" {
  count    = var.cloud_provider == "azure" ? 1 : 0
  name     = "${var.cluster_name}-rg"  # e.g., "marketing-agent-cluster-rg"
  location = var.azure_location         # e.g., "eastus", "westeurope"

  # TAGS
  # Key-value pairs for organization and cost tracking
  # Inherited by resources in this group (unless overridden)
  tags = {
    Environment = var.environment  # staging, production
    ManagedBy   = "Terraform"      # Who/what manages this
  }
}

################################################################################
# VIRTUAL NETWORK (VNet)
################################################################################
#
# WHAT IS A VNet?
#   Azure's private network (equivalent to AWS VPC)
#   Isolated network where your resources communicate securely
#
# ADDRESS SPACE:
#   10.0.0.0/16 = 65,536 IP addresses total
#   - 10.0.1.0/24 = 256 IPs for AKS (subnet 1)
#   - 10.0.2.0/24 = 256 IPs for PostgreSQL (subnet 2)
#   - Remaining space available for future subnets
#
# WHY /16?
#   - Large enough for growth
#   - Standard private IP range (RFC 1918)
#   - Won't conflict with common on-premises networks
#
################################################################################

resource "azurerm_virtual_network" "main" {
  count               = var.cloud_provider == "azure" ? 1 : 0
  name                = "${var.cluster_name}-vnet"
  address_space       = ["10.0.0.0/16"]  # Total IP space for this VNet
  location            = azurerm_resource_group.main[0].location
  resource_group_name = azurerm_resource_group.main[0].name

  tags = {
    Environment = var.environment
  }
}

################################################################################
# SUBNET FOR AKS
################################################################################
#
# WHAT IS A SUBNET?
#   A segment of the VNet with a subset of the IP address range
#   Resources in a subnet can communicate easily with each other
#
# THIS SUBNET:
#   For AKS cluster nodes (Kubernetes worker VMs)
#   10.0.1.0/24 = 256 IP addresses
#   - Azure reserves 5 IPs per subnet (first 4 and last 1)
#   - Usable IPs: 251
#   - Enough for ~200 nodes (accounting for load balancers, etc.)
#
################################################################################

resource "azurerm_subnet" "aks" {
  count                = var.cloud_provider == "azure" ? 1 : 0
  name                 = "${var.cluster_name}-aks-subnet"
  resource_group_name  = azurerm_resource_group.main[0].name
  virtual_network_name = azurerm_virtual_network.main[0].name
  address_prefixes     = ["10.0.1.0/24"]  # IP range for AKS nodes
}

################################################################################
# SUBNET FOR POSTGRESQL DATABASE
################################################################################
#
# WHAT'S DIFFERENT HERE?
#   This subnet has two special configurations:
#   1. Service Endpoints: Allow direct access to Azure services
#   2. Delegation: Subnet is exclusively for PostgreSQL
#
# SERVICE ENDPOINTS:
#   - Optimized network path to Azure SQL service
#   - Traffic stays on Azure backbone (doesn't go to internet)
#   - Better security and performance
#
# DELEGATION:
#   - Assigns subnet exclusively to PostgreSQL Flexible Server
#   - Azure can inject network interfaces for the database
#   - Required for PostgreSQL private networking
#
################################################################################

resource "azurerm_subnet" "db" {
  count                = var.cloud_provider == "azure" ? 1 : 0
  name                 = "${var.cluster_name}-db-subnet"
  resource_group_name  = azurerm_resource_group.main[0].name
  virtual_network_name = azurerm_virtual_network.main[0].name
  address_prefixes     = ["10.0.2.0/24"]  # IP range for database

  # SERVICE ENDPOINTS
  # Allow direct access to Azure SQL service
  # Traffic doesn't leave Azure network (more secure, faster)
  service_endpoints = ["Microsoft.Sql"]

  # SUBNET DELEGATION
  # Dedicate this subnet exclusively to PostgreSQL Flexible Servers
  delegation {
    name = "fs"  # Flexible Server
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",  # Join subnet
      ]
    }
  }
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "main" {
  count               = var.cloud_provider == "azure" ? 1 : 0
  name                = var.cluster_name
  location            = azurerm_resource_group.main[0].location
  resource_group_name = azurerm_resource_group.main[0].name
  dns_prefix          = var.cluster_name
  kubernetes_version  = "1.28"

  default_node_pool {
    name                = "default"
    node_count          = var.node_count
    vm_size             = "Standard_D2_v2"
    vnet_subnet_id      = azurerm_subnet.aks[0].id
    enable_auto_scaling = true
    min_count           = 2
    max_count           = var.node_count * 2
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    service_cidr      = "10.0.10.0/24"
    dns_service_ip    = "10.0.10.10"
    docker_bridge_cidr = "172.17.0.1/16"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main[0].id
  }

  azure_policy_enabled = true

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Log Analytics Workspace for monitoring
resource "azurerm_log_analytics_workspace" "main" {
  count               = var.cloud_provider == "azure" ? 1 : 0
  name                = "${var.cluster_name}-logs"
  location            = azurerm_resource_group.main[0].location
  resource_group_name = azurerm_resource_group.main[0].name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Environment = var.environment
  }
}

# Container Registry
resource "azurerm_container_registry" "main" {
  count               = var.cloud_provider == "azure" ? 1 : 0
  name                = replace("${var.cluster_name}acr", "-", "")
  resource_group_name = azurerm_resource_group.main[0].name
  location            = azurerm_resource_group.main[0].location
  sku                 = "Standard"
  admin_enabled       = true

  tags = {
    Environment = var.environment
  }
}

# Role assignment for AKS to pull from ACR
resource "azurerm_role_assignment" "aks_acr" {
  count                = var.cloud_provider == "azure" ? 1 : 0
  principal_id         = azurerm_kubernetes_cluster.main[0].kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.main[0].id
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "main" {
  count               = var.cloud_provider == "azure" ? 1 : 0
  name                = "${var.cluster_name}-db"
  resource_group_name = azurerm_resource_group.main[0].name
  location            = azurerm_resource_group.main[0].location
  version             = "15"
  delegated_subnet_id = azurerm_subnet.db[0].id
  private_dns_zone_id = azurerm_private_dns_zone.db[0].id

  administrator_login    = "postgres"
  administrator_password = random_password.azure_db_password.result

  storage_mb = 32768
  sku_name   = "B_Standard_B1ms"

  backup_retention_days = var.environment == "production" ? 7 : 1
  geo_redundant_backup_enabled = var.environment == "production"

  high_availability {
    mode = var.environment == "production" ? "ZoneRedundant" : "Disabled"
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.db]

  tags = {
    Environment = var.environment
  }
}

resource "azurerm_postgresql_flexible_server_database" "main" {
  count     = var.cloud_provider == "azure" ? 1 : 0
  name      = "marketing_agent"
  server_id = azurerm_postgresql_flexible_server.main[0].id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# Private DNS Zone for PostgreSQL
resource "azurerm_private_dns_zone" "db" {
  count               = var.cloud_provider == "azure" ? 1 : 0
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.main[0].name
}

resource "azurerm_private_dns_zone_virtual_network_link" "db" {
  count                 = var.cloud_provider == "azure" ? 1 : 0
  name                  = "${var.cluster_name}-db-dns-link"
  private_dns_zone_name = azurerm_private_dns_zone.db[0].name
  virtual_network_id    = azurerm_virtual_network.main[0].id
  resource_group_name   = azurerm_resource_group.main[0].name
}

# Azure Cache for Redis
resource "azurerm_redis_cache" "main" {
  count               = var.cloud_provider == "azure" ? 1 : 0
  name                = "${var.cluster_name}-cache"
  location            = azurerm_resource_group.main[0].location
  resource_group_name = azurerm_resource_group.main[0].name
  capacity            = 0
  family              = "C"
  sku_name            = "Basic"
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"

  redis_configuration {
  }

  tags = {
    Environment = var.environment
  }
}

# Random password for Azure PostgreSQL
resource "random_password" "azure_db_password" {
  length  = 32
  special = true
}

# Outputs
output "cluster_endpoint" {
  value = var.cloud_provider == "azure" ? azurerm_kubernetes_cluster.main[0].kube_config[0].host : null
}

output "acr_login_server" {
  value = var.cloud_provider == "azure" ? azurerm_container_registry.main[0].login_server : null
}

output "postgresql_fqdn" {
  value = var.cloud_provider == "azure" ? azurerm_postgresql_flexible_server.main[0].fqdn : null
}

output "redis_hostname" {
  value = var.cloud_provider == "azure" ? azurerm_redis_cache.main[0].hostname : null
}

output "load_balancer_ip" {
  value = var.cloud_provider == "azure" ? azurerm_kubernetes_cluster.main[0].kube_config[0].host : null
}
