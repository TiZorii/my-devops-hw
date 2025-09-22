# ===========================================
# ECR Module - Outputs
# ===========================================

# ===========================================
# Repository Information
# ===========================================

output "repository_urls" {
  description = "URLs репозиторіїв ECR"
  value = {
    for name, repo in aws_ecr_repository.repositories : name => repo.repository_url
  }
}

output "repository_arns" {
  description = "ARNs репозиторіїв ECR"
  value = {
    for name, repo in aws_ecr_repository.repositories : name => repo.arn
  }
}

output "repository_names" {
  description = "Назви репозиторіїв ECR"
  value = {
    for name, repo in aws_ecr_repository.repositories : name => repo.name
  }
}

# ===========================================
# Registry Information
# ===========================================

output "registry_id" {
  description = "ID AWS ECR registry"
  value       = data.aws_caller_identity.current.account_id
}

output "registry_url" {
  description = "URL AWS ECR registry"
  value       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
}

# ===========================================
# Django App Repository (основний)
# ===========================================

output "django_app_repository_url" {
  description = "URL репозиторію Django app"
  value       = aws_ecr_repository.repositories["django-app"].repository_url
}

output "django_app_repository_arn" {
  description = "ARN репозиторію Django app"  
  value       = aws_ecr_repository.repositories["django-app"].arn
}

# ===========================================
# Docker Commands для використання
# ===========================================

output "docker_login_command" {
  description = "Команда для логіну в ECR"
  value       = "aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
  sensitive   = false
}

output "docker_build_commands" {
  description = "Приклади команд для build та push образів"
  value = {
    for name, repo in aws_ecr_repository.repositories : name => {
      build_command = "docker build -t ${name} ."
      tag_command   = "docker tag ${name}:latest ${repo.repository_url}:latest"
      push_command  = "docker push ${repo.repository_url}:latest"
      full_example  = "docker build -t ${name} . && docker tag ${name}:latest ${repo.repository_url}:latest && docker push ${repo.repository_url}:latest"
    }
  }
}

# ===========================================
# Jenkins Integration
# ===========================================

output "jenkins_pipeline_vars" {
  description = "Змінні для Jenkins pipeline"
  value = {
    ECR_REGISTRY    = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
    ECR_REPOSITORY  = aws_ecr_repository.repositories["django-app"].name
    AWS_REGION      = data.aws_region.current.name
    DJANGO_APP_URL  = aws_ecr_repository.repositories["django-app"].repository_url
  }
  sensitive = false
}

# ===========================================
# Cost Information
# ===========================================

output "estimated_monthly_cost" {
  description = "Приблизна щомісячна вартість ECR"
  value = {
    storage_gb_price = "$0.10 per GB/month"
    data_transfer   = "$0.09 per GB (out to internet)"
    free_tier      = "500MB storage + 5GB transfer per month"
    estimated_cost = length(local.repositories) <= 2 ? "$0-5/month (Free Tier eligible)" : "$5-15/month"
    note          = "Вартість залежить від розміру та кількості образів"
  }
}

# ===========================================
# Management URLs
# ===========================================

output "management_urls" {
  description = "Посилання для управління в AWS Console"
  value = {
    ecr_console = "https://${data.aws_region.current.name}.console.aws.amazon.com/ecr/repositories?region=${data.aws_region.current.name}"
    repositories = {
      for name, repo in aws_ecr_repository.repositories : name => 
      "https://${data.aws_region.current.name}.console.aws.amazon.com/ecr/repositories/private/${data.aws_caller_identity.current.account_id}/${repo.name}?region=${data.aws_region.current.name}"
    }
  }
}

# ===========================================
# Summary Information
# ===========================================

output "ecr_summary" {
  description = "Підсумок конфігурації ECR"
  value = {
    registry_url       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
    repositories_count = length(local.repositories)
    repositories_names = keys(local.repositories)
    image_mutability   = var.image_tag_mutability
    encryption_type    = var.encryption_type
    vulnerability_scan = var.enable_vulnerability_scanning
    lifecycle_policy  = {
      max_images      = var.max_image_count
      untagged_days  = var.untagged_image_days
    }
  }
}