# ===========================================
# EKS Module Variables
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
  description = "ID VPC для EKS кластера"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs приватних підмереж для EKS"
  type        = list(string)
  
  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "Потрібно мінімум 2 приватні підмережі для high availability."
  }
}

variable "cluster_security_group_ids" {
  description = "Security groups для EKS cluster"
  type        = list(string)
  default     = []
}

variable "node_security_group_ids" {
  description = "Security groups для EKS worker nodes"
  type        = list(string)
  default     = []
}

# ===========================================
# EKS Cluster Configuration
# ===========================================

variable "kubernetes_version" {
  description = "Версія Kubernetes для EKS кластера"
  type        = string
  default     = "1.28"
  
  validation {
    condition     = can(regex("^1\\.(2[4-9]|[3-9][0-9])$", var.kubernetes_version))
    error_message = "Kubernetes version має бути підтримуваною версією (наприклад, 1.28)."
  }
}

variable "cluster_log_types" {
  description = "Типи логів які потрібно включити"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "endpoint_public_access" {
  description = "Дозволити публічний доступ до EKS API"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDR блоки з яких дозволено публічний доступ"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "kms_key_arn" {
  description = "ARN KMS ключа для шифрування secrets"
  type        = string
  default     = null
}

# ===========================================
# Node Group Configuration
# ===========================================

variable "node_instance_types" {
  description = "Типи EC2 інстансів для worker nodes"
  type        = list(string)
  default     = ["t3.micro"]
}

variable "node_ami_type" {
  description = "AMI тип для worker nodes"
  type        = string
  default     = "AL2_x86_64"
  
  validation {
    condition     = contains(["AL2_x86_64", "AL2_x86_64_GPU", "AL2_ARM_64"], var.node_ami_type)
    error_message = "Node AMI type має бути одним з підтримуваних типів."
  }
}

variable "node_capacity_type" {
  description = "Тип capacity для nodes (ON_DEMAND або SPOT)"
  type        = string
  default     = "ON_DEMAND"
  
  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.node_capacity_type)
    error_message = "Node capacity type має бути ON_DEMAND або SPOT."
  }
}

variable "node_disk_size" {
  description = "Розмір диска для worker nodes (GB)"
  type        = number
  default     = 20
  
  validation {
    condition     = var.node_disk_size >= 20 && var.node_disk_size <= 100
    error_message = "Node disk size має бути між 20 і 100 GB."
  }
}

# ===========================================
# Scaling Configuration
# ===========================================

variable "node_desired_capacity" {
  description = "Бажана кількість worker nodes"
  type        = number
  default     = 2
  
  validation {
    condition     = var.node_desired_capacity >= 1 && var.node_desired_capacity <= 10
    error_message = "Node desired capacity має бути між 1 і 10."
  }
}

variable "node_min_capacity" {
  description = "Мінімальна кількість worker nodes"
  type        = number
  default     = 1
  
  validation {
    condition     = var.node_min_capacity >= 1 && var.node_min_capacity <= 5
    error_message = "Node min capacity має бути між 1 і 5."
  }
}

variable "node_max_capacity" {
  description = "Максимальна кількість worker nodes"
  type        = number
  default     = 4
  
  validation {
    condition     = var.node_max_capacity >= 2 && var.node_max_capacity <= 20
    error_message = "Node max capacity має бути між 2 і 20."
  }
}

# ===========================================
# SSH Access
# ===========================================

variable "node_ssh_key" {
  description = "Назва EC2 Key Pair для SSH доступу до nodes"
  type        = string
  default     = null
}

# ===========================================
# Node Labels and Taints
# ===========================================

variable "node_taints" {
  description = "Taints для worker nodes"
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
}

# ===========================================
# Addon Versions
# ===========================================

variable "vpc_cni_addon_version" {
  description = "Версія VPC CNI addon"
  type        = string
  default     = null  # Використовувати останню рекомендовану
}

variable "coredns_addon_version" {
  description = "Версія CoreDNS addon"
  type        = string
  default     = null
}

variable "kube_proxy_addon_version" {
  description = "Версія kube-proxy addon"
  type        = string
  default     = null
}

variable "ebs_csi_addon_version" {
  description = "Версія EBS CSI driver addon"
  type        = string
  default     = null
}

# ===========================================
# Tags
# ===========================================

variable "tags" {
  description = "Теги для ресурсів EKS"
  type        = map(string)
  default     = {}
}