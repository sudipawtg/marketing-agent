# AWS AI/Ops CI/CD System Design - End-to-End Platform Engineering Solution

## Executive Summary

This document provides a comprehensive system design for implementing a highly scalable, automated AI/OpsContinuous Integration and Continuous Deployment (CI/CD) platform on Amazon Web Services (AWS). The solution leverages AWS-native services, AI-driven operations, and industry best practices for reliability, security, and cost optimization.

**Target Audience:** Platform Engineers, DevOps Engineers, SREs, Cloud Architects  
**Last Updated:** February 2026  
**Current Implementation:** Based on marketing-agent project architecture

---

## 📊 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           AWS AI/Ops CI/CD Platform                                 │
│                                                                                     │
│  ┌──────────────────────────────────────────────────────────────────────────────┐  │
│  │  DEVELOPMENT LAYER                                                           │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │  │
│  │  │   GitHub     │  │ AWS CodeCommit│  │  VS Code    │  │   Docker     │   │  │
│  │  │   Codespaces │  │   (Git)       │  │  Dev Env    │  │   Desktop    │   │  │
│  │  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘   │  │
│  └─────────┼──────────────────┼──────────────────┼──────────────────┼───────────┘  │
│            │                  │                  │                  │              │
│  ┌─────────▼──────────────────▼──────────────────▼──────────────────▼───────────┐  │
│  │  CI LAYER (GitHub Actions + AWS CodeBuild)                                  │  │
│  │  ┌────────────────────────────────────────────────────────────────────────┐ │  │
│  │  │  Workflow Orchestration                                                 │ │  │
│  │  │  • Code Quality (SonarQube/CodeGuru)                                   │ │  │
│  │  │  • Security Scanning (Snyk/Inspector)                                  │ │  │
│  │  │  • Testing (pytest/jest + AWS Device Farm)                             │ │  │
│  │  │  • Build Artifacts (CodeBuild + ECR)                                   │ │  │
│  │  └────────────────────────────────────────────────────────────────────────┘ │  │
│  └─────────┬──────────────────────────────────────────────────────────────────┘  │
│            │                                                                      │
│  ┌─────────▼──────────────────────────────────────────────────────────────────┐  │
│  │  ARTIFACT STORAGE & REGISTRY                                               │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │  │
│  │  │   ECR        │  │   S3 Bucket  │  │  CodeArtifact│  │  Parameter   │  │  │
│  │  │  (Containers)│  │  (Builds)    │  │  (Packages)  │  │   Store      │  │  │
│  │  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │  │
│  └─────────┼──────────────────┼──────────────────┼──────────────────┼─────────┘  │
│            │                  │                  │                  │            │
│  ┌─────────▼──────────────────▼──────────────────▼──────────────────▼─────────┐  │
│  │  CD LAYER (AWS CodePipeline + CodeDeploy + EKS)                            │  │
│  │  ┌────────────────────────────────────────────────────────────────────────┐│  │
│  │  │  Deployment Orchestration                                              ││  │
│  │  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                ││  │
│  │  │  │   Staging    │  │    Canary    │  │  Production  │                ││  │
│  │  │  │  Environment │  │  (10% traffic)│  │  (Blue/Green)│                ││  │
│  │  │  │  - Auto Deploy│→│  - Validation│→│  - Manual    │                ││  │
│  │  │  │  - Integration│  │  - Metrics   │  │    Approval  │                ││  │
│  │  │  │    Tests     │  │  - Rollback  │  │  - Full      │                ││  │
│  │  │  └──────────────┘  └──────────────┘  └──────────────┘                ││  │
│  │  └────────────────────────────────────────────────────────────────────────┘│  │
│  └─────────┬───────────────────────────────────────────────────────────────────┘  │
│            │                                                                      │
│  ┌─────────▼──────────────────────────────────────────────────────────────────┐  │
│  │  INFRASTRUCTURE LAYER (EKS + RDS + ElastiCache + S3)                      │  │
│  │  ┌────────────────────────────────────────────────────────────────────────┐│  │
│  │  │  Amazon EKS Cluster (Kubernetes 1.28)                                  ││  │
│  │  │  ┌──────────────────────────────────────────────────────────────────┐ ││  │
│  │  │  │  Worker Nodes (EC2 Auto Scaling Group)                            │ ││  │
│  │  │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │ ││  │
│  │  │  │  │   Backend   │  │  Frontend   │  │   Workers   │              │ ││  │
│  │  │  │  │   Pods      │  │   Pods      │  │   (Celery)  │              │ ││  │
│  │  │  │  │  (FastAPI)  │  │  (React)    │  │             │              │ ││  │
│  │  │  │  └─────────────┘  └─────────────┘  └─────────────┘              │ ││  │
│  │  │  └──────────────────────────────────────────────────────────────────┘ ││  │
│  │  │  ┌──────────────────────────────────────────────────────────────────┐ ││  │
│  │  │  │  Data Layer                                                       │ ││  │
│  │  │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │ ││  │
│  │  │  │  │  RDS Postgres│ │ ElastiCache │  │     S3      │              │ ││  │
│  │  │  │  │  Multi-AZ    │  │   Redis     │  │  (Storage)  │              │ ││  │
│  │  │  │  │  (Database)  │  │   (Cache)   │  │             │              │ ││  │
│  │  │  │  └─────────────┘  └─────────────┘  └─────────────┘              │ ││  │
│  │  │  └──────────────────────────────────────────────────────────────────┘ ││  │
│  │  └────────────────────────────────────────────────────────────────────────┘│  │
│  └─────────┬───────────────────────────────────────────────────────────────────┘  │
│            │                                                                      │
│  ┌─────────▼──────────────────────────────────────────────────────────────────┐  │
│  │  AI/OPS OBSERVABILITY LAYER                                                │  │
│  │  ┌────────────────────────────────────────────────────────────────────────┐│  │
│  │  │  Monitoring & Alerting                                                 ││  │
│  │  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                ││  │
│  │  │  │  CloudWatch  │  │   X-Ray      │  │  CloudWatch  │                ││  │
│  │  │  │  Metrics     │  │  (Tracing)   │  │  Logs Insights│               ││  │
│  │  │  │  + Alarms    │  │  + Service   │  │  + Anomaly   │                ││  │
│  │  │  │              │  │    Map       │  │    Detection │                ││  │
│  │  │  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘                ││  │
│  │  │         └──────────────────┴──────────────────┘                       ││  │
│  │  │                            │                                           ││  │
│  │  │  ┌─────────────────────────▼─────────────────────────────┐            ││  │
│  │  │  │  Amazon DevOps Guru (AI-Powered Anomaly Detection)    │            ││  │
│  │  │  │  • Automatic issue detection                          │            ││  │
│  │  │  │  • Root cause analysis                                │            ││  │
│  │  │  │  • Operational recommendations                        │            ││  │
│  │  │  │  • Integration with CodeGuru for code quality         │            ││  │
│  │  │  └────────────────────────────────────────────────────────┘            ││  │
│  │  │                                                                         ││  │
│  │  │  ┌────────────────────────────────────────────────────────┐            ││  │
│  │  │  │  Third-Party AI/Ops (Optional)                         │            ││  │
│  │  │  │  • Datadog (APM + Logs + Synthetic Monitoring)         │            ││  │
│  │  │  │  • New Relic (Infrastructure + Application Perf)       │            ││  │
│  │  │  │  • PagerDuty (Incident Management + On-Call)           │            ││  │
│  │  │  └────────────────────────────────────────────────────────┘            ││  │
│  │  └────────────────────────────────────────────────────────────────────────┘│  │
│  └───────────────────────────────────────────────────────────────────────────┘  │
│                                                                                  │
│  ┌──────────────────────────────────────────────────────────────────────────┐  │
│  │  SECURITY & COMPLIANCE LAYER                                             │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐ │  │
│  │  │   IAM +      │  │   Secrets    │  │   AWS WAF    │  │  GuardDuty  │ │  │
│  │  │   IRSA       │  │   Manager    │  │   (Firewall) │  │  (Threat    │ │  │
│  │  │   (Auth)     │  │   (Secrets)  │  │              │  │  Detection) │ │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  └─────────────┘ │  │
│  └──────────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 🏗️ Detailed Service Breakdown

### 1. **Source Control & Collaboration**

#### **Primary: GitHub + GitHub Actions**
- **Service:** GitHub Enterprise Cloud
- **Purpose:** Source code management, CI orchestration, collaboration
- **Why:** 
  - Native integration with AWS (OIDC authentication)
  - Marketplace actions for AWS services
  - Current implementation already uses GitHub Actions
  - Cost-effective (free for open source, included in Enterprise)

#### **Alternative: AWS CodeCommit**
- **Service:** AWS CodeCommit
- **Purpose:** Git repository hosting
- **Advantages:**
  - Fully managed by AWS (no third-party dependency)
  - Integrated with IAM for fine-grained access control
  - Encrypted at rest (KMS) and in transit
  - No cost for first 5 users
- **Disadvantages:**
  - Less feature-rich than GitHub (no Issues, Projects, Discussions)
  - Smaller ecosystem (fewer integrations)
  - Limited pull request review features
- **Cost:** $1/user/month after 5 free users + $0.001/request

