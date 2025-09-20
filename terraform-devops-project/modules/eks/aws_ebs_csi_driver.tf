# modules/eks/aws_ebs_csi_driver.tf - закоментуйте EKS Addon
# IAM роль для EBS CSI Driver
resource "aws_iam_role" "ebs_csi_driver_role" {
  name = "${var.project_name}-ebs-csi-driver-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud": "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ebs-csi-driver-role"
    Project = var.project_name
  }
}

# Прикріплення політики для EBS CSI Driver
resource "aws_iam_role_policy_attachment" "ebs_csi_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver_role.name
}

# OIDC Provider для EKS
resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = {
    Name = "${var.project_name}-eks-irsa"
    Project = var.project_name
  }
}

# TLS certificate data
data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# ТИМЧАСОВО ЗАКОМЕНТОВАНО - EKS Addon для EBS CSI Driver
# resource "aws_eks_addon" "ebs_csi" {
#   cluster_name             = aws_eks_cluster.main.name
#   addon_name               = "aws-ebs-csi-driver"
#   addon_version            = "v1.24.0-eksbuild.1"
#   service_account_role_arn = aws_iam_role.ebs_csi_driver_role.arn

#   depends_on = [
#     aws_eks_node_group.main
#   ]

#   tags = {
#     Name = "${var.project_name}-ebs-csi-addon"
#     Project = var.project_name
#   }
# }