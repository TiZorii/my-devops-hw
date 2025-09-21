# modules/argo_cd/argo_cd.tf

# Namespace для ArgoCD
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
    labels = {
      name = "argocd"
    }
  }
}

# ArgoCD Helm Release
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.51.6"
  namespace  = "argocd"

  values = [file("${path.module}/values.yaml")]

  depends_on = [kubernetes_namespace.argocd]

  timeout = 600
}

# Service для доступу до ArgoCD
resource "kubernetes_service" "argocd_server_loadbalancer" {
  metadata {
    name      = "argocd-server-lb"
    namespace = "argocd"
    labels = {
      "app.kubernetes.io/component" = "server"
      "app.kubernetes.io/name"      = "argocd-server"
    }
  }

  spec {
    type = "LoadBalancer"
    
    selector = {
      "app.kubernetes.io/name" = "argocd-server"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 8080
      protocol    = "TCP"
    }

    port {
      name        = "https"
      port        = 443
      target_port = 8080
      protocol    = "TCP"
    }
  }

  depends_on = [helm_release.argocd]
}