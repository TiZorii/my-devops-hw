variable "ecr_name" {
  description = "Ім'я ECR репозиторію"
  type        = string
}

variable "scan_on_push" {
  description = "Чи увімкнути сканування образів при завантаженні"
  type        = bool
  default     = true
}

variable "image_tag_mutability" {
  description = "Тип мутабельності тегів образів (MUTABLE або IMMUTABLE)"
  type        = string
  default     = "MUTABLE"
}

variable "encryption_type" {
  description = "Тип шифрування для репозиторію (AES256 або KMS)"
  type        = string
  default     = "AES256"
}

variable "environment" {
  description = "Середовище (dev, staging, prod)"
  type        = string
  default     = "dev"
}