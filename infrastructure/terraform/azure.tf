# Azure Infrastructure Module

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "main" {
  count    = var.cloud_provider == "azure" ? 1 : 0
  name     = "${var.cluster_name}-rg"
  location = var.azure_location

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  count               = var.cloud_provider == "azure" ? 1 : 0
  name                = "${var.cluster_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main[0].location
  resource_group_name = azurerm_resource_group.main[0].name

  tags = {
    Environment = var.environment
  }
}

# Subnet for AKS
resource "azurerm_subnet" "aks" {
  count                = var.cloud_provider == "azure" ? 1 : 0
  name                 = "${var.cluster_name}-aks-subnet"
  resource_group_name  = azurerm_resource_group.main[0].name
  virtual_network_name = azurerm_virtual_network.main[0].name
  address_prefixes     = ["10.0.1.0/24"]
}

# Subnet for PostgreSQL
resource "azurerm_subnet" "db" {
  count                = var.cloud_provider == "azure" ? 1 : 0
  name                 = "${var.cluster_name}-db-subnet"
  resource_group_name  = azurerm_resource_group.main[0].name
  virtual_network_name = azurerm_virtual_network.main[0].name
  address_prefixes     = ["10.0.2.0/24"]

  service_endpoints = ["Microsoft.Sql"]

  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
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
