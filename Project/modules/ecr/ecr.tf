# ===========================================
# ECR Module - Container Registry
# ===========================================

# Локальні змінні
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Список репозиторіїв для створення
  repositories = {
    django-app = {
      description = "Django application repository"
      scan_config = true
    }
    nginx = {
      description = "Custom nginx configuration"
      scan_config = false
    }
  }
}

# ===========================================
# ECR Repositories
# ===========================================

resource "aws_ecr_repository" "repositories" {
  for_each = local.repositories
  
  name                 = "${local.name_prefix}-${each.key}"
  image_tag_mutability = var.image_tag_mutability
  
  # Налаштування сканування на вразливості
  image_scanning_configuration {
    scan_on_push = each.value.scan_config
  }
  
  # Шифрування
  encryption_configuration {
    encryption_type = var.encryption_type
    kms_key        = var.kms_key_id
  }
  
  tags = merge(var.tags, {
    Name        = "${local.name_prefix}-${each.key}"
    Type        = "ecr-repository"
    Repository  = each.key
    Description = each.value.description
  })
}

# ===========================================
# Lifecycle Policy для економії місця
# ===========================================

resource "aws_ecr_lifecycle_policy" "repositories_policy" {
  for_each = aws_ecr_repository.repositories
  
  repository = each.value.name
  
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.max_image_count} images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = var.max_image_count
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images older than ${var.untagged_image_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.untagged_image_days
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
  
  depends_on = [aws_ecr_repository.repositories]
}

# ===========================================
# Repository Policy для доступу
# ===========================================

# Дозволяємо EKS кластеру pull образи
data "aws_iam_policy_document" "ecr_policy" {
  statement {
    sid    = "AllowPullFromEKS"
    effect = "Allow"
    
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }
    
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage", 
      "ecr:GetDownloadUrlForLayer"
    ]
  }
  
  # Дозволяємо Jenkins push образи
  statement {
    sid    = "AllowPushFromJenkins"
    effect = "Allow"
    
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }
    
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage"
    ]
  }
}

resource "aws_ecr_repository_policy" "repositories_policy" {
  for_each = aws_ecr_repository.repositories
  
  repository = each.value.name
  policy     = data.aws_iam_policy_document.ecr_policy.json
  
  depends_on = [aws_ecr_repository.repositories]
}

# ===========================================
# Data sources
# ===========================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}