output "argocd_server_service" {
  description = "Argo CD server service name"
  value       = helm_release.argocd.name
}
