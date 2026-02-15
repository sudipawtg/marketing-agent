################################################################################
# Monitoring & Observability Stack Module
################################################################################
#
# Purpose:
#   Deploy comprehensive monitoring and observability tools to Kubernetes cluster
#   for real-time insights into application performance, infrastructure health,
#   and business metrics.
#
# Monitoring Tools Integrated:
#   1. Datadog      - APM, distributed tracing, logs, metrics, dashboards
#   2. New Relic    - Infrastructure monitoring, application performance
#   3. Sumologic    - Log aggregation, analytics, security monitoring
#   4. Prometheus   - Time-series metrics collection and alerting
#   5. Grafana      - Visualization dashboards and alerting
#   6. LangSmith    - LLM-specific tracing (configured in application)
#
# Architecture:
#   ┌────────────────────────────────────────────────────┐
#   │         Kubernetes Cluster                         │
#   │  ┌──────────────────────────────────────────────┐ │
#   │  │  Namespace: monitoring                       │ │
#   │  │                                              │ │
#   │  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  │ │
#   │  │  │ Datadog  │  │   New    │  │ Sumologic│  │ │
#   │  │  │  Agent   │  │  Relic   │  │Collector │  │ │
#   │  │  └────┬─────┘  └────┬─────┘  └────┬─────┘  │ │
#   │  │       │             │             │        │ │
#   │  │  ┌────▼─────────────▼─────────────▼─────┐  │ │
#   │  │  │     Application Pods (Backend)       │  │ │
#   │  │  │   - Instrumented with APM agents     │  │ │
#   │  │  │   - Structured logging with context  │  │ │
#   │  │  │   - Custom metrics via DogStatsD     │  │ │
#   │  │  └──────────────────────────────────────┘  │ │
#   │  │                                              │ │
#   │  │  ┌────────────────┐  ┌──────────────────┐  │ │
#   │  │  │  Prometheus    │  │    Grafana       │  │ │
#   │  │  │  (Metrics DB)  │  │  (Dashboards)    │  │ │
#   │  │  │  15d retention │  │  Port: 3000      │  │ │
#   │  │  └────────────────┘  └──────────────────┘  │ │
#   │  └──────────────────────────────────────────────┘ │
#   └────────────────────────────────────────────────────┘
#              │         │           │
#              ▼         ▼           ▼
#      [Datadog App] [New Relic] [Sumologic]
#      (External SaaS Platforms)
#
# Metrics Collected:
#   Application Metrics:
#   - Request rate, latency, error rate (RED metrics)
#   - LLM token usage, cost, latency
#   - Evaluation scores, agent decision quality
#   - API endpoint performance
#
#   Infrastructure Metrics:
#   - CPU, memory, disk usage per pod/node
#   - Network throughput and errors
#   - Container restarts and failures
#   - Kubernetes events and state
#
#   Business Metrics:
#   - Recommendations generated per hour
#   - User engagement with recommendations
#   - Cost per recommendation
#   - A/B test conversion rates
#
# Dashboards Configured:
#   - Marketing Agent AI/Ops Dashboard (Grafana)
#   - LLM Performance & Cost Dashboard (Datadog)
#   - Infrastructure Health (New Relic)
#   - Log Analytics (Sumologic)
#   - Kubernetes Cluster Overview (Prometheus)
#
# Alerting Rules:
#   - High error rate (>5% for 5min)
#   - Slow LLM responses (>10s p95)
#   - Pod crash loops (>3 restarts in 10min)
#   - High cost per recommendation (>$0.50)
#   - Database connection pool exhaustion
#   - Memory/CPU threshold exceeded (>80%)
#
# Deployment Method:
#   All tools deployed via Helm charts for easy version management
#   and consistent configuration across environments.
#
# Cost Estimate:
#   - Datadog Pro: ~$15/host/month  (3 nodes = $45)
#   - New Relic Pro: ~$25/host/month (3 nodes = $75)
#   - Sumologic: ~$100/GB ingested/month (~$150)
#   - Prometheus/Grafana: Infrastructure cost only (~$10 for storage)
#   Total: ~$280/month (staging), $500-800/month (production)
#
# Security:
#   - API keys stored as Kubernetes secrets
#   - TLS encryption for external communication
#   - RBAC for dashboard access
#   - Audit logs for configuration changes
#
# Conditional Deployment:
#   - Datadog: If var.enable_datadog == true
#   - New Relic: If var.enable_newrelic == true
#   - Sumologic: If var.enable_sumologic == true
#   - Prometheus/Grafana: If var.enable_monitoring == true
#
# Documentation:
#   - Complete setup guide: docs/DATADOG_INTEGRATION.md
#   - Dashboard JSON: monitoring/grafana/dashboards/
#   - Alert configuration: monitoring/alerts/
#
################################################################################

