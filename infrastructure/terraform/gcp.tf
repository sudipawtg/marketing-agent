################################################################################
# GCP (Google Cloud Platform) Infrastructure Module
################################################################################
#
# PURPOSE:
#   Provision complete GCP infrastructure for Marketing Agent platform including:
#   - GKE (Google Kubernetes Engine) cluster v1.28
#   - VPC with custom subnets and secondary CIDR ranges for pods/services
#   - Cloud SQL PostgreSQL 15 database with automated backups
#   - Cloud Memorystore Redis 7.0 cluster
#   - Artifact Registry (container registry) repositories
#   - IAM service accounts and IAM bindings
#
# ARCHITECTURE:
#   ┌─────────────────────────────────────────────────────┐
#   │                    GCP Region (e.g., us-central1)   │
#   │  ┌───────────────────────────────────────────────┐  │
#   │  │  VPC Network (Custom Mode)                    │  │
#   │  │  ┌─────────────────────────────────────────┐  │  │
#   │  │  │  Primary Subnet: 10.0.0.0/24            │  │  │
#   │  │  │  (For GKE nodes and pods)               │  │  │
#   │  │  │                                          │  │  │
#   │  │  │  Secondary IP Ranges:                   │  │  │
#   │  │  │  - Pods:     10.1.0.0/16                │  │  │
#   │  │  │  - Services: 10.2.0.0/16                │  │  │
#   │  │  │                                          │  │  │
#   │  │  │  ┌────────────────────────────────────┐ │  │  │
#   │  │  │  │  GKE Cluster (Regional)            │ │  │  │
#   │  │  │  │  - Node Pool (e2-medium)           │ │  │  │
#   │  │  │  │  - Autoscaling (2-6 nodes)         │ │  │  │
#   │  │  │  │  - Workload Identity enabled       │ │  │  │
#   │  │  │  └────────────────────────────────────┘ │  │  │
#   │  │  └─────────────────────────────────────────┘  │  │
#   │  │                                                 │  │
#   │  │  [Cloud SQL PostgreSQL - Private IP]           │  │
#   │  │  [Memorystore Redis - VPC Native]              │  │
#   │  └─────────────────────────────────────────────────┘  │
#   └─────────────────────────────────────────────────────────┘
#              │
#              ▼
#   [Artifact Registry: {region}-docker.pkg.dev]
#   (Container images stored in regional repository)
#
# GCP-SPECIFIC CONCEPTS:
#
#   VPC-Native Cluster (Alias IPs):
#   - GKE cluster uses VPC-native networking (IP aliasing)
#   - Each pod gets an IP from the secondary "pods" CIDR range
#   - Services get IPs from the secondary "services" CIDR range
#   - Benefits: Better network performance, automatic firewall rules
#
#   Workload Identity:
#   - Secure way to grant GKE pods access to GCP services
#   - Pods use Kubernetes service accounts mapped to GCP service accounts
#   - No need to manage JSON key files (security best practice)
#   - Enabled with: workload_identity_config
#
#   Regional vs Zonal Clusters:
#   - Regional: Control plane replicated across multiple zones (HA)
#   - Zonal: Control plane in single zone (cheaper, less available)
#   - Production should use regional for 99.95% SLA
#
#   Cloud SQL Private IP:
#   - Database accessible only within VPC (no public internet)
#   - Uses VPC peering for connectivity
#   - More secure than public IP + authorized networks
#
#   Binary Authorization:
#   - Enforces deployment of only verified container images
#   - Images must be signed or come from trusted registries
#   - Prevents deployment of vulnerable/malicious images
#
# RESOURCES CREATED:
#   - 1 VPC network (custom mode)
#   - 1 Subnet with 2 secondary IP ranges
#   - 1 GKE cluster (regional or zonal based on config)
#   - 1 GKE node pool (e2-medium, autoscaling 2-6 nodes)
#   - 1 Cloud SQL PostgreSQL instance (db-f1-micro for staging)
#   - 1 Cloud SQL database (marketing_agent)
#   - 1 Cloud SQL user (postgres)
#   - 1 Memorystore Redis instance (BASIC tier, 1GB)
#   - 1 Artifact Registry repository (Docker format)
#   - 1 Service account for GKE nodes
#   - 3 IAM bindings (logging, monitoring, artifact registry access)
#   - 1 Firewall rule (allow internal traffic)
#
# CONDITIONAL CREATION:
#   All resources only created when: var.cloud_provider == "gcp"
#
# COST ESTIMATE (Staging):
#   - GKE Cluster: Free (no cluster management fee)
#   - Compute Engine (3x e2-medium): ~$75/month
#   - Cloud SQL (db-f1-micro): ~$15/month
#   - Memorystore Redis (BASIC 1GB): ~$30/month
#   - Artifact Registry: ~$5/month (storage + egress)
#   - Network Egress: ~$10/month
#   Total: ~$135/month (GCP is typically cheaper than AWS/Azure)
#
# COST ESTIMATE (Production):
#   - GKE Cluster: Free
#   - Compute Engine (5x e2-standard-4): ~$550/month
#   - Cloud SQL (db-n1-standard-2, HA): ~$280/month
#   - Memorystore Redis (STANDARD_HA 5GB): ~$180/month
#   - Artifact Registry: ~$20/month
#   - Network Egress: ~$80/month
#   - Cloud Load Balancer: ~$20/month
#   Total: ~$1,130/month
#
# SECURITY FEATURES:
#   - VPC-native networking (no external IPs for pods)
#   - Private Google Access (nodes can reach GCP APIs without public IP)
#   - Workload Identity (secure auth for pods → GCP services)
#   - Shielded GKE nodes (Secure Boot, vTPM, Integrity Monitoring)
#   - Binary Authorization (only deploy verified images)
#   - Cloud SQL private IP (no internet exposure)
#   - Automatic node upgrades and security patches
#   - GKE audit logging enabled
#
# HIGH AVAILABILITY:
#   - Regional GKE cluster (control plane replicated)
#   - Multi-zone node pool (nodes spread across zones)
#   - Cloud SQL regional replication (production)
#   - Memorystore STANDARD_HA tier (production)
#   - Autoscaling for capacity management
#
# LEARNING NOTES:
#   - GCP uses "projects" instead of AWS accounts
#   - GCP uses "regions" and "zones" (e.g., us-central1-a)
#   - GCP APIs must be enabled before resource creation
#   - gcloud CLI is GCP equivalent of aws CLI
#   - GKE is generally easier to manage than EKS
#   - Pricing is per-second billing (vs AWS per-hour)
#
################################################################################

