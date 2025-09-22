output "jenkins_service_name" {
  description = "Jenkins service name"
  value       = "${helm_release.jenkins.name}"
}

output "jenkins_namespace" {
  description = "Jenkins namespace"
  value       = var.jenkins_namespace
}

output "jenkins_admin_password" {
  description = "Jenkins admin password"
  value       = var.jenkins_admin_password
  sensitive   = true
}

output "jenkins_url_internal" {
  description = "Internal Jenkins URL (for port-forward)"
  value       = "http://jenkins.${var.jenkins_namespace}.svc.cluster.local:8080"
}

output "port_forward_command" {
  description = "Command to port-forward Jenkins"
  value       = "kubectl port-forward svc/jenkins 8080:8080 -n ${var.jenkins_namespace}"
}