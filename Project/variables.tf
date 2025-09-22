# ===========================================
# AWS Configuration
# ===========================================

variable "aws_region" {
  description = "AWS region для розгортання ресурсів"
  type        = string
  default     = "us-east-1"
  
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "AWS region має бути у правильному форматі, наприклад: us-east-1."
  }
}

# ===========================================
# Project Configuration
# ===========================================

variable "project_name" {
  description = "Назва проєкту (використовується в назвах ресурсів)"
  type        = string
  default     = "devops-final"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Назва проєкту може містити тільки малі літери, цифри та дефіси."
  }
}

variable "environment" {
  description = "Середовище розгортання"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment має бути одним з: dev, staging, prod."
  }
}

# ===========================================
# VPC Configuration
# ===========================================

variable "vpc_cidr" {
  description = "CIDR блок для VPC"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR має бути валідним CIDR блоком."
  }
}

variable "availability_zones" {
  description = "Список Availability Zones для використання"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
  
  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "Потрібно мінімум 2 Availability Zones для high availability."
  }
}

# ===========================================
# EKS Configuration
# ===========================================

variable "kubernetes_version" {
  description = "Версія Kubernetes для EKS кластера"
  type        = string
  default     = "1.28"
}

variable "node_instance_types" {
  description = "Типи інстансів для EKS worker nodes"
  type        = list(string)
  default     = ["t3.small"]  # Мінімальний підтримуваний EKS instance type
}

variable "node_desired_capacity" {
  description = "Бажана кількість worker nodes"
  type        = number
  default     = 1  # Мінімум для Free Tier
  
  validation {
    condition     = var.node_desired_capacity >= 1 && var.node_desired_capacity <= 5
    error_message = "Desired capacity має бути між 1 та 5 для Free Tier."
  }
}

variable "node_max_capacity" {
  description = "Максимальна кількість worker nodes"
  type        = number
  default     = 2  # Обмежуємо для Free Tier
  
  validation {
    condition     = var.node_max_capacity >= 1 && var.node_max_capacity <= 5
    error_message = "Max capacity має бути між 1 та 5 для Free Tier."
  }
}

variable "node_min_capacity" {
  description = "Мінімальна кількість worker nodes"
  type        = number
  default     = 1
  
  validation {
    condition     = var.node_min_capacity >= 0 && var.node_min_capacity <= 10
    error_message = "Min capacity має бути між 0 та 10."
  }
}

# ===========================================
# RDS Configuration
# ===========================================

variable "db_instance_class" {
  description = "Клас інстанса для RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Розмір сховища для RDS (GB)"
  type        = number
  default     = 20
  
  validation {
    condition     = var.db_allocated_storage >= 20 && var.db_allocated_storage <= 100
    error_message = "DB storage має бути між 20GB та 100GB."
  }
}

variable "db_engine_version" {
  description = "Версія PostgreSQL"
  type        = string
  default     = "15.14"
}

variable "db_name" {
  description = "Назва бази даних"
  type        = string
  default     = "djangodb"
  
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.db_name))
    error_message = "DB name має починатися з літери та містити тільки літери, цифри та підкреслення."
  }
}

variable "db_username" {
  description = "Користувач бази даних"
  type        = string
  default     = "dbadmin"
  
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.db_username))
    error_message = "DB username має починатися з літери та містити тільки літери, цифри та підкреслення."
  }
}

variable "db_password" {
  description = "Пароль для бази даних"
  type        = string
  default     = "ChangeMe123!"
  sensitive   = true
  
  validation {
    condition     = length(var.db_password) >= 8
    error_message = "DB password має містити мінімум 8 символів."
  }
}

# ===========================================
# Helm Charts Configuration
# ===========================================

variable "jenkins_chart_version" {
  description = "Версія Jenkins Helm чарта"
  type        = string
  default     = "4.8.3"
}

variable "argocd_chart_version" {
  description = "Версія ArgoCD Helm чарта"
  type        = string
  default     = "5.51.4"
}

variable "prometheus_chart_version" {
  description = "Версія Prometheus Helm чарта"
  type        = string
  default     = "25.8.0"
}

variable "grafana_chart_version" {
  description = "Версія Grafana Helm чарта"
  type        = string
  default     = "7.0.19"
}

variable "jenkins_admin_password" {
  description = "Admin password for Jenkins"
  type        = string
  sensitive   = true
  default     = "123Password123" 
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# ===========================================
# Tags
# ===========================================

variable "common_tags" {
  description = "Загальні теги для всіх ресурсів"
  type        = map(string)
  default = {
    Project     = "DevOps Final Project"
    Environment = "Development"
    Terraform   = "true"
    Repository  = "https://github.com/TiZorii/my-devops-hw"
  }
}

variable "argocd_admin_password" {
  description = "Admin password for ArgoCD"
  type        = string
  sensitive   = true
  default     = "ArgoCD2024!"
}