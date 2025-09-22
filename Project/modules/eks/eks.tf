# ===========================================
# EKS Module - Kubernetes Cluster
# ===========================================

# Локальні змінні
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  # EKS cluster name (має бути унікальним)
  cluster_name = "${local.name_prefix}-cluster"
  
  # Node group name
  node_group_name = "${local.name_prefix}-nodes"
}

# ===========================================
# IAM Role для EKS Cluster
# ===========================================

resource "aws_iam_role" "eks_cluster_role" {
  name = "${local.name_prefix}-eks-cluster-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
  
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# ===========================================
# IAM Role для EKS Node Group
# ===========================================

resource "aws_iam_role" "eks_node_role" {
  name = "${local.name_prefix}-eks-node-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

# Додаткові права для CSI driver
resource "aws_iam_role_policy_attachment" "eks_ebs_csi_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.eks_node_role.name
}

# ===========================================
# EKS Cluster
# ===========================================

resource "aws_eks_cluster" "main" {
  name     = local.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.kubernetes_version
  
  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.endpoint_public_access ? var.public_access_cidrs : []
    
    security_group_ids = var.cluster_security_group_ids
  }
  
  # Налаштування логування
  enabled_cluster_log_types = var.cluster_log_types
  
  # Шифрування secrets (тільки якщо вказано KMS ключ)
  dynamic "encryption_config" {
    for_each = var.kms_key_arn != null ? [1] : []
    content {
      provider {
        key_arn = var.kms_key_arn
      }
      resources = ["secrets"]
    }
  }
  
  tags = merge(var.tags, {
    Name = local.cluster_name
    Type = "eks-cluster"
  })
  
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

# ===========================================
# EKS Node Group
# ===========================================

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = local.node_group_name
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = var.private_subnet_ids
  
  # Instance налаштування
  instance_types = var.node_instance_types
  ami_type      = var.node_ami_type
  capacity_type = var.node_capacity_type
  disk_size     = var.node_disk_size
  
  # Scaling configuration
  scaling_config {
    desired_size = var.node_desired_capacity
    max_size     = var.node_max_capacity
    min_size     = var.node_min_capacity
  }
  
  # Update configuration
  update_config {
    max_unavailable_percentage = 25
  }
  
  
  # Labels для nodes
  labels = {
    Environment = var.environment
    Project     = var.project_name
    NodeGroup   = "primary"
  }
  
  # Taints (опціонально)
  dynamic "taint" {
    for_each = var.node_taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }
  
  tags = merge(var.tags, {
    Name = local.node_group_name
    Type = "eks-node-group"
  })
  
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy,
    aws_iam_role_policy_attachment.eks_ebs_csi_policy
  ]
}

# ===========================================
# EKS Addons
# ===========================================

# VPC CNI Addon
resource "aws_eks_addon" "vpc_cni" {
  cluster_name      = aws_eks_cluster.main.name
  addon_name        = "vpc-cni"
  addon_version     = var.vpc_cni_addon_version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
  
  tags = merge(var.tags, {
    Name = "${local.cluster_name}-vpc-cni"
    Type = "eks-addon"
  })
  
  depends_on = [aws_eks_node_group.main]
}

# CoreDNS Addon
resource "aws_eks_addon" "coredns" {
  cluster_name      = aws_eks_cluster.main.name
  addon_name        = "coredns"
  addon_version     = var.coredns_addon_version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
  
  tags = merge(var.tags, {
    Name = "${local.cluster_name}-coredns"
    Type = "eks-addon"
  })
  
  depends_on = [aws_eks_node_group.main]
}

# Kube-proxy Addon
resource "aws_eks_addon" "kube_proxy" {
  cluster_name      = aws_eks_cluster.main.name
  addon_name        = "kube-proxy"
  addon_version     = var.kube_proxy_addon_version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
  
  tags = merge(var.tags, {
    Name = "${local.cluster_name}-kube-proxy"
    Type = "eks-addon"
  })
  
  depends_on = [aws_eks_node_group.main]
}

# ===========================================
# Data sources
# ===========================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}