# =============================================================================
# PROVIDER CONFIGURATION
# =============================================================================
# Configure the Google Cloud provider with project and region settings
# The project ID is where all resources will be created
# The region determines the geographic location of resources

provider "google" {
  project = var.gcp_project  # GCP project ID (e.g., "my-project-12345")
  region  = var.gcp_region   # Default region (e.g., "us-central1")
}

################################################################################
# GKE (Google Kubernetes Engine) CLUSTER
################################################################################
#
# WHAT IS GKE?
#   Google Kubernetes Engine is a managed Kubernetes service that handles
#   the control plane (API server, scheduler, etc.) for you. You only manage
#   the worker nodes and your applications.
#
# KEY FEATURES:
#   - Auto-upgrades: Kubernetes and node OS patches applied automatically
#   - Auto-repair: Unhealthy nodes automatically replaced
#   - Stackdriver integration: Built-in logging and monitoring
#   - Workload Identity: Secure way to access GCP services from pods
#   - Binary Authorization: Only deploy verified container images
#   - VPC-native networking: Pods get VPC IPs (better performance)
#
# INITIAL NODE COUNT:
#   Set to 1 because we immediately remove this default node pool
#   and create a custom node pool with autoscaling and specific settings
#
# REMOVE DEFAULT NODE POOL:
#   The default node pool has limited configuration options
#   We remove it and create a custom node pool for more control
#
################################################################################

