# ===========================================
# EKS Cluster Security Group (виправлено)
# ===========================================

resource "aws_security_group" "eks_cluster" {
  count = var.create_eks_security_group ? 1 : 0

  name_prefix = "${local.name_prefix}-eks-cluster-"
  description = "Security group for EKS cluster control plane"
  vpc_id      = aws_vpc.main.id

  # Outbound правила (важливо - спочатку egress)
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name    = "${local.name_prefix}-eks-cluster-sg"
    Type    = "security-group"
    Purpose = "eks-cluster"
  })

  depends_on = [aws_vpc.main]

  lifecycle {
    create_before_destroy = true
  }
}

# ===========================================
# EKS Worker Nodes Security Group (виправлено)
# ===========================================

resource "aws_security_group" "eks_nodes" {
  count = var.create_eks_security_group ? 1 : 0

  name_prefix = "${local.name_prefix}-eks-nodes-"
  description = "Security group for EKS worker nodes"
  vpc_id      = aws_vpc.main.id

  # Базові ingress правила (без посилань на інші SG)
  ingress {
    description = "All traffic from other nodes"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "HTTPS for kubectl access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP for health checks"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "NodePort range"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = local.public_subnet_cidrs
  }

  # SSH доступ
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Outbound правила
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name    = "${local.name_prefix}-eks-nodes-sg"
    Type    = "security-group"
    Purpose = "eks-nodes"
  })

  depends_on = [aws_vpc.main]

  lifecycle {
    create_before_destroy = true
  }
}

# ===========================================
# Окремі Security Group Rules (після створення SG)
# ===========================================

# Дозволяємо трафік від worker nodes до cluster
resource "aws_security_group_rule" "cluster_ingress_nodes" {
  count = var.create_eks_security_group ? 1 : 0

  description              = "HTTPS from worker nodes"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_nodes[0].id
  security_group_id        = aws_security_group.eks_cluster[0].id

  depends_on = [aws_security_group.eks_cluster, aws_security_group.eks_nodes]
}

# Дозволяємо трафік від cluster до worker nodes
resource "aws_security_group_rule" "nodes_ingress_cluster" {
  count = var.create_eks_security_group ? 1 : 0

  description              = "All traffic from cluster"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster[0].id
  security_group_id        = aws_security_group.eks_nodes[0].id

  depends_on = [aws_security_group.eks_cluster, aws_security_group.eks_nodes]
}