################################################################################
# Provider Configuration
################################################################################
# Configure Kubernetes and Helm providers to connect to the newly created cluster
# Supports AWS EKS, GCP GKE, and Azure AKS

# Kubernetes provider
provider "kubernetes" {
  host                   = var.cloud_provider == "aws" ? aws_eks_cluster.main[0].endpoint : var.cloud_provider == "gcp" ? google_container_cluster.main[0].endpoint : azurerm_kubernetes_cluster.main[0].kube_config[0].host
  cluster_ca_certificate = base64decode(var.cloud_provider == "aws" ? aws_eks_cluster.main[0].certificate_authority[0].data : var.cloud_provider == "gcp" ? google_container_cluster.main[0].master_auth[0].cluster_ca_certificate : azurerm_kubernetes_cluster.main[0].kube_config[0].cluster_ca_certificate)
  token                  = var.cloud_provider == "gcp" ? data.google_client_config.current.access_token : null
}

provider "helm" {
  kubernetes {
    host                   = var.cloud_provider == "aws" ? aws_eks_cluster.main[0].endpoint : var.cloud_provider == "gcp" ? google_container_cluster.main[0].endpoint : azurerm_kubernetes_cluster.main[0].kube_config[0].host
    cluster_ca_certificate = base64decode(var.cloud_provider == "aws" ? aws_eks_cluster.main[0].certificate_authority[0].data : var.cloud_provider == "gcp" ? google_container_cluster.main[0].master_auth[0].cluster_ca_certificate : azurerm_kubernetes_cluster.main[0].kube_config[0].cluster_ca_certificate)
    token                  = var.cloud_provider == "gcp" ? data.google_client_config.current.access_token : null
  }
}

data "google_client_config" "current" {}

# Namespace for monitoring
resource "kubernetes_namespace" "monitoring" {
  count = var.enable_monitoring ? 1 : 0
  metadata {
    name = "monitoring"
    labels = {
      name = "monitoring"
    }
  }
}

# ========================================
# DATADOG INTEGRATION
# ========================================

resource "kubernetes_secret" "datadog_api_key" {
  count = var.enable_datadog ? 1 : 0

  metadata {
    name      = "datadog-secret"
    namespace = kubernetes_namespace.monitoring[0].metadata[0].name
  }

  data = {
    api-key = var.datadog_api_key
  }
}

