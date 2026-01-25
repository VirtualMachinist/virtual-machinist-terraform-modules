# =============================================================================
# AWS FORGE + ARMORY - Testing & Deployment Environment
# Full Stack Virtual Machinist
# 
# CERT ALIGNMENT:
# - AWS Solutions Architect Pro: VPC, multi-AZ, DR, cost optimization, EKS
# - AWS AI Practitioner: Bedrock, SageMaker foundations
# - CKA/CKAD/CKS: EKS cluster, workloads, RBAC, network policies
# - Terraform Associate: Module composition, data sources, depends_on
# =============================================================================

locals {
  environment = "forge-armory"
  
  tags = merge(var.tags, {
    Environment = local.environment
    ManagedBy   = "terraform"
    Project     = "virtual-machinist"
  })

  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# -----------------------------------------------------------------------------
# NETWORKING (AWS SA Pro: VPC design, multi-AZ, subnets)
# -----------------------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.tags, {
    Name = "${var.environment_name}-vpc"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.tags, {
    Name = "${var.environment_name}-igw"
  })
}

# Public Subnets (multi-AZ for high availability)
resource "aws_subnet" "public" {
  count             = length(local.azs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone = local.azs[count.index]

  map_public_ip_on_launch = true

  tags = merge(local.tags, {
    Name                                           = "${var.environment_name}-public-${local.azs[count.index]}"
    "kubernetes.io/role/elb"                       = "1"
    "kubernetes.io/cluster/${var.environment_name}" = "shared"
  })
}

# Private Subnets (for EKS nodes, RDS, etc.)
resource "aws_subnet" "private" {
  count             = length(local.azs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + length(local.azs))
  availability_zone = local.azs[count.index]

  tags = merge(local.tags, {
    Name                                           = "${var.environment_name}-private-${local.azs[count.index]}"
    "kubernetes.io/role/internal-elb"              = "1"
    "kubernetes.io/cluster/${var.environment_name}" = "shared"
  })
}

# NAT Gateway (one per AZ for HA - AWS SA Pro: cost vs availability tradeoff)
resource "aws_eip" "nat" {
  count  = var.single_nat_gateway ? 1 : length(local.azs)
  domain = "vpc"

  tags = merge(local.tags, {
    Name = "${var.environment_name}-nat-eip-${count.index}"
  })

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count         = var.single_nat_gateway ? 1 : length(local.azs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(local.tags, {
    Name = "${var.environment_name}-nat-${count.index}"
  })

  depends_on = [aws_internet_gateway.main]
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.tags, {
    Name = "${var.environment_name}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  count          = length(local.azs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count  = var.single_nat_gateway ? 1 : length(local.azs)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = merge(local.tags, {
    Name = "${var.environment_name}-private-rt-${count.index}"
  })
}

resource "aws_route_table_association" "private" {
  count          = length(local.azs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[var.single_nat_gateway ? 0 : count.index].id
}

# -----------------------------------------------------------------------------
# EKS CLUSTER (CKA/CKAD/CKS + AWS SA Pro)
# -----------------------------------------------------------------------------

resource "aws_eks_cluster" "main" {
  name     = var.environment_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.eks_version

  vpc_config {
    subnet_ids              = aws_subnet.private[*].id
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = var.eks_public_access_cidrs
    security_group_ids      = [aws_security_group.eks_cluster.id]
  }

  # Enable logging (AWS SA Pro: observability)
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # Encryption (CKS: security)
  encryption_config {
    provider {
      key_arn = var.eks_encryption_key_arn != null ? var.eks_encryption_key_arn : aws_kms_key.eks[0].arn
    }
    resources = ["secrets"]
  }

  tags = local.tags

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller,
  ]
}

# EKS KMS Key for secrets encryption
resource "aws_kms_key" "eks" {
  count                   = var.eks_encryption_key_arn == null ? 1 : 0
  description             = "EKS Secret Encryption Key for ${var.environment_name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = local.tags
}

# EKS Cluster IAM Role
resource "aws_iam_role" "eks_cluster" {
  name = "${var.environment_name}-eks-cluster-role"

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

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster.name
}

# EKS Security Group
resource "aws_security_group" "eks_cluster" {
  name        = "${var.environment_name}-eks-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${var.environment_name}-eks-cluster-sg"
  })
}

# EKS Managed Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.environment_name}-nodes"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = aws_subnet.private[*].id

  scaling_config {
    desired_size = var.eks_node_desired_size
    max_size     = var.eks_node_max_size
    min_size     = var.eks_node_min_size
  }

  instance_types = var.eks_node_instance_types
  capacity_type  = var.eks_node_capacity_type

  update_config {
    max_unavailable = 1
  }

  labels = {
    Environment = local.environment
  }

  tags = local.tags

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry,
  ]
}

# EKS Node IAM Role
resource "aws_iam_role" "eks_nodes" {
  name = "${var.environment_name}-eks-nodes-role"

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

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}

# OIDC Provider for IRSA (AWS SA Pro + CKS: secure pod authentication)
data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = local.tags
}

# -----------------------------------------------------------------------------
# ECR (Container Registry)
# -----------------------------------------------------------------------------

resource "aws_ecr_repository" "main" {
  name                 = "${var.environment_name}-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = local.tags
}

resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 30 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 30
      }
      action = {
        type = "expire"
      }
    }]
  })
}

# -----------------------------------------------------------------------------
# BEDROCK ACCESS (AWS AI Practitioner)
# -----------------------------------------------------------------------------

resource "aws_iam_policy" "bedrock_access" {
  count       = var.enable_bedrock ? 1 : 0
  name        = "${var.environment_name}-bedrock-access"
  description = "Policy for accessing Amazon Bedrock"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream",
          "bedrock:ListFoundationModels",
          "bedrock:GetFoundationModel"
        ]
        Resource = "*"
      }
    ]
  })

  tags = local.tags
}

# IRSA role for Bedrock access from EKS
resource "aws_iam_role" "bedrock_irsa" {
  count = var.enable_bedrock ? 1 : 0
  name  = "${var.environment_name}-bedrock-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:${var.k8s_namespace}:${var.k8s_service_account}"
          "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "bedrock_irsa" {
  count      = var.enable_bedrock ? 1 : 0
  policy_arn = aws_iam_policy.bedrock_access[0].arn
  role       = aws_iam_role.bedrock_irsa[0].name
}

# -----------------------------------------------------------------------------
# SECRETS MANAGER
# -----------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "app_secrets" {
  for_each = toset(var.secret_names)
  name     = "${var.environment_name}/${each.key}"

  tags = local.tags
}