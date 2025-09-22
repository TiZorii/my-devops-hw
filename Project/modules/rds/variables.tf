# ===========================================
# RDS Module Variables
# ===========================================

variable "project_name" {
  description = "Назва проєкту"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name може містити тільки малі літери, цифри та дефіси."
  }
}

variable "environment" {
  description = "Середовище розгортання (dev, staging, prod)"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment має бути одним з: dev, staging, prod."
  }
}

# ===========================================
# Network Configuration
# ===========================================

variable "vpc_id" {
  description = "ID VPC для RDS"
  type        = string
}

variable "db_subnet_group_name" {
  description = "Назва DB subnet group (з VPC модуля)"
  type        = string
}

variable "allowed_security_group_ids" {
  description = "Security groups яким дозволено доступ до RDS"
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "CIDR блоки з яких дозволено доступ до RDS"
  type        = list(string)
  default     = []
}

# ===========================================
# Database Configuration
# ===========================================

variable "db_engine_version" {
  description = "Версія PostgreSQL"
  type        = string
  default     = "15.14"
  
  validation {
    condition     = can(regex("^1[2-9]|1[5]\\.", var.db_engine_version))
    error_message = "PostgreSQL version має бути 12.x або вище."
  }
}


variable "db_instance_class" {
  description = "Клас інстанса RDS"
  type        = string
  default     = "db.t3.micro"
  
  validation {
    condition = contains([
      "db.t3.micro", "db.t3.small", "db.t3.medium", "db.t3.large",
      "db.t4g.micro", "db.t4g.small", "db.t4g.medium",
      "db.r5.large", "db.r5.xlarge", "db.r6i.large"
    ], var.db_instance_class)
    error_message = "DB instance class має бути одним з підтримуваних типів."
  }
}

variable "db_name" {
  description = "Назва бази даних"
  type        = string
  default     = "django_app"
  
  validation {
    condition     = can(regex("^[a-z][a-z0-9_]*$", var.db_name))
    error_message = "DB name має починатися з літери і містити тільки малі літери, цифри та підкреслення."
  }
}

variable "db_username" {
  description = "Головний користувач бази даних"
  type        = string
  default     = "django_user"
  
  validation {
    condition     = can(regex("^[a-z][a-z0-9_]*$", var.db_username)) && length(var.db_username) <= 63
    error_message = "DB username має починатися з літери, містити тільки малі літери, цифри та підкреслення, і бути не більше 63 символів."
  }
}

variable "db_password" {
  description = "Пароль бази даних (якщо null - генерується автоматично)"
  type        = string
  default     = null
  sensitive   = true
}

# ===========================================
# Storage Configuration
# ===========================================

variable "db_allocated_storage" {
  description = "Початковий розмір сховища (GB)"
  type        = number
  default     = 20
  
  validation {
    condition     = var.db_allocated_storage >= 20 && var.db_allocated_storage <= 1000
    error_message = "Allocated storage має бути між 20 і 1000 GB."
  }
}

variable "db_max_allocated_storage" {
  description = "Максимальний розмір автоматичного розширення (GB)"
  type        = number
  default     = 100
  
  validation {
    condition     = var.db_max_allocated_storage >= 20 && var.db_max_allocated_storage <= 1000
    error_message = "Max allocated storage має бути між 20 і 1000 GB."
  }
}

variable "db_storage_type" {
  description = "Тип сховища (gp2, gp3, io1)"
  type        = string
  default     = "gp3"
  
  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.db_storage_type)
    error_message = "Storage type має бути одним з: gp2, gp3, io1, io2."
  }
}

variable "db_storage_encrypted" {
  description = "Чи шифрувати сховище"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID для шифрування"
  type        = string
  default     = null
}

# ===========================================
# Performance and Monitoring
# ===========================================

variable "auto_minor_version_upgrade" {
  description = "Автоматично оновлювати мінорні версії"
  type        = bool
  default     = true
}

variable "store_credentials_in_secrets_manager" {
  description = "Зберігати креденшели в AWS Secrets Manager"
  type        = bool
  default     = true
}

# ===========================================
# Backup Configuration
# ===========================================

variable "backup_retention_period" {
  description = "Кількість днів зберігання backup (0 = відключити)"
  type        = number
  default     = null  # Визначається автоматично згідно середовища
  
  validation {
    condition     = var.backup_retention_period == null || (var.backup_retention_period >= 0 && var.backup_retention_period <= 35)
    error_message = "Backup retention period має бути між 0 і 35 днів."
  }
}

# ===========================================
# Tags
# ===========================================

variable "tags" {
  description = "Теги для ресурсів RDS"
  type        = map(string)
  default     = {}
}