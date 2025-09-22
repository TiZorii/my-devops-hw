resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = var.namespace
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.51.4"  # Стабільна версія

  create_namespace = true
  timeout          = 600   # Зменшили timeout
  wait             = false # Не чекати повного запуску
  
  # Мінімальні налаштування через set
  set {
    name  = "dex.enabled"
    value = "false"
  }
  
  set {
    name  = "notifications.enabled" 
    value = "false"
  }
  
  set {
    name  = "server.extraArgs[0]"
    value = "--insecure"
  }
  
  set {
    name  = "controller.resources.requests.cpu"
    value = "100m"
  }
  
  set {
    name  = "controller.resources.requests.memory"
    value = "256Mi"
  }
  
  set {
    name  = "server.resources.requests.cpu"
    value = "50m"
  }
  
  set {
    name  = "server.resources.requests.memory"
    value = "64Mi"
  }
}