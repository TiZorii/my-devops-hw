variable "bucket_name" {
  description = "Ім'я S3 бакету для збереження Terraform стейтів"
  type        = string

  validation {
    condition     = length(var.bucket_name) > 3 && length(var.bucket_name) < 64
    error_message = "Ім'я бакету повинно бути від 3 до 63 символів."
  }
}

variable "table_name" {
  description = "Ім'я DynamoDB таблиці для блокування стейтів"
  type        = string
  default     = "terraform-locks"
}