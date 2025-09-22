# ===========================================
# EKS EBS CSI Driver Configuration
# ===========================================

# ===========================================
# IAM Role for EBS CSI Driver
# ===========================================

data "aws_iam_policy_document" "ebs_csi_trust_policy" {
  statement {
    effect = "Allow"
    
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }
    
    actions = ["sts:AssumeRoleWithWebIdentity"]
    
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }
    
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ebs_csi_driver_role" {
  name               = "${local.name_prefix}-ebs-csi-driver-role"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_trust_policy.json
  
  tags = merge(var.tags, {
    Name = "${local.name_prefix}-ebs-csi-driver-role"
    Type = "iam-role"
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver_role.name
}

# ===========================================
# OIDC Identity Provider для EKS
# ===========================================

data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
  
  tags = merge(var.tags, {
    Name = "${local.name_prefix}-eks-oidc"
    Type = "oidc-provider"
  })
}

# ===========================================
# EBS CSI Driver Addon
# ===========================================

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = var.ebs_csi_addon_version
  service_account_role_arn = aws_iam_role.ebs_csi_driver_role.arn
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
  
  tags = merge(var.tags, {
    Name = "${local.cluster_name}-ebs-csi-driver"
    Type = "eks-addon"
  })
  
  depends_on = [
    aws_eks_node_group.main,
    aws_iam_role_policy_attachment.ebs_csi_driver_policy,
    aws_iam_openid_connect_provider.eks
  ]
}