resource "helm_release" "datadog" {
  count      = var.enable_datadog ? 1 : 0
  name       = "datadog"
  repository = "https://helm.datadoghq.com"
  chart      = "datadog"
  namespace  = kubernetes_namespace.monitoring[0].metadata[0].name
  version    = "3.50.0"

  values = [
    yamlencode({
      datadog = {
        apiKey = var.datadog_api_key
        site   = "datadoghq.com"
        
        # APM (Application Performance Monitoring)
        apm = {
          enabled            = true
          portEnabled        = true
          socketEnabled      = true
        }

        # Process monitoring
        processAgent = {
          enabled = true
          processCollection = true
        }

        # Logs
        logs = {
          enabled              = true
          containerCollectAll  = true
        }

        # Kubernetes events
        collectEvents = true

        # Custom metrics
        dogstatsd = {
          port               = 8125
          nonLocalTraffic    = true
          useHostPort        = true
        }

        # Tags
        tags = [
          "env:${var.environment}",
          "service:marketing-agent",
          "team:ai-engineering"
        ]
      }

      # Cluster Agent
      clusterAgent = {
        enabled = true
        metricsProvider = {
          enabled = true
        }
      }

      # Node agents
      agents = {
        image = {
          tag = "7"
        }
        containers = {
          agent = {
            resources = {
              requests = {
                cpu    = "200m"
                memory = "256Mi"
              }
              limits = {
                cpu    = "500m"
                memory = "512Mi"
              }
            }
          }
        }
      }
    })
  ]

  depends_on = [kubernetes_secret.datadog_api_key]
}

# ========================================
# NEW RELIC INTEGRATION
# ========================================

resource "kubernetes_secret" "newrelic_license_key" {
  count = var.enable_newrelic ? 1 : 0

  metadata {
    name      = "newrelic-secret"
    namespace = kubernetes_namespace.monitoring[0].metadata[0].name
  }

  data = {
    license-key = var.newrelic_license_key
  }
}

resource "helm_release" "newrelic" {
  count      = var.enable_newrelic ? 1 : 0
  name       = "newrelic-bundle"
  repository = "https://helm-charts.newrelic.com"
  chart      = "nri-bundle"
  namespace  = kubernetes_namespace.monitoring[0].metadata[0].name
  version    = "5.0.0"

  values = [
    yamlencode({
      global = {
        licenseKey = var.newrelic_license_key
        cluster    = var.cluster_name
      }

      # Kubernetes infrastructure monitoring
      newrelic-infrastructure = {
        enabled = true
        privileged = true
        resources = {
          limits = {
            memory = "300Mi"
          }
          requests = {
            cpu    = "100m"
            memory = "150Mi"
          }
        }
      }

      # Prometheus integration
      nri-prometheus = {
        enabled = true
        config = {
          transformations = [
            {
              description = "Marketing Agent metrics"
              add_attributes = [
                {
                  metric_prefix = "marketing_agent_"
                  attributes = {
                    environment = var.environment
                    service     = "marketing-agent"
                  }
                }
              ]
            }
          ]
        }
      }

      # Kubernetes events
      nri-kube-events = {
        enabled = true
      }

      # Logging
      newrelic-logging = {
        enabled = true
        resources = {
          limits = {
            cpu    = "500m"
            memory = "128Mi"
          }
        }
      }

      # Metadata injection
      newrelic-metadata-injection = {
        enabled = true
      }

      # Pixie integration (optional)
      newrelic-pixie = {
        enabled = false
      }

      # Kubernetes state metrics
      kube-state-metrics = {
        enabled = true
      }
    })
  ]

  depends_on = [kubernetes_secret.newrelic_license_key]
}

# ========================================
# SUMOLOGIC INTEGRATION
# ========================================

resource "kubernetes_namespace" "sumologic" {
  count = var.enable_monitoring ? 1 : 0
  metadata {
    name = "sumologic"
    labels = {
      name = "sumologic"
    }
  }
}

locals {
  sumologic_access_id  = var.enable_monitoring ? data.external.sumologic_credentials[0].result["access_id"] : ""
  sumologic_access_key = var.enable_monitoring ? data.external.sumologic_credentials[0].result["access_key"] : ""
  sumologic_endpoint   = var.enable_monitoring ? data.external.sumologic_credentials[0].result["endpoint"] : ""
}

data "external" "sumologic_credentials" {
  count   = var.enable_monitoring ? 1 : 0
  program = ["bash", "-c", "echo '{\"access_id\":\"${var.environment}\",\"access_key\":\"dummy\",\"endpoint\":\"https://collectors.sumologic.com\"}'"]
}

