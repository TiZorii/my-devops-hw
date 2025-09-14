output "repository_url" {
  description = "URL ECR репозиторію"
  value       = aws_ecr_repository.main.repository_url
}

output "repository_name" {
  description = "Ім'я ECR репозиторію"
  value       = aws_ecr_repository.main.name
}

output "repository_arn" {
  description = "ARN ECR репозиторію"
  value       = aws_ecr_repository.main.arn
}

output "registry_id" {
  description = "AWS Account ID (Registry ID)"
  value       = aws_ecr_repository.main.registry_id
}