**Recommendation:** Continue with GitHub for feature richness, use CodeCommit for sensitive repositories requiring AWS-only access.

---

### 2. **CI Pipeline - Build & Test**

#### **GitHub Actions (Primary CI Orchestration)**
- **Service:** GitHub Actions
- **Purpose:** Workflow automation, test execution, artifact building
- **Configuration:** `.github/workflows/ci.yml`
- **Runners:**
  - GitHub-hosted runners: Ubuntu-latest, macOS, Windows
  - Self-hosted runners on EC2 (for large builds or specific requirements)
  
**Self-Hosted Runners on AWS:**
```terraform
# EC2 Auto Scaling Group for GitHub Actions Runners
resource "aws_autoscaling_group" "github_runners" {
  name                = "github-actions-runners"
  vpc_zone_identifier = aws_subnet.private[*].id
  min_size            = 2
  max_size            = 20
  desired_capacity    = 5

  launch_template {
    id      = aws_launch_template.github_runner.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "GitHubActionsRunner"
    propagate_at_launch = true
  }
}

resource "aws_launch_template" "github_runner" {
  name_prefix   = "github-runner-"
  image_id      = data.aws_ami.ubuntu.id  # Ubuntu 22.04 LTS
  instance_type = "t3.xlarge"  # 4 vCPU, 16 GB RAM

  # User data installs GitHub Actions runner
  user_data = base64encode(templatefile("${path.module}/scripts/install-runner.sh", {
    github_token = var.github_runner_token
    github_org   = var.github_organization
  }))

  iam_instance_profile {
    name = aws_iam_instance_profile.github_runner.name
  }

  vpc_security_group_ids = [aws_security_group.github_runner.id]
}
```

**Cost Optimization:**
- Use GitHub-hosted runners for small builds (2,000 free minutes/month for private repos)
- Self-hosted EC2 runners for:
  - Large builds (reduce minute consumption)
  - Specific tools/dependencies
  - Faster builds (persistent caching)
  - Cost: t3.xlarge = $0.1664/hour × 24 hours × 30 days = $119.81/month per runner (on-demand)
  - Spot instances: 60-70% discount ($47.92/month)

#### **AWS CodeBuild (Alternative/Supplement)**
- **Service:** AWS CodeBuild
- **Purpose:** Scalable build service, runs in parallel
- **Use Cases:**
  - Docker image builds
  - Complex compilation jobs
  - Integration with CodePipeline
- **Advantages:**
  - Pay-per-minute billing (no idle cost)
  - Fully managed (no runner maintenance)
  - Integrated with AWS services (ECR, S3, Secrets Manager)
  - Supports custom build environments (Docker)
- **Disadvantages:**
  - Slower cold start than self-hosted runners
  - Limited to 100 concurrent builds (can request increase)
- **Cost:**
  - build.general1.small (3 GB, 2 vCPU): $0.005/minute
  - build.general1.medium (7 GB, 4 vCPU): $0.01/minute
  - build.general1.large (15 GB, 8 vCPU): $0.02/minute
  - Average build time: 10 minutes
  - Cost per build: $0.05 to $0.20
  - 1,000 builds/month: $50 to $200

**Example CodeBuild Project:**
```yaml
# buildspec.yml
version: 0.2

phases:
  pre_build:
    commands:
      - echo "Logging in to Amazon ECR..."
      - aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY
      - COMMIT_HASH=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)
      - IMAGE_TAG=${COMMIT_HASH:=latest}
  
  build:
    commands:
      - echo "Building Docker image..."
      - docker build -t $ECR_REGISTRY/$IMAGE_REPO_NAME:$IMAGE_TAG -f infrastructure/docker/Dockerfile.backend .
      - docker tag $ECR_REGISTRY/$IMAGE_REPO_NAME:$IMAGE_TAG $ECR_REGISTRY/$IMAGE_REPO_NAME:latest
  
  post_build:
    commands:
      - echo "Pushing Docker image..."
      - docker push $ECR_REGISTRY/$IMAGE_REPO_NAME:$IMAGE_TAG
      - docker push $ECR_REGISTRY/$IMAGE_REPO_NAME:latest
      - echo "Writing image definitions..."
      - printf '[{"name":"backend","imageUri":"%s"}]' $ECR_REGISTRY/$IMAGE_REPO_NAME:$IMAGE_TAG > imagedefinitions.json

artifacts:
  files:
    - imagedefinitions.json
```

---

### 3. **Code Quality & Security Scanning**

#### **Amazon CodeGuru (AI-Powered Code Analysis)**
- **Service:** Amazon CodeGuru Reviewer + CodeGuru Profiler
- **Purpose:** 
  - **Reviewer:** Automated code reviews (security, performance, best practices)
  - **Profiler:** Runtime performance analysis (identify bottlenecks)
- **How It Works:**
  - Integrates with GitHub pull requests
  - Machine learning trained on millions of code reviews
  - Detects: Resource leaks, security vulnerabilities, concurrency issues
- **Cost:**
  - CodeGuru Reviewer: $0.50 per 100 lines of code reviewed
  - CodeGuru Profiler: $0.005/sampling hour
  - Example: 10,000 lines/month = $50/month

**Integration Example:**
```yaml
# .github/workflows/codeguru.yml
name: CodeGuru Review

on:
  pull_request:
    branches: [main]

jobs:
  codeguru:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Full history for accurate analysis
      
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/GitHubActionsRole
          aws-region: us-east-1
      
      - name: CodeGuru Reviewer
        run: |
          aws codeguru-reviewer create-code-review \
            --name "PR-${{ github.event.pull_request.number }}" \
            --repository-association-arn ${{ secrets.CODEGURU_REPO_ARN }} \
            --type PullRequest={PullRequestId="${{ github.event.pull_request.number }}"}
```

#### **AWS Inspector (Container & Lambda Security Scanning)**
- **Service:** Amazon Inspector
- **Purpose:** Automated vulnerability scanning for ECR images and running containers
- **Features:**
  - Continuous scanning (automated on image push)
  - CVE detection (Common Vulnerabilities and Exposures)
  - Risk scoring and prioritization
  - Integration with Security Hub
- **Cost:**
  - ECR scanning: First 30,000 scans/month free, then $0.09/scan
  - EC2 scanning: $0.01/instance/day

**ECR Image Scanning Configuration:**
```terraform
resource "aws_ecr_repository" "backend" {
  name                 = "marketing-agent-backend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true  # Automatic scanning
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.ecr.arn
  }
}

# SNS Topic for vulnerability alerts
resource "aws_sns_topic" "security_alerts" {
  name = "ecr-security-alerts"
}

# EventBridge rule for critical vulnerabilities
resource "aws_cloudwatch_event_rule" "high_severity_vulnerabilities" {
  name        = "high-severity-vulnerabilities"
  description = "Alert on high severity vulnerabilities"

  event_pattern = jsonencode({
    source      = ["aws.inspector2"]
    detail-type = ["Inspector2 Finding"]
    detail = {
      severity = ["HIGH", "CRITICAL"]
    }
  })
}

resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.high_severity_vulnerabilities.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.security_alerts.arn
}
```

#### **Third-Party: Snyk (Comprehensive Security)**
- **Service:** Snyk (SaaS)
- **Purpose:** Dependency vulnerability scanning, license compliance
- **Advantages:**
  - Broader coverage (npm, pip, Maven, Docker, Kubernetes)
  - Developer-friendly (IDE integration, fix suggestions)
  - License compliance checking
- **Cost:** $0 for open source, $98/developer/month for teams
- **Integration:** GitHub Actions marketplace action

---

### 4. **Artifact Storage & Management**

#### **Amazon ECR (Elastic Container Registry)**
- **Service:** Amazon ECR
- **Purpose:** Docker and OCI image storage
- **Features:**
  - Integrated with EKS, ECS, Lambda
  - Image lifecycle policies (auto-delete old images)
  - Cross-region replication
  - Immutable tags (prevent overwrites)
- **Cost:**
  - Storage: $0.10/GB/month
  - Data transfer out: $0.09/GB (to internet), free to EKS in same region
  - Example: 50 images × 500 MB = 25 GB = $2.50/month

**Lifecycle Policy Example:**
```json
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Delete untagged images after 7 days",
      "selection": {
        "tagStatus": "untagged",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 7
      },
      "action": {
        "type": "expire"
      }
    },
    {
      "rulePriority": 2,
      "description": "Keep last 30 tagged images",
      "selection": {
        "tagStatus": "tagged",
        "tagPrefixList": ["v"],
        "countType": "imageCountMoreThan",
        "countNumber": 30
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
```

#### **AWS CodeArtifact (Package Management)**
- **Service:** AWS CodeArtifact
- **Purpose:** NPM, PyPI, Maven artifact repository
- **Use Cases:**
  - Private package hosting
  - Caching public packages (npm, PyPI)
  - Version control for internal libraries
- **Cost:**
  - Storage: $0.05/GB/month
  - Requests: $0.05 per 10,000 requests
  - Example: 5 GB storage + 1M requests/month = $5.25/month

#### **Amazon S3 (Build Artifacts & Static Assets)**
- **Service:** Amazon S3
- **Purpose:**
  - Build logs and artifacts
  - Terraform state (with DynamoDB locking)
  - Static website hosting (frontend builds)
  - Database backups
