# ===========================================
# S3 Backend Module Outputs
# ===========================================

# S3 Bucket Outputs
output "s3_bucket_name" {
  description = "Назва S3 bucket для Terraform state"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "s3_bucket_arn" {
  description = "ARN S3 bucket"
  value       = aws_s3_bucket.terraform_state.arn
}

output "s3_bucket_id" {
  description = "ID S3 bucket"
  value       = aws_s3_bucket.terraform_state.id
}

output "s3_bucket_region" {
  description = "Region S3 bucket"
  value       = aws_s3_bucket.terraform_state.region
}

output "s3_bucket_domain_name" {
  description = "Domain name S3 bucket"
  value       = aws_s3_bucket.terraform_state.bucket_domain_name
}

# DynamoDB Outputs
output "dynamodb_table_name" {
  description = "Назва DynamoDB таблиці для state locking"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "dynamodb_table_arn" {
  description = "ARN DynamoDB таблиці"
  value       = aws_dynamodb_table.terraform_locks.arn
}

output "dynamodb_table_id" {
  description = "ID DynamoDB таблиці"
  value       = aws_dynamodb_table.terraform_locks.id
}

# Backend Configuration
output "backend_config" {
  description = "Готова конфігурація для backend.tf файлу"
  value = {
    bucket         = aws_s3_bucket.terraform_state.bucket
    key            = "terraform.tfstate"
    region         = var.aws_region
    dynamodb_table = aws_dynamodb_table.terraform_locks.name
    encrypt        = true
  }
}

# Terraform Backend Configuration Template
output "terraform_backend_config" {
  description = "Готовий код для backend.tf"
  value = <<-EOT
  terraform {
    backend "s3" {
      bucket         = "${aws_s3_bucket.terraform_state.bucket}"
      key            = "terraform.tfstate"
      region         = "${var.aws_region}"
      dynamodb_table = "${aws_dynamodb_table.terraform_locks.name}"
      encrypt        = true
    }
  }
  EOT
}

# Security Information
output "bucket_encryption" {
  description = "Інформація про шифрування S3 bucket"
  value = {
    sse_algorithm = "AES256"
    encrypted     = true
  }
}

output "backup_policy" {
  description = "Політика резервного копіювання"
  value = {
    versioning_enabled = var.versioning_enabled
    lifecycle_days     = var.lifecycle_expiration_days
    backup_enabled     = var.environment == "prod"
  }
}

# Cost Information
output "estimated_monthly_cost" {
  description = "Приблизна місячна вартість (USD)"
  value = {
    s3_storage_gb     = "First 5GB free in Free Tier"
    s3_requests       = "First 2000 PUT/COPY/POST/LIST requests free"
    dynamodb_requests = "First 25 WCU and 25 RCU free"
    total_estimated   = "$0.00 - $2.00 per month (depending on usage)"
  }
}

# URLs for Management
output "management_urls" {
  description = "Посилання для управління ресурсами в AWS Console"
  value = {
    s3_bucket = "https://s3.console.aws.amazon.com/s3/buckets/${aws_s3_bucket.terraform_state.bucket}"
    dynamodb  = "https://${var.aws_region}.console.aws.amazon.com/dynamodb/home?region=${var.aws_region}#tables:selected=${aws_dynamodb_table.terraform_locks.name}"
  }
}