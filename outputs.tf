# outputs.tf - Загальне виведення ресурсів

# Виходи з модуля S3 Backend
output "s3_bucket_name" {
  description = "Ім'я S3 бакету для стейтів"
  value       = module.s3_backend.bucket_name
}

output "s3_bucket_url" {
  description = "URL S3 бакету"
  value       = module.s3_backend.bucket_url
}

output "dynamodb_table_name" {
  description = "Ім'я DynamoDB таблиці"
  value       = module.s3_backend.dynamodb_table_name
}

# Виходи з модуля VPC
output "vpc_id" {
  description = "ID створеного VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs публічних підмереж"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs приватних підмереж"
  value       = module.vpc.private_subnet_ids
}

output "internet_gateway_id" {
  description = "ID Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

output "nat_gateway_ids" {
  description = "IDs NAT Gateways"
  value       = module.vpc.nat_gateway_ids
}

# Виходи з модуля ECR
output "ecr_repository_url" {
  description = "URL ECR репозиторію"
  value       = module.ecr.repository_url
}

output "ecr_repository_name" {
  description = "Ім'я ECR репозиторію"
  value       = module.ecr.repository_name
}