- **Cost:**
  - Standard storage: $0.023/GB/month
  - Intelligent-Tiering: Auto-move to cheaper tiers
  - Data transfer: Free within same region, $0.09/GB out to internet
  - Example: 100 GB = $2.30/month

**S3 Bucket for CI/CD Artifacts:**
```terraform
resource "aws_s3_bucket" "cicd_artifacts" {
  bucket = "${var.project_name}-cicd-artifacts"

  tags = {
    Purpose = "CI/CD build artifacts and logs"
  }
}

# Versioning for rollback capability
resource "aws_s3_bucket_versioning" "cicd_artifacts" {
  bucket = aws_s3_bucket.cicd_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Lifecycle rules (cost optimization)
resource "aws_s3_bucket_lifecycle_configuration" "cicd_artifacts" {
  bucket = aws_s3_bucket.cicd_artifacts.id

  rule {
    id     = "transition-old-artifacts"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"  # Infrequent Access
    }

    transition {
      days          = 90
      storage_class = "GLACIER"  # Archive
    }

    expiration {
      days = 365  # Delete after 1 year
    }
  }
}

# Encryption at rest
resource "aws_s3_bucket_server_side_encryption_configuration" "cicd_artifacts" {
  bucket = aws_s3_bucket.cicd_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
  }
}
```

---

### 5. **CD Pipeline - Deployment Orchestration**

#### **AWS CodePipeline (Deployment Orchestration)**
- **Service:** AWS CodePipeline
- **Purpose:** Multi-stage deployment pipeline (staging → canary → production)
- **Stages:**
  1. **Source:** GitHub webhook triggers pipeline
  2. **Build:** CodeBuild creates Docker images
  3. **Deploy Staging:** Auto-deploy to EKS staging namespace
  4. **Integration Tests:** Run tests against staging
  5. **Manual Approval:** Team reviews staging
  6. **Deploy Canary:** 10% traffic to new version
  7. **Validation:** Monitor canary metrics (5-30 minutes)
  8. **Deploy Production:** Blue/green deployment
- **Cost:**
  - $1/active pipeline/month
  - Example: 3 pipelines (frontend, backend, infra) = $3/month

**CodePipeline Configuration:**
```terraform
resource "aws_codepipeline" "backend" {
  name     = "marketing-agent-backend-pipeline"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.cicd_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "GitHub_Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = "sudipawtg/marketing-agent"
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build_Docker_Image"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.backend.name
      }
    }
  }

  stage {
    name = "Deploy_Staging"

    action {
      name            = "Deploy_to_EKS_Staging"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"  # Or custom EKS deploy
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ClusterName = aws_eks_cluster.main.name
        ServiceName = "marketing-agent-backend"
        FileName    = "imagedefinitions.json"
      }
    }
  }

  stage {
    name = "Integration_Tests"

    action {
      name            = "Run_Tests"
      category        = "Test"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source_output"]

      configuration = {
        ProjectName = aws_codebuild_project.integration_tests.name
        EnvironmentVariables = jsonencode([
          {
            name  = "TEST_ENVIRONMENT"
            value = "staging"
            type  = "PLAINTEXT"
          }
        ])
      }
    }
  }

  stage {
    name = "Manual_Approval"

    action {
      name     = "Approve_Production_Deploy"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"

      configuration = {
        CustomData = "Review staging deployment before promoting to production"
        NotificationArn = aws_sns_topic.deployment_approvals.arn
      }
    }
  }

  stage {
    name = "Deploy_Production"

    action {
      name            = "Deploy_to_EKS_Production"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"  # Custom deploy action
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ClusterName = aws_eks_cluster.main.name
        ServiceName = "marketing-agent-backend"
        FileName    = "imagedefinitions.json"
      }
    }
  }
}

# SNS topic for approval notifications
resource "aws_sns_topic" "deployment_approvals" {
  name = "deployment-approvals"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.deployment_approvals.arn
  protocol  = "email"
  endpoint  = "devops@example.com"
}
```

#### **AWS CodeDeploy (Blue/Green & Canary Deployments)**
- **Service:** AWS CodeDeploy
- **Purpose:** Automated deployment with traffic shifting
- **Deployment Strategies:**
  1. **Blue/Green:** Deploy to new environment, switch traffic instantly
  2. **Canary:** Gradually shift traffic (10% → 50% → 100%)
  3. **Linear:** Shift traffic in equal increments (10% every 10 minutes)
- **Advantages:**
  - Automatic rollback on CloudWatch alarms
  - Zero-downtime deployments
  - Integrated with EKS, ECS, Lambda, EC2
- **Cost:** Free (pay for underlying resources)

**EKS Blue/Green Deployment:**
```yaml
# infrastructure/k8s/codedeploy/appspec.yaml
version: 0.0
Resources:
  - TargetService:
      Type: AWS::ECS::Service  # Or Kubernetes Service
      Properties:
        TaskDefinition: <TASK_DEFINITION>
        LoadBalancerInfo:
          ContainerName: "backend"
          ContainerPort: 8000
        PlatformVersion: "LATEST"

Hooks:
  - BeforeInstall: "scripts/before_install.sh"
  - AfterInstall: "scripts/after_install.sh"
  - ApplicationStart: "scripts/start_server.sh"
  - ValidateService: "scripts/validate_deployment.sh"
```

**Canary Deployment Configuration:**
```terraform
resource "aws_codedeploy_deployment_config" "canary_10_percent_15_minutes" {
  deployment_config_name = "Canary10Percent15Minutes"
  compute_platform       = "ECS"  # Or Lambda, Server

  traffic_routing_config {
    type = "TimeBasedCanary"

    time_based_canary {
      interval   = 15  # Wait 15 minutes
      percentage = 10  # Start with 10% traffic
    }
  }
}

resource "aws_codedeploy_deployment_group" "backend" {
  app_name               = aws_codedeploy_app.main.name
  deployment_group_name  = "backend-production"
  service_role_arn       = aws_iam_role.codedeploy.arn
  deployment_config_name = aws_codedeploy_deployment_config.canary_10_percent_15_minutes.id

  ecs_service {
    cluster_name = aws_eks_cluster.main.name
    service_name = "marketing-agent-backend"
  }

  blue_green_deployment_config {
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }

    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    green_fleet_provisioning_option {
      action = "COPY_AUTO_SCALING_GROUP"
    }
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.backend.arn]
      }

      target_group {
        name = aws_lb_target_group.backend_blue.name
      }

      target_group {
        name = aws_lb_target_group.backend_green.name
      }
    }
  }

  # Automatic rollback on CloudWatch alarms
  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  }

  alarm_configuration {
    alarms  = [aws_cloudwatch_metric_alarm.backend_error_rate.alarm_name]
    enabled = true
  }
}
```

---

### 6. **Infrastructure Layer - Compute & Data**

#### **Amazon EKS (Elastic Kubernetes Service)**
- **Service:** Amazon EKS
- **Purpose:** Managed Kubernetes cluster for containerized applications
- **Configuration:**
  - Version: 1.28 (latest stable)
  - Control plane: Fully managed by AWS
  - Worker nodes: EC2 Auto Scaling Groups or Fargate
  - Networking: VPC CNI plugin (pods get VPC IPs)
  - Add-ons: CoreDNS, kube-proxy, VPC CNI, EBS CSI driver
- **Cost:**
  - EKS control plane: $0.10/hour = $73/month
  - Worker nodes (EC2): Depends on instance type
  - Fargate: $0.04048/vCPU/hour + $0.004445/GB/hour

**EKS Cluster Terraform:**
```terraform
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.28"

  vpc_config {
    subnet_ids              = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
    endpoint_private_access = true
    endpoint_public_access  = true  # Restrict in production
    public_access_cidrs    = ["0.0.0.0/0"]  # Restrict to office IPs
    security_group_ids      = [aws_security_group.eks_cluster.id]
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  encryption_config {
    provider {
      key_arn = aws_kms_key.eks.arn
    }
    resources = ["secrets"]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_cloudwatch_log_group.eks
  ]
}

# CloudWatch log group for EKS cluster logs
resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 30
}

# EKS Node Group (Managed Worker Nodes)
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = aws_subnet.private[*].id

  # Instance configuration
  instance_types = ["t3.large"]  # 2 vCPU, 8 GB RAM

  scaling_config {
    desired_size = 3
    min_size     = 2
    max_size     = 10
  }

  update_config {
    max_unavailable_percentage = 33  # Allow 1/3 nodes to be unavailable during updates
  }

  # Launch template for custom configuration
  launch_template {
    id      = aws_launch_template.eks_node.id
    version = "$Latest"
  }

  # Ensure proper IAM permissions are in place before creating
  depends_on = [
    aws_iam_role_policy_attachment.eks_node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks_node_AmazonEC2ContainerRegistryReadOnly,
  ]
}

# Launch template for EKS nodes (custom AMI, user data, etc.)
resource "aws_launch_template" "eks_node" {
  name_prefix   = "${var.cluster_name}-node-"
  instance_type = "t3.large"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 50  # GB
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
      kms_key_id            = aws_kms_key.ebs.arn
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"  # Require IMDSv2
    http_put_response_hop_limit = 1
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.cluster_name}-eks-node"
    }
  }
}
```