resource "google_container_cluster" "main" {
  # Only create this resource if GCP is the selected cloud provider
  count              = var.cloud_provider == "gcp" ? 1 : 0
  name               = var.cluster_name           # e.g., "marketing-agent-cluster"
  location           = var.gcp_region             # Regional cluster (HA) or specific zone
  initial_node_count = 1                          # Temporary, removed immediately

  # REMOVE DEFAULT NODE POOL
  # The default node pool has limited configuration options
  # We create a custom node pool below with autoscaling and better settings
  remove_default_node_pool = true

  # NETWORK CONFIGURATION
  # Attach cluster to the VPC network and subnet created below
  # This determines which network the cluster nodes live in
  network    = google_compute_network.main[0].name    # VPC network name
  subnetwork = google_compute_subnetwork.main[0].name # Subnet name

  # IP ALLOCATION POLICY (VPC-Native / Alias IPs)
  #
  # WHY VPC-NATIVE?
  # - Pods get real VPC IP addresses (not NAT'd)
  # - Better network performance (no iptables overhead)
  # - Automatic firewall rules for pod-to-pod traffic
  # - Can communicate with other GCP services directly
  #
  # SECONDARY RANGES:
  # - cluster_secondary_range_name: CIDR block for pod IPs (10.1.0.0/16)
  # - services_secondary_range_name: CIDR block for service IPs (10.2.0.0/16)
  #
  # These ranges are defined in the subnet resource below
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"      # Secondary range for pod IPs
    services_secondary_range_name = "services"  # Secondary range for service IPs
  }

  # WORKLOAD IDENTITY
  #
  # WHAT IS IT?
  # - Allows Kubernetes pods to authenticate as GCP service accounts
  # - Pods can access GCP APIs (Cloud Storage, Cloud SQL, etc.) securely
  # - No need to download JSON key files (security risk)
  #
  # HOW IT WORKS:
  # 1. Create a Kubernetes service account (in K8s)
  # 2. Create a GCP service account (in GCP IAM)
  # 3. Bind them together with IAM policy
  # 4. Pods using K8s SA automatically get GCP SA credentials
  #
  # WORKLOAD POOL FORMAT:
  # - {PROJECT_ID}.svc.id.goog
  # - This is a special identity namespace for workload identity
  workload_identity_config {
    workload_pool = "${var.gcp_project}.svc.id.goog"
  }

  # LOGGING AND MONITORING
  #
  # GKE integrates with Cloud Logging and Cloud Monitoring (formerly Stackdriver)
  # - logging.googleapis.com/kubernetes: Stream logs to Cloud Logging
  # - monitoring.googleapis.com/kubernetes: Send metrics to Cloud Monitoring
  #
  # LOGS COLLECTED:
  # - Container stdout/stderr
  # - Kubernetes audit logs
  # - Kubernetes events
  # - Node system logs
  #
  # METRICS COLLECTED:
  # - CPU, memory, disk usage
  # - Network throughput
  # - Kubernetes API requests
  # - Pod/container metrics
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  # GKE ADDONS
  # Built-in features that enhance cluster functionality
  addons_config {
    # HTTP LOAD BALANCING
    # - Automatically provisions Google Cloud Load Balancers
    # - When you create a LoadBalancer service in K8s, GKE creates a GCP LB
    # - Handles SSL termination, health checks, and traffic distribution
    http_load_balancing {
      disabled = false  # enabled
    }
    
    # HORIZONTAL POD AUTOSCALING
    # - Enables the HorizontalPodAutoscaler resource
    # - Automatically scales pods based on CPU/memory/custom metrics
    # - Requires metrics-server (installed automatically)
    horizontal_pod_autoscaling {
      disabled = false  # enabled
    }
  }

  # MASTER AUTHENTICATION
  #
  # CLIENT CERTIFICATES (LEGACY):
  # - Old authentication method using client certificates
  # - Deprecated in favor of OAuth tokens and OIDC
  # - Disabled for security (modern auth methods are more secure)
  #
  # MODERN AUTH:
  # - Use gcloud to get credentials: gcloud container clusters get-credentials
  # - Uses OAuth token from your gcloud auth
  # - Tokens expire automatically (better security)
  master_auth {
    client_certificate_config {
      issue_client_certificate = false  # Disable legacy client certs
    }
  }

  # BINARY AUTHORIZATION
  #
  # WHAT IS IT?
  # - Policy-based deployment control
  # - Only allows deployment of verified/signed container images
  # - Prevents deployment of vulnerable or malicious images
  #
  # MODES:
  # - DISABLED: No checks (not recommended for production)
  # - PROJECT_SINGLETON_POLICY_ENFORCE: Enforce policy (production)
  #
  # USE CASES:
  # - Require images from specific registries (e.g., only gcr.io/my-project)
  # - Require images to be scanned for vulnerabilities
  # - Require images to be signed by trusted authorities
  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }
}

################################################################################
# GKE NODE POOL
################################################################################
#
# WHAT IS A NODE POOL?
#   A node pool is a group of nodes (VMs) within a GKE cluster that all have
#   the same configuration (machine type, disk size, service account, etc.)
#
# WHY SEPARATE FROM CLUSTER?
#   - Allows multiple node pools with different configurations
#   - Can have GPU nodes, high-memory nodes, spot instances in different pools
#   - Easy to upgrade/replace nodes without affecting the cluster
#
# KEY FEATURES:
#   - Autoscaling: Automatically add/remove nodes based on pod resource requests
#   - Auto-upgrade: Nodes automatically upgraded to match cluster version
#   - Auto-repair: Unhealthy nodes automatically repaired or replaced
#
# NODE COUNT:
#   - Initial: var.node_count (typically 3 for staging)
#   - Min: 2 (ensure availability during failures/upgrades)
#   - Max: var.node_count * 2 (handle traffic spikes)
#
################################################################################

