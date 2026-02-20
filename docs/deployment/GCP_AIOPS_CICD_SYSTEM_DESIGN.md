# GCP AI/Ops CI/CD System Design - End-to-End Platform Engineering Solution

## Executive Summary

This document provides a comprehensive system design for implementing a highly scalable, automated AI/Ops Continuous Integration and Continuous Deployment (CI/CD) platform on Google Cloud Platform (GCP). The solution leverages GCP-native services, AI-driven operations through Google's machine learning capabilities, and industry best practices for reliability, security, and cost optimization.

**Target Audience:** Platform Engineers, DevOps Engineers, SREs, Cloud Architects  
**Last Updated:** February 2026  
**Current Implementation:** Based on marketing-agent project architecture

---

## 📊 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           GCP AI/Ops CI/CD Platform                                 │
│                                                                                     │
│  ┌──────────────────────────────────────────────────────────────────────────────┐  │
│  │  DEVELOPMENT LAYER                                                           │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │  │
│  │  │   GitHub     │  │ Cloud Source │  │  Cloud Shell│  │   Docker     │   │  │
│  │  │   Codespaces │  │  Repositories│  │  IDE        │  │   (local)    │   │  │
│  │  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘   │  │
│  └─────────┼──────────────────┼──────────────────┼──────────────────┼───────────┘  │
│            │                  │                  │                  │              │
│  ┌─────────▼──────────────────▼──────────────────▼──────────────────▼───────────┐  │
│  │  CI LAYER (GitHub Actions + Cloud Build)                                    │  │
│  │  ┌────────────────────────────────────────────────────────────────────────┐ │  │
│  │  │  Workflow Orchestration                                                 │ │  │
│  │  │  • Code Quality (SonarCloud + Google Code Review AI)                   │ │  │
│  │  │  • Security Scanning (Container Analysis + Binary Authorization)       │ │  │
│  │  │  • Testing (pytest/jest + Cloud Testing)                               │ │  │
│  │  │  • Build Artifacts (Cloud Build + Artifact Registry)                   │ │  │
│  │  └────────────────────────────────────────────────────────────────────────┘ │  │
│  └─────────┬──────────────────────────────────────────────────────────────────┘  │
│            │                                                                      │
│  ┌─────────▼──────────────────────────────────────────────────────────────────┐  │
│  │  ARTIFACT STORAGE & REGISTRY                                               │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │  │
│  │  │  Artifact    │  │ Cloud Storage│  │  Artifact    │  │ Secret       │  │  │
│  │  │  Registry    │  │  (Buckets)   │  │  Analysis    │  │ Manager      │  │  │
│  │  │  (Docker)    │  │  (Builds)    │  │  (CVE Scan)  │  │ (Secrets)    │  │  │
│  │  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │  │
│  └─────────┼──────────────────┼──────────────────┼──────────────────┼─────────┘  │
│            │                  │                  │                  │            │
│  ┌─────────▼──────────────────▼──────────────────▼──────────────────▼─────────┐  │
│  │  CD LAYER (Cloud Deploy + GKE)                                             │  │
│  │  ┌────────────────────────────────────────────────────────────────────────┐│  │
│  │  │  Deployment Orchestration (Google Cloud Deploy)                        ││  │
│  │  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                ││  │
│  │  │  │   Staging    │  │    Canary    │  │  Production  │                ││  │
│  │  │  │  Environment │  │  (Progressive │  │  (Blue/Green)│                ││  │
│  │  │  │  - Auto Deploy│→│   Delivery)  │→│  - Approval  │                ││  │
│  │  │  │  - Skaffold  │  │  - Metrics   │  │  - Full      │                ││  │
│  │  │  └──────────────┘  └──────────────┘  └──────────────┘                ││  │
│  │  └────────────────────────────────────────────────────────────────────────┘│  │
│  └─────────┬───────────────────────────────────────────────────────────────────┘  │
│            │                                                                      │
│  ┌─────────▼──────────────────────────────────────────────────────────────────┐  │
│  │  INFRASTRUCTURE LAYER (GKE + Cloud SQL + Memorystore + GCS)               │  │
│  │  ┌────────────────────────────────────────────────────────────────────────┐│  │
│  │  │  Google Kubernetes Engine (GKE Autopilot)                              ││  │
│  │  │  ┌──────────────────────────────────────────────────────────────────┐ ││  │
│  │  │  │  Auto-Managed Nodes (GKE manages infrastructure)                  │ ││  │
│  │  │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │ ││  │
│  │  │  │  │   Backend   │  │  Frontend   │  │   Workers   │              │ ││  │
│  │  │  │  │   Pods      │  │   Pods      │  │   (Celery)  │              │ ││  │
│  │  │  │  │  (FastAPI)  │  │  (React)    │  │             │              │ ││  │
│  │  │  │  └─────────────┘  └─────────────┘  └─────────────┘              │ ││  │
│  │  │  └──────────────────────────────────────────────────────────────────┘ ││  │
│  │  │  ┌──────────────────────────────────────────────────────────────────┐ ││  │
│  │  │  │  Data Layer                                                       │ ││  │
│  │  │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │ ││  │
│  │  │  │  │  Cloud SQL  │  │ Memorystore │  │    GCS      │              │ ││  │
│  │  │  │  │  PostgreSQL │  │   Redis     │  │  (Storage)  │              │ ││  │
│  │  │  │  │  (HA Config)│  │  (HA Redis) │  │             │              │ ││  │
│  │  │  │  └─────────────┘  └─────────────┘  └─────────────┘              │ ││  │
│  │  │  └──────────────────────────────────────────────────────────────────┘ ││  │
│  │  └────────────────────────────────────────────────────────────────────────┘│  │
│  └─────────┬───────────────────────────────────────────────────────────────────┘  │
│            │                                                                      │
│  ┌─────────▼──────────────────────────────────────────────────────────────────┐  │
│  │  AI/OPS OBSERVABILITY LAYER (Cloud Operations Suite)                      │  │
│  │  ┌────────────────────────────────────────────────────────────────────────┐│  │
│  │  │  Cloud Monitoring & Logging                                            ││  │
│  │  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                ││  │
│  │  │  │  Cloud       │  │  Cloud       │  │  Cloud       │                ││  │
│  │  │  │  Monitoring  │  │  Logging     │  │  Trace       │                ││  │
│  │  │  │  (Metrics)   │  │  (Logs)      │  │  (OpenTelem.)│                ││  │
│  │  │  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘                ││  │
│  │  │         └──────────────────┴──────────────────┘                       ││  │
│  │  │                            │                                           ││  │
│  │  │  ┌─────────────────────────▼─────────────────────────────┐            ││  │
│  │  │  │  Vertex AI + Cloud Functions (AI-Powered AIOps)       │            ││  │
│  │  │  │  • Predictive autoscaling (ML models)                 │            ││  │
│  │  │  │  • Anomaly detection (time-series forecasting)        │            ││  │
│  │  │  │  • Log analysis (natural language processing)         │            ││  │
│  │  │  │  • Automated remediation (Cloud Functions triggers)   │            ││  │
│  │  │  └────────────────────────────────────────────────────────┘            ││  │
│  │  │                                                                         ││  │
│  │  │  ┌────────────────────────────────────────────────────────┐            ││  │
│  │  │  │  SRE Best Practices (Google SRE Handbook)              │            ││  │
│  │  │  │  • Error budgets and SLO tracking                      │            ││  │
│  │  │  │  • Toil automation                                     │            ││  │
│  │  │  │  • Capacity planning (Vertex AI forecasting)           │            ││  │
│  │  │  │  • Incident response automation                        │            ││  │
│  │  │  └────────────────────────────────────────────────────────┘            ││  │
│  │  └────────────────────────────────────────────────────────────────────────┘│  │
│  └───────────────────────────────────────────────────────────────────────────┘  │
│                                                                                  │
│  ┌──────────────────────────────────────────────────────────────────────────┐  │
│  │  SECURITY & COMPLIANCE LAYER                                             │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐ │  │
│  │  │   IAM +      │  │   Secret     │  │   Cloud      │  │  Security   │ │  │
│  │  │   Workload   │  │   Manager    │  │   Armor      │  │  Command    │ │  │
│  │  │   Identity   │  │   (Secrets)  │  │   (WAF)      │  │  Center     │ │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  └─────────────┘ │  │
│  └──────────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 🏗️ Detailed Service Breakdown

### 1. **Source Control & Collaboration**

#### **Primary: GitHub + GitHub Actions**
- **Service:** GitHub Enterprise Cloud
- **Purpose:** Source code management, CI orchestration
- **Advantages:**
  - Same as AWS setup (consistency)
  - GCP Workload Identity Federation for GitHub Actions
  - Native Artifact Registry integration

#### **Alternative: Cloud Source Repositories**
- **Service:** Cloud Source Repositories
- **Purpose:** Git repository hosting
- **Advantages:**
  - Fully integrated with Cloud Build
  - Automatic mirroring from GitHub/Bitbucket
  - IAM-based access control
  - Private Git repositories
  - Free up to 50 GB storage
- **Disadvantages:**
  - Limited features vs GitHub (no Issues, PRs are basic)
  - Smaller ecosystem
  - No built-in CI/CD (requires Cloud Build)
- **Cost:** Free up to 50 GB, then $0.10/GB/month for storage

**Recommendation:** Use GitHub for feature-richness, mirror to Cloud Source Repositories for GCP integration.

---

### 2. **CI Pipeline - Build & Test**

