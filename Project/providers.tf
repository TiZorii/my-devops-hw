# ===========================================
# Terraform Configuration
# ===========================================

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
    
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
  
  # Backend буде налаштований після створення S3 bucket
  # Розкоментуйте після запуску terraform apply для s3-backend модуля
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "your-terraform-locks-table"
  #   encrypt        = true
  # }
}

# ===========================================
# AWS Provider Configuration
# ===========================================

provider "aws" {
  region = "us-east-1"

  
  # Загальні теги для всіх ресурсів
  default_tags {
    tags = var.common_tags
  }
}

# ===========================================
# Random Provider
# ===========================================

provider "random" {
  # Використовується для генерації випадкових значень
}

# ===========================================
# Data Sources
# ===========================================

# Отримання інформації про поточний AWS аккаунт
data "aws_caller_identity" "current" {}

# Отримання інформації про поточний регіон
data "aws_region" "current" {}

# Отримання доступних Availability Zones
data "aws_availability_zones" "available" {
  state = "available"
}

# ===========================================
# Global Data Sources and Helper Values
# ===========================================

# Ці locals будуть використовуватися в інших модулях
# Основні locals визначені в main.tf