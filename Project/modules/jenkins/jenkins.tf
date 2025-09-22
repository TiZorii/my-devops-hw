# Jenkins Helm Release
resource "helm_release" "jenkins" {
  name       = "jenkins"
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  version    = "5.1.9"
  namespace  = var.jenkins_namespace
  
  create_namespace = true
  timeout          = 600
  
  values = [
    file("${path.module}/values.yaml")
  ]

  set {
    name  = "controller.admin.password"
    value = var.jenkins_admin_password
  }

  set {
    name  = "controller.serviceAccount.create"
    value = "true"
  }

  set {
    name  = "controller.serviceAccount.name"
    value = "jenkins"
  }

  depends_on = [
    var.eks_cluster_endpoint
  ]
}

# ServiceAccount for Jenkins with proper permissions
resource "kubernetes_cluster_role_binding" "jenkins_cluster_admin" {
  metadata {
    name = "jenkins-cluster-admin"
  }
  
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  
  subject {
    kind      = "ServiceAccount"
    name      = "jenkins"
    namespace = var.jenkins_namespace
  }

  depends_on = [helm_release.jenkins]
}