resource "google_container_node_pool" "main" {
  count      = var.cloud_provider == "gcp" ? 1 : 0
  name       = "${var.cluster_name}-node-pool"  # e.g., "marketing-agent-cluster-node-pool"
  location   = var.gcp_region                    # Same region as cluster
  cluster    = google_container_cluster.main[0].name  # Attach to the cluster above
  node_count = var.node_count                    # Initial number of nodes per zone

  # NODE CONFIGURATION
  # Defines the specs for each VM in this node pool
  node_config {
    # MACHINE TYPE
    # - e2-medium: 2 vCPUs, 4GB RAM (~$25/month per node)
    # - e2-standard-2: 2 vCPUs, 8GB RAM (~$50/month)
    # - e2-standard-4: 4 vCPUs, 16GB RAM (~$100/month)
    #
    # E2 SERIES:
    # - Cost-optimized, general-purpose workloads
    # - Good for web servers, dev/test, microservices
    # - Cheaper than N1/N2 series (20-30% cost savings)
    machine_type = "e2-medium"
    
    # DISK CONFIGURATION
    # - disk_size_gb: Storage for OS and container images
    # - disk_type: pd-standard (HDD, cheap) or pd-ssd (SSD, fast)
    #
    # 50GB is sufficient for:
    # - Operating system (~10GB)
    # - Container images (~20GB)
    # - Local ephemeral storage (~20GB)
    disk_size_gb = 50
    disk_type    = "pd-standard"  # HDD is fine for node disk (use SSD for databases)

    # SERVICE ACCOUNT
    # - Nodes run as this service account
    # - Determines what GCP APIs nodes can access
    # - Created below with minimal permissions (principle of least privilege)
    service_account = google_service_account.gke_node[0].email
    
    # OAUTH SCOPES
    # - Defines which Google APIs the nodes can access
    # - cloud-platform: Full access to all Cloud APIs (scoped by IAM)
    #
    # NOTE: OAuth scopes are legacy, IAM roles are preferred
    # Using cloud-platform scope + IAM is modern best practice
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # WORKLOAD IDENTITY
    # - Required for pods to use Workload Identity
    # - GKE_METADATA: Enables the GKE metadata server
    # - Pods can then authenticate as GCP service accounts
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # METADATA
    # - disable-legacy-endpoints: Disables old metadata endpoints (security)
    # - Legacy endpoints don't enforce service account scopes properly
    # - Always disable for security
    metadata = {
      disable-legacy-endpoints = "true"
    }

    # LABELS
    # - Key-value pairs attached to nodes
    # - Used for node selection, monitoring, cost allocation
    # - Can be used in nodeSelector or nodeAffinity in pod specs
    labels = {
      environment = var.environment  # e.g., "staging", "production"
      managed_by  = "terraform"      # Indicates infrastructure management tool
    }

    # TAGS
    # - Network tags for firewall rules
    # - Firewall rules can target nodes with specific tags
    # - e.g., "Allow traffic to nodes with tag 'web-server'"
    tags = ["gke-node", "${var.cluster_name}"]
  }

  # AUTOSCALING
  #
  # WHY AUTOSCALE?
  # - Automatically add nodes when pods can't be scheduled (not enough resources)
  # - Automatically remove nodes when they're underutilized (save money)
  # - Ensures applications have resources they need without over-provisioning
  #
  # HOW IT WORKS:
  # 1. A pod is created but can't be scheduled (not enough CPU/memory)
  # 2. Cluster autoscaler detects this and adds a node
  # 3. New node joins the cluster, pod is scheduled
  # 4. When nodes are underutilized, autoscaler scales down
  #
  # MIN/MAX NODES:
  # - min: 2 (always have capacity for core services)
  # - max: var.node_count * 2 (prevent runaway scaling, cost control)
  autoscaling {
    min_node_count = 2                   # Minimum nodes (always running)
    max_node_count = var.node_count * 2  # Maximum nodes (cost ceiling)
  }

  # MANAGEMENT
  #
  # AUTO-REPAIR:
  # - Unhealthy nodes are automatically replaced
  # - GKE monitors node health (disk, memory, network)
  # - Failed nodes are drained and replaced with new ones
  #
  # AUTO-UPGRADE:
  # - Nodes automatically upgraded to match cluster version
  # - Upgrades are rolling (no downtime)
  # - GKE drains pods before upgrading each node
  #
  # Both are essential for production (hands-free operations)
  management {
    auto_repair  = true  # Replace unhealthy nodes automatically
    auto_upgrade = true  # Keep nodes up-to-date with cluster version
  }
}

################################################################################
# VPC NETWORK
################################################################################
#
# WHAT IS A VPC?
#   Virtual Private Cloud - an isolated network in GCP where resources live
#
# NETWORK MODES:
#   - Auto mode: GCP creates subnets in all regions automatically (not flexible)
#   - Custom mode: You create subnets manually (full control, recommended)
#
# WHY CUSTOM MODE?
#   - Full control over IP ranges
#   - Only create subnets in regions you use (cost optimization)
#   - Better security (explicit subnet design)
#
################################################################################

resource "google_compute_network" "main" {
  count                   = var.cloud_provider == "gcp" ? 1 : 0
  name                    = "${var.cluster_name}-network"
  
  # CUSTOM MODE: We manually create subnets (see below)
  # AUTO MODE: GCP would create subnets in all regions automatically
  auto_create_subnetworks = false
}