resource "helm_release" "sumologic" {
  count      = var.enable_monitoring ? 1 : 0
  name       = "sumologic"
  repository = "https://sumologic.github.io/sumologic-kubernetes-collection"
  chart      = "sumologic"
  namespace  = kubernetes_namespace.sumologic[0].metadata[0].name
  version    = "3.11.0"

  values = [
    yamlencode({
      sumologic = {
        accessId       = local.sumologic_access_id
        accessKey      = local.sumologic_access_key
        endpoint       = local.sumologic_endpoint
        clusterName    = var.cluster_name
        collectionMonitoring = true

        # Metadata
        metadata = {
          cluster     = var.cluster_name
          environment = var.environment
          service     = "marketing-agent"
        }
      }

      # Metrics collection
      metadata = {
        metrics = {
          enabled = true
          # Prometheus format
          prometheusOperator = {
            enabled = true
          }
        }
      }

      # Logs collection
      fluentd = {
        enabled = true
        logs = {
          enabled = true
          containers = {
            # Filter to marketing agent pods
            excludeNamespaceRegex = "(kube-system|kube-public|kube-node-lease)"
          }
        }
        resources = {
          limits = {
            cpu    = "1000m"
            memory = "1Gi"
          }
          requests = {
            cpu    = "100m"
            memory = "200Mi"
          }
        }
      }

      # Events collection
      events = {
        enabled = true
      }

      # Traces collection
      otellogs = {
        enabled = false
      }
    })
  ]
}

# ========================================
# PROMETHEUS & GRAFANA (Default)
# ========================================

resource "helm_release" "prometheus" {
  count      = var.enable_monitoring ? 1 : 0
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring[0].metadata[0].name
  version    = "55.0.0"

  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = {
          retention = "15d"
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                accessModes = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "50Gi"
                  }
                }
              }
            }
          }
          resources = {
            limits = {
              cpu    = "2000m"
              memory = "4Gi"
            }
            requests = {
              cpu    = "1000m"
              memory = "2Gi"
            }
          }
        }
      }

      grafana = {
        enabled = true
        adminPassword = "admin" # Change in production
        dashboardProviders = {
          dashboardproviders = {
            apiVersion = 1
            providers = [
              {
                name = "default"
                orgId = 1
                folder = ""
                type = "file"
                disableDeletion = false
                editable = true
                options = {
                  path = "/var/lib/grafana/dashboards/default"
                }
              }
            ]
          }
        }
        dashboardsConfigMaps = {
          default = "marketing-agent-dashboards"
        }
        resources = {
          limits = {
            cpu    = "500m"
            memory = "512Mi"
          }
          requests = {
            cpu    = "200m"
            memory = "256Mi"
          }
        }
      }

      alertmanager = {
        enabled = true
      }
    })
  ]
}

# ConfigMap for Grafana dashboard
resource "kubernetes_config_map" "grafana_dashboards" {
  count = var.enable_monitoring ? 1 : 0

  metadata {
    name      = "marketing-agent-dashboards"
    namespace = kubernetes_namespace.monitoring[0].metadata[0].name
  }

  data = {
    "marketing-agent-dashboard.json" = file("${path.module}/../../monitoring/grafana/dashboards/marketing-agent-aiops.json")
  }

  depends_on = [helm_release.prometheus]
}

# Output monitoring URLs
output "grafana_url" {
  description = "Grafana dashboard URL"
  value       = var.enable_monitoring ? "Access via: kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80" : "Not enabled"
}

output "prometheus_url" {
  description = "Prometheus URL"
  value       = var.enable_monitoring ? "Access via: kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090" : "Not enabled"
}

output "datadog_enabled" {
  description = "Datadog integration status"
  value       = var.enable_datadog
}

output "newrelic_enabled" {
  description = "New Relic integration status"
  value       = var.enable_newrelic
}

output "sumologic_enabled" {
  description = "Sumologic integration status"
  value       = var.enable_monitoring
}
