# modules/argo_cd/variables.tf

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

variable "argocd_admin_password" {
  description = "Admin password for ArgoCD"
  type        = string
  default     = "admin123"
  sensitive   = true
}