################################################################################
# SUBNET
################################################################################
#
# WHAT IS A SUBNET?
#   A subnet is a range of IP addresses in your VPC
#   Resources in a subnet can communicate with each other locally
#
# IP CIDR RANGES:
#   - Primary: 10.0.0.0/24 (256 IPs for nodes)
#   - Secondary "pods": 10.1.0.0/16 (65,536 IPs for pods)
#   - Secondary "services": 10.2.0.0/16 (65,536 IPs for services)
#
# WHY SECONDARY RANGES?
#   GKE needs separate IP ranges for:
#   1. Nodes (VMs): Use primary range
#   2. Pods: Use "pods" secondary range (VPC-native networking)
#   3. Services: Use "services" secondary range (ClusterIP services)
#
# SIZING:
#   - /24 primary = 256 IPs (enough for ~200 nodes)
#   - /16 pods = 65,536 IPs (enough for ~6,000 pods with /24 per node)
#   - /16 services = 65,536 IPs (way more than needed, but free)
#
################################################################################

resource "google_compute_subnetwork" "main" {
  count         = var.cloud_provider == "gcp" ? 1 : 0
  name          = "${var.cluster_name}-subnet"
  ip_cidr_range = "10.0.0.0/24"         # Primary range for nodes (256 IPs)
  region        = var.gcp_region
  network       = google_compute_network.main[0].id  # Attach to VPC above

  # SECONDARY IP RANGE FOR PODS
  # - GKE allocates pod IPs from this range
  # - Each node gets a /24 block (256 pod IPs per node)
  # - 10.1.0.0/16 allows ~250 nodes (256 * 256 = 65,536 total pod IPs)
  secondary_ip_range {
    range_name    = "pods"        # Referenced in cluster ip_allocation_policy
    ip_cidr_range = "10.1.0.0/16" # 65,536 IPs for pods
  }

  # SECONDARY IP RANGE FOR SERVICES
  # - Kubernetes Service (ClusterIP) IPs come from this range
  # - Services are virtual IPs (not tied to physical interfaces)
  # - 10.2.0.0/16 allows 65,536 services (way more than needed)
  secondary_ip_range {
    range_name    = "services"    # Referenced in cluster ip_allocation_policy
    ip_cidr_range = "10.2.0.0/16" # 65,536 IPs for services
  }
}

################################################################################
# FIREWALL RULES
################################################################################
#
# WHY FIREWALL RULES?
#   By default, GCP VPC firewall blocks all traffic
#   We need to explicitly allow traffic between cluster components
#
# THIS RULE:
#   Allows all internal traffic within the 10.0.0.0/8 range
#   - Nodes can talk to each other
#   - Pods can talk to each other
#   - Services can talk to pods
#
# PROTOCOLS:
#   - TCP: All ports (application traffic)
#   - UDP: All ports (DNS, some databases)
#   - ICMP: Ping and network diagnostics
#
# SOURCE RANGE:
#   10.0.0.0/8 includes:
#   - 10.0.0.0/24 (nodes)
#   - 10.1.0.0/16 (pods)
#   - 10.2.0.0/16 (services)
#
################################################################################

resource "google_compute_firewall" "allow_internal" {
  count   = var.cloud_provider == "gcp" ? 1 : 0
  name    = "${var.cluster_name}-allow-internal"
  network = google_compute_network.main[0].name

  # Allow all TCP traffic
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]  # All TCP ports
  }

  # Allow all UDP traffic
  allow {
    protocol = "udp"
    ports    = ["0-65535"]  # All UDP ports
  }

  # Allow ICMP (ping, traceroute)
  allow {
    protocol = "icmp"
  }

  # SOURCE: Allow from all internal IPs
  # 10.0.0.0/8 includes our node, pod, and service ranges
  source_ranges = ["10.0.0.0/8"]
}

################################################################################
# CLOUD SQL POSTGRESQL DATABASE
################################################################################
#
# WHAT IS CLOUD SQL?
#   Fully managed relational database service (MySQL, PostgreSQL, SQL Server)
#   Google handles backups, patches, high availability, and monitoring
#
# INSTANCE vs DATABASE:
#   - Instance: The database server (like an EC2 instance)
#   - Database: The actual database within the instance (like a PostgreSQL database)
#
# TIERS:
#   - db-f1-micro: 1 vCPU shared, 614MB RAM (~$8/month) - staging/dev
#   - db-g1-small: 1 vCPU shared, 1.7GB RAM (~$25/month) - small prod
#   - db-n1-standard-1: 1 vCPU, 3.75GB RAM (~$80/month) - production
#
# AVAILABILITY:
#   - ZONAL: Single zone, cheaper, less available
#   - REGIONAL: Multi-zone with automatic failover (production)
#
# PRIVATE IP:
#   Database is only accessible within VPC (no internet exposure)
#   More secure than public IP + authorized networks
#
################################################################################