#### **Cloud Build (Primary Build Service)**
- **Service:** Google Cloud Build
- **Purpose:** Serverless CI/CD platform
- **Configuration:** `cloudbuild.yaml`
- **Advantages:**
  - Serverless (no runner management)
  - Docker-native (every build runs in containerized environment)
  - Native integration with Artifact Registry, GKE, GCS
  - Build triggers from GitHub, Cloud Source Repositories, Bitbucket
  - Build caching (Docker layer caching, custom caches)
  - Parallel build steps
  - Private pools for sensitive builds
- **Disadvantages:**
  - Slower cold starts than self-hosted runners
  - Limited to 100 concurrent builds (default)
  - Less flexible than GitHub Actions
- **Cost:**
  - First 120 build-minutes/day: Free
  - Additional build-minutes: $0.003/build-minute
  - n1-standard-1 (1 vCPU, 3.75 GB): Default
  - n1-highcpu-8 (8 vCPU, 7.2 GB): $0.016/build-minute
  - n1-highcpu-32 (32 vCPU, 28.8 GB): $0.064/build-minute

**Example Cloud Build Configuration:**
```yaml
# cloudbuild.yaml
steps:
  # Step 1: Install dependencies
  - name: 'python:3.11-slim'
    entrypoint: 'pip'
    args: ['install', '-r', 'requirements.txt', '-t', '/workspace/lib']
    id: 'install-deps'

  # Step 2: Run tests
  - name: 'python:3.11-slim'
    entrypoint: 'pytest'
    args: ['tests/', '-v', '--cov=src', '--cov-report=xml']
    id: 'run-tests'
    waitFor: ['install-deps']

  # Step 3: SonarCloud analysis (optional)
  - name: 'gcr.io/cloud-builders/gcloud'
    entrypoint: 'bash'
    args:
      - '-c'
      - |
        curl -sSLo sonar-scanner.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006.zip
        unzip -o sonar-scanner.zip
        sonar-scanner-5.0.1.3006/bin/sonar-scanner \
          -Dsonar.projectKey=marketing-agent \
          -Dsonar.sources=src \
          -Dsonar.python.coverage.reportPaths=coverage.xml \
          -Dsonar.host.url=$_SONAR_HOST_URL \
          -Dsonar.login=$_SONAR_TOKEN
    id: 'code-quality'
    waitFor: ['run-tests']

  # Step 4: Build Docker image
  - name: 'gcr.io/cloud-builders/docker'
    args:
      - 'build'
      - '-t'
      - '${_REGION}-docker.pkg.dev/${PROJECT_ID}/${_ARTIFACT_REGISTRY_REPO}/backend:${COMMIT_SHA}'
      - '-t'
      - '${_REGION}-docker.pkg.dev/${PROJECT_ID}/${_ARTIFACT_REGISTRY_REPO}/backend:latest'
      - '-f'
      - 'infrastructure/docker/Dockerfile.backend'
      - '.'
    id: 'build-image'
    waitFor: ['code-quality']

  # Step 5: Push to Artifact Registry
  - name: 'gcr.io/cloud-builders/docker'
    args:
      - 'push'
      - '${_REGION}-docker.pkg.dev/${PROJECT_ID}/${_ARTIFACT_REGISTRY_REPO}/backend:${COMMIT_SHA}'
    id: 'push-image'
    waitFor: ['build-image']

  # Step 6: Container vulnerability scanning
  - name: 'gcr.io/cloud-builders/gcloud'
    args:
      - 'artifacts'
      - 'docker'
      - 'images'
      - 'scan'
      - '${_REGION}-docker.pkg.dev/${PROJECT_ID}/${_ARTIFACT_REGISTRY_REPO}/backend:${COMMIT_SHA}'
    id: 'scan-vulnerabilities'
    waitFor: ['push-image']

  # Step 7: Deploy to GKE (staging)
  - name: 'gcr.io/cloud-builders/gke-deploy'
    args:
      - 'run'
      - '--filename=infrastructure/k8s/base/'
      - '--location=${_REGION}'
      - '--cluster=${_GKE_CLUSTER_STAGING}'
      - '--namespace=marketing-agent'
      - '--image=${_REGION}-docker.pkg.dev/${PROJECT_ID}/${_ARTIFACT_REGISTRY_REPO}/backend:${COMMIT_SHA}'
    id: 'deploy-staging'
    waitFor: ['scan-vulnerabilities']

# Substitutions (variables)
substitutions:
  _REGION: 'us-central1'
  _ARTIFACT_REGISTRY_REPO: 'marketing-agent'
  _GKE_CLUSTER_STAGING: 'marketing-agent-staging'
  _SONAR_HOST_URL: 'https://sonarcloud.io'
  _SONAR_TOKEN: 'will-be-injected-from-secret-manager'

# Options
options:
  machineType: 'N1_HIGHCPU_8'  # 8 vCPU for faster builds
  logging: 'CLOUD_LOGGING_ONLY'
  
# Timeout
timeout: '1800s'  # 30 minutes

# Artifacts
artifacts:
  objects:
    location: 'gs://${PROJECT_ID}-build-artifacts'
    paths:
      - 'coverage.xml'
      - 'test-results.xml'
```

**Cloud Build Triggers:**
```terraform
# infrastructure/terraform/gcp-cloudbuild.tf

resource "google_cloudbuild_trigger" "backend_ci" {
  name        = "backend-ci-trigger"
  description = "Trigger CI pipeline for backend on every push to main"

  github {
    owner = "sudipawtg"
    name  = "marketing-agent"
    push {
      branch = "^main$"
    }
  }

  filename = "cloudbuild.yaml"

  substitutions = {
    _REGION                  = var.region
    _ARTIFACT_REGISTRY_REPO  = google_artifact_registry_repository.main.name
    _GKE_CLUSTER_STAGING     = google_container_cluster.main.name
  }

  # Service account for build
  service_account = google_service_account.cloud_build.id
}

# Service account for Cloud Build
resource "google_service_account" "cloud_build" {
  account_id   = "cloud-build-sa"
  display_name = "Cloud Build Service Account"
}

# Grant permissions to push images
resource "google_artifact_registry_repository_iam_member" "cloud_build_writer" {
  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.main.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.cloud_build.email}"
}

# Grant permissions to deploy to GKE
resource "google_project_iam_member" "cloud_build_gke" {
  project = var.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.cloud_build.email}"
}
```

#### **GitHub Actions (Hybrid Approach)**
- **Use Case:** Use GitHub Actions for PR checks and Cloud Build for deployment
- **Advantages:** Best of both worlds (GitHub UX + GCP integration)

```yaml
# .github/workflows/gcp-ci.yml
name: GCP CI

on:
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      
      - name: Install dependencies
        run: pip install -r requirements.txt
      
      - name: Run tests
        run: pytest tests/ -v --cov=src
      
      - name: Authenticate to GCP
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: ${{ secrets.GCP_WORKLOAD_IDENTITY_PROVIDER }}
          service_account: ${{ secrets.GCP_SERVICE_ACCOUNT }}
      
      - name: Trigger Cloud Build
        run: |
          gcloud builds submit \
            --config=cloudbuild.yaml \
            --substitutions=COMMIT_SHA=${{ github.sha }}
```

---

### 3. **Code Quality & Security Scanning**

#### **Artifact Analysis (Automatic Container Scanning)**
- **Service:** Artifact Analysis (part of Artifact Registry)
- **Purpose:** Automated vulnerability scanning for container images
- **Features:**
  - Continuous scanning (rescans on new CVE database updates)
  - OS and language package vulnerability detection
  - Integration with Security Command Center
  - CVE severity scoring (CRITICAL, HIGH, MEDIUM, LOW)
  - Attestation support (Binary Authorization)
- **Cost:** Included with Artifact Registry (no additional cost)

**Enable Artifact Analysis:**
```terraform
resource "google_artifact_registry_repository" "main" {
  location      = var.region
  repository_id = "marketing-agent"
  format        = "DOCKER"

  # Automatic vulnerability scanning
  docker_config {
    immutable_tags = true  # Prevent tag overwrites
  }

  labels = {
    environment = var.environment
    project     = "marketing-agent"
  }
}

# Pub/Sub notification for vulnerabilities
resource "google_pubsub_topic" "vulnerability_occurrences" {
  name = "vulnerability-occurrences"
}

resource "google_pubsub_subscription" "vulnerability_occurrences" {
  name  = "vulnerability-occurrences-sub"
  topic = google_pubsub_topic.vulnerability_occurrences.name

  # Dead letter topic for failed messages
  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dead_letter.id
    max_delivery_attempts = 5
  }

  # Retry policy
  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }
}

# Cloud Function to handle vulnerability alerts
resource "google_cloudfunctions_function" "vulnerability_handler" {
  name        = "vulnerability-handler"
  runtime     = "python311"
  entry_point = "handle_vulnerability"

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.vulnerability_occurrences.name
  }

  source_archive_bucket = google_storage_bucket.functions_source.name
  source_archive_object = google_storage_bucket_object.function_source.name

  environment_variables = {
    SLACK_WEBHOOK_URL = var.slack_webhook_url
  }
}
```

**Cloud Function Code (vulnerability_handler.py):**
```python
import base64
import json
import requests
from google.cloud import containeranalysis_v1

def handle_vulnerability(event, context):
    """Handle vulnerability occurrence notifications."""
    
    # Decode Pub/Sub message
    pubsub_message = base64.b64decode(event['data']).decode('utf-8')
    message_data = json.loads(pubsub_message)
    
    # Extract vulnerability details
    resource_uri = message_data.get('resourceUri', '')
    severity = message_data.get('vulnerability', {}).get('severity', 'UNKNOWN')
    cve_id = message_data.get('vulnerability', {}).get('shortDescription', '')
    
    # Only alert on HIGH and CRITICAL
    if severity in ['HIGH', 'CRITICAL']:
        send_slack_alert(resource_uri, severity, cve_id)
        
        # Optionally: Block deployment if CRITICAL
        if severity == 'CRITICAL':
            update_binary_authorization_policy(resource_uri, allow=False)

def send_slack_alert(image, severity, cve_id):
    """Send alert to Slack channel."""
    webhook_url = os.environ.get('SLACK_WEBHOOK_URL')
    
    payload = {
        "text": f"🚨 *{severity}* vulnerability detected",
        "blocks": [
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*Image:* `{image}`\n*Severity:* {severity}\n*CVE:* {cve_id}"
                }
            }
        ]
    }
    
    requests.post(webhook_url, json=payload)
```

