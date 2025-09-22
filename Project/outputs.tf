# ===========================================
# DevOps Final Project - Outputs
# ===========================================

# ===========================================
# S3 Backend Outputs (закоментовано після створення)
# ===========================================

# output "s3_bucket_name" {
#   description = "Назва S3 bucket для Terraform state"
#   value       = module.s3_backend.s3_bucket_name
# }

# output "s3_bucket_arn" {
#   description = "ARN S3 bucket"
#   value       = module.s3_backend.s3_bucket_arn
# }

# output "dynamodb_table_name" {
#   description = "Назва DynamoDB таблиці для state locking"
#   value       = module.s3_backend.dynamodb_table_name
# }

# output "dynamodb_table_arn" {
#   description = "ARN DynamoDB таблиці"
#   value       = module.s3_backend.dynamodb_table_arn
# }

# ===========================================
# Backend Configuration Template (закоментовано)
# ===========================================

# output "terraform_backend_config" {
#   description = "Готовий код для backend.tf файлу"
#   value       = module.s3_backend.terraform_backend_config
# }

# output "backend_config" {
#   description = "Конфігурація backend у вигляді об'єкту"
#   value       = module.s3_backend.backend_config
#   sensitive   = false
# }

# ===========================================
# Management Information (закоментовано)
# ===========================================

# output "management_urls" {
#   description = "Посилання для управління ресурсами в AWS Console"
#   value       = module.s3_backend.management_urls
# }

# output "estimated_cost" {
#   description = "Приблизна вартість S3 Backend"
#   value       = module.s3_backend.estimated_monthly_cost
# }

# ===========================================
# Next Steps Information (закоментовано)
# ===========================================

# output "next_steps" {
#   description = "Інструкції для наступних кроків"
#   value = <<-EOT
#     
#     🎉 S3 Backend створено успішно!
#     
#     📋 НАСТУПНІ КРОКИ:
#     
#     1. Створіть файл backend.tf з таким вмістом:
#     
#     ${module.s3_backend.terraform_backend_config}
#     
#     2. Виконайте міграцію state:
#        terraform init -migrate-state
#     
#     3. Розкоментуйте інші модулі в main.tf
#     
#     4. Продовжуйте з створення VPC модуля
#     
#     💰 Вартість: ~$0-2/місяць (Free Tier)
#     
#     🔗 Управління: ${module.s3_backend.management_urls.s3_bucket}
#     
#   EOT
# }

# ===========================================
# VPC Outputs (виправлено)
# ===========================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "database_subnet_ids" {
  description = "IDs of the database subnets"
  value       = module.vpc.database_subnet_ids
}

output "vpc_estimated_cost" {
  description = "Estimated monthly cost for VPC"
  value       = module.vpc.estimated_monthly_cost
}

output "vpc_summary" {
  description = "Summary of VPC configuration"
  value       = module.vpc.vpc_summary
}

# ===========================================
# EKS Security Groups (якщо створені)
# ===========================================

output "eks_cluster_security_group_id" {
  description = "ID of the EKS cluster security group"
  value       = module.vpc.eks_cluster_security_group_id
}

output "eks_nodes_security_group_id" {
  description = "ID of the EKS nodes security group"  
  value       = module.vpc.eks_nodes_security_group_id
}

# ===========================================
# ECR Outputs
# ===========================================

output "ecr_repository_urls" {
  description = "URLs ECR репозиторіїв"
  value       = module.ecr.repository_urls
}

output "ecr_django_app_url" {
  description = "URL основного Django app репозиторію"
  value       = module.ecr.django_app_repository_url
}

output "ecr_registry_url" {
  description = "URL ECR registry"
  value       = module.ecr.registry_url
}

output "docker_login_command" {
  description = "Команда для логіну в ECR"
  value       = module.ecr.docker_login_command
}

output "ecr_estimated_cost" {
  description = "Приблизна вартість ECR"
  value       = module.ecr.estimated_monthly_cost
}

# ===========================================
# EKS Outputs
# ===========================================

output "eks_cluster_name" {
  description = "Назва EKS кластера"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint EKS кластера"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_version" {
  description = "Версія Kubernetes"
  value       = module.eks.cluster_version
}

output "kubectl_config" {
  description = "Команда для налаштування kubectl"
  value       = module.eks.kubectl_config
}

output "eks_estimated_cost" {
  description = "Приблизна вартість EKS"
  value       = module.eks.estimated_monthly_cost
}

output "eks_management_urls" {
  description = "Посилання для управління EKS в AWS Console"
  value       = module.eks.management_urls
}

# ===========================================
# RDS Outputs
# ===========================================

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.db_instance_endpoint
  sensitive   = false
}

output "rds_port" {
  description = "RDS port"
  value       = module.rds.db_instance_port
}

output "rds_database_name" {
  description = "Назва бази даних"
  value       = module.rds.db_name
}

output "rds_secrets_manager_arn" {
  description = "ARN Secrets Manager для DB креденшелів"
  value       = module.rds.secrets_manager_secret_arn
}

output "rds_estimated_cost" {
  description = "Приблизна вартість RDS"
  value       = module.rds.estimated_monthly_cost
}

output "rds_summary" {
  description = "Підсумок RDS конфігурації"
  value       = module.rds.rds_summary
}