# ===========================================
# VPC Module Variables
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
  
  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "Потрібно мінімум 2 Availability Zones для high availability."
  }
}

# ===========================================
# Subnet Configuration
# ===========================================

variable "public_subnet_cidrs" {
  description = "CIDR блоки для публічних підмереж"
  type        = list(string)
  default     = []
}

variable "private_subnet_cidrs" {
  description = "CIDR блоки для приватних підмереж"
  type        = list(string)
  default     = []
}

variable "database_subnet_cidrs" {
  description = "CIDR блоки для підмереж бази даних"
  type        = list(string)
  default     = []
}

# ===========================================
# NAT Gateway Configuration
# ===========================================

variable "enable_nat_gateway" {
  description = "Увімкнути NAT Gateway для приватних підмереж"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Використовувати один NAT Gateway для всіх AZ (економія коштів)"
  type        = bool
  default     = true  # Для Free Tier економії
}

variable "enable_vpn_gateway" {
  description = "Увімкнути VPN Gateway"
  type        = bool
  default     = false
}

# ===========================================
# DNS Configuration
# ===========================================

variable "enable_dns_hostnames" {
  description = "Увімкнути DNS hostnames у VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Увімкнути DNS support у VPC"
  type        = bool
  default     = true
}

# ===========================================
# Flow Logs Configuration
# ===========================================

variable "enable_flow_logs" {
  description = "Увімкнути VPC Flow Logs"
  type        = bool
  default     = false  # Вимкнути для dev щоб зменшити витрати
}

variable "flow_logs_retention_days" {
  description = "Кількість днів зберігання Flow Logs"
  type        = number
  default     = 7
  
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.flow_logs_retention_days)
    error_message = "Flow logs retention має бути одним з дозволених значень AWS CloudWatch."
  }
}

# ===========================================
# Security Groups
# ===========================================

variable "create_database_security_group" {
  description = "Створити security group для бази даних"
  type        = bool
  default     = true
}

variable "create_eks_security_group" {
  description = "Створити додаткові security groups для EKS"
  type        = bool
  default     = true
}

# ===========================================
# Tags
# ===========================================

variable "tags" {
  description = "Теги для ресурсів VPC"
  type        = map(string)
  default     = {}
}

variable "public_subnet_tags" {
  description = "Додаткові теги для публічних підмереж"
  type        = map(string)
  default = {
    "kubernetes.io/role/elb" = "1"
  }
}

variable "private_subnet_tags" {
  description = "Додаткові теги для приватних підмереж"
  type        = map(string)
  default = {
    "kubernetes.io/role/internal-elb" = "1" 
  }
}

variable "database_subnet_tags" {
  description = "Додаткові теги для підмереж бази даних"
  type        = map(string)
  default = {
    "Purpose" = "database"
  }
}