#### **Binary Authorization (Deployment Policy Enforcement)**
- **Service:** Binary Authorization
- **Purpose:** Only allow deployment of signed, verified container images
- **How It Works:**
  1. Attest images after successful scans
  2. Require attestations for deployment
  3. Deny deployment if attestation missing or vulnerabilities found
- **Cost:** Free (included with GKE)

**Binary Authorization Policy:**
```terraform
resource "google_binary_authorization_policy" "main" {
  admission_whitelist_patterns {
    name_pattern = "gcr.io/google_containers/*"  # Allow GKE system images
  }

  admission_whitelist_patterns {
    name_pattern = "gcr.io/gke-release/*"
  }

  default_admission_rule {
    evaluation_mode  = "REQUIRE_ATTESTATION"
    enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"

    require_attestations_by = [
      google_binary_authorization_attestor.vulnerability_scan.name,
      google_binary_authorization_attestor.code_review.name,
    ]
  }

  # Cluster-specific overrides
  cluster_admission_rules {
    cluster                 = "${var.project_id}.${var.region}.${google_container_cluster.main.name}"
    evaluation_mode         = "REQUIRE_ATTESTATION"
    enforcement_mode        = "ENFORCED_BLOCK_AND_AUDIT_LOG"
    require_attestations_by = [
      google_binary_authorization_attestor.vulnerability_scan.name,
    ]
  }
}

# Attestor for vulnerability scanning
resource "google_binary_authorization_attestor" "vulnerability_scan" {
  name = "vulnerability-scan-attestor"

  attestation_authority_note {
    note_reference = google_container_analysis_note.vulnerability_scan.name

    public_keys {
      id = "vulnerability-scan-key"
      pkix_public_key {
        public_key_pem      = file("${path.module}/keys/vulnerability-scan-public.pem")
        signature_algorithm = "RSA_SIGN_PKCS1_4096_SHA512"
      }
    }
  }
}

resource "google_container_analysis_note" "vulnerability_scan" {
  name = "vulnerability-scan-note"

  attestation_authority {
    hint {
      human_readable_name = "Vulnerability scan attestation"
    }
  }
}
```

#### **Security Command Center (Unified Security View)**
- **Service:** Security Command Center
- **Purpose:** Centralized security and risk dashboard
- **Features:**
  - Asset discovery and inventory
  - Vulnerability detection
  - Threat detection (anomalous activity)
  - Compliance monitoring (CIS benchmarks)
  - Security recommendations
- **Tiers:**
  - Standard: Free (basic asset discovery)
  - Premium: $0.03/resource/month (advanced threat detection)

---

### 4. **Artifact Storage & Management**

#### **Artifact Registry (Docker, Maven, NPM, Python)**
- **Service:** Artifact Registry
- **Purpose:** Unified artifact management
- **Supported Formats:**
  - Docker/OCI images
  - Maven (Java)
  - NPM (Node.js)
  - Python (PyPI)
  - APT (Debian packages)
  - YUM (RPM packages)
- **Features:**
  - Regional and multi-regional repositories
  - IAM-based access control
  - Automatic vulnerability scanning
  - Cleanup policies
  - VPC Service Controls for private access
- **Cost:**
  - Storage: $0.10/GB/month
  - Egress: Free within same region, $0.12/GB to internet
  - Example: 50 images × 500 MB = 25 GB = $2.50/month

**Artifact Registry Configuration:**
```terraform
resource "google_artifact_registry_repository" "main" {
  location      = var.region
  repository_id = "marketing-agent"
  format        = "DOCKER"

  labels = {
    environment = var.environment
  }
}

# Python repository for internal packages
resource "google_artifact_registry_repository" "python" {
  location      = var.region
  repository_id = "python-packages"
  format        = "PYTHON"
}

# Cleanup policy (delete old images)
resource "google_artifact_registry_repository" "main" {
  location      = var.region
  repository_id = "marketing-agent"
  format        = "DOCKER"

  cleanup_policies {
    id     = "delete-untagged"
    action = "DELETE"

    condition {
      tag_state = "UNTAGGED"
      older_than = "604800s"  # 7 days
    }
  }

  cleanup_policies {
    id     = "keep-recent-versions"
    action = "KEEP"

    most_recent_versions {
      keep_count = 30
    }
  }
}
```

**Using Artifact Registry in Cloud Build:**
```bash
# Authenticate Docker to Artifact Registry
gcloud auth configure-docker us-central1-docker.pkg.dev

# Build and push image
docker build -t us-central1-docker.pkg.dev/PROJECT_ID/marketing-agent/backend:latest .
docker push us-central1-docker.pkg.dev/PROJECT_ID/marketing-agent/backend:latest
```

#### **Cloud Storage (Build Artifacts & Static Assets)**
- **Service:** Cloud Storage
- **Purpose:**
  - Build logs and artifacts
  - Terraform state
  - Static website hosting
  - Database backups
- **Storage Classes:**
  - Standard: $0.020/GB/month (hot data)
  - Nearline: $0.010/GB/month (accessed < once/month)
  - Coldline: $0.004/GB/month (accessed < once/quarter)
  - Archive: $0.0012/GB/month (accessed < once/year)
- **Features:**
  - Lifecycle management (auto-migrate to cheaper classes)
  - Object versioning
  - Retention policies
  - Signed URLs for temporary access
- **Cost:**
  - Storage: $0.020/GB/month (Standard)
  - Operations: $0.05 per 10,000 Class A, $0.004 per 10,000 Class B
  - Egress: Free within GCP, $0.12/GB to internet

**Cloud Storage Terraform:**
```terraform
# Bucket for build artifacts
resource "google_storage_bucket" "build_artifacts" {
  name     = "${var.project_id}-build-artifacts"
  location = var.region

  # Lifecycle rules for cost optimization
  lifecycle_rule {
    condition {
      age = 30  # Days
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }

  # Versioning for rollback
  versioning {
    enabled = true
  }

  # Uniform bucket-level access (recommended)
  uniform_bucket_level_access = true

  # Encryption
  encryption {
    default_kms_key_name = google_kms_crypto_key.gcs.id
  }
}

# Bucket for Terraform state
resource "google_storage_bucket" "terraform_state" {
  name     = "${var.project_id}-terraform-state"
  location = "US"  # Multi-region for high availability

  versioning {
    enabled = true
  }

  uniform_bucket_level_access = true

  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = true
  }
}
```

---

### 5. **CD Pipeline - Deployment Orchestration**

#### **Cloud Deploy (Continuous Delivery Service)**
- **Service:** Google Cloud Deploy
- **Purpose:** Automated, opinionated deployment pipelines
- **Features:**
  - Progressive delivery (canary, blue/green)
  - Automated rollback
  - Skaffold-based deployments
  - Approval gates
  - Deployment verification (metrics-based)
  - Audit logging
- **Advantages over DIY:**
  - Managed service (no pipeline maintenance)
  - Built-in best practices
  - Integration with GKE, Cloud Run, Anthos
  - Native Google Cloud Operations integration
- **Cost:**
  - $0.04 per target per hour per active pipeline
  - Example: 3 targets (staging, canary, prod) × 730 hours = $87.60/month per pipeline

**Cloud Deploy Configuration:**
```yaml
# clouddeploy.yaml
apiVersion: deploy.cloud.google.com/v1
kind: DeliveryPipeline
metadata:
  name: marketing-agent-pipeline
description: Deployment pipeline for marketing-agent
serialPipeline:
  stages:
    - targetId: staging
      profiles: [staging]
    - targetId: canary
      profiles: [canary]
      strategy:
        canary:
          runtimeConfig:
            cloudRun:
              automaticTrafficControl: true
          canaryDeployment:
            percentages: [10, 50]
            verify: true
            predeploy:
              actions:
                - name: pre-deployment-check
            postdeploy:
              actions:
                - name: integration-tests
    - targetId: production
      profiles: [production]
      strategy:
        standard:
          verify: true
          predeploy:
            actions:
              - name: backup-database
---
apiVersion: deploy.cloud.google.com/v1
kind: Target
metadata:
  name: staging
description: Staging environment
gke:
  cluster: projects/PROJECT_ID/locations/us-central1/clusters/marketing-agent-staging
---
apiVersion: deploy.cloud.google.com/v1
kind: Target
metadata:
  name: canary
description: Canary environment (10% of production traffic)
gke:
  cluster: projects/PROJECT_ID/locations/us-central1/clusters/marketing-agent-production
---
apiVersion: deploy.cloud.google.com/v1
kind: Target
metadata:
  name: production
description: Production environment
requireApproval: true
gke:
  cluster: projects/PROJECT_ID/locations/us-central1/clusters/marketing-agent-production
```

