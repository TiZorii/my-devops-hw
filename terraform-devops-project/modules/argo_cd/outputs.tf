# modules/argo_cd/outputs.tf

# Get ArgoCD admin password
data "kubernetes_secret" "argocd_initial_admin_secret" {
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = "argocd"
  }

  depends_on = [helm_release.argocd]
}

# Get Load Balancer URL
data "kubernetes_service" "argocd_server_lb" {
  metadata {
    name      = "argocd-server-lb"
    namespace = "argocd"
  }

  depends_on = [kubernetes_service.argocd_server_loadbalancer]
}

output "argocd_url" {
  description = "URL to access ArgoCD"
  value = length(data.kubernetes_service.argocd_server_lb.status[0].load_balancer[0].ingress) > 0 ? (
    data.kubernetes_service.argocd_server_lb.status[0].load_balancer[0].ingress[0].hostname != null ?
    "http://${data.kubernetes_service.argocd_server_lb.status[0].load_balancer[0].ingress[0].hostname}" :
    "http://${data.kubernetes_service.argocd_server_lb.status[0].load_balancer[0].ingress[0].ip}"
  ) : "LoadBalancer is being created..."
}

output "argocd_admin_password" {
  description = "ArgoCD admin password"
  value       = base64decode(data.kubernetes_secret.argocd_initial_admin_secret.data["password"])
  sensitive   = true
}

output "argocd_namespace" {
  description = "ArgoCD namespace"
  value       = kubernetes_namespace.argocd.metadata[0].name
}