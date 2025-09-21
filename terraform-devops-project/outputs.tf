# outputs.tf - тимчасова версія для тестування VPC
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.vpc.private_subnet_ids
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.ecr.repository_url
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value = module.rds.endpoint
}

output "rds_connection_string" {
  description = "RDS connection string"
  value = module.rds.connection_string
  sensitive = true
}


# output "jenkins_url" {
#   description = "URL to access Jenkins"
#   value       = module.jenkins.jenkins_url
# }

# output "argocd_url" {
#   description = "URL to access Argo CD"
#   value       = module.argo_cd.argocd_url
# }

# output "argocd_admin_password" {
#   description = "ArgoCD admin password"
#   value       = module.argo_cd.argocd_admin_password
#   sensitive   = true
# }