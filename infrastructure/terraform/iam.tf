################################################################################
# AWS IAM (Identity and Access Management) CONFIGURATION
################################################################################
#
# PURPOSE:
#   Define IAM roles and policies for AWS resources to securely access
#   AWS services without hardcoded credentials. This implements the principle
#   of least privilege - each resource gets only the permissions it needs.
#
# WHAT IS IAM?
#   AWS Identity and Access Management controls WHO can do WHAT in your AWS account
#   - WHO: Users, roles, services (identity)
#   - WHAT: Actions on resources (permissions)
#
# KEY IAM CONCEPTS:
#
#   IAM Role:
#   - An identity with permissions that can be assumed by AWS services
#   - Like a "costume" that a service wears to get temporary permissions
#   - No permanent credentials (more secure than access keys)
#   - Example: EKS cluster assumes a role to manage EC2 instances
#
#   IAM Policy:
#   - JSON document that defines permissions (allow/deny actions)
#   - Attached to roles, users, or groups
#   - Example: Allow ec2:CreateInstance, Deny s3:DeleteBucket
#
#   Trust Policy (AssumeRole):
#   - Defines WHO can assume a role
#   - Example: Allow eks.amazonaws.com to assume this role
#
#   Managed Policy:
#   - Pre-built policies maintained by AWS (e.g., AmazonEKSClusterPolicy)
#   - Best practice: Use AWS managed policies when available
#   - AWS keeps them updated with new features
#
# IAM IN THIS MODULE:
#   1. EKS Cluster Role: Allows EKS to manage AWS resources
#   2. EKS Node Role: Allows worker nodes to join cluster and pull images
#   3. Pod Execution Role: Allows pods to access AWS services (via IRSA)
#
# SECURITY BEST PRACTICES:
#   ✅ Use IAM roles instead of access keys (no credentials in code)
#   ✅ Follow principle of least privilege (minimal permissions)
#   ✅ Use AWS managed policies when available (maintained by AWS)
#   ✅ Enable CloudTrail (audit all IAM actions)
#   ✅ Use IAM Roles for Service Accounts (IRSA) for pods
#
# LEARNING NOTE:
#   IAM is AWS-specific. Equivalent concepts in other clouds:
#   - GCP: Service Accounts and IAM bindings
#   - Azure: Managed Identities and RBAC
#
################################################################################

################################################################################
# EKS CLUSTER IAM ROLE
################################################################################
#
# PURPOSE:
#   Allows the EKS control plane to manage AWS resources on your behalf
#
# WHAT DOES EKS CONTROL PLANE DO?
#   - Creates/manages Elastic Network Interfaces (ENIs) for pod networking
#   - Writes logs to CloudWatch Logs
#   - Integrates with AWS services (ELB, EBS, etc.)
#   - Manages worker node registration
#
# PERMISSIONS GRANTED:
#   - AmazonEKSClusterPolicy: Core EKS cluster management
#   - AmazonEKSServicePolicy: Legacy policy (still needed for older clusters)
#
# TRUST POLICY:
#   Only eks.amazonaws.com can assume this role
#   No users or other services can use it
#
################################################################################

resource "aws_iam_role" "eks_cluster" {
  count = var.cloud_provider == "aws" ? 1 : 0
  name  = "${var.cluster_name}-eks-cluster-role"

  # ASSUME ROLE POLICY (Trust Policy)
  #
  # WHO CAN ASSUME THIS ROLE?
  # Only the EKS service (eks.amazonaws.com)
  #
  # JSON STRUCTURE:
  # - Version: Policy language version (always "2012-10-17")
  # - Statement: Array of permission statements
  # - Action: sts:AssumeRole = allows assuming this role
  # - Effect: Allow = permit this action
  # - Principal: WHO can do this (eks.amazonaws.com service)
  #
  # ANALOGY:
  # This is like giving EKS service a key to "wear" this role
  # When EKS needs to do something, it assumes this role temporarily
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"  # Only EKS service can assume this
      }
    }]
  })

  tags = {
    Name = "${var.cluster_name}-eks-cluster-role"
  }
}