**Skaffold Configuration (used by Cloud Deploy):**
```yaml
# skaffold.yaml
apiVersion: skaffold/v4beta6
kind: Config
metadata:
  name: marketing-agent-backend
build:
  artifacts:
    - image: backend
      docker:
        dockerfile: infrastructure/docker/Dockerfile.backend
        cacheFrom:
          - us-central1-docker.pkg.dev/PROJECT_ID/marketing-agent/backend:latest
  googleCloudBuild:
    projectId: PROJECT_ID
    machineType: N1_HIGHCPU_8
deploy:
  kubectl:
    manifests:
      - infrastructure/k8s/base/backend-deployment.yaml
      - infrastructure/k8s/base/frontend-deployment.yaml
profiles:
  - name: staging
    deploy:
      kubectl:
        defaultNamespace: marketing-agent-staging
  - name: canary
    deploy:
      kubectl:
        defaultNamespace: marketing-agent-production
        hooks:
          before:
            - host:
                command: ["sh", "-c", "kubectl label pods -n marketing-agent-production app=backend version=canary"]
  - name: production
    deploy:
      kubectl:
        defaultNamespace: marketing-agent-production
```

**Triggering Cloud Deploy from Cloud Build:**
```yaml
# cloudbuild.yaml (additional step)
steps:
  # ... previous build steps ...

  # Create Cloud Deploy release
  - name: 'gcr.io/google.com/cloudsdktool/cloud-sdk'
    entrypoint: 'gcloud'
    args:
      - 'deploy'
      - 'releases'
      - 'create'
      - 'release-${SHORT_SHA}'
      - '--delivery-pipeline=marketing-agent-pipeline'
      - '--region=${_REGION}'
      - '--source=.'
      - '--images=backend=${_REGION}-docker.pkg.dev/${PROJECT_ID}/${_ARTIFACT_REGISTRY_REPO}/backend:${COMMIT_SHA}'
```

**Deploy with Cloud Deploy CLI:**
```bash
# Create release
gcloud deploy releases create release-v1-0-0 \
  --delivery-pipeline=marketing-agent-pipeline \
  --region=us-central1 \
  --source=. \
  --images=backend=us-central1-docker.pkg.dev/PROJECT_ID/marketing-agent/backend:v1.0.0

# Promote to next stage
gcloud deploy releases promote \
  --release=release-v1-0-0 \
  --delivery-pipeline=marketing-agent-pipeline \
  --region=us-central1

# Rollback
gcloud deploy targets rollback production \
  --delivery-pipeline=marketing-agent-pipeline \
  --region=us-central1
```

---

### 6. **Infrastructure Layer - Compute & Data**

#### **Google Kubernetes Engine (GKE Autopilot)**
- **Service:** Google Kubernetes Engine (GKE Autopilot mode)
- **Purpose:** Managed, serverless Kubernetes
- **Key Difference from AWS EKS:**
  - **Autopilot Mode:** Google manages nodes entirely (no node pools to configure)
  - **Pod-level Billing:** Pay only for pod resources (no idle node cost)
  - **Automatic Scaling:** Nodes scale automatically based on pod requests
  - **Security Hardening:** Enforced security best practices (no SSH, restricted permissions)
- **Advantages:**
  - Lower operational overhead (no node management)
  - Cost-efficient (pay only for pod resources)
  - Built-in security (Shielded GKE nodes, Workload Identity)
  - Automatic upgrades (control plane and nodes)