**Cost Optimization for EKS:**
1. **Use Spot Instances for Non-Critical Workloads:**
   - 70-90% discount vs on-demand
   - Configure node groups with spot instances
   - Use `node.kubernetes.io/instance-type` affinity for scheduling

2. **Right-size Nodes:**
   - t3.large ($0.0832/hour) for general workloads
   - r5.large ($0.126/hour) for memory-intensive (databases)
   - c5.large ($0.085/hour) for CPU-intensive

3. **Cluster Autoscaler:**
   - Automatically scales node groups based on pod resource requests
   - Reduces cost during low traffic periods

4. **Fargate for Batch Jobs:**
   - No idle capacity cost
   - Pay only for running pods
   - Good for ETL jobs, scheduled tasks

**EKS Monthly Cost Estimate (Staging):**
- Control plane: $73
- 3 × t3.large nodes (24/7): 3 × $0.0832/hr × 730 hrs = $182
- Data transfer: ~$20
- EBS volumes: 3 × 50 GB × $0.10/GB = $15
- **Total: ~$290/month**

**EKS Monthly Cost Estimate (Production):**
- Control plane: $73
- 6 × t3.xlarge nodes (4 vCPU, 16 GB): 6 × $0.1664/hr × 730 hrs = $728
- Data transfer: ~$100
- EBS volumes: 6 × 100 GB × $0.10/GB = $60
- Network Load Balancer: $22
- **Total: ~$983/month**

#### **Amazon RDS Multi-AZ (PostgreSQL)**
- **Service:** Amazon RDS for PostgreSQL
- **Purpose:** Managed relational database with automatic backups and failover
- **Configuration:**
  - Engine: PostgreSQL 15.4
  - Instance: db.t3.medium (staging), db.r5.large (production)
  - Multi-AZ: Automatic failover to standby in another AZ
  - Storage: General Purpose SSD (gp3) with autoscaling
  - Backups: Automated daily backups with 7-30 day retention
  - Encryption: At rest (KMS) and in transit (SSL)
- **Cost:**
  - db.t3.medium Multi-AZ: $0.136/hour × 2 = $0.272/hour × 730 hours = $199/month
  - Storage: 100 GB gp3 = $0.115/GB Multi-AZ = $23/month
  - Backup storage: Included up to 100% of DB size
  - **Total staging: ~$222/month**

**RDS Terraform Configuration:**
```terraform
# RDS Subnet Group (private subnets)
resource "aws_db_subnet_group" "main" {
  name       = "${var.cluster_name}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id
 
 tags = {
    Name = "${var.cluster_name}-db-subnet-group"
  }
}

# Security group for RDS
resource "aws_security_group" "rds" {
  name_prefix = "${var.cluster_name}-rds-"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from EKS nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_node.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# RDS PostgreSQL instance
resource "aws_db_instance" "postgres" {
  identifier     = "${var.cluster_name}-postgres"
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = var.environment == "production" ? "db.r5.large" : "db.t3.medium"

  allocated_storage     = 100  # GB
  max_allocated_storage = 1000  # Autoscaling up to 1 TB
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.rds.arn

  db_name  = "marketing_agent"
  username = "postgres"
  password = random_password.db_password.result  # Use Secrets Manager in production

  multi_az               = var.environment == "production" ? true : false
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  backup_retention_period = 30  # Days
  backup_window           = "03:00-04:00"  # UTC
  maintenance_window      = "sun:04:00-sun:05:00"

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  performance_insights_enabled    = true
  performance_insights_retention_period = 7

  deletion_protection = var.environment == "production" ? true : false
  skip_final_snapshot = var.environment == "staging" ? true : false
  final_snapshot_identifier = var.environment == "production" ? "${var.cluster_name}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}" : null

  tags = {
    Name        = "${var.cluster_name}-postgres"
    Environment = var.environment
  }
}

# Random password for database (store in Secrets Manager)
resource "random_password" "db_password" {
  length  = 32
  special = true
}

# Store password in Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name = "${var.cluster_name}/database/password"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = aws_db_instance.postgres.username
    password = random_password.db_password.result
    engine   = "postgres"
    host     = aws_db_instance.postgres.address
    port     = aws_db_instance.postgres.port
    dbname   = aws_db_instance.postgres.db_name
  })
}
```

**RDS Cost Optimization:**
1. **Use Aurora Serverless v2 for Variable Workloads:**
   - Scales from 0.5 to 128 ACUs (Aurora Capacity Units)
   - Pay per second
   - Cost: $0.12 per ACU-hour
   - Good for dev/staging environments

2. **Use Reserved Instances for Production:**
   - 1-year no upfront: 42% discount
   - 3-year all upfront: 62% discount
   - db.r5.large 3-year RI: $0.049/hr (vs $0.24/hr on-demand)

3. **Enable Storage Autoscaling:**
   - Avoid over-provisioning
   - Automatically increases storage when needed

#### **Amazon ElastiCache Multi-AZ (Redis)**
- **Service:** Amazon ElastiCache for Redis
- **Purpose:** In-memory cache, session storage, rate limiting
- **Configuration:**
  - Engine: Redis 7.0
  - Node type: cache.t3.medium (staging), cache.r5.large (production)
  - Cluster mode: Disabled (simple replication)
  - Multi-AZ: Automatic failover
  - Encryption: At rest and in transit
- **Cost:**
  - cache.t3.medium: $0.068/hour × 730 hours = $50/month (primary)
  - Replica (Multi-AZ): +$50/month
 - **Total staging: ~$100/month**

**ElastiCache Terraform:**
```terraform
# ElastiCache subnet group
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.cluster_name}-redis-subnet-group"
  subnet_ids = aws_subnet.private[*].id
}

# Security group for ElastiCache
resource "aws_security_group" "redis" {
  name_prefix = "${var.cluster_name}-redis-"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Redis from EKS nodes"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_node.id]
  }
}

# ElastiCache replication group (Multi-AZ)
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "${var.cluster_name}-redis"
  replication_group_description = "Redis cluster for ${var.cluster_name}"

  engine               = "redis"
  engine_version       = "7.0"
  node_type            = var.environment == "production" ? "cache.r5.large" : "cache.t3.medium"
  num_cache_clusters   = 2  # Primary + 1 replica
  port                 = 6379

  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.redis.id]

  automatic_failover_enabled = true
  multi_az_enabled           = true

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token_enabled         = true
  auth_token                 = random_password.redis_auth_token.result

  snapshot_retention_limit = 7
  snapshot_window          = "03:00-05:00"

  maintenance_window = "sun:05:00-sun:06:00"

  notification_topic_arn = aws_sns_topic.elasticache_alerts.arn

  tags = {
    Name        = "${var.cluster_name}-redis"
    Environment = var.environment
  }
}

resource "random_password" "redis_auth_token" {
  length  = 32
  special = false  # Redis auth token has character restrictions
}
```

---

### 7. **AI/Ops Monitoring & Observability**

#### **Amazon DevOps Guru (AI-Powered Anomaly Detection)**
- **Service:** Amazon DevOps Guru
- **Purpose:** Machine learning-powered operational insights
- **Features:**
  - Automatic baseline learning of normal behavior
  - Anomaly detection (CPU spikes, memory leaks, error rate increases)
  - Root cause analysis with recommendations
  - Integration with CloudWatch, X-Ray, Config
  - Proactive insights (predict issues before they occur)
- **How It Works:**
  1. Analyzes CloudWatch metrics, logs, events, and AWS Config
  2. Builds ML model of normal application behavior
  3. Detects deviations from baseline
  4. Groups related anomalies into insights
  5. Recommends remediation actions (scale up, restart service, etc.)
- **Cost:**
  - $0.0028 per resource per hour
  - Example: 20 resources × $0.0028/hr × 730 hrs = $41/month

**DevOps Guru Configuration:**
```terraform
resource "aws_devopsguru_resource_collection" "main" {
  type = "AWS_SERVICE"

  cloudformation {
    stack_names = [var.cloudformation_stack_name]
  }
}

resource "aws_devopsguru_notification_channel" "sns" {
  sns {
    topic_arn = aws_sns_topic.devopsguru_notifications.arn
  }
}

# SNS topic for DevOps Guru insights
resource "aws_sns_topic" "devopsguru_notifications" {
  name = "${var.cluster_name}-devopsguru-notifications"
}

resource "aws_sns_topic_subscription" "slack" {
  topic_arn = aws_sns_topic.devopsguru_notifications.arn
  protocol  = "https"
  endpoint  = var.slack_webhook_url
}
```

**Example DevOps Guru Insight:**
```json
{
  "id": "insight-12345",
  "severity": "high",
  "status": "ongoing",
  "description": "Elevated error rates and increased latency detected in marketing-agent-backend",
  "recommendedActions": [
    {
      "title": "Scale EKS nodes",
      "description": "CPU utilization exceeded 80% for 15 minutes. Consider scaling from 3 to 5 nodes.",
      "url": "https://console.aws.amazon.com/eks/home?region=us-east-1#/clusters/marketing-agent"
    },
    {
      "title": "Investigate database connection pool",
      "description": "RDS connection count increased by 200%. May indicate connection leak.",
      "url": "https://console.aws.amazon.com/rds/home?region=us-east-1"
    }
  ],
  "relatedAnomalies": [
    {
      "metric": "CPUUtilization",
      "threshold": 80,
      "actual": 95,
      "resource": "eks-node-1"
    },
    {
      "metric": "DatabaseConnections",
      "threshold": 100,
      "actual": 300,
      "resource": "marketing-agent-postgres"
    }
  ]
}
```

