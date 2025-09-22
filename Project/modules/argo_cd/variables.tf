variable "namespace" {
  description = "Namespace for ArgoCD"
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "Version of ArgoCD Helm chart"
  type        = string
  default     = ""
}