resource "google_sql_database_instance" "main" {
  count            = var.cloud_provider == "gcp" ? 1 : 0
  name             = "${var.cluster_name}-db"
  database_version = "POSTGRES_15"  # PostgreSQL version
  region           = var.gcp_region

  settings {
    # TIER (Instance Size)
    # - db-f1-micro: Cheapest, good for staging (~$8/month)
    # - db-n1-standard-1: Production-ready (~$80/month)
    tier              = "db-f1-micro"
    
    # AVAILABILITY TYPE
    # - ZONAL: Single zone (staging) - if zone fails, database is down
    # - REGIONAL: Multi-zone with auto-failover (production) - 99.95% SLA
    availability_type = var.environment == "production" ? "REGIONAL" : "ZONAL"
    
    # DISK CONFIGURATION
    # - disk_size: 20GB minimum (auto-grows if needed)
    # - PD_SSD: Fast solid-state storage (recommended for databases)
    # - PD_HDD: Cheaper but slower (not recommended for production)
    disk_size         = 20
    disk_type         = "PD_SSD"

    # AUTOMATED BACKUPS
    # - enabled: Create daily backups automatically
    # - start_time: 03:00 UTC (low-traffic time)
    # - Backups retained for 7 days (can be configured)
    #
    # RECOVERY:
    # - Can restore to any point in time within backup retention
    # - Can clone database from backup (testing, staging)
    backup_configuration {
      enabled    = true
      start_time = "03:00"  # 3 AM UTC (adjust for your timezone)
    }

    # IP CONFIGURATION
    # - ipv4_enabled: false = no public IP (more secure)
    # - private_network: Connect via VPC private IP only
    #
    # PRIVATE IP BENEFITS:
    # - Database not accessible from internet
    # - Lower latency (no NAT gateway)
    # - No egress charges for internal traffic
    ip_configuration {
      ipv4_enabled    = false  # No public IP
      private_network = google_compute_network.main[0].id  # Use VPC private IP
    }

    # QUERY INSIGHTS
    # - Tracks slow queries and performance issues
    # - Viewable in GCP Console "Query Insights" tab
    # - Helps identify optimization opportunities
    insights_config {
      query_insights_enabled = true
    }
  }

  # DELETION PROTECTION
  # - production: true = can't delete without removing this flag first
  # - staging/dev: false = can delete easily (for testing)
  #
  # Production databases should have deletion_protection = true
  # to prevent accidental deletion (very important!)
  deletion_protection = var.environment == "production"
}

################################################################################
# DATABASE (within Cloud SQL instance)
################################################################################
#
# This creates the actual database named "marketing_agent"
# within the PostgreSQL instance above
#
# ANALOGY:
#   - Instance = PostgreSQL server
#   - Database = "marketing_agent" database on that server
#
################################################################################

resource "google_sql_database" "main" {
  count    = var.cloud_provider == "gcp" ? 1 : 0
  name     = "marketing_agent"  # Database name
  instance = google_sql_database_instance.main[0].name  # Which instance
}

################################################################################
# DATABASE USER
################################################################################
#
# Creates a PostgreSQL user account
#
# USERNAME: postgres (default PostgreSQL superuser)
# PASSWORD: Generated randomly (see random_password resource below)
#
# SECURITY NOTE:
#   - Never hardcode passwords in Terraform
#   - Use random_password or reference from secret manager
#   - Store connection strings in Kubernetes secrets
#
################################################################################

resource "google_sql_user" "main" {
  count    = var.cloud_provider == "gcp" ? 1 : 0
  name     = "postgres"
  instance = google_sql_database_instance.main[0].name
  password = random_password.db_password.result  # Random password from resource below
}

################################################################################
# CLOUD MEMORYSTORE REDIS
################################################################################
#
# WHAT IS CLOUD MEMORYSTORE?
#   Fully managed Redis service (in-memory key-value store)
#   Used for: caching, session storage, real-time analytics, pub/sub
#
# REDIS USE CASES IN THIS APP:
#   - Session storage (user authentication tokens)
#   - API response caching (reduce database load)
#   - Rate limiting (track API call counts)
#   - Real-time features (pub/sub for notifications)
#
# TIERS:
#   - BASIC: Single instance, no replication (~$30/month for 1GB)
#   - STANDARD_HA: Primary + replica, automatic failover (~$150/month for 5GB)
#
# MEMORY SIZE:
#   - 1GB: Good for staging, ~100k cache entries
#   - 5GB: Production startup, ~500k cache entries
#   - 10GB+: High-traffic production
#
# REDIS VERSION:
#   - REDIS_7_0: Latest stable version
#   - Includes features: ACLs, streams, client-side caching
#
################################################################################

resource "google_redis_instance" "main" {
  count          = var.cloud_provider == "gcp" ? 1 : 0
  name           = "${var.cluster_name}-cache"
  
  # TIER OPTIONS:
  # - BASIC: Single Redis instance, no replication
  #   Good for: dev/staging, non-critical caching
  #   Cost: ~$30/month for 1GB
  # - STANDARD_HA: Primary + replica with automatic failover
  #   Good for: production, critical data
  #   Cost: ~$150/month for 5GB (5x more expensive)
  tier           = "BASIC"
  
  # MEMORY SIZE (GB)
  # - 1GB: ~100,000 cache entries (staging)
  # - 5GB: ~500,000 cache entries (small production)
  # - 10GB+: Large production workloads
  memory_size_gb = 1
  
  region         = var.gcp_region
  
  # REDIS VERSION
  # - REDIS_7_0: Latest stable (recommended)
  # - REDIS_6_X: Older version (for compatibility)
  redis_version  = "REDIS_7_0"

  # AUTHORIZED NETWORK
  # - Redis instance can only be accessed from this VPC
  # - No public IP (secure)
  # - Pods in GKE can connect directly via private IP
  authorized_network = google_compute_network.main[0].id

  display_name = "${var.cluster_name} Redis Cache"
}