################################################################################
# ATTACH AWS MANAGED POLICY: AmazonEKSClusterPolicy
################################################################################
#
# WHAT DOES THIS POLICY ALLOW?
#   - Create/manage Elastic Network Interfaces (ENIs)
#   - Discover VPC configuration
#   - Associate security groups with ENIs
#   - Manage load balancers for services
#   - Write cluster logs to CloudWatch
#
# WHY AWS MANAGED POLICY?
#   - Maintained by AWS (updated automatically with new EKS features)
#   - Best practices built-in
#   - No need to write custom JSON policies
#
# POLICY ARN FORMAT:
#   arn:aws:iam::aws:policy/{PolicyName}
#   "aws" = AWS-managed (not account-specific)
#
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  count      = var.cloud_provider == "aws" ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster[0].name
}

################################################################################
# ATTACH AWS MANAGED POLICY: AmazonEKSServicePolicy (Legacy)
################################################################################
#
# NOTE: This policy is deprecated but still required for some EKS features
# AWS recommends attaching it for compatibility with older EKS versions
#
# WHAT IT ALLOWS:
#   - Additional EC2 and ELB permissions
#   - Legacy networking features
#
# FUTURE:
#   Eventually can be removed (AWS is migrating features to AmazonEKSClusterPolicy)
#
resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  count      = var.cloud_provider == "aws" ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster[0].name
}

################################################################################
# EKS NODE IAM ROLE
################################################################################
#
# PURPOSE:
#   Allows EC2 instances (worker nodes) to:
#   - Join the EKS cluster
#   - Pull container images from ECR
#   - Send logs and metrics to CloudWatch
#   - Use EBS volumes for persistent storage
#   - Communicate with EKS control plane
#
# WHO USES THIS ROLE?
#   - EC2 instances in the EKS node group
#   - Not individual pods (they use Pod Execution Role below)
#
# PERMISSIONS GRANTED:
#   - AmazonEKSWorkerNodePolicy: Core node functionality
#   - AmazonEKS_CNI_Policy: Network plugin (VPC CNI)
#   - AmazonEC2ContainerRegistryReadOnly: Pull images from ECR
#   - Custom CloudWatch Logs policy: Write logs
#
################################################################################

resource "aws_iam_role" "eks_node" {
  count = var.cloud_provider == "aws" ? 1 : 0
  name  = "${var.cluster_name}-eks-node-role"

  # ASSUME ROLE POLICY
  #
  # WHO CAN ASSUME THIS ROLE?
  # EC2 instances (ec2.amazonaws.com)
  #
  # HOW IT WORKS:
  # 1. EC2 instance launches with this role attached
  # 2. Instance metadata service provides temporary credentials
  # 3. Applications on instance can use AWS SDK without access keys
  #
  # SECURITY:
  # - Credentials rotate automatically (every few hours)
  # - No long-term access keys stored on disk
  # - If instance is compromised, role can be revoked centrally
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"  # Only EC2 instances can assume this
      }
    }]
  })

  tags = {
    Name = "${var.cluster_name}-eks-node-role"
  }
}

################################################################################
# ATTACH: AmazonEKSWorkerNodePolicy
################################################################################
#
# WHAT THIS ALLOWS:
#   - ec2:DescribeInstances: Discover other nodes in cluster
#   - ec2:DescribeRouteTables: Network routing information
#   - ec2:DescribeSecurityGroups: Security group configuration
#   - ec2:DescribeSubnets: Subnet information for pod networking
#   - ec2:DescribeVolumes: EBS volumes for persistent storage
# # POLICY DOCUMENT (JSON)
  #
  # STRUCTURE:
  # - Version: "2012-10-17" (policy language version, always this)
  # - Statement: Array of permission rules
  #
  # THIS STATEMENT:
  # - Effect: Allow (permit these actions)
  # - Action: List of CloudWatch Logs API operations
  # - Resource: "arn:aws:logs:*:*:*" (all log groups/streams in all regions)
  #
  # RESOURCE ARN BREAKDOWN:
  # arn:aws:logs:{region}:{account-id}:{log-group-name}
  # Using * means apply to all (could be more restrictive in production)
  #
  # PRINCIPLE OF LEAST PRIVILEGE:
  # Production improvement: Restrict to specific log groups
  # Resource = "arn:aws:logs:*:*:log-group:/aws/eks/${var.cluster_name}/*"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",      # Create new log group if doesn't exist
        "logs:CreateLogStream",     # Create new stream within log group
        "logs:PutLogEvents",        # Write actual log messages
  # ASSUME ROLE POLICY FOR IRSA
  #
  # COMPLEX BUT IMPORTANT:
  #
  # Principal.Federated:
  #   OIDC (OpenID Connect) provider created by EKS
  #   Acts as identity broker between Kubernetes and IAM
  #   Format: arn:aws:iam::{account}:oidc-provider/{oidc-issuer-url}
  #
  # Action: sts:AssumeRoleWithWebIdentity
  #   Different from AssumeRole (used for AWS services)
  #   Uses web identity tokens (OIDC JWT tokens)
  #   Kubernetes issues these tokens to pods
  #
  # Condition:
  #   Restricts which pods can assume this role
  #   Only pods using service account "marketing-agent" in namespace "default"
  #
  # HOW TO READ THE CONDITION:
  #   "{oidc-issuer}:sub" = "system:serviceaccount:{namespace}:{serviceaccount}"
  #   "sub" = subject claim in OIDC token (identifies the pod)
  #
  # SECURITY:
  #   Even if attacker gets cluster access, they can only assume this role
  #   if they're running as the specific service account
  #
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        # OIDC provider ARN (federated identity)
        Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(aws_eks_cluster.main[0].identity[0].oidc[0].issuer, "https://", "")}"
      }
      Action = "sts:AssumeRoleWithWebIdentity"  # Assume role using OIDC token
      Condition = {
        StringEquals = {
          # Only allow specific service account
          "${replace(aws_eks_cluster.main[0].identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:default:marketing-agent"
        }
      }
    }]
  })

  tags = {
    Name = "${var.cluster_name}-pod-execution-role"
  }
}

################################################################################
# CUSTOM POLICY: AWS Secrets Manager Access
################################################################################
#
# PURPOSE:
#   Allow pods to retrieve secrets from AWS Secrets Manager
#
# WHAT IS SECRETS MANAGER?
#   Managed service for storing sensitive data (passwords, API keys, certificates)
#   - Automatic rotation (change passwords on schedule)
#   - Audit logging (who accessed what, when)
#   - Encryption at rest (KMS)
#   - Version history (rollback if needed)
#
# WHY USE IT?
#   Instead of storing secrets in:
#   - Code (insecure, visible in Git)
#   - Environment variables (visible in process list)
#   - Kubernetes secrets (base64 encoded, not encrypted at rest by default)
#
# THIS POLICY ALLOWS:
#   - GetSecretValue: Retrieve secret contents
#   - DescribeSecret: Get metadata (not the actual secret)
#
# RESOURCE RESTRICTION:
#   Only secrets with name pattern: {cluster-name}/*
#   Example: marketing-agent-cluster/database-password
#
# COST:
#   - $0.40 per secret per month
#   - $0.05 per 10,000 API calls
#   - Typical app: 5-10 secrets = $2-4/month
#
# USAGE IN CODE:
#   ```python
#   import boto3
#   client = boto3.client('secretsmanager')
#   secret = client.get_secret_value(SecretId='cluster/openai-key')
#   api_key = secret['SecretString']
#   ```
#
# WHAT IS IRSA?
#   - Kubernetes Service Account → IAM Role mapping
#   - Pods assume IAM roles without storing credentials
#   - Each pod can have different permissions (fine-grained access)
#
# HOW IRSA WORKS:
#   1. Create Kubernetes service account (e.g., "marketing-agent")
#   2. Create IAM role with trust policy for that service account
#   3. Annotate K8s service account with IAM role ARN
#   4. Pods using that service account automatically get IAM credentials
#   5. AWS SDK in pod uses these credentials transparently
#
# BENEFITS OVER TRADITIONAL APPROACH:
#   Traditional: All pods on a node share node's IAM role (overly permissive)
#   IRSA: Each pod gets only permissions it needs (least privilege)
#
# EXAMPLE USE CASES:
#   - Backend pods access S3 buckets (store/retrieve files)
#   - Backend pods read secrets from AWS Secrets Manager
#   - Pods send metrics to CloudWatch
#   - Pods access RDS databases via IAM authentication
#
# TRUST POLICY:
#   Only pods using service account "marketing-agent" in namespace "default"
#   can assume this role
#
################################################################################
ach ENIs to instances
#   - ec2:DeleteNetworkInterface: Clean up unused ENIs
#   - ec2:DescribeNetworkInterfaces: List existing ENIs
#   - ec2:ModifyNetworkInterfaceAttribute: Configure ENI settings
#   - ec2:AssignPrivateIpAddresses: Allocate IPs from subnet
#
# WHY NEEDED:
#   Each pod gets a real VPC IP address
#   CNI plugin manages this allocation dynamically
#
# PERFORMANCE BENEFIT:
#   No NAT overhead (pods communicate directly with VPC resources)
#
resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  count      = var.cloud_provider == "aw    # Retrieve secret value
        "secretsmanager:DescribeSecret"     # Get metadata (name, tags, rotation)
      ]
      # RESOURCE RESTRICTION:
      # Only allow access to secrets under this cluster's namespace
      # Pattern: {cluster-name}/*
      # Example: marketing-agent-cluster/openai-api-key
      #
      # WILDCARDS:
      # - *:*:*: Any region, any account (within your account context)
      # - secret:{cluster-name}/*: Secrets starting with cluster name
      Resource = "arn:aws:secretsmanager:*:*:secret:${var.cluster_name}/*"
    }]
  })
}

# ATTACH SECRETS ACCESS POLICY TO POD EXECUTION ROLE
#
# RESULT:
# Pods using the "marketing-agent" service account can now:
# - Read secrets from AWS Secrets Manager
# - Only secrets with the cluster name prefix
# - No need to store secrets in code or env vars
#
resource "aws_iam_role_policy_attachment" "pod_secrets_access" {
  count      = var.cloud_provider == "aws" ? 1 : 0
  policy_arn = aws_iam_policy.secrets_access[0].arn
  role       = aws_iam_role.pod_execution[0].name
}

################################################################################
# DATA SOURCE: Current AWS Account
################################################################################
#
# WHAT IS A DATA SOURCE?
#   Read-only query of existing resources (doesn't create anything)
#
# WHAT THIS PROVIDES:
#   - account_id: Your AWS account ID (12-digit number)
#   - arn: ARN of the current caller
#   - user_id: Unique ID of caller
#
# WHY NEEDED:
#   Used above to construct OIDC provider ARN dynamically
#   Makes this Terraform reusable across different AWS accounts
#
# USAGE:
#   data.aws_caller_identity.current.account_id
#
data "aws_caller_identity" "current" {}

################################################################################
# END OF IAM CONFIGURATION
################################################################################
#
# SUMMARY OF ROLES CREATED:
#   1. eks_cluster_role:
#      - Used by: EKS control plane
#      - Permissions: Manage AWS resources for cluster
#
#   2. eks_node_role:
#      - Used by: EC2 worker nodes
#      - Permissions: Join cluster, pull images, send logs
#
#   3. pod_execution_role:
#      - Used by: Application pods (via IRSA)
#      - Permissions: Access Secrets Manager
#
# SECURITY ARCHITECTURE:
#   ┌─────────────────────────────────────────┐
#   │  EKS Control Plane (eks_cluster_role)   │
#   │  - Manages ENIs, security groups        │
#   │  - Writes cluster logs                  │
#   └─────────────────────────────────────────┘
#                    │
#                    ▼
#   ┌─────────────────────────────────────────┐
#   │  Worker Nodes (eks_node_role)           │
#   │  - Pull images from ECR                 │
#   │  - Send metrics/logs to CloudWatch      │
#   │  - Manage pod networking (VPC CNI)      │
#   └─────────────────────────────────────────┘
#                    │
#                    ▼
#   ┌─────────────────────────────────────────┐
#   │  Pods (pod_execution_role via IRSA)     │
#   │  - Access Secrets Manager               │
#   │  - Fine-grained per-pod permissions     │
#   └─────────────────────────────────────────┘
#
# NEXT STEPS:
#   1. Create Kubernetes service account:
#      kubectl create serviceaccount marketing-agent
#
#   2. Annotate with IAM role:
#      kubectl annotate serviceaccount marketing-agent \
#        eks.amazonaws.com/role-arn=arn:aws:iam::ACCOUNT:role/pod-execution-role
#
#   3. Use in pod spec:
#      spec:
#        serviceAccountName: marketing-agent
#
#   4. Test from pod:
#      aws secretsmanager get-secret-value --secret-id cluster/my-secret
#
# MONITORING:
#   - CloudTrail: Audit all IAM actions (who assumed which role)
#   - IAM Access Analyzer: Identify overly permissive policies
#   - AWS Config: Track IAM role changes over time
#
# BEST PRACTICES:
#   ✅ Use IRSA instead of node roles for pod permissions
#   ✅ Follow principle of least privilege
#   ✅ Use AWS managed policies when available
#   ✅ Restrict resources with ARN patterns
#   ✅ Enable CloudTrail for audit logging
#   - Review and rotate credentials regularly
#   - Use IAM Access Advisor to remove unused permissions
#
################################################################################
# WHY NEEDED:
#   Nodes need to pull (download) container images from ECR
#   Without this, pods can't start
#
# READ-ONLY:
#   Can pull images but can't push (security best practice)
#   Pushing should be done by CI/CD pipelines, not nodes
#
resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  count      = var.cloud_provider == "aws" ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node[0].name
}

################################################################################
# CUSTOM POLICY: CloudWatch Logs
################################################################################
#
# PURPOSE:
#   Allow nodes to send logs to CloudWatch Logs
#
# WHY CUSTOM POLICY?
#   No AWS managed policy for CloudWatch Logs write access
#   We create minimal permissions needed
#
# WHAT THIS ALLOWS:
#   - logs:CreateLogGroup: Create new log groups (e.g., /aws/eks/cluster)
#   - logs:CreateLogStream: Create new log streams (one per pod/container)
#   - logs:PutLogEvents: Send actual log messages
#   - logs:DescribeLogStreams: List existing log streams
#
# WHERE LOGS GO:
#   CloudWatch Logs → Log Group: /aws/eks/{cluster-name}/
#   Each pod creates its own log stream
#
# RETENTION:
#   Default: Never expire (costs add up!)
#   Best practice: Set retention (7-30 days) via CloudWatch Logs settings
#
# COST:
#   - Ingestion: $0.50 per GB
#   - Storage: $0.03 per GB per month
#   - Typical app: 5-10 GB/month = $5-10/month
#
resource "aws_iam_policy" "eks_cloudwatch_logs" {
  count       = var.cloud_provider == "aws" ? 1 : 0
  name        = "${var.cluster_name}-eks-cloudwatch-logs"
  description = "Policy for EKS to push logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ]
      Resource = "arn:aws:logs:*:*:*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cloudwatch_logs" {
  count      = var.cloud_provider == "aws" ? 1 : 0
  policy_arn = aws_iam_policy.eks_cloudwatch_logs[0].arn
  role       = aws_iam_role.eks_node[0].name
}

# Service Account for Kubernetes Pods
resource "aws_iam_role" "pod_execution" {
  count = var.cloud_provider == "aws" ? 1 : 0
  name  = "${var.cluster_name}-pod-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(aws_eks_cluster.main[0].identity[0].oidc[0].issuer, "https://", "")}"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(aws_eks_cluster.main[0].identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:default:marketing-agent"
        }
      }
    }]
  })

  tags = {
    Name = "${var.cluster_name}-pod-execution-role"
  }
}

# Secrets Manager Access
resource "aws_iam_policy" "secrets_access" {
  count       = var.cloud_provider == "aws" ? 1 : 0
  name        = "${var.cluster_name}-secrets-access"
  description = "Policy for accessing secrets manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Resource = "arn:aws:secretsmanager:*:*:secret:${var.cluster_name}/*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "pod_secrets_access" {
  count      = var.cloud_provider == "aws" ? 1 : 0
  policy_arn = aws_iam_policy.secrets_access[0].arn
  role       = aws_iam_role.pod_execution[0].name
}

data "aws_caller_identity" "current" {}
