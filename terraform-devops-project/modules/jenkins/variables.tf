variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  type        = string
}

variable "jenkins_admin_password" {
  description = "Admin password for Jenkins"
  type        = string
  default     = "admin123"
  sensitive   = true
}

variable "jenkins_storage_size" {
  description = "Size of Jenkins persistent volume"
  type        = string
  default     = "10Gi"
}