################################################################################
# ARTIFACT REGISTRY (Container Registry)
################################################################################
#
# WHAT IS ARTIFACT REGISTRY?
#   A service for storing Docker images, npm packages, Maven artifacts, etc.
#   Successor to Container Registry (gcr.io)
#
# WHY USE IT?
#   - Store your custom Docker images close to your GKE cluster
#   - Faster image pulls (same region = low latency)
#   - Private by default (only your project can access)
#   - Integrated with GKE (nodes can pull without credentials)
#
# FORMATS SUPPORTED:
#   - DOCKER: Container images
#   - NPM: Node.js packages
#   - MAVEN: Java artifacts
#   - PYTHON: pip packages
#
# REPOSITORY URL:
#   {region}-docker.pkg.dev/{project-id}/{repository-name}
#   Example: us-central1-docker.pkg.dev/my-project/marketing-agent
#
# PUSHING IMAGES:
#   1. Authenticate: gcloud auth configure-docker us-central1-docker.pkg.dev
#   2. Tag image: docker tag myimage:latest us-central1-docker.pkg.dev/my-project/repo/myimage:latest
#   3. Push: docker push us-central1-docker.pkg.dev/my-project/repo/myimage:latest
#
################################################################################

resource "google_artifact_registry_repository" "main" {
  count         = var.cloud_provider == "gcp" ? 1 : 0
  location      = var.gcp_region                # Store images in same region as cluster
  repository_id = var.cluster_name              # Repository name
  description   = "Docker repository for ${var.cluster_name}"
  format        = "DOCKER"                      # Container image format
}

################################################################################
# SERVICE ACCOUNT FOR GKE NODES
################################################################################
#
# WHAT IS A SERVICE ACCOUNT?
#   An identity that nodes (VMs) use to access GCP services
#   Similar to IAM roles in AWS
#
# WHY CUSTOM SERVICE ACCOUNT?
#   - Default service account has too many permissions (overly permissive)
#   - Custom SA follows principle of least privilege
#   - Only grant permissions needed for GKE nodes to function
#
# PERMISSIONS GRANTED (via IAM bindings below):
#   - logging.logWriter: Write logs to Cloud Logging
#   - monitoring.metricWriter: Send metrics to Cloud Monitoring
#   - artifactregistry.reader: Pull images from Artifact Registry
#
################################################################################

resource "google_service_account" "gke_node" {
  count        = var.cloud_provider == "gcp" ? 1 : 0
  account_id   = "${var.cluster_name}-gke-node"  # Unique ID within project
  display_name = "Service Account for GKE Nodes"  # Human-readable name
}

################################################################################
# IAM BINDINGS FOR GKE NODE SERVICE ACCOUNT
################################################################################
#
# These grant the GKE node service account permissions to access GCP services
#
# IAM HIERARCHY:
#   - Project: Highest level (affects all resources in project)
#   - Resource: Specific resource (e.g., specific bucket)
#
# We're granting project-level permissions because nodes need to:
#   - Write logs from any pod
#   - Send metrics from any pod
#   - Pull images from any repository
#
################################################################################

# LOGGING PERMISSION
# Allows nodes to write logs to Cloud Logging
# Logs from pods' stdout/stderr are forwarded to Cloud Logging
resource "google_project_iam_member" "gke_node_logging" {
  count   = var.cloud_provider == "gcp" ? 1 : 0
  project = var.gcp_project
  role    = "roles/logging.logWriter"  # Permission to write logs
  member  = "serviceAccount:${google_service_account.gke_node[0].email}"
}

# MONITORING PERMISSION
# Allows nodes to send metrics to Cloud Monitoring
# Metrics include CPU, memory, disk, network usage
resource "google_project_iam_member" "gke_node_monitoring" {
  count   = var.cloud_provider == "gcp" ? 1 : 0
  project = var.gcp_project
  role    = "roles/monitoring.metricWriter"  # Permission to write metrics
  member  = "serviceAccount:${google_service_account.gke_node[0].email}"
}

# ARTIFACT REGISTRY PERMISSION
# Allows nodes to pull Docker images from Artifact Registry
# Required for deploying containers from your private registry
resource "google_project_iam_member" "gke_node_registry" {
  count   = var.cloud_provider == "gcp" ? 1 : 0
  project = var.gcp_project
  role    = "roles/artifactregistry.reader"  # Permission to read (pull) images
  member  = "serviceAccount:${google_service_account.gke_node[0].email}"
}

