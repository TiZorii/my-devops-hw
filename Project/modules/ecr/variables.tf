# ===========================================
# ECR Module Variables
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
# ECR Configuration
# ===========================================

variable "image_tag_mutability" {
  description = "Чи можна змінювати теги образів (MUTABLE або IMMUTABLE)"
  type        = string
  default     = "MUTABLE"
  
  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "Image tag mutability має бути MUTABLE або IMMUTABLE."
  }
}

variable "encryption_type" {
  description = "Тип шифрування (AES256 або KMS)"
  type        = string
  default     = "AES256"
  
  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "Encryption type має бути AES256 або KMS."
  }
}

variable "kms_key_id" {
  description = "KMS key ID для шифрування (тільки якщо encryption_type = KMS)"
  type        = string
  default     = null
}

# ===========================================
# Lifecycle Policy Configuration
# ===========================================

variable "max_image_count" {
  description = "Максимальна кількість образів для зберігання"
  type        = number
  default     = 10
  
  validation {
    condition     = var.max_image_count > 0 && var.max_image_count <= 100
    error_message = "Max image count має бути між 1 і 100."
  }
}

variable "untagged_image_days" {
  description = "Кількість днів для зберігання untagged образів"
  type        = number
  default     = 7
  
  validation {
    condition     = var.untagged_image_days > 0 && var.untagged_image_days <= 365
    error_message = "Untagged image days має бути між 1 і 365."
  }
}

# ===========================================
# Repository Configuration
# ===========================================

variable "enable_vulnerability_scanning" {
  description = "Увімкнути сканування на вразливості"
  type        = bool
  default     = true
}

variable "repositories" {
  description = "Додаткові репозиторії для створення"
  type = map(object({
    description = string
    scan_config = bool
  }))
  default = {}
}

# ===========================================
# Tags
# ===========================================

variable "tags" {
  description = "Теги для ресурсів ECR"
  type        = map(string)
  default     = {}
}