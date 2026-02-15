# GCP Infrastructure Module

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# GKE Cluster
resource "google_container_cluster" "main" {
  count              = var.cloud_provider == "gcp" ? 1 : 0
  name               = var.cluster_name
  location           = var.gcp_region
  initial_node_count = 1

  # Remove default node pool immediately
  remove_default_node_pool = true

  # Network configuration
  network    = google_compute_network.main[0].name
  subnetwork = google_compute_subnetwork.main[0].name

  # IP allocation policy for VPC-native cluster
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Enable Workload Identity
  workload_identity_config {
    workload_pool = "${var.gcp_project}.svc.id.goog"
  }

  # Logging and monitoring
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  # Enable addons
  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  # Master auth
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  # Binary authorization
  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }
}

# GKE Node Pool
resource "google_container_node_pool" "main" {
  count      = var.cloud_provider == "gcp" ? 1 : 0
  name       = "${var.cluster_name}-node-pool"
  location   = var.gcp_region
  cluster    = google_container_cluster.main[0].name
  node_count = var.node_count

  node_config {
    machine_type = "e2-medium"
    disk_size_gb = 50
    disk_type    = "pd-standard"

    # Service account with minimal permissions
    service_account = google_service_account.gke_node[0].email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    metadata = {
      disable-legacy-endpoints = "true"
    }

    labels = {
      environment = var.environment
      managed_by  = "terraform"
    }

    tags = ["gke-node", "${var.cluster_name}"]
  }

  autoscaling {
    min_node_count = 2
    max_node_count = var.node_count * 2
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# VPC Network
resource "google_compute_network" "main" {
  count                   = var.cloud_provider == "gcp" ? 1 : 0
  name                    = "${var.cluster_name}-network"
  auto_create_subnetworks = false
}

# Subnet
resource "google_compute_subnetwork" "main" {
  count         = var.cloud_provider == "gcp" ? 1 : 0
  name          = "${var.cluster_name}-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.gcp_region
  network       = google_compute_network.main[0].id

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.1.0.0/16"
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.2.0.0/16"
  }
}

# Firewall Rules
resource "google_compute_firewall" "allow_internal" {
  count   = var.cloud_provider == "gcp" ? 1 : 0
  name    = "${var.cluster_name}-allow-internal"
  network = google_compute_network.main[0].name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.0.0.0/8"]
}

# Cloud SQL PostgreSQL
resource "google_sql_database_instance" "main" {
  count            = var.cloud_provider == "gcp" ? 1 : 0
  name             = "${var.cluster_name}-db"
  database_version = "POSTGRES_15"
  region           = var.gcp_region

  settings {
    tier              = "db-f1-micro"
    availability_type = var.environment == "production" ? "REGIONAL" : "ZONAL"
    disk_size         = 20
    disk_type         = "PD_SSD"

    backup_configuration {
      enabled    = true
      start_time = "03:00"
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.main[0].id
    }

    insights_config {
      query_insights_enabled = true
    }
  }

  deletion_protection = var.environment == "production"
}

resource "google_sql_database" "main" {
  count    = var.cloud_provider == "gcp" ? 1 : 0
  name     = "marketing_agent"
  instance = google_sql_database_instance.main[0].name
}

resource "google_sql_user" "main" {
  count    = var.cloud_provider == "gcp" ? 1 : 0
  name     = "postgres"
  instance = google_sql_database_instance.main[0].name
  password = random_password.db_password.result
}

# Cloud Memorystore Redis
resource "google_redis_instance" "main" {
  count          = var.cloud_provider == "gcp" ? 1 : 0
  name           = "${var.cluster_name}-cache"
  tier           = "BASIC"
  memory_size_gb = 1
  region         = var.gcp_region
  redis_version  = "REDIS_7_0"

  authorized_network = google_compute_network.main[0].id

  display_name = "${var.cluster_name} Redis Cache"
}

# Artifact Registry (Container Registry)
resource "google_artifact_registry_repository" "main" {
  count         = var.cloud_provider == "gcp" ? 1 : 0
  location      = var.gcp_region
  repository_id = var.cluster_name
  description   = "Docker repository for ${var.cluster_name}"
  format        = "DOCKER"
}

# Service Account for GKE Nodes
resource "google_service_account" "gke_node" {
  count        = var.cloud_provider == "gcp" ? 1 : 0
  account_id   = "${var.cluster_name}-gke-node"
  display_name = "Service Account for GKE Nodes"
}

# IAM bindings for GKE service account
resource "google_project_iam_member" "gke_node_logging" {
  count   = var.cloud_provider == "gcp" ? 1 : 0
  project = var.gcp_project
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_node[0].email}"
}

resource "google_project_iam_member" "gke_node_monitoring" {
  count   = var.cloud_provider == "gcp" ? 1 : 0
  project = var.gcp_project
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_node[0].email}"
}

resource "google_project_iam_member" "gke_node_registry" {
  count   = var.cloud_provider == "gcp" ? 1 : 0
  project = var.gcp_project
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke_node[0].email}"
}

# Random password for database
resource "random_password" "db_password" {
  length  = 32
  special = true
}

# Outputs
output "cluster_endpoint" {
  value = var.cloud_provider == "gcp" ? google_container_cluster.main[0].endpoint : null
}

output "gcr_repository_url" {
  value = var.cloud_provider == "gcp" ? "${var.gcp_region}-docker.pkg.dev/${var.gcp_project}/${var.cluster_name}" : null
}

output "cloudsql_connection" {
  value = var.cloud_provider == "gcp" ? google_sql_database_instance.main[0].connection_name : null
}

output "memorystore_host" {
  value = var.cloud_provider == "gcp" ? google_redis_instance.main[0].host : null
}

output "ingress_ip" {
  value = var.cloud_provider == "gcp" ? google_container_cluster.main[0].endpoint : null
}