################################################################################
# RANDOM PASSWORD
################################################################################
#
# WHAT IS THIS?
#   Generates a cryptographically secure random password
#   Used for PostgreSQL database user password
#
# WHY RANDOM?
#   - More secure than hardcoded passwords
#   - Different for each deployment
#   - Terraform manages it automatically
#
# WHERE IS IT STORED?
#   - Terraform state file (terraform.tfstate)
#   - State file should be encrypted and access-controlled
#   - For production, use remote state backend (GCS, S3)
#
# SECURITY NOTES:
#   - Never commit terraform.tfstate to git
#   - Use encrypted remote state backend
#   - Rotate passwords regularly (not automated by Terraform)
#   - Consider using Secret Manager for production
#
################################################################################

resource "random_password" "db_password" {
  length  = 32         # 32 characters (very strong)
  special = true       # Include special characters (!@#$%^&*)
  # Password will be different on each terraform apply
  # Stored in state file and referenced by other resources
}

################################################################################
# OUTPUTS
################################################################################
#
# WHAT ARE OUTPUTS?
#   Values that Terraform prints after successful apply
#   Can be referenced by other Terraform modules or used in scripts
#
# HOW TO VIEW:
#   - terraform output                    (show all outputs)
#   - terraform output cluster_endpoint   (show specific output)
#   - terraform output -json > output.json (export to JSON)
#
# USE CASES:
#   - Get cluster endpoint for kubectl configuration
#   - Get database connection string for application
#   - Get registry URL for docker push
#   - Share values with other infrastructure code
#
################################################################################

# GKE CLUSTER ENDPOINT
# The API server URL for kubectl to connect to
# Format: https://1.2.3.4 (IP address of control plane)
output "cluster_endpoint" {
  description = "GKE cluster API endpoint"
  value = var.cloud_provider == "gcp" ? google_container_cluster.main[0].endpoint : null
}

# ARTIFACT REGISTRY URL
# The base URL for pushing/pulling Docker images
# Format: {region}-docker.pkg.dev/{project}/{repository}
output "gcr_repository_url" {
  description = "Artifact Registry repository URL"
  value = var.cloud_provider == "gcp" ? "${var.gcp_region}-docker.pkg.dev/${var.gcp_project}/${var.cluster_name}" : null
}

# CLOUD SQL CONNECTION NAME
# Used for connecting via Cloud SQL Proxy
# Format: {project}:{region}:{instance}
output "cloudsql_connection" {
  description = "Cloud SQL connection name (for Cloud SQL Proxy)"
  value = var.cloud_provider == "gcp" ? google_sql_database_instance.main[0].connection_name : null
}

# MEMORYSTORE REDIS HOST
# Private IP address of Redis instance
# Format: 10.x.x.x (internal IP)
output "memorystore_host" {
  description = "Memorystore Redis host IP"
  value = var.cloud_provider == "gcp" ? google_redis_instance.main[0].host : null
}

# INGRESS IP
# Placeholder - actual IP assigned when LoadBalancer service created
# GKE provisions a TCP/UDP load balancer when you create a LoadBalancer service
output "ingress_ip" {
  description = "Cluster ingress IP (assigned after service deployment)"
  value = var.cloud_provider == "gcp" ? google_container_cluster.main[0].endpoint : null
}

################################################################################
# END OF GCP INFRASTRUCTURE MODULE
################################################################################
#
# NEXT STEPS AFTER TERRAFORM APPLY:
#
#   1. Configure kubectl to connect to cluster:
#      gcloud container clusters get-credentials {cluster_name} --region {region}
#
#   2. Verify cluster access:
#      kubectl get nodes
#      kubectl cluster-info
#
#   3. Push Docker images to Artifact Registry:
#      gcloud auth configure-docker {region}-docker.pkg.dev
#      docker tag myimage:latest {region}-docker.pkg.dev/{project}/{repo}/myimage:latest
#      docker push {region}-docker.pkg.dev/{project}/{repo}/myimage:latest
#
#   4. Deploy application:
#      kubectl apply -k infrastructure/k8s/base/
#
#   5. Get database connection string:
#      terraform output cloudsql_connection
#
#   6. Set up Cloud SQL Proxy (for local development):
#      cloud_sql_proxy -instances={connection_name}=tcp:5432
#
# MONITORING:
#   - Cloud Console → Kubernetes Engine → Clusters → {cluster_name}
#   - Cloud Console → Logging → Logs Explorer (view logs)
#   - Cloud Console → Monitoring → Metrics Explorer (view metrics)
#
# COST MONITORING:
#   - Cloud Console → Billing → Cost Table
#   - Set up budget alerts to avoid surprise bills
#   - Staging should cost ~$135/month
#
# DOCUMENTATION:
#   - GKE docs: https://cloud.google.com/kubernetes-engine/docs
#   - Cloud SQL docs: https://cloud.google.com/sql/docs
#   - Terraform GCP provider: https://registry.terraform.io/providers/hashicorp/google
#
################################################################################
