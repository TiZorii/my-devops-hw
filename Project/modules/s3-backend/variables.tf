# ===========================================
# S3 Backend Module Variables
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

variable "aws_region" {
  description = "AWS region для S3 bucket та DynamoDB"
  type        = string
}

variable "tags" {
  description = "Теги для ресурсів"
  type        = map(string)
  default     = {}
}

variable "force_destroy" {
  description = "Дозволити видалення S3 bucket навіть якщо він не пустий (для dev/testing)"
  type        = bool
  default     = true
}

variable "versioning_enabled" {
  description = "Увімкнути версіонування S3 bucket"
  type        = bool
  default     = true
}

variable "lifecycle_expiration_days" {
  description = "Кількість днів для зберігання старих версій state файлів"
  type        = number
  default     = 30
  
  validation {
    condition     = var.lifecycle_expiration_days >= 1 && var.lifecycle_expiration_days <= 365
    error_message = "Lifecycle expiration має бути між 1 та 365 днями."
  }
}

variable "mfa_delete" {
  description = "Увімкнути MFA delete для S3 bucket (тільки для root користувача)"
  type        = bool
  default     = false
}