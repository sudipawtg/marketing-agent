# IAM Roles and Policies for AWS

# EKS Cluster IAM Role
resource "aws_iam_role" "eks_cluster" {
  count = var.cloud_provider == "aws" ? 1 : 0
  name  = "${var.cluster_name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "${var.cluster_name}-eks-cluster-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  count      = var.cloud_provider == "aws" ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster[0].name
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  count      = var.cloud_provider == "aws" ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster[0].name
}

# EKS Node IAM Role
resource "aws_iam_role" "eks_node" {
  count = var.cloud_provider == "aws" ? 1 : 0
  name  = "${var.cluster_name}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "${var.cluster_name}-eks-node-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  count      = var.cloud_provider == "aws" ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node[0].name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  count      = var.cloud_provider == "aws" ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node[0].name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  count      = var.cloud_provider == "aws" ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node[0].name
}

# CloudWatch Logs Policy for EKS
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