#### **Amazon CloudWatch (Metrics, Logs, Alarms)**
- **Service:** Amazon CloudWatch
- **Purpose:** Centralized monitoring and logging
- **Components:**
  - **Metrics:** Time-series data (CPU, memory, custom metrics)
  - **Logs:** Application and infrastructure logs
  - **Alarms:** Automated alerting based on metric thresholds
  - **Dashboards:** Visual monitoring
  - **Insights:** Log query and analysis
  - **Anomaly Detection:** ML-powered threshold detection
  - **Synthetics:** Canary monitoring (uptime checks)
- **Cost:**
  - Metrics: First 10 metrics free, then $0.30/metric/month
  - Logs ingestion: $0.50/GB
  - Logs storage: $0.03/GB/month
  - Alarms: $0.10/alarm/month (first 10 free)
  - Dashboards: $3/dashboard/month
  - Example: 100 metrics, 50 GB logs/month, 20 alarms = $30 + $25 + $2 = $57/month

**CloudWatch Logs for EKS:**
```terraform
# Fluent Bit DaemonSet for log forwarding
resource "kubernetes_daemonset" "fluent_bit" {
  metadata {
    name      = "fluent-bit"
    namespace = "kube-system"
  }

  spec {
    selector {
      match_labels = {
        k8s-app = "fluent-bit"
      }
    }

    template {
      metadata {
        labels = {
          k8s-app = "fluent-bit"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.fluent_bit.metadata[0].name

        container {
          name  = "fluent-bit"
          image = "amazon/aws-for-fluent-bit:2.31.11"

          env {
            name  = "AWS_REGION"
            value = var.aws_region
          }

          env {
            name  = "CLUSTER_NAME"
            value = var.cluster_name
          }

          env {
            name  = "READ_FROM_HEAD"
            value = "On"
          }

          volume_mount {
            name       = "varlog"
            mount_path = "/var/log"
            read_only  = true
          }

          volume_mount {
            name       = "varlibdockercontainers"
            mount_path = "/var/lib/docker/containers"
            read_only  = true
          }

          volume_mount {
            name       = "fluent-bit-config"
            mount_path = "/fluent-bit/etc/"
          }
        }

        volume {
          name = "varlog"
          host_path {
            path = "/var/log"
          }
        }

        volume {
          name = "varlibdockercontainers"
          host_path {
            path = "/var/lib/docker/containers"
          }
        }

        volume {
          name = "fluent-bit-config"
          config_map {
            name = kubernetes_config_map.fluent_bit_config.metadata[0].name
          }
        }
      }
    }
  }
}

# Fluent Bit configuration
resource "kubernetes_config_map" "fluent_bit_config" {
  metadata {
    name      = "fluent-bit-config"
    namespace = "kube-system"
  }

  data = {
    "fluent-bit.conf" = <<EOF
[SERVICE]
    Flush                     5
    Grace                     30
    Log_Level                 info
    Daemon                    off
    Parsers_File              parsers.conf

[INPUT]
    Name                      tail
    Tag                       application.*
    Path                      /var/log/containers/*.log
    Parser                    docker
    DB                        /var/log/flb_kube.db
    Mem_Buf_Limit             50MB
    Skip_Long_Lines           On
    Refresh_Interval          10

[FILTER]
    Name                      kubernetes
    Match                     application.*
    Kube_URL                  https://kubernetes.default.svc:443
    Kube_CA_File              /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    Kube_Token_File           /var/run/secrets/kubernetes.io/serviceaccount/token
    Kube_Tag_Prefix           application.var.log.containers.
    Merge_Log                 On
    Keep_Log                  On
    K8S-Logging.Parser        On
    K8S-Logging.Exclude       On

[OUTPUT]
    Name                      cloudwatch_logs
    Match                     application.*
    region                    ${var.aws_region}
    log_group_name            /aws/eks/${var.cluster_name}/application
    log_stream_prefix         ${var.cluster_name}-
    auto_create_group         true
EOF

    "parsers.conf" = <<EOF
[PARSER]
    Name                      docker
    Format                    json
    Time_Key                  time
    Time_Format               %Y-%m-%dT%H:%M:%S.%LZ
    Time_Keep                 On
EOF
  }
}
```

**CloudWatch Alarms:**
```terraform
# High error rate alarm
resource "aws_cloudwatch_metric_alarm" "backend_error_rate" {
  alarm_name          = "${var.cluster_name}-backend-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "5XXError"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Alert when backend error count exceeds 10 in 5 minutes"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = aws_lb.backend.arn_suffix
  }
}

# High latency alarm
resource "aws_cloudwatch_metric_alarm" "backend_latency" {
  alarm_name          = "${var.cluster_name}-backend-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 2  # 2 seconds
  alarm_description   = "Alert when backend response time exceeds 2 seconds"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = aws_lb.backend.arn_suffix
  }
}

# RDS CPU utilization alarm
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.cluster_name}-rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when RDS CPU exceeds 80%"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.id
  }
}

# Anomaly detection alarm (ML-powered)
resource "aws_cloudwatch_metric_alarm" "api_requests_anomaly" {
  alarm_name          = "${var.cluster_name}-api-requests-anomaly"
  comparison_operator = "LessThanLowerOrGreaterThanUpperThreshold"
  evaluation_periods  = 2
  threshold_metric_id = "e1"
  alarm_description   = "Alert on anomalous API request patterns"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  metric_query {
    id          = "e1"
    expression  = "ANOMALY_DETECTION_BAND(m1)"
    label       = "API Requests (Expected)"
    return_data = true
  }

  metric_query {
    id          = "m1"
    return_data = true

    metric {
      metric_name = "RequestCount"
      namespace   = "AWS/ApplicationELB"
      period      = 300
      stat        = "Sum"

      dimensions = {
        LoadBalancer = aws_lb.backend.arn_suffix
      }
    }
  }
}
```

#### **AWS X-Ray (Distributed Tracing)**
- **Service:** AWS X-Ray
- **Purpose:** End-to-end request tracing across microservices
- **Capabilities:**
  - Trace requests through EKS, Lambda, API Gateway, RDS
  - Identify bottlenecks and latency sources
  - Service map visualization
  - Error and exception tracking
  - Integration with CloudWatch ServiceLens
- **Cost:**
  - First 100,000 traces/month: Free
  - Additional traces: $5 per 1 million
  - Trace storage (30 days): $1 per 1 million

**X-Ray Integration with FastAPI:**
```python
# src/main.py
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.ext.fastapi import XRayMiddleware
from fastapi import FastAPI

app = FastAPI()

# Configure X-Ray
xray_recorder.configure(
    service="marketing-agent-backend",
    sampling=True,
    context_missing="LOG_ERROR",
    daemon_address="xray-daemon.monitoring.svc.cluster.local:2000",
)

# Add X-Ray middleware
app.add_middleware(
    XRayMiddleware,
    recorder=xray_recorder,
    service_name="marketing-agent-backend",
)

@app.get("/api/campaigns")
async def get_campaigns():
    # X-Ray automatically traces this endpoint
    
    # Custom subsegment for database query
    with xray_recorder.capture("database_query"):
        campaigns = await db.query("SELECT * FROM campaigns")
    
    # Custom subsegment for external API call
    with xray_recorder.capture("openai_api_call"):
        recommendations = await openai.generate_recommendations(campaigns)
    
    return {"campaigns": campaigns, "recommendations": recommendations}
```

**X-Ray Daemon DaemonSet:**
```yaml
# infrastructure/k8s/monitoring/xray-daemon.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: xray-daemon
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: xray-daemon
  template:
    metadata:
      labels:
        app: xray-daemon
    spec:
      serviceAccountName: xray-daemon
      containers:
        - name: xray-daemon
          image: public.ecr.aws/xray/aws-xray-daemon:latest
          ports:
            - containerPort: 2000
              protocol: UDP
              name: xray
          resources:
            requests:
              memory: "128Mi"
              cpu: "100m"
            limits:
              memory: "256Mi"
              cpu: "200m"
          env:
            - name: AWS_REGION
              value: us-east-1
---
apiVersion: v1
kind: Service
metadata:
  name: xray-daemon
  namespace: monitoring
spec:
  clusterIP: None  # Headless service
  selector:
    app: xray-daemon
  ports:
    - port: 2000
      protocol: UDP
      targetPort: 2000
```

#### **Third-Party: Datadog (Comprehensive APM)**
- **Service:** Datadog (SaaS)
- **Purpose:** All-in-one monitoring (APM, logs, metrics, synthetics, security)
- **Advantages:**
  - Unified platform (no need for multiple tools)
  - Better visualization than CloudWatch
  - Real user monitoring (RUM)
  - AI-powered anomaly detection
  - Extensive integrations (250+ services)
  - Superior alerting and incident management
- **Disadvantages:**
  - Higher cost than AWS-native solutions
  - Data egress costs (logs sent outside AWS)
  - Vendor lock-in