- **Disadvantages:**
  - Less control (can't customize node OS, install node-level agents)
  - Higher per-pod cost than optimized Standard mode
  - Some workloads unsupported (DaemonSets with node access)
- **Cost:**
  - Control plane: $0.10/hour = $73/month (same as AWS)
  - Pod resources: $0.00004256/vCPU-hour + $0.00000473/GB-hour
  - Example: 10 pods × 500m CPU × 1 GB RAM = 5 vCPU, 10 GB
    - vCPU: 5 × $0.00004256 × 730 = $155
    - Memory: 10 × $0.00000473 × 730 = $35
    - **Total: ~$263/month** (vs $290 AWS with t3.large nodes)

**GKE Autopilot Terraform:**
```terraform
resource "google_container_cluster" "main" {
  name     = var.cluster_name
  location = var.region

  # Enable Autopilot
  enable_autopilot = true

  # Network configuration
  network    = google_compute_network.main.name
  subnetwork = google_compute_subnetwork.gke.name

  # IP allocation policy (required for VPC-native clusters)
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Workload Identity (IAM for pods)
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Release channel (automatic upgrades)
  release_channel {
    channel = "REGULAR"  # RAPID, REGULAR, or STABLE
  }

  # Binary Authorization
  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

  # Logging and monitoring
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
    managed_prometheus {
      enabled = true
    }
  }

  # Maintenance window
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"  # UTC
    }
  }

  # Shielded nodes (secure boot, integrity monitoring)
  enable_shielded_nodes = true

  # Network policy enforcement
  network_policy {
    enabled = true
  }

  # Master authorized networks (restrict API access)
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"  # Restrict to office IPs in production
      display_name = "All"
    }
  }

  # Private cluster (nodes have private IPs only)
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false  # Set true for fully private
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  # Add-ons
  addons_config {
    http_load_balancing {
      disabled = false
    }

    horizontal_pod_autoscaling {
      disabled = false
    }

    gce_persistent_disk_csi_driver_config {
      enabled = true
    }

    gcs_fuse_csi_driver_config {
      enabled = true  # Mount GCS buckets as volumes
    }
  }

  # Resource labels
  resource_labels = {
    environment = var.environment
    project     = "marketing-agent"
  }
}

# VPC network for GKE
resource "google_compute_network" "main" {
  name                    = "${var.cluster_name}-network"
  auto_create_subnetworks = false
}

# Subnet for GKE with secondary ranges
resource "google_compute_subnetwork" "gke" {
  name          = "${var.cluster_name}-subnet"
  ip_cidr_range = "10.0.0.0/20"  # 4096 IPs for nodes
  region        = var.region
  network       = google_compute_network.main.name

  # Secondary ranges for pods and services
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.4.0.0/14"  # 262,144 pod IPs
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.8.0.0/20"  # 4096 service IPs
  }

  # Private Google Access (access GCS, Artifact Registry without public IPs)
  private_ip_google_access = true
}

# Cloud Router for NAT (outbound internet access)
resource "google_compute_router" "main" {
  name    = "${var.cluster_name}-router"
  region  = var.region
  network = google_compute_network.main.id
}

# Cloud NAT for outbound traffic
resource "google_compute_router_nat" "main" {
  name   = "${var.cluster_name}-nat"
  router = google_compute_router.main.name
  region = var.region

  nat_ip_allocate_option = "AUTO_ONLY"

  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
```

**GKE Standard Mode (for comparison):**
If you need more control, use Standard mode with node pools:
```terraform
resource "google_container_cluster" "standard" {
  name     = var.cluster_name
  location = var.region

  # Remove default node pool (we'll create custom ones)
  remove_default_node_pool = true
  initial_node_count       = 1

  # ... rest of configuration same as Autopilot ...
}

# Custom node pool
resource "google_container_node_pool" "primary" {
  name       = "primary-node-pool"
  cluster    = google_container_cluster.standard.name
  location   = var.region
  node_count = 3

  # Autoscaling
  autoscaling {
    min_node_count = 2
    max_node_count = 10
  }

  # Node configuration
  node_config {
    machine_type = "n2-standard-4"  # 4 vCPU, 16 GB RAM
    disk_size_gb = 50
    disk_type    = "pd-ssd"

    # Preemptible nodes (70% discount)
    preemptible = var.environment == "staging" ? true : false

    # OAuth scopes
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Labels
    labels = {
      environment = var.environment
    }

    # Taints (for workload isolation)
    taint {
      key    = "workload"
      value  = "backend"
      effect = "NO_SCHEDULE"
    }

    # Shielded instance config
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    # Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  # Upgrade settings
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # Upgrade strategy
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
    strategy        = "SURGE"
  }
}

# Spot node pool (for batch workloads)
resource "google_container_node_pool" "spot" {
  name       = "spot-node-pool"
  cluster    = google_container_cluster.standard.name
  location   = var.region
  node_count = 1

  autoscaling {
    min_node_count = 0
    max_node_count = 20
  }

  node_config {
    machine_type = "n2-standard-4"
    spot         = true  # Spot VMs (up to 90% discount)

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      workload = "batch"
    }

    taint {
      key    = "workload"
      value  = "batch"
      effect = "NO_SCHEDULE"
    }
  }
}
```

**Cost Comparison: Autopilot vs Standard:**

| Configuration | Cost/Month (Staging) | Cost/Month (Production) |
|---------------|---------------------|-------------------------|
| **GKE Autopilot** | $263 (10 pods, 5 vCPU, 10 GB) | $526 (20 pods, 10 vCPU, 20 GB) |
| **GKE Standard (n2-standard-4)** | $220 (2 nodes) | $660 (6 nodes) |
| **GKE Standard (preemptible)** | $66 (2 nodes) | $198 (6 nodes) |

**Recommendation:** Use Autopilot for simplicity and GKE Standard with preemptible/spot nodes for cost optimization in non-critical environments.

#### **Cloud SQL (PostgreSQL)**
- **Service:** Cloud SQL for PostgreSQL
- **Purpose:** Fully managed relational database
- **Configuration:**
  - Engine: PostgreSQL 15
  - Machine type: db-n1-standard-2 (staging), db-n1-standard-4 (production)
  - High Availability: Regional (automatic failover)
  - Storage: SSD with automatic storage increase
  - Backups: Automated daily backups + transaction logs
  - Encryption: At rest and in transit
- **Advantages over AWS RDS:**
  - Simpler pricing (no Multi-AZ surcharge)
  - Better integration with GKE (Workload Identity)
  - Cloud SQL Proxy for secure connections (no VPN needed)
  - Automated storage increases (no manual intervention)
- **Cost:**
  - db-n1-standard-2 (2 vCPU, 7.5 GB): $0.1380/hour = $101/month
  - HA (regional): +$0.1380/hour = +$101/month
  - Storage: $0.17/GB/month (SSD)
  - Backups: $0.08/GB/month
  - **Total staging (HA, 100 GB):** ~$219/month (similar to AWS)

**Cloud SQL Terraform:**
```terraform
resource "google_sql_database_instance" "postgres" {
  name             = "${var.cluster_name}-postgres"
  database_version = "POSTGRES_15"
  region           = var.region

  settings {
    tier = var.environment == "production" ? "db-n1-standard-4" : "db-n1-standard-2"

    # High Availability (regional)
    availability_type = var.environment == "production" ? "REGIONAL" : "ZONAL"

    # Disk configuration
    disk_type       = "PD_SSD"
    disk_size       = 100  # GB
    disk_autoresize = true
    disk_autoresize_limit = 1000

    # Backups
    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"  # UTC
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
      backup_retention_settings {
        retained_backups = 30
      }
    }

    # Maintenance window
    maintenance_window {
      day  = 7  # Sunday
      hour = 4  # 4 AM UTC
    }

    # IP configuration (private IP only)
    ip_configuration {
      ipv4_enabled    = false  # No public IP
      private_network = google_compute_network.main.id
      require_ssl     = true

      # Authorized networks (if public IP was enabled)
      # authorized_networks {
      #   name  = "office"
      #   value = "1.2.3.4/32"
      # }
    }

    # Insights
    insights_config {
      query_insights_enabled = true
      query_plans_per_minute = 5
      query_string_length    = 1024
      record_application_tags = true
      record_client_address   = true
    }

    # Database flags
    database_flags {
      name  = "max_connections"
      value = "500"
    }

    database_flags {
      name  = "shared_buffers"
      value = "2097152"  # 2 GB in 8KB pages
    }

    database_flags {
      name  = "work_mem"
      value = "16384"  # 16 MB in KB
    }
  }

  # Deletion protection
  deletion_protection = var.environment == "production" ? true : false
}

# Database
resource "google_sql_database" "main" {
  name     = "marketing_agent"
  instance = google_sql_database_instance.postgres.name
}

# User
resource "google_sql_user" "main" {
  name     = "marketing_agent"
  instance = google_sql_database_instance.postgres.name
  password = random_password.db_password.result
}

resource "random_password" "db_password" {
  length  = 32
  special = true
}

# Store credentials in Secret Manager
resource "google_secret_manager_secret" "db_password" {
  secret_id = "${var.cluster_name}-db-password"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = jsonencode({
    username = google_sql_user.main.name
    password = random_password.db_password.result
    host     = google_sql_database_instance.postgres.private_ip_address
    port     = 5432
    database = google_sql_database.main.name
  })
}

# Private service connection for Cloud SQL
resource "google_compute_global_address" "private_ip_address" {
  name          = "${var.cluster_name}-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.main.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}
```

**Cloud SQL Proxy (for secure connections from GKE):**
```yaml
# infrastructure/k8s/base/cloudsql-proxy.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: marketing-agent-backend
  namespace: marketing-agent
spec:
  template:
    spec:
      serviceAccountName: marketing-agent  # With Workload Identity
      containers:
        # Application container
        - name: backend
          image: us-central1-docker.pkg.dev/PROJECT_ID/marketing-agent/backend:latest
          env:
            - name: DATABASE_HOST
              value: "127.0.0.1"  # Connect via proxy
            - name: DATABASE_PORT
              value: "5432"
            - name: DATABASE_USER
              valueFrom:
                secretKeyRef:
                  name: db-credentials
                  key: username
            - name: DATABASE_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-credentials
                  key: password
        
        # Cloud SQL Proxy sidecar
        - name: cloud-sql-proxy
          image: gcr.io/cloud-sql-connectors/cloud-sql-proxy:latest
          args:
            - "--private-ip"
            - "PROJECT_ID:REGION:INSTANCE_NAME"
          securityContext:
            runAsNonRoot: true
          resources:
            requests:
              memory: "128Mi"
              cpu: "100m"
            limits:
              memory: "256Mi"
              cpu: "200m"
```

#### **Memorystore for Redis**
- **Service:** Memorystore for Redis
- **Purpose:** Fully managed Redis
- **Configuration:**
  - Engine: Redis 7.0
  - Tier: Standard (HA with automatic failover)
  - Capacity: 5 GB (staging), 20 GB (production)
  - Replicas: 1 (for HA)
  - Encryption: In-transit encryption
- **Cost:**
  - Standard tier: $0.063/GB/hour
  - 5 GB: $0.315/hour = $230/month
  - **Total for 5 GB HA:** ~$230/month (vs $100 AWS ElastiCache)
  - **Note:** Memorystore is more expensive but includes better SLA and management

**Memorystore Terraform:**
```terraform
resource "google_redis_instance" "main" {
  name           = "${var.cluster_name}-redis"
  tier           = var.environment == "production" ? "STANDARD_HA" : "BASIC"
  memory_size_gb = var.environment == "production" ? 20 : 5
  region         = var.region

  redis_version = "REDIS_7_0"

  # Network
  authorized_network = google_compute_network.main.name
  connect_mode       = "PRIVATE_SERVICE_ACCESS"

  # High availability (automatic failover)
  replica_count = var.environment == "production" ? 1 : 0
  read_replicas_mode = var.environment == "production" ? "READ_REPLICAS_ENABLED" : "READ_REPLICAS_DISABLED"

  # Maintenance
  maintenance_policy {
    weekly_maintenance_window {
      day = "SUNDAY"
      start_time {
        hours   = 4
        minutes = 0
      }
    }
  }

  # Persistence
  persistence_config {
    persistence_mode    = "RDB"
    rdb_snapshot_period = "TWENTY_FOUR_HOURS"
  }

  # Auth
  auth_enabled = true

  # Transit encryption
  transit_encryption_mode = "SERVER_AUTHENTICATION"

  labels = {
    environment = var.environment
  }
}

# Output connection info
output "redis_host" {
  value = google_redis_instance.main.host
}

output "redis_port" {
  value = google_redis_instance.main.port
}
```

---

### 7. **AI/Ops Monitoring & Observability (Cloud Operations Suite)**

#### **Cloud Monitoring (formerly Stackdriver)**
- **Service:** Cloud Monitoring
- **Purpose:** Metrics collection, alerting, dashboards
- **Features:**
  - Automatic GKE metrics (CPU, memory, network)
  - Custom metrics (application-level)
  - Uptime checks (synthetic monitoring)
  - Alerting policies with notification channels
  - Multi-cloud monitoring (AWS, Azure via agents)
- **Advantages over CloudWatch:**
  - Better UI/UX (more intuitive dashboards)
  - Unified monitoring for multi-cloud
  - No separate charges for metrics (included in GKE pricing)
  - Query Language (MQL) for complex metric transformations
- **Cost:**
  - First 150-250 GB of logs: Free
  - Metrics: Free for GKE/Cloud SQL/Compute Engine
  - Uptime checks: First 1 million checks/month free
  - Custom metrics: $0.2582 per 1K time series per month
  - Example: 100 custom metrics = ~$26/month

**Cloud Monitoring Terraform:**
```terraform
# High error rate alert
resource "google_monitoring_alert_policy" "high_error_rate" {
  display_name = "${var.cluster_name} - High Error Rate"
  combiner     = "OR"

  conditions {
    display_name = "HTTP 5XX Error Rate > 5%"

    condition_threshold {
      filter          = "resource.type = \"k8s_container\" AND resource.labels.cluster_name = \"${var.cluster_name}\" AND metric.type = \"logging.googleapis.com/user/http_response_status\" AND metric.labels.status >= \"500\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.05  # 5%

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = [
    google_monitoring_notification_channel.email.name,
    google_monitoring_notification_channel.slack.name,
  ]

  alert_strategy {
    auto_close = "1800s"  # 30 minutes
  }
}

# High latency alert
resource "google_monitoring_alert_policy" "high_latency" {
  display_name = "${var.cluster_name} - High Latency"
  combiner     = "OR"

  conditions {
    display_name = "P95 Latency > 2000ms"

    condition_threshold {
      filter          = "resource.type = \"k8s_container\" AND metric.type = \"custom.googleapis.com/http_request_duration\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 2000  # 2 seconds

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_DELTA"
        cross_series_reducer = "REDUCE_PERCENTILE_95"
        group_by_fields      = ["resource.namespace_name"]
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]
}

# Notification channels
resource "google_monitoring_notification_channel" "email" {
  display_name = "Email Notifications"
  type         = "email"

  labels = {
    email_address = "devops@example.com"
  }
}

resource "google_monitoring_notification_channel" "slack" {
  display_name = "Slack Notifications"
  type         = "slack"

  labels = {
    channel_name = "#alerts"
  }

  sensitive_labels {
    auth_token = var.slack_token
  }
}

# Uptime check
resource "google_monitoring_uptime_check_config" "https" {
  display_name = "${var.cluster_name} - HTTPS Check"
  timeout      = "10s"
  period       = "60s"

  http_check {
    path           = "/health"
    port           = 443
    request_method = "GET"
    use_ssl        = true
    validate_ssl   = true
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = "marketing-agent.example.com"
    }
  }
}
```

**Custom Metrics in Python (OpenCensus):**
```python
# src/monitoring.py
from opencensus.ext.stackdriver import stats_exporter
from opencensus.stats import aggregation, measure, stats, view

# Create stats recorder
stats_recorder = stats.stats_recorder()

# Define measures
http_request_duration = measure.MeasureFloat(
    "http_request_duration",
    "Duration of HTTP requests in milliseconds",
    "ms"
)

http_request_count = measure.MeasureInt(
    "http_request_count",
    "Count of HTTP requests",
    "1"
)

# Define views (how to aggregate measures)
latency_view = view.View(
    "http_request_duration_view",
    "Distribution of HTTP request latencies",
    ["method", "endpoint", "status_code"],
    http_request_duration,
    aggregation.DistributionAggregation([50, 100, 200, 500, 1000, 2000, 5000])
)

count_view = view.View(
    "http_request_count_view",
    "Count of HTTP requests by method and endpoint",
    ["method", "endpoint", "status_code"],
    http_request_count,
    aggregation.CountAggregation()
)

# Register views
view_manager = stats.view_manager
view_manager.register_view(latency_view)
view_manager.register_view(count_view)

# Export to Cloud Monitoring
exporter = stats_exporter.new_stats_exporter()
view_manager.register_exporter(exporter)

# Usage in application
from fastapi import FastAPI, Request
import time

app = FastAPI()

@app.middleware("http")
async def monitor_requests(request: Request, call_next):
    start_time = time.time()
    
    response = await call_next(request)
    
    duration_ms = (time.time() - start_time) * 1000
    
    # Record metrics
    tags = {
        "method": request.method,
        "endpoint": request.url.path,
        "status_code": str(response.status_code)
    }
    
    mmap = stats_recorder.new_measurement_map()
    mmap.measure_float_put(http_request_duration, duration_ms)
    mmap.measure_int_put(http_request_count, 1)
    mmap.record(tags)
    
    return response
```

#### **Cloud Logging (formerly Stackdriver Logging)**
- **Service:** Cloud Logging
- **Purpose:** Centralized log management
- **Features:**
  - Automatic GKE log collection
  - Log-based metrics (create metrics from log patterns)
  - Log sinks (export to BigQuery, Cloud Storage, Pub/Sub)
  - Log retention (30 days default, customizable)
  - Advanced filters (query language)
- **Cost:**
  - First 50 GB/project/month: Free
  - Additional ingestion: $0.50/GB
  - Storage (beyond 30 days): $0.01/GB/month
  - Example: 100 GB logs/month = $25/month

**Log Sink to BigQuery (for analytics):**
```terraform
# BigQuery dataset for logs
resource "google_bigquery_dataset" "logs" {
  dataset_id = "${replace(var.cluster_name, "-", "_")}_logs"
  location   = "US"

  default_table_expiration_ms = 2592000000  # 30 days

  labels = {
    environment = var.environment
  }
}

# Log sink to BigQuery
resource "google_logging_project_sink" "bigquery" {
  name        = "${var.cluster_name}-bigquery-sink"
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${google_bigquery_dataset.logs.dataset_id}"

  # Filter (only application logs)
  filter = "resource.type=\"k8s_container\" AND resource.labels.namespace_name=\"marketing-agent\""

  # Create tables automatically
  bigquery_options {
    use_partitioned_tables = true
  }
}

# Grant sink permission to write to BigQuery
resource "google_bigquery_dataset_iam_member" "log_sink_writer" {
  dataset_id = google_bigquery_dataset.logs.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_project_sink.bigquery.writer_identity
}
```

#### **Cloud Trace (Distributed Tracing)**
- **Service:** Cloud Trace
- **Purpose:** Distributed tracing (similar to AWS X-Ray)
- **Features:**
  - Automatic tracing for GKE (with OpenTelemetry)
  - Service latency analysis
  - Trace visualization
  - Integration with Cloud Logging and Profiler
- **Advantages over X-Ray:**
  - Better integration with Kubernetes
  - OpenTelemetry native (vendor-neutral)
  - No separate daemon needed (direct export)
- **Cost:**
  - First 2.5 million trace spans/month: Free
  - Additional spans: $0.20 per million
  - Example: 10M spans/month = $1.50/month

**OpenTelemetry in Python:**
```python
# src/tracing.py
from opentelemetry import trace
from opentelemetry.exporter.cloud_trace import CloudTraceSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor

# Create tracer provider
tracer_provider = TracerProvider()
trace.set_tracer_provider(tracer_provider)

# Configure Cloud Trace exporter
cloud_trace_exporter = CloudTraceSpanExporter()
tracer_provider.add_span_processor(
    BatchSpanProcessor(cloud_trace_exporter)
)

# Get tracer
tracer = trace.get_tracer(__name__)

# Auto-instrument FastAPI
from fastapi import FastAPI
app = FastAPI()
FastAPIInstrumentor.instrument_app(app)

# Custom spans
@app.get("/api/campaigns")
async def get_campaigns():
    with tracer.start_as_current_span("fetch_campaigns"):
        # Database query
        with tracer.start_as_current_span("db_query"):
            campaigns = await db.query("SELECT * FROM campaigns")
        
        # External API call
        with tracer.start_as_current_span("openai_api"):
            recommendations = await openai.generate(campaigns)
        
        return {"campaigns": campaigns, "recommendations": recommendations}
```

#### **Vertex AI for AIOps (Custom AI Models)**
- **Service:** Vertex AI + Cloud Functions
- **Purpose:** Custom AI-powered operations automation
- **Use Cases:**
  1. **Predictive Autoscaling:** Train ML model on historical traffic patterns
  2. **Anomaly Detection:** Time-series forecasting for metric anomalies
  3. **Log Analysis:** NLP for automatic root cause analysis
  4. **Capacity Planning:** Forecast resource needs

**Example: Predictive Autoscaling with Vertex AI:**
```python
# train_autoscaling_model.py
from google.cloud import aiplatform
from google.cloud import bigquery
import pandas as pd
from sklearn.ensemble import RandomForestRegressor
import joblib

# Initialize Vertex AI
aiplatform.init(project="PROJECT_ID", location="us-central1")

# Fetch historical metrics from BigQuery
bq_client = bigquery.Client()
query = """
SELECT
  timestamp,
  AVG(cpu_usage) as cpu_usage,
  AVG(memory_usage) as memory_usage,
  COUNT(requests) as request_count,
  EXTRACT(HOUR FROM timestamp) as hour_of_day,
  EXTRACT(DAYOFWEEK FROM timestamp) as day_of_week
FROM
  `marketing_agent_logs.metrics`
WHERE
  timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
GROUP BY
  timestamp
ORDER BY
  timestamp
"""
df = bq_client.query(query).to_dataframe()

# Feature engineering
df['hour_sin'] = np.sin(2 * np.pi * df['hour_of_day'] / 24)
df['hour_cos'] = np.cos(2 * np.pi * df['hour_of_day'] / 24)
df['day_sin'] = np.sin(2 * np.pi * df['day_of_week'] / 7)
df['day_cos'] = np.cos(2 * np.pi * df['day_of_week'] / 7)

# Train model
X = df[['cpu_usage', 'memory_usage', 'hour_sin', 'hour_cos', 'day_sin', 'day_cos']]
y = df['request_count']

model = RandomForestRegressor(n_estimators=100)
model.fit(X, y)

# Export model
joblib.dump(model, 'autoscaling_model.joblib')

# Upload to Vertex AI
model = aiplatform.Model.upload(
    display_name="autoscaling-model",
    artifact_uri="gs://marketing-agent-models/autoscaling_model.joblib",
    serving_container_image_uri="us-docker.pkg.dev/vertex-ai/prediction/sklearn-cpu.1-0:latest"
)
```

**Cloud Function for Automated Scaling:**
```python
# autoscale_function.py
from google.cloud import aiplatform
from google.cloud import container_v1
from google.cloud import monitoring_v3
import datetime

def autoscale_gke(event, context):
    """Predict traffic and scale GKE cluster proactively."""
    
    # Fetch current metrics
    client = monitoring_v3.MetricServiceClient()
    project_name = f"projects/{PROJECT_ID}"
    
    now = datetime.datetime.utcnow()
    interval = monitoring_v3.TimeInterval({
        "end_time": {"seconds": int(now.timestamp())},
        "start_time": {"seconds": int((now - datetime.timedelta(hours=1)).timestamp())},
    })
    
    results = client.list_time_series(
        request={
            "name": project_name,
            "filter": 'metric.type="kubernetes.io/pod/cpu/usage_time"',
            "interval": interval,
        }
    )
    
    # Calculate current load
    current_cpu = sum([point.value.double_value for result in results for point in result.points]) / len(list(results))
    
    # Predict future load (using Vertex AI model)
    endpoint = aiplatform.Endpoint("projects/PROJECT_ID/locations/us-central1/endpoints/ENDPOINT_ID")
    prediction = endpoint.predict(instances=[[current_cpu, hour_of_day, day_of_week]])
    
    predicted_requests = prediction.predictions[0]
    
    # Calculate required nodes
    requests_per_node = 1000
    required_nodes = int(predicted_requests / requests_per_node) + 1
    
    # Scale GKE cluster
    if required_nodes > current_nodes:
        container_client = container_v1.ClusterManagerClient()
        cluster_path = container_client.cluster_path(PROJECT_ID, ZONE, CLUSTER_NAME)
        
        container_client.set_node_pool_size(
            name=f"{cluster_path}/nodePools/primary-node-pool",
            node_count=required_nodes
        )
        
        print(f"Scaled cluster to {required_nodes} nodes (predicted {predicted_requests} requests)")
```

---

### 8. **Security & Compliance**

#### **IAM + Workload Identity**
- **Service:** Cloud IAM with Workload Identity
- **Purpose:** Fine-grained pod-level permissions
- **How Workload Identity Works:**
  1. Map Kubernetes Service Account to Google Service Account
  2. Pods use KSA to automatically get GSA credentials
  3. No service account keys needed
- **Advantages over AWS IRSA:**
  - Simpler setup (no OIDC provider configuration)
  - Better integration with GKE (built-in support)
  - Automatic credential rotation

**Workload Identity Configuration:** (See `gcp.tf` documentation for full example)

#### **Secret Manager**
- **Service:** Google Secret Manager
- **Purpose:** Centralized secret storage
- **Features:**
  - Automatic versioning
  - IAM-based access control
  - Secret rotation (manual or automatic via Cloud Functions)
  - Integration with GKE via External Secrets Operator
- **Cost:**
  - Active secret versions: $0.06/secret/month
  - Access operations: $0.03 per 10,000 operations
  - Example: 10 secrets = $0.60/month (vs $4 AWS Secrets Manager)

#### **Cloud Armor (WAF)**
- **Service:** Google Cloud Armor
- **Purpose:** DDoS protection and WAF
- **Features:**
  - Pre-configured security policies (OWASP Top 10)
  - Rate limiting (per IP, per region)
  - Geo-blocking
  - Bot management (Adaptive Protection)
  - Integration with Cloud Load Balancing
- **Cost:**
  - Policy: $5/policy/month
  - Rules: $1/rule/month
  - Requests: $0.75 per 1 million requests
  - Example: 1 policy, 5 rules, 10M requests = $17.50/month (similar to AWS WAF)

**Cloud Armor Configuration:**
```terraform
# Security policy
resource "google_compute_security_policy" "main" {
  name = "${var.cluster_name}-security-policy"

  # Rate limiting rule
  rule {
    action   = "rate_based_ban"
    priority = 1000

  match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }

    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"

      rate_limit_threshold {
        count        = 1000
        interval_sec = 60
      }

      ban_duration_sec = 600  # 10 minutes
    }

    description = "Rate limit: 1000 requests per minute per IP"
  }

  # OWASP ModSecurity Core Rule Set
  rule {
    action   = "deny(403)"
    priority = 2000

    match {
      expr {
        expression = "evaluatePreconfiguredExpr('xss-stable')"
      }
    }

    description = "Block XSS attacks"
  }

  rule {
    action   = "deny(403)"
    priority = 2001

    match {
      expr {
        expression = "evaluatePreconfiguredExpr('sqli-stable')"
      }
    }

    description = "Block SQL injection attacks"
  }

  # Geo-blocking (optional)
  rule {
    action   = "deny(403)"
    priority = 3000

    match {
      expr {
        expression = "origin.region_code == 'CN' || origin.region_code == 'RU'"
      }
    }

    description = "Block traffic from specific countries"
  }

  # Default rule (allow)
  rule {
    action   = "allow"
    priority = 2147483647  # Lowest priority

    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }

    description = "Default allow rule"
  }
}

# Attach policy to backend service
resource "google_compute_backend_service" "backend" {
  name                  = "marketing-agent-backend"
  protocol              = "HTTP"
  port_name             = "http"
  timeout_sec           = 30
  enable_cdn            = true
  security_policy       = google_compute_security_policy.main.id

  backend {
    group = google_compute_network_endpoint_group.backend.id
  }

  health_checks = [google_compute_health_check.backend.id]
}
```

#### **Security Command Center (Unified Security Dashboard)**
- **Service:** Security Command Center
- **Purpose:** Security and risk management platform
- **Tiers:**
  - Standard: Free (asset discovery, vulnerability reporting)
  - Premium: $0.03/resource/month (threat detection, compliance monitoring)
- **Features:**
  - Asset inventory across all GCP services
  - Security findings and recommendations
  - Compliance reports (PCI-DSS, HIPAA, ISO 27001)
  - Integration with Chronicle SIEM (Google's security analytics)

---

### 9. **Cost Summary - GCP AI/Ops CI/CD Platform**

#### **Staging Environment (GKE Autopilot, Low Traffic)**

| Service | Configuration | Monthly Cost |
|---------|--------------|--------------|
| **GKE Control Plane** | 1 cluster | $73 |
| **GKE Autopilot Pods** | 10 pods (5 vCPU, 10 GB) | $190 |
| **Cloud SQL PostgreSQL** | db-n1-standard-2 HA, 100 GB | $219 |
| **Memorystore Redis** | 5 GB Standard tier | $230 |
| **Cloud Load Balancing** | 1 LB, 5M requests | $25 |
| **Cloud NAT** | 50 GB egress | $23 |
| **Artifact Registry** | 25 GB images | $3 |
| **Cloud Storage** | 100 GB | $2 |
| **Cloud Monitoring** | 100 custom metrics | $26 |
| **Cloud Logging** | 50 GB logs | Free |
| **Cloud Trace** | 3M spans | Free |
| **Cloud Build** | 500 build-minutes | $1.50 |
| **Cloud Deploy** | 3 targets | $88 |
| **Cloud Armor** | 1 policy, 5 rules | $10 |
| **Secret Manager** | 10 secrets | $1 |
| **TOTAL STAGING** | | **~$891/month** |

#### **Production Environment (GKE Standard, High Availability)**

| Service | Configuration | Monthly Cost |
|---------|--------------|--------------|
| **GKE Control Plane** | 1 cluster | $73 |
| **GKE Nodes** | 6 × n2-standard-4 (24 vCPU, 96 GB) | $768 |
| **Cloud SQL PostgreSQL** | db-n1-standard-4 HA, 500 GB | $480 |
| **Memorystore Redis** | 20 GB Standard HA | $920 |
| **Cloud Load Balancing** | 1 LB, 50M requests | $60 |
| **Cloud NAT** | 500 GB egress | $230 |
| **Artifact Registry** | 100 GB images | $10 |
| **Cloud Storage** | 1 TB | $20 |
| **Cloud Monitoring** | 500 custom metrics | $130 |
| **Cloud Logging** | 200 GB logs | $75 |
| **Cloud Trace** | 20M spans | $3.50 |
| **Cloud Build** | 2000 build-minutes | $6 |
| **Cloud Deploy** | 3 targets | $88 |
| **Cloud Armor** | 1 policy, 10 rules | $18 |
| **Security Command Center Premium** | 100 resources | $3 |
| **Secret Manager** | 20 secrets | $1.20 |
| **Datadog (optional)** | 6 hosts, APM, 200 GB logs | $296 |
| **TOTAL PRODUCTION** | | **~$3,181/month** |
| **With Datadog** | | **~$3,477/month** |

#### **Cost Optimization Strategies**

1. **Use GKE Autopilot for Variable Workloads:**
   - Pay only for pod resources (no idle node cost)
   - Savings: 20-40% vs Standard mode
   - **Best for:** Dev/staging environments

2. **Use Preemptible/Spot VMs for Batch Workloads:**
   - 70-80% discount
   - Savings: $500-700/month for production
   - **Best for:** CI/CD runners, data processing jobs

3. **Committed Use Discounts (1/3-year):**
   - 1-year: 37% discount on compute
   - 3-year: 55% discount
   - Savings: $300-500/month for production
   - **Best for:** Stable, predictable workloads

4. **Use Cloud Storage Lifecycle Policies:**
   - Auto-migrate logs to Nearline (50% cheaper) after 30 days
   - Auto-migrate to Coldline (80% cheaper) after 90 days
   - Savings: $50-100/month

5. **BigQuery Flat-Rate Pricing (for heavy log analytics):**
   - $2,000/month for 100 slots (unlimited queries)
   - Savings vs on-demand if > 5 TB scanned/month
   - **Best for:** Large-scale log analytics

6. **Use Cloud CDN:**
   - Cache static assets at edge locations
   - Reduce backend load and egress costs
   - Savings: 40-60% on egress

**Total Optimized Monthly Cost:**
- **Staging:** ~$700/month (22% savings)
- **Production:** ~$2,400/month (25% savings)
- **Annual Savings:** ~$12,000+

---

### 10. **Setup Guide - Local to Production**

#### **Phase 1: Local Development (Same as AWS)**

Follow the same local setup as AWS (Docker Compose, Python/Node.js environment).

#### **Phase 2: GCP Project Setup**

**Step 1: Create GCP Project**
```bash
# Install Google Cloud SDK
# https://cloud.google.com/sdk/docs/install

# Authenticate
gcloud auth login

# Create project
gcloud projects create marketing-agent-prod --name="Marketing Agent"

# Set default project
gcloud config set project marketing-agent-prod

# Enable billing (replace BILLING_ACCOUNT_ID)
gcloud beta billing projects link marketing-agent-prod \
  --billing-account=BILLING_ACCOUNT_ID
```

**Step 2: Enable Required APIs**
```bash
# Enable all required APIs
gcloud services enable \
  container.googleapis.com \
  compute.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  sqladmin.googleapis.com \
  redis.googleapis.com \
  secretmanager.googleapis.com \
  cloudtrace.googleapis.com \
  monitoring.googleapis.com \
  logging.googleapis.com \
  clouddeploy.googleapis.com \
  security commandcenter.googleapis.com \
  binaryauthorization.googleapis.com \
  servicenetworking.googleapis.com
```

**Step 3: Create Terraform Backend**
```bash
# Create GCS bucket for Terraform state
gsutil mb -p marketing-agent-prod -l us-central1 gs://marketing-agent-terraform-state

# Enable versioning
gsutil versioning set on gs://marketing-agent-terraform-state

# Block public access
gsutil iam ch allUsers:legacyObjectReader gs://marketing-agent-terraform-state
```

**Step 4: Configure Workload Identity for GitHub Actions**
```bash
# Create service account for GitHub Actions
gcloud iam service-accounts create github-actions-sa \
  --description="Service account for GitHub Actions" \
  --display-name="GitHub Actions SA"

# Grant permissions
gcloud projects add-iam-policy-binding marketing-agent-prod \
  --member="serviceAccount:github-actions-sa@marketing-agent-prod.iam.gserviceaccount.com" \
  --role="roles/container.developer"

gcloud projects add-iam-policy-binding marketing-agent-prod \
  --member="serviceAccount:github-actions-sa@marketing-agent-prod.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"

# Create Workload Identity Pool
gcloud iam workload-identity-pools create "github-pool" \
  --project="marketing-agent-prod" \
  --location="global" \
  --display-name="GitHub Actions Pool"

# Create Workload Identity Provider
gcloud iam workload-identity-pools providers create-oidc "github-provider" \
  --project="marketing-agent-prod" \
  --location="global" \
  --workload-identity-pool="github-pool" \
  --display-name="GitHub Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
  --issuer-uri="https://token.actions.githubusercontent.com"

# Allow GitHub Actions to impersonate service account
gcloud iam service-accounts add-iam-policy-binding \
  github-actions-sa@marketing-agent-prod.iam.gserviceaccount.com \
  --project="marketing-agent-prod" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/attribute.repository/sudipawtg/marketing-agent"
```

**Get Workload Identity Provider Resource Name:**
```bash
gcloud iam workload-identity-pools providers describe "github-provider" \
  --project="marketing-agent-prod" \
  --location="global" \
  --workload-identity-pool="github-pool" \
  --format="value(name)"

# Output: projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/providers/github-provider
# Add this to GitHub Secrets as GCP_WORKLOAD_IDENTITY_PROVIDER
```

#### **Phase 3: Infrastructure Deployment**

**Step 1: Initialize Terraform**
```bash
cd infrastructure/terraform

# Update backend configuration for GCP
cat > backend.tf <<EOF
terraform {
  backend "gcs" {
    bucket = "marketing-agent-terraform-state"
    prefix = "terraform/state"
  }
}
EOF

# Initialize
terraform init
```

**Step 2: Create terraform.tfvars**
```hcl
# infrastructure/terraform/terraform-gcp.tfvars
cloud_provider = "gcp"
project_id     = "marketing-agent-prod"
region         = "us-central1"
environment    = "staging"
cluster_name   = "marketing-agent-staging"

# GKE configuration
use_autopilot = true  # Set false for Standard mode

# Monitoring
enable_cloud_trace     = true
enable_security_cc_premium = false  # Set true for production

tags = {
  environment = "staging"
  project     = "marketing-agent"
  managed_by  = "terraform"
}
```

**Step 3: Deploy Infrastructure**
```bash
# Plan
terraform plan -var-file=terraform-gcp.tfvars -out=tfplan

# Apply (creates GKE, Cloud SQL, Memorystore, etc.)
terraform apply tfplan

# This takes 15-20 minutes
```

**Step 4: Configure kubectl**
```bash
# Get GKE credentials
gcloud container clusters get-credentials marketing-agent-staging\
  --region=us-central1

# Verify
kubectl get nodes
```

**Step 5: Deploy Kubernetes Resources**
```bash
# Same as AWS setup
kubectl apply -f infrastructure/k8s/base/namespace.yaml
kubectl apply -f infrastructure/k8s/base/rbac.yaml
kubectlapply -f infrastructure/k8s/base/configmap.yaml
kubectl apply -f infrastructure/k8s/base/backend-deployment.yaml
kubectl apply -f infrastructure/k8s/base/frontend-deployment.yaml
kubectl apply -f infrastructure/k8s/base/ingress.yaml

# Check status
kubectl get pods -n marketing-agent -w
```

#### **Phase 4: CI/CD Setup**

**Step 1: Configure GitHub Secrets**

Add these secrets to GitHub repository:
```
GCP_PROJECT_ID: marketing-agent-prod
GCP_WORKLOAD_IDENTITY_PROVIDER: projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/providers/github-provider
GCP_SERVICE_ACCOUNT: github-actions-sa@marketing-agent-prod.iam.gserviceaccount.com
```

**Step 2: Create Cloud Build Trigger**
```bash
# Connect GitHub repository
gcloud beta builds triggers create github \
  --name="backend-ci" \
  --repo-name="marketing-agent" \
  --repo-owner="sudipawtg" \
  --branch-pattern="^main$" \
  --build-config="cloudbuild.yaml"
```

**Step 3: Setup Cloud Deploy**
```bash
# Apply Cloud Deploy configuration
gcloud deploy apply --file=clouddeploy.yaml--region=us-central1

# Create first release
gcloud deploy releases create release-v1-0-0 \
  --delivery-pipeline=marketing-agent-pipeline \
  --region=us-central1 \
  --source=.
```

#### **Phase 5: Monitoring Setup**

**Step 1: Install Cloud Operations Agents**
(Automatic for GKE Autopilot)

**Step 2: Create Dashboards**
```bash
# Import dashboard from JSON
gcloud monitoring dashboards create --config-from-file=infrastructure/monitoring/gcp-dashboard.json
```

**Step 3: Configure Alerts**
```bash
# Apply alert policies via Terraform
terraform apply -target=google_monitoring_alert_policy.high_error_rate
```

---

### 11. **Advantages & Disadvantages of GCP**

#### **✅ Advantages**

1. **GKE Autopilot (Serverless Kubernetes):**
   - No node management (Google manages everything)
   - Pay only for pod resources (no idle capacity waste)
   - Automatic security hardening
   - **Best in class:** No equivalent in AWS or Azure

2. **Superior Developer Experience:**
   - Better UI/UX (Cloud Console is more intuitive)
   - Unified Cloud Operations Suite
   - Better documentation and quickstarts
   - Cloud Shell (built-in IDE in browser)

3. **AI/ML Superiority:**
   - Vertex AI (most advanced ML platform)
   - TensorFlow native integration
   - BigQuery ML (SQL-based machine learning)
   - Better for AI-powered AIOps

4. **Network Performance:**
   - Global VPC (single VPC spans all regions)
   - Premium Tier (Google's private backbone)
   - Lower latency between regions

5. **Open Source Leadership:**
   - Kubernetes originated from Google (Borg)
   - Istio, Knative, gRPC from Google
   - Better open-source compatibility

6. **BigQuery for Log Analytics:**
   - Serverless data warehouse
   - Analyze petabytes of logs with SQL
   - Cheaper than Elasticsearch/Splunk

7. **Simpler Pricing:**
   - Per-second billing (vs per-hour AWS)
   - No Multi-AZ surcharge (included in regional resources)
   - Clearer cost breakdowns

#### **❌ Disadvantages**

1. **Smaller Service Portfolio:**
   - ~100 services vs 200+ AWS
   - Some niche services missing
   - Less mature marketplace

2.**Limited Regions:**
   - 39 regions vs 32 AWS
   - Fewer edge locations

3. **Less Enterprise Adoption:**
   - Smaller market share (10% vs 33% AWS)
   - Fewer third-party integrations
   - Fewer certified professionals

4. **Memorystore Cost:**
   - More expensive than AWS ElastiCache
   - $230/month for 5GB vs $100 AWS
   - No serverless option (yet)

5. **Support Options:**
   - Basic support is limited
   - Standard support: $150/month (flat fee, better than AWS percentage)
   - Enhanced support: $500/month
   - Premium support: Custom pricing

6. **Learning Curve for AWS-Native Teams:**
   - Different terminology (projects vs accounts, VPC vs VNet)
   - Different IAM model
   - Requires retraining

---

### 12. **Migration & Disaster Recovery**

#### **Multi-Cloud Strategy (GCP + AWS)**

Use Terraform workspaces for multi-cloud:
```bash
# Deploy to GCP
terraform workspace select gcp
terraform apply -var="cloud_provider=gcp"

# Deploy to AWS
terraform workspace select aws
terraform apply -var="cloud_provider=aws"
```

#### **Disaster Recovery (GCP)**

**RTO:** < 1 hour  
**RPO:** < 5 minutes

**Backup Strategy:**
1. **Cloud SQL:** Automated backups + point-in-time recovery
2. **GCS:** Object versioning + cross-region replication
3. **Terraform State:** Versioned in GCS

**Failover Procedure:**
```bash
# 1. Restore Cloud SQL from backup
gcloud sql backups restore BACKUP_ID \
  --backup-instance=marketing-agent-postgres

# 2. Update DNS (Cloud DNS)
gcloud dns record-sets update marketing-agent.example.com \
  --type=A \
  --ttl=300 \
  --rrdatas=NEW_LB_IP \
  --zone=marketing-agent-zone

# 3. Scale up DR cluster (if using warm standby)
kubectl scale deployment marketing-agent-backend --replicas=6
```

---

## 📚 Additional Resources

### **GCP Documentation**
- [GKE Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices)
- [Cloud Operations Suite Guide](https://cloud.google.com/stackdriver/docs)
- [Vertex AI Documentation](https://cloud.google.com/vertex-ai/docs)
- [SRE Handbook (Google)](https://sre.google/books/)

### **Terraform GCP Modules**
- [terraform-google-modules/kubernetes-engine](https://github.com/terraform-google-modules/terraform-google-kubernetes-engine)
- [terraform-google-modules/sql-db](https://github.com/terraform-google-modules/terraform-google-sql-db)
- [terraform-google-modules/vpc](https://github.com/terraform-google-modules/terraform-google-network)

---

## 🎯 Next Steps

1. **Deploy to GCP** using provided Terraform configurations
2. **Setup Cloud Deploy** for automated deployments
3. **Enable Security Command Center Premium** for production
4. **Train Vertex AI models** for predictive autoscaling
5. **Integrate BigQuery** for advanced log analytics

**Document Version:** 1.0  
**Last Reviewed:** February 19, 2026  
**Next Review:** May 19, 2026
