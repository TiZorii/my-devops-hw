output "repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.django_app.repository_url
}

output "repository_arn" {
  description = "ECR repository ARN"  
  value       = aws_ecr_repository.django_app.arn
}