- **Cost:**
  - Pro plan: $15/host/month
  - APM: $31/host/month
  - Logs: $0.10/GB ingested
  - Example: 5 hosts, APM, 100 GB logs/month = (5 × $46) + $10 = $240/month

**Datadog Agent DaemonSet:**
```yaml
# infrastructure/k8s/monitoring/datadog-agent.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: datadog-agent
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: datadog-agent
  template:
    metadata:
      labels:
        app: datadog-agent
    spec:
      serviceAccountName: datadog-agent
      containers:
        - name: agent
          image: gcr.io/datadoghq/agent:latest
          env:
            - name: DD_API_KEY
              valueFrom:
                secretKeyRef:
                  name: datadog-secret
                  key: api-key
            - name: DD_SITE
              value: "datadoghq.com"
            - name: DD_KUBERNETES_KUBELET_HOST
              valueFrom:
                fieldRef:
                  fieldPath: status.hostIP
            - name: DD_APM_ENABLED
              value: "true"
            - name: DD_LOGS_ENABLED
              value: "true"
            - name: DD_LOGS_CONFIG_CONTAINER_COLLECT_ALL
              value: "true"
            - name: DD_CONTAINER_EXCLUDE
              value: "name:datadog-agent"
          resources:
            requests:
              memory: "256Mi"
              cpu: "200m"
            limits:
              memory: "512Mi"
              cpu: "500m"
          volumeMounts:
            - name: dockersocket
              mountPath: /var/run/docker.sock
            - name: procdir
              mountPath: /host/proc
              readOnly: true
            - name: cgroups
              mountPath: /host/sys/fs/cgroup
              readOnly: true
      volumes:
        - name: dockersocket
          hostPath:
            path: /var/run/docker.sock
        - name: procdir
          hostPath:
            path: /proc
        - name: cgroups
          hostPath:
            path: /sys/fs/cgroup
```

---

### 8. **Security & Compliance**

#### **AWS IAM + IRSA (IAM Roles for Service Accounts)**
- **Service:** AWS IAM with EKS IRSA
- **Purpose:** Fine-grained pod-level permissions without managing credentials
- **How IRSA Works:**
  1. Create IAM role with trust policy for EKS OIDC provider
  2. Associate role with Kubernetes service account
  3. Pods use service account to assume IAM role
  4. AWS SDK automatically fetches temporary credentials
- **Advantages:**
  - No long-lived credentials in pods
  - Automatic credential rotation
  - Pod-level permissions (not node-level)
  - Audit trail in CloudTrail

**IRSA Configuration:** (See detailed setup in `iam.tf` documentation)

#### **AWS Secrets Manager**
- **Service:** AWS Secrets Manager
- **Purpose:** Centralized secret storage with rotation
- **Features:**
  - Automatic rotation for RDS, DocumentDB, Redshift
  - Version management
  - Encryption with KMS
  - Integration with CloudFormation, EKS, Lambda
  - Fine-grained access control (IAM)
- **Cost:**
  - $0.40/secret/month
  - $0.05 per 10,000 API calls
  - Example: 10 secrets, 100K API calls/month = $4 + $0.50 = $4.50/month

**External Secrets Operator (Kubernetes Integration):**
```yaml
# infrastructure/k8s/base/external-secret.yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secretsmanager
  namespace: marketing-agent
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1
      auth:
        jwt:
          serviceAccountRef:
            name: marketing-agent  # Uses IRSA
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: marketing-agent-secrets
  namespace: marketing-agent
spec:
  refreshInterval: 1h  # Sync every hour
  secretStoreRef:
    name: aws-secretsmanager
    kind: SecretStore
  target:
    name: marketing-agent-secrets
    creationPolicy: Owner
  data:
    - secretKey: DATABASE_PASSWORD
      remoteRef:
        key: /marketing-agent/database/password
        property: password
    - secretKey: OPENAI_API_KEY
      remoteRef:
        key: /marketing-agent/openai/api-key
        property: api_key
```

#### **AWS WAF (Web Application Firewall)**
- **Service:** AWS WAF
- **Purpose:** Protect applications from common web exploits (SQL injection, XSS)
- **Features:**
  - Managed rules (OWASP Top 10, bot detection)
  - Custom rules (rate limiting, geo-blocking)
  - Integration with ALB, CloudFront, API Gateway
  - Real-time metrics and logging
- **Cost:**
  - Web ACL: $5/month
  - Rules: $1/rule/month
  - Requests: $0.60 per 1 million
  - Example: 1 ACL, 5 rules, 10M requests = $5 + $5 + $6 = $16/month

**WAF Configuration:**
```terraform
resource "aws_wafv2_web_acl" "main" {
  name  = "${var.cluster_name}-web-acl"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  # Rule 1: Rate limiting (1000 requests per 5 minutes per IP)
  rule {
    name     = "RateLimiting"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 1000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimiting"
      sampled_requests_enabled   = true
    }
  }

  # Rule 2: AWS Managed Rules - Core Rule Set (OWASP Top 10)
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # Rule 3: SQL Injection Protection
  rule {
    name     = "SQLInjectionProtection"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "SQLInjectionProtectionMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.cluster_name}-web-acl"
    sampled_requests_enabled   = true
  }
}

# Associate WAF with Application Load Balancer
resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = aws_lb.backend.arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}
```

#### **Amazon GuardDuty (Threat Detection)**
- **Service:** Amazon GuardDuty
- **Purpose:** Continuous security monitoring and threat detection
- **Detection Types:**
  - Unusual API calls or deployments
  - Compromised instances (crypto mining, C&C communication)
  - Reconnaissance (port scanning, SSH brute force)
  - Account compromise (leaked credentials)
- **Integration:** CloudWatch Events, Security Hub, Lambda for automated response
- **Cost:**
  - CloudTrail events: $4.50 per million events
  - VPC Flow Logs: $1.00 per GB analyzed
  - DNS logs: $0.40 per million queries
  - Example: ~$50/month for medium workload

---

### 9. **Cost Summary - AWS AI/Ops CI/CD Platform**

#### **Staging Environment (3 EKS Nodes, Low Traffic)**

| Service | Configuration | Monthly Cost |
|---------|--------------|--------------|
| **EKS Control Plane** | 1 cluster | $73 |
| **EC2 Instances** | 3 × t3.large (24/7) | $182 |
| **RDS PostgreSQL** | db.t3.medium Multi-AZ, 100 GB | $222 |
| **ElastiCache Redis** | cache.t3.medium Multi-AZ | $100 |
| **Application Load Balancer** | 1 ALB | $22 |
| **NAT Gateways** | 2 × NAT | $65 |
| **ECR Storage** | 25 GB images | $3 |
| **S3 Storage** | 100 GB artifacts/logs | $2 |
| **CloudWatch** | 100 metrics, 50 GB logs | $57 |
| **DevOps Guru** | 20 resources | $41 |
| **CodePipeline** | 3 pipelines | $3 |
| **WAF** | 1 ACL, 5 rules, 5M requests | $11 |
| **Secrets Manager** | 10 secrets | $4 |
| **Data Transfer** | 50 GB egress | $4.50 |
| **TOTAL STAGING** | | **~$790/month** |

#### **Production Environment (6 EKS Nodes, High Availability)**

| Service | Configuration | Monthly Cost |
|---------|--------------|--------------|
| **EKS Control Plane** | 1 cluster | $73 |
| **EC2 Instances** | 6 × t3.xlarge (24/7) | $728 |
| **RDS PostgreSQL** | db.r5.large Multi-AZ, 500 GB, Performance Insights | $450 |
| **ElastiCache Redis** | cache.r5.large Multi-AZ (cluster mode) | $350 |
| **Application Load Balancer** | 1 ALB, high traffic | $40 |
| **Network Load Balancer** | 1 NLB for internal | $22 |
| **NAT Gateways** | 2 × NAT, high traffic | $100 |
| **ECR Storage** | 100 GB images | $10 |
| **S3 Storage** | 1 TB artifacts/logs/backups | $23 |
| **CloudWatch** | 500 metrics, 200 GB logs, dashboards | $200 |
| **X-Ray** | 50M traces/month | $250 |
| **DevOps Guru** | 50 resources | $102 |
| **CodePipeline** | 3 pipelines | $3 |
| **WAF** | 1 ACL, 10 rules, 50M requests | $46 |
| **GuardDuty** | Full threat detection | $50 |
| **Secrets Manager** | 20 secrets, 200K API calls | $9 |
| **Data Transfer** | 500 GB egress | $45 |
| **Route 53** | Hosted zone, health checks | $5 |
| **Backups** | AWS Backup (automated) | $30 |
| **Datadog (optional)** | 6 hosts, APM, 200 GB logs | $296 |
| **TOTAL PRODUCTION** | | **~$2,832/month** |
| **With Datadog** | | **~$3,128/month** |

#### **Cost Optimization Strategies**

1. **Use Spot Instances for Non-Critical Workloads:**
   - 70% discount on EC2 pricing
   - Savings: $500-700/month for production

2. **Reserved Instances (1-year commitment):**
   - 40% discount on EC2 and RDS
   - Savings: $400-600/month for production

