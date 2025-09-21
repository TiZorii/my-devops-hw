output "bucket_name" {
  description = "Ім'я створеного S3 бакету"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "bucket_url" {
  description = "URL S3 бакету"
  value       = "https://${aws_s3_bucket.terraform_state.bucket}.s3.${aws_s3_bucket.terraform_state.region}.amazonaws.com"
}

output "bucket_arn" {
  description = "ARN S3 бакету"
  value       = aws_s3_bucket.terraform_state.arn
}

output "dynamodb_table_name" {
  description = "Ім'я створеної DynamoDB таблиці"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "dynamodb_table_arn" {
  description = "ARN DynamoDB таблиці"
  value       = aws_dynamodb_table.terraform_locks.arn
}