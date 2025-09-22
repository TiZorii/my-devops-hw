# ===========================================
# EKS Module - Outputs
# ===========================================

# ===========================================
# Cluster Information
# ===========================================

output "cluster_id" {
  description = "ID EKS кластера"
  value       = aws_eks_cluster.main.id
}

output "cluster_name" {
  description = "Назва EKS кластера"
  value       = aws_eks_cluster.main.name
}

output "cluster_arn" {
  description = "ARN EKS кластера"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "Endpoint EKS кластера"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_version" {
  description = "Версія Kubernetes кластера"
  value       = aws_eks_cluster.main.version
}

output "cluster_platform_version" {
  description = "Версія платформи EKS"
  value       = aws_eks_cluster.main.platform_version
}

output "cluster_status" {
  description = "Статус EKS кластера"
  value       = aws_eks_cluster.main.status
}

# ===========================================
# Cluster Security
# ===========================================

output "cluster_security_group_id" {
  description = "ID security group створеного EKS кластером"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "cluster_iam_role_name" {
  description = "Назва IAM ролі кластера"
  value       = aws_iam_role.eks_cluster_role.name
}

output "cluster_iam_role_arn" {
  description = "ARN IAM ролі кластера"
  value       = aws_iam_role.eks_cluster_role.arn
}

# ===========================================
# OIDC Provider
# ===========================================

output "cluster_oidc_issuer_url" {
  description = "URL OIDC провайдера кластера"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "oidc_provider_arn" {
  description = "ARN OIDC провайдера"
  value       = aws_iam_openid_connect_provider.eks.arn
}

# ===========================================
# Node Group Information
# ===========================================

output "node_group_id" {
  description = "ID node group"
  value       = aws_eks_node_group.main.id
}

output "node_group_arn" {
  description = "ARN node group"
  value       = aws_eks_node_group.main.arn
}

output "node_group_status" {
  description = "Статус node group"
  value       = aws_eks_node_group.main.status
}

output "node_group_capacity_type" {
  description = "Тип capacity node group"
  value       = aws_eks_node_group.main.capacity_type
}

output "node_group_instance_types" {
  description = "Типи інстансів node group"
  value       = aws_eks_node_group.main.instance_types
}

output "node_group_iam_role_name" {
  description = "Назва IAM ролі node group"
  value       = aws_iam_role.eks_node_role.name
}

output "node_group_iam_role_arn" {
  description = "ARN IAM ролі node group"
  value       = aws_iam_role.eks_node_role.arn
}

# ===========================================
# Kubectl Configuration
# ===========================================

output "kubectl_config" {
  description = "Команда для налаштування kubectl"
  value       = "aws eks update-kubeconfig --region ${data.aws_region.current.name} --name ${aws_eks_cluster.main.name}"
}

output "cluster_certificate_authority_data" {
  description = "Certificate authority data для kubectl"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

# ===========================================
# EKS Addons Information
# ===========================================

output "addons" {
  description = "Інформація про встановлені addons"
  value = {
    vpc_cni = {
      name    = aws_eks_addon.vpc_cni.addon_name
      version = aws_eks_addon.vpc_cni.addon_version
      arn     = aws_eks_addon.vpc_cni.arn
    }
    coredns = {
      name    = aws_eks_addon.coredns.addon_name
      version = aws_eks_addon.coredns.addon_version
      arn     = aws_eks_addon.coredns.arn
    }
    kube_proxy = {
      name    = aws_eks_addon.kube_proxy.addon_name
      version = aws_eks_addon.kube_proxy.addon_version
      arn     = aws_eks_addon.kube_proxy.arn
    }
    ebs_csi_driver = {
      name    = aws_eks_addon.ebs_csi_driver.addon_name
      version = aws_eks_addon.ebs_csi_driver.addon_version
      arn     = aws_eks_addon.ebs_csi_driver.arn
    }
  }
}

# ===========================================
# Cost Information
# ===========================================

output "estimated_monthly_cost" {
  description = "Приблизна щомісячна вартість EKS"
  value = {
    control_plane     = "$73.00/month (EKS cluster)"
    worker_nodes     = "~$${var.node_desired_capacity * 30}/month (${var.node_desired_capacity} x t3.medium)"
    data_transfer    = "$0.09/GB (egress)"
    total_estimated  = "~$${73 + (var.node_desired_capacity * 30)}/month"
    free_tier_note   = "No free tier for EKS control plane"
    optimization     = "Consider SPOT instances or smaller node types for cost savings"
  }
}

# ===========================================
# Management URLs
# ===========================================

output "management_urls" {
  description = "Посилання для управління в AWS Console"
  value = {
    eks_cluster = "https://${data.aws_region.current.name}.console.aws.amazon.com/eks/home?region=${data.aws_region.current.name}#/clusters/${aws_eks_cluster.main.name}"
    ec2_instances = "https://${data.aws_region.current.name}.console.aws.amazon.com/ec2/v2/home?region=${data.aws_region.current.name}#Instances:tag:eks:cluster-name=${aws_eks_cluster.main.name}"
    cloudwatch_logs = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#logsV2:log-groups/log-group/$252Faws$252Feks$252F${aws_eks_cluster.main.name}"
  }
}

# ===========================================
# Network Information
# ===========================================

output "cluster_network_config" {
  description = "Мережева конфігурація кластера"
  value = {
    vpc_id                  = aws_eks_cluster.main.vpc_config[0].vpc_id
    subnet_ids              = aws_eks_cluster.main.vpc_config[0].subnet_ids
    endpoint_public_access  = aws_eks_cluster.main.vpc_config[0].endpoint_public_access
    endpoint_private_access = aws_eks_cluster.main.vpc_config[0].endpoint_private_access
    public_access_cidrs     = aws_eks_cluster.main.vpc_config[0].public_access_cidrs
  }
}

# ===========================================
# Summary Information
# ===========================================

output "eks_summary" {
  description = "Підсумок конфігурації EKS"
  value = {
    cluster_name        = aws_eks_cluster.main.name
    kubernetes_version  = aws_eks_cluster.main.version
    cluster_endpoint    = aws_eks_cluster.main.endpoint
    node_group_name     = aws_eks_node_group.main.node_group_name
    node_instance_types = aws_eks_node_group.main.instance_types
    node_capacity       = {
      desired = aws_eks_node_group.main.scaling_config[0].desired_size
      min     = aws_eks_node_group.main.scaling_config[0].min_size
      max     = aws_eks_node_group.main.scaling_config[0].max_size
    }
    addons_count       = 4
    estimated_cost     = "~$${73 + (var.node_desired_capacity * 30)}/month"
  }
}