3. **Savings Plans (1-year commitment):**
   - Flexible compute savings (EC2, Fargate, Lambda)
   - 40-60% discount
   - Savings: $500-800/month for production

4. **Right-size Resources:**
   - Use Compute Optimizer recommendations
   - Monitor actual usage vs provisioned
   - Potential savings: 20-30%

5. **Use Aurora Serverless for Variable Workloads:**
   - Dev/test environments scale to zero
   - Savings: $100-200/month for staging

6. **Implement Data Lifecycle Policies:**
   - Move logs to S3 Glacier after 90 days
   - Delete old artifacts
   - Savings: $50-100/month

**Total Optimized Monthly Cost:**
- **Staging:** ~$600/month (24% savings)
- **Production:** ~$2,000/month (30% savings)
- **Annual Savings:** ~$10,000+

---

### 10. **Setup Guide - Local to Production**

#### **Phase 1: Local Development Environment**

**Prerequisites:**
- Docker Desktop (with Kubernetes enabled)
- kubectl (1.28+)
- AWS CLI v2
- Terraform (1.5+)
- Python 3.11+
- Node.js 18+

**Step 1: Clone Repository**
```bash
git clone https://github.com/sudipawtg/marketing-agent.git
cd marketing-agent
```

**Step 2: Setup Python Environment**
```bash
# Create virtual environment
python -m venv .venv
source .venv/bin/activate  # Linux/Mac
# OR
.venv\Scripts\activate  # Windows

# Install dependencies
pip install -e ".[dev]"
```

**Step 3: Setup Frontend**
```bash
cd frontend
npm install
```

**Step 4: Local Docker Compose**
```bash
# Start PostgreSQL and Redis locally
docker-compose up -d postgres redis

# Run database migrations
alembic upgrade head

# Seed test data (optional)
python scripts/seed_data.py
```

**Step 5: Run Services Locally**
```bash
# Terminal 1: Backend
uvicorn src.api.main:app --reload --host 0.0.0.0 --port 8000

# Terminal 2: Frontend
cd frontend
npm run dev
```

**Step 6: Access Application**
- Frontend: http://localhost:5173
- Backend API: http://localhost:8000
- API Docs: http://localhost:8000/docs

#### **Phase 2: AWS Account Setup**

**Step 1: AWS Account Preparation**
```bash
# Configure AWS CLI
aws configure
# Enter: Access Key ID, Secret Access Key, Region (us-east-1)

# Verify configuration
aws sts get-caller-identity
```

**Step 2: Create S3 Bucket for Terraform State**
```bash
# Create bucket (replace with unique name)
aws s3 mb s3://marketing-agent-terraform-state --region us-east-1

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
```

**Step 3: Create DynamoDB Table for State Locking**
```bash
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

**Step 4: Create GitHub OIDC Provider (for GitHub Actions)**
```bash
# Get GitHub thumbprint
THUMBPRINT=$(echo | openssl s_client -servername token.actions.githubusercontent.com \
  -connect token.actions.githubusercontent.com:443 2>/dev/null | openssl x509 -fingerprint -noout | \
  sed 's/://g' | sed 's/.*=//')

# Create OIDC provider
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list $THUMBPRINT
```

**Step 5: Create IAM Role for GitHub Actions**
```bash
# Save as github-actions-trust-policy.json
cat > github-actions-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:sudipawtg/marketing-agent:*"
        }
      }
    }
  ]
}
EOF

# Create role
aws iam create-role \
  --role-name GitHubActionsRole \
  --assume-role-policy-document file://github-actions-trust-policy.json

# Attach policies (adjust as needed)
aws iam attach-role-policy \
  --role-name GitHubActionsRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser

aws iam attach-role-policy \
  --role-name GitHubActionsRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy

# Create custom policy for additional permissions
cat > github-actions-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:DescribeCluster",
        "eks:ListClusters",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Resource": "*"
    }
  ]
}
EOF

aws iam create-policy \
  --policy-name GitHubActionsAdditionalPermissions \
  --policy-document file://github-actions-policy.json

aws iam attach-role-policy \
  --role-name GitHubActionsRole \
  --policy-arn arn:aws:iam::YOUR_ACCOUNT_ID:policy/GitHubActionsAdditionalPermissions
```

#### **Phase 3: Infrastructure Deployment**

**Step 1: Initialize Terraform**
```bash
cd infrastructure/terraform

# Initialize (downloads providers)
terraform init

# Validate configuration
terraform validate
```

**Step 2: Create terraform.tfvars**
```hcl
# infrastructure/terraform/terraform.tfvars
cloud_provider = "aws"
aws_region     = "us-east-1"
environment    = "staging"
cluster_name   = "marketing-agent-staging"
node_count     = 3

# Domain configuration
domain_name = "marketing-agent.example.com"

# Monitoring
enable_datadog    = false  # Set true if using Datadog
datadog_api_key   = ""     # If enabled
enable_devops_guru = true

# Tags
tags = {
  Project     = "marketing-agent"
  Environment = "staging"
  Team        = "platform-engineering"
  ManagedBy   = "terraform"
}
```

**Step 3: Plan Infrastructure**
```bash
# Preview changes
terraform plan -out=tfplan

# Review plan carefully
# Estimated cost will be shown
```

**Step 4: Apply Infrastructure**
```bash
# Apply changes (creates all AWS resources)
terraform apply tfplan

# This will take 15-20 minutes
# Resources created:
# - VPC, subnets, NAT gateways
# - EKS cluster and node groups
# - RDS PostgreSQL
# - ElastiCache Redis
# - ECR repositories
# - IAM roles and policies
# - Security groups
# - Load balancers
```

**Step 5: Configure kubectl**
```bash
# Update kubeconfig to access EKS cluster
aws eks update-kubeconfig \
  --name marketing-agent-staging \
  --region us-east-1

# Verify connection
kubectl get nodes
# Should show 3 nodes in Ready state
```

**Step 6: Deploy Kubernetes Resources**
```bash
# Create namespace
kubectl apply -f infrastructure/k8s/base/namespace.yaml

# Create RBAC resources
kubectl apply -f infrastructure/k8s/base/rbac.yaml

# Create ConfigMap and Secrets
kubectl apply -f infrastructure/k8s/base/configmap.yaml

# Deploy databases (if running in K8s instead of RDS)
# For production, use RDS/ElastiCache instead
kubectl apply -f infrastructure/k8s/base/databases.yaml

# Deploy backend
kubectl apply -f infrastructure/k8s/base/backend-deployment.yaml

# Deploy frontend
kubectl apply -f infrastructure/k8s/base/frontend-deployment.yaml

# Deploy ingress
kubectl apply -f infrastructure/k8s/base/ingress.yaml

# Check deployment status
kubectl get pods -n marketing-agent -w
```

#### **Phase 4: CI/CD Pipeline Setup**

**Step 1: Configure GitHub Secrets**

Navigate to GitHub repository → Settings → Secrets and variables → Actions

Add the following secrets:
```
AWS_ACCOUNT_ID: <your-aws-account-id>
AWS_REGION: us-east-1
KUBE_CONFIG_STAGING: <base64-encoded-kubeconfig>
KUBE_CONFIG_PRODUCTION: <base64-encoded-kubeconfig>
SLACK_WEBHOOK_URL: <optional-slack-webhook>
DATADOG_API_KEY: <optional-datadog-key>
```

**Get kubeconfig for GitHub Actions:**
```bash
# Export kubeconfig
kubectl config view --minify --flatten > kubeconfig-staging.yaml

# Base64 encode
cat kubeconfig-staging.yaml | base64 -w 0

# Copy output and add as GitHub secret KUBE_CONFIG_STAGING
```

**Step 2: Verify CI Workflow**
```bash
# Push code to trigger CI
git add .
git commit -m "Initial AWS deployment"
git push origin main

# Check GitHub Actions tab
# CI workflow should run automatically
```

**Step 3: First Deployment**
```bash
# CD workflow triggers automatically on push to main
# Or manually trigger via GitHub Actions UI

# Monitor deployment
kubectl get deployments -n marketing-agent -w

# Check pods
kubectl get pods -n marketing-agent

# View logs
kubectl logs -f deployment/marketing-agent-backend -n marketing-agent
```

**Step 4: Setup DNS**
```bash
# Get load balancer address
kubectl get ingress -n marketing-agent

# Output will show ADDRESS column
# Example: abc123-1234567890.us-east-1.elb.amazonaws.com

# Create Route 53 hosted zone (if not exists)
aws route53 create-hosted-zone \
  --name marketing-agent.example.com \
  --caller-reference $(date +%s)

# Get hosted zone ID
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name \
  --dns-name marketing-agent.example.com \
  --query 'HostedZones[0].Id' --output text)

# Get ALB DNS name
ALB_DNS=$(kubectl get ingress marketing-agent-ingress \
  -n marketing-agent \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Create DNS record
cat > change-batch.json <<EOF
{
  "Changes": [
    {
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "marketing-agent.example.com",
        "Type": "CNAME",
        "TTL": 300,
        "ResourceRecords": [
          {
            "Value": "$ALB_DNS"
          }
        ]
      }
    },
    {
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "api.marketing-agent.example.com",
        "Type": "CNAME",
        "TTL": 300,
        "ResourceRecords": [
          {
            "Value": "$ALB_DNS"
          }
        ]
      }
    }
  ]
}
EOF

aws route53 change-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --change-batch file://change-batch.json
```

**Step 5: SSL Certificate Setup (cert-manager)**
```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml

# Wait for cert-manager to be ready
kubectl wait --for=condition=available --timeout=300s \
  deployment/cert-manager -n cert-manager

# Create ClusterIssuer for Let's Encrypt
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
      - http01:
          ingress:
            class: nginx
EOF

# cert-manager will automatically create certificates
# Check certificate status
kubectl get certificates -n marketing-agent

# Wait for certificate to be issued (may take 1-5 minutes)
kubectl wait --for=condition=ready --timeout=600s \
  certificate/marketing-agent-tls -n marketing-agent
```

#### **Phase 5: Monitoring & AI/Ops Setup**

**Step 1: Deploy CloudWatch Container Insights**
```bash
# Install CloudWatch agent
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluentd-quickstart.yaml

# Verify installation
kubectl get daemonset -n amazon-cloudwatch
```

**Step 2: Deploy X-Ray Daemon**
```bash
kubectl apply -f infrastructure/k8s/monitoring/xray-daemon.yaml

# Verify
kubectl get daemonset xray-daemon -n monitoring
```

**Step 3: Enable DevOps Guru**
```bash
# Enable DevOps Guru for EKS cluster
aws devops-guru update-resource-collection \
  --action ADD \
  --resource-collection '{
    "CloudFormation": {
      "StackNames": ["eksctl-marketing-agent-staging-cluster"]
    }
  }'

# Create SNS topic for notifications
aws sns create-topic --name devopsguru-notifications

# Subscribe email
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:ACCOUNT_ID:devopsguru-notifications \
  --protocol email \
  --notification-endpoint devops@example.com
```

**Step 4: Setup CloudWatch Dashboards**
```bash
# Create custom dashboard
aws cloudwatch put-dashboard \
  --dashboard-name marketing-agent-staging \
  --dashboard-body file://infrastructure/monitoring/cloudwatch-dashboard.json
```

**Step 5: Configure Alarms**
```bash
# Apply alarm configurations
terraform apply -target=aws_cloudwatch_metric_alarm.backend_error_rate
terraform apply -target=aws_cloudwatch_metric_alarm.backend_latency
terraform apply -target=aws_cloudwatch_metric_alarm.rds_cpu
```

#### **Phase 6: Production Deployment**

**Step 1: Create Production Infrastructure**
```bash
# Update terraform.tfvars for production
cat > infrastructure/terraform/terraform-prod.tfvars <<EOF
cloud_provider    = "aws"
aws_region        = "us-east-1"
environment       = "production"
cluster_name      = "marketing-agent-production"
node_count        = 6  # More nodes for production

# Production-specific settings
enable_multi_az   = true
enable_backups    = true
backup_retention  = 30

# Monitoring
enable_datadog     = true
enable_devops_guru = true
EOF

# Plan production infrastructure
terraform plan -var-file=terraform-prod.tfvars -out=tfplan-prod

# Apply (after review)
terraform apply tfplan-prod
```

**Step 2: Deploy to Production via CD Pipeline**
```bash
# Create production tag
git tag -a v1.0.0 -m "First production release"
git push origin v1.0.0

# CD pipeline will automatically:
# 1. Build images
# 2. Deploy to staging
# 3. Run integration tests
# 4. Wait for manual approval
# 5. Deploy to production
```

**Step 3: Verify Production Deployment**
```bash
# Update kubeconfig for production
aws eks update-kubeconfig \
  --name marketing-agent-production \
  --region us-east-1

# Check deployment
kubectl get all -n marketing-agent

# Test endpoints
curl https://marketing-agent.example.com/health
curl https://api.marketing-agent.example.com/health
```

---

### 11. **Advantages & Disadvantages of AWS**

#### **✅ Advantages**

1. **Broadest Service Portfolio:**
   - 200+ services covering compute, storage, ML, IoT, blockchain
   - Most mature ecosystem (since 2006)
   - Best for complex, multi-service architectures

2. **EKS Maturity:**
   - Excellent Kubernetes integration
   - IRSA (IAM Roles for Service Accounts) for security
   - Seamless integration with AWS services (RDS, ElastiCache, S3)

3. **AI/Ops Native Services:**
   - DevOps Guru (ML-powered anomaly detection)
   - CodeGuru (AI code reviews)
   - X-Ray (distributed tracing)
   - CloudWatch Anomaly Detection

4. **Global Infrastructure:**
   - 32 regions (more than any cloud provider)
   - 102 availability zones
   - Best for global deployments

5. **Cost Optimization Tools:**
   - Savings Plans (flexible compute discounts)
   - Spot Instances (up to 90% discount)
   - Cost Explorer and Budgets
   - Compute Optimizer (ML-powered sizing recommendations)

6. **Security & Compliance:**
   - Most compliance certifications (90+)
   - GuardDuty (threat detection)
   - Security Hub (unified security view)
   - AWS Config (compliance auditing)

7. **Strong GitHub Integration:**
   - GitHub Actions OIDC provider
   - CodeStar connections
   - Native CI/CD with CodePipeline/CodeBuild

#### **❌ Disadvantages**

1. **Complexity:**
   - Steep learning curve (200+ services)
   - IAM policies can be complex
   - Networking (VPC, subnets, route tables) requires expertise

2. **Cost Management:**
   - Easy to overspend without proper monitoring
   - Complex pricing (per-service, per-region variations)
   - Data transfer costs can be high

3. **Opinionated Architecture:**
   - Best practices encourage AWS-specific patterns
   - Harder to migrate to other clouds
   - Vendor lock-in risk

4. **Service Inconsistency:**
   - UI/UX varies across services
   - API design inconsistencies
   - Some services lag behind competitors (e.g., GKE vs EKS multi-cluster)

5. **Support Cost:**
   - Basic support is limited
   - Business support: $100/month minimum (or 10% of AWS spend)
   - Enterprise support: $15,000/month minimum

6. **Regional Availability:**
   - Newest services often US-only initially
   - Feature parity gaps between regions

---

### 12. **Migration Path & Disaster Recovery**

#### **Blue/Green Deployment Strategy**

```terraform
# infrastructure/terraform/blue-green.tf

# Blue environment (current production)
resource "aws_lb_target_group" "blue" {
  name     = "${var.cluster_name}-blue"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Green environment (new version)
resource "aws_lb_target_group" "green" {
  name     = "${var.cluster_name}-green"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Listener rule (switches between blue and green)
resource "aws_lb_listener_rule" "main" {
  listener_arn = aws_lb_listener.frontend.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = var.active_environment == "blue" ? aws_lb_target_group.blue.arn : aws_lb_target_group.green.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}
```

#### **Disaster Recovery Plan**

**RTO (Recovery Time Objective):** < 1 hour  
**RPO (Recovery Point Objective):** < 5 minutes

**Backup Strategy:**
1. **Database (RDS):**
   - Automated daily backups (30-day retention)
   - Transaction logs backed up every 5 minutes
   - Multi-AZ for immediate failover

2. **Application State:**
   - S3 versioning enabled
   - Cross-region replication to us-west-2

3. **Infrastructure as Code:**
   - Terraform state in S3 with versioning
   - All infrastructure reproducible

**Failover Procedure:**
```bash
# 1. Verify backup availability
aws rds describe-db-snapshots \
  --db-instance-identifier marketing-agent-production

# 2. Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier marketing-agent-production-restored \
  --db-snapshot-identifier rds:marketing-agent-production-2026-02-19-03-00

# 3. Update Route 53 to point to DR region
aws route53 change-resource-record-sets \
  --hosted-zone-id Z123456 \
  --change-batch file://failover-change-batch.json

# 4. Scale up DR environment (if using warm standby)
terraform apply -var="environment=dr" -var="node_count=6"
```

---

## 📚 Additional Resources

### **AWS Documentation**
- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [DevOps Guru User Guide](https://docs.aws.amazon.com/devops-guru/)
- [CloudWatch Container Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContainerInsights.html)

### **Terraform AWS Modules**
- [terraform-aws-modules/eks](https://github.com/terraform-aws-modules/terraform-aws-eks)
- [terraform-aws-modules/rds](https://github.com/terraform-aws-modules/terraform-aws-rds)
- [terraform-aws-modules/vpc](https://github.com/terraform-aws-modules/terraform-aws-vpc)

### **GitHub Actions**
- [configure-aws-credentials](https://github.com/aws-actions/configure-aws-credentials)
- [amazon-eks-action](https://github.com/aws-actions/amazon-eks-tools)

---

## 🎯 Next Steps

1. **Implement this design** using the Terraform configurations provided
2. **Review security** with your security team (IAM policies, network rules)
3. **Set up monitoring** with CloudWatch/DevOps Guru/Datadog
4. **Run load tests** to validate scaling behavior
5. **Document runbooks** for common operational tasks
6. **Train team** on AWS services and CI/CD workflows

**Questions or need clarification on specific components?** Refer to the inline comments in the Terraform files or reach out to the Platform Engineering team.

---

**Document Version:** 1.0  
**Last Reviewed:** February 19, 2026  
**Next Review:** May 19, 2026
