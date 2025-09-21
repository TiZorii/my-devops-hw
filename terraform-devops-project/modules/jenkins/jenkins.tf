# modules/jenkins/jenkins.tf - без PVC

# Namespace для Jenkins
resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = "jenkins"
    labels = {
      name = "jenkins"
    }
  }
}

# Service Account для Jenkins
resource "kubernetes_service_account" "jenkins" {
  metadata {
    name      = "jenkins"
    namespace = "jenkins"
  }
  
  depends_on = [kubernetes_namespace.jenkins]
}

# ClusterRole для Jenkins
resource "kubernetes_cluster_role" "jenkins" {
  metadata {
    name = "jenkins"
  }

  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["create", "delete", "get", "list", "patch", "update", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods/exec"]
    verbs      = ["create", "delete", "get", "list", "patch", "update", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods/log"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "list", "create", "update", "patch", "delete"]
  }
}

# ClusterRoleBinding
resource "kubernetes_cluster_role_binding" "jenkins" {
  metadata {
    name = "jenkins"
  }
  
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "jenkins"
  }
  
  subject {
    kind      = "ServiceAccount"
    name      = "jenkins"
    namespace = "jenkins"
  }

  depends_on = [
    kubernetes_service_account.jenkins,
    kubernetes_cluster_role.jenkins
  ]
}

# Jenkins Helm Release БЕЗ PVC
resource "helm_release" "jenkins" {
  name       = "jenkins"
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  version    = "4.8.3"
  namespace  = "jenkins"

  values = [file("${path.module}/values.yaml")]

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.jenkins.metadata[0].name
  }

  depends_on = [
    kubernetes_namespace.jenkins,
    kubernetes_service_account.jenkins,
    kubernetes_cluster_role_binding.jenkins
  ]

  timeout = 600
}

# Service для доступу до Jenkins
resource "kubernetes_service" "jenkins_loadbalancer" {
  metadata {
    name      = "jenkins-lb"
    namespace = "jenkins"
  }

  spec {
    type = "LoadBalancer"
    
    selector = {
      "app.kubernetes.io/component" = "jenkins-controller"
      "app.kubernetes.io/instance"  = "jenkins"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 8080
      protocol    = "TCP"
    }
  }

  depends_on = [helm_release.jenkins]
}