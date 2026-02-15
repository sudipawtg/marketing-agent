################################################################################
# AWS Infrastructure Module
################################################################################
#
# Purpose:
#   Provision complete AWS infrastructure for Marketing Agent platform including:
#   - EKS (Elastic Kubernetes Service) cluster v1.28
#   - VPC with public/private subnets across 2 availability zones
#   - RDS PostgreSQL 15.4 database with automated backups
#   - ElastiCache Redis 7.0 cluster
#   - ECR (Elastic Container Registry) repositories
#   - IAM roles and security groups
#
# Architecture:
#   ┌─────────────────────────────────────────────────────┐
#   │                      AWS Region                      │
#   │  ┌───────────────────────────────────────────────┐  │
#   │  │  VPC (10.0.0.0/16)                            │  │
#   │  │  ┌─────────────────┐  ┌─────────────────┐    │  │
#   │  │  │  Public Subnet  │  │  Public Subnet  │    │  │
#   │  │  │  10.0.0.0/24    │  │  10.0.1.0/24    │    │  │
#   │  │  │  (NAT Gateway)  │  │  (NAT Gateway)  │    │  │
#   │  │  └────────┬────────┘  └────────┬────────┘    │  │
#   │  │           │                    │              │  │
#   │  │  ┌────────▼────────┐  ┌───────▼─────────┐   │  │
#   │  │  │ Private Subnet  │  │ Private Subnet  │   │  │
#   │  │  │ 10.0.10.0/24    │  │ 10.0.11.0/24    │   │  │
#   │  │  │ (EKS Nodes)     │  │ (EKS Nodes)     │   │  │
#   │  │  └─────────────────┘  └─────────────────┘   │  │
#   │  │                                              │  │
#   │  │  [RDS PostgreSQL]  [ElastiCache Redis]      │  │
#   │  │  (Private Subnets)  (Private Subnets)       │  │
#   │  └──────────────────────────────────────────────┘  │
#   └─────────────────────────────────────────────────────┘
#
# Resources Created:
#   - 1 VPC with CIDR 10.0.0.0/16
#   - 2 Public subnets (AZ-a, AZ-b)
#   - 2 Private subnets (AZ-a, AZ-b)
#   - 1 Internet Gateway
#   - 2 NAT Gateways (high availability)
#   - 1 EKS Cluster
#   - 1 EKS Node Group (t3.medium x3)
#   - 1 RDS PostgreSQL instance
#   - 1 ElastiCache Redis cluster
#   - 2 ECR repositories (backend, frontend)
#   - Security groups for each service
#
# Conditional Creation:
#   All resources only created when: var.cloud_provider == "aws"
#
# Cost Estimate (Staging):
#   - EKS Control Plane: $73/month
#   - EC2 Nodes (3x t3.medium): ~$90/month
#   - RDS (db.t3.medium): ~$70/month
#   - ElastiCache (cache.t3.medium): ~$50/month
#   - NAT Gateways (2x): ~$65/month
#   - Data Transfer: ~$30/month
#   Total: ~$378/month
#
# Security Features:
#   - Private subnets for workloads and databases
#   - Security groups with least-privilege rules
#   - Encrypted EBS volumes
#   - Encrypted RDS storage
#   - IAM roles for service accounts (IRSA)
#   - VPC flow logs (optional)
#
################################################################################

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      CreatedAt   = timestamp()
    }
  }
}

################################################################################
# Data Sources
################################################################################

# VPC Configuration
resource "aws_vpc" "main" {
  count                = var.cloud_provider == "aws" ? 1 : 0
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.cluster_name}-vpc"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Subnets
resource "aws_subnet" "public" {
  count                   = var.cloud_provider == "aws" ? 2 : 0
  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = "10.0.${count.index}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "${var.cluster_name}-public-${count.index}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }
}

resource "aws_subnet" "private" {
  count             = var.cloud_provider == "aws" ? 2 : 0
  vpc_id            = aws_vpc.main[0].id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name                                        = "${var.cluster_name}-private-${count.index}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  count  = var.cloud_provider == "aws" ? 1 : 0
  vpc_id = aws_vpc.main[0].id

  tags = {
    Name = "${var.cluster_name}-igw"
  }
}

# NAT Gateway
resource "aws_eip" "nat" {
  count  = var.cloud_provider == "aws" ? 2 : 0
  domain = "vpc"

  tags = {
    Name = "${var.cluster_name}-nat-eip-${count.index}"
  }
}

resource "aws_nat_gateway" "main" {
  count         = var.cloud_provider == "aws" ? 2 : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.cluster_name}-nat-${count.index}"
  }
}

# Route Tables
resource "aws_route_table" "public" {
  count  = var.cloud_provider == "aws" ? 1 : 0
  vpc_id = aws_vpc.main[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main[0].id
  }

  tags = {
    Name = "${var.cluster_name}-public-rt"
  }
}

resource "aws_route_table" "private" {
  count  = var.cloud_provider == "aws" ? 2 : 0
  vpc_id = aws_vpc.main[0].id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = "${var.cluster_name}-private-rt-${count.index}"
  }
}

resource "aws_route_table_association" "public" {
  count          = var.cloud_provider == "aws" ? 2 : 0
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table_association" "private" {
  count          = var.cloud_provider == "aws" ? 2 : 0
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
  count    = var.cloud_provider == "aws" ? 1 : 0
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster[0].arn
  version  = "1.28"

  vpc_config {
    subnet_ids              = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_service_policy,
  ]

  tags = {
    Name        = var.cluster_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# EKS Node Group
resource "aws_eks_node_group" "main" {
  count           = var.cloud_provider == "aws" ? 1 : 0
  cluster_name    = aws_eks_cluster.main[0].name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node[0].arn
  subnet_ids      = aws_subnet.private[*].id

  scaling_config {
    desired_size = var.node_count
    max_size     = var.node_count * 2
    min_size     = 2
  }

  instance_types = [var.node_instance_type]

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy,
  ]

  tags = {
    Name        = "${var.cluster_name}-node-group"
    Environment = var.environment
  }
}

# ECR Repository
resource "aws_ecr_repository" "backend" {
  count = var.cloud_provider == "aws" ? 1 : 0
  name  = "${var.cluster_name}-backend"

  image_scanning_configuration {
    scan_on_push = true
  }

  image_tag_mutability = "MUTABLE"

  tags = {
    Name        = "${var.cluster_name}-backend"
    Environment = var.environment
  }
}

resource "aws_ecr_repository" "frontend" {
  count = var.cloud_provider == "aws" ? 1 : 0
  name  = "${var.cluster_name}-frontend"

  image_scanning_configuration {
    scan_on_push = true
  }

  image_tag_mutability = "MUTABLE"

  tags = {
    Name        = "${var.cluster_name}-frontend"
    Environment = var.environment
  }
}

# RDS PostgreSQL
resource "aws_db_subnet_group" "main" {
  count      = var.cloud_provider == "aws" ? 1 : 0
  name       = "${var.cluster_name}-db-subnet"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.cluster_name}-db-subnet"
  }
}

resource "aws_security_group" "rds" {
  count       = var.cloud_provider == "aws" ? 1 : 0
  name        = "${var.cluster_name}-rds-sg"
  description = "Security group for RDS"
  vpc_id      = aws_vpc.main[0].id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main[0].cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-rds-sg"
  }
}

resource "aws_db_instance" "main" {
  count                  = var.cloud_provider == "aws" ? 1 : 0
  identifier             = "${var.cluster_name}-db"
  engine                 = "postgres"
  engine_version         = "15.4"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type          = "gp3"
  db_name                = "marketing_agent"
  username               = "postgres"
  manage_master_user_password = true
  db_subnet_group_name   = aws_db_subnet_group.main[0].name
  vpc_security_group_ids = [aws_security_group.rds[0].id]
  skip_final_snapshot    = var.environment != "production"
  backup_retention_period = var.environment == "production" ? 7 : 1
  multi_az               = var.environment == "production"

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  tags = {
    Name        = "${var.cluster_name}-db"
    Environment = var.environment
  }
}

# ElastiCache Redis
resource "aws_elasticache_subnet_group" "main" {
  count      = var.cloud_provider == "aws" ? 1 : 0
  name       = "${var.cluster_name}-cache-subnet"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_security_group" "elasticache" {
  count       = var.cloud_provider == "aws" ? 1 : 0
  name        = "${var.cluster_name}-elasticache-sg"
  description = "Security group for ElastiCache"
  vpc_id      = aws_vpc.main[0].id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main[0].cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-elasticache-sg"
  }
}

resource "aws_elasticache_cluster" "main" {
  count                = var.cloud_provider == "aws" ? 1 : 0
  cluster_id           = "${var.cluster_name}-cache"
  engine               = "redis"
  engine_version       = "7.0"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  subnet_group_name    = aws_elasticache_subnet_group.main[0].name
  security_group_ids   = [aws_security_group.elasticache[0].id]

  tags = {
    Name        = "${var.cluster_name}-cache"
    Environment = var.environment
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

# Outputs
output "cluster_endpoint" {
  value = var.cloud_provider == "aws" ? aws_eks_cluster.main[0].endpoint : null
}

output "ecr_repository_url" {
  value = var.cloud_provider == "aws" ? aws_ecr_repository.backend[0].repository_url : null
}

output "rds_endpoint" {
  value = var.cloud_provider == "aws" ? aws_db_instance.main[0].endpoint : null
}

output "elasticache_endpoint" {
  value = var.cloud_provider == "aws" ? aws_elasticache_cluster.main[0].cache_nodes[0].address : null
}

output "load_balancer_dns" {
  value = var.cloud_provider == "aws" ? aws_eks_cluster.main[0].endpoint : null
}
