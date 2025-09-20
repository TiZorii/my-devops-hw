# Отримання Load Balancer URL
data "kubernetes_service" "jenkins_lb" {
  metadata {
    name      = "jenkins-lb"
    namespace = "jenkins"
  }

  depends_on = [kubernetes_service.jenkins_loadbalancer]
}

output "jenkins_url" {
  description = "URL to access Jenkins"
  value = length(data.kubernetes_service.jenkins_lb.status[0].load_balancer[0].ingress) > 0 ? (
    data.kubernetes_service.jenkins_lb.status[0].load_balancer[0].ingress[0].hostname != null ?
    "http://${data.kubernetes_service.jenkins_lb.status[0].load_balancer[0].ingress[0].hostname}" :
    "http://${data.kubernetes_service.jenkins_lb.status[0].load_balancer[0].ingress[0].ip}"
  ) : "LoadBalancer is being created..."
}

output "jenkins_admin_password" {
  description = "Jenkins admin password"
  value       = var.jenkins_admin_password
  sensitive   = true
}

output "jenkins_namespace" {
  description = "Jenkins namespace"
  value       = kubernetes_namespace.jenkins.metadata[0].name
}