# ===========================================
# S3 Bucket for Terraform State
# ===========================================

# Генерація унікального суфікса для S3 bucket (глобальна унікальність)
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Створення S3 bucket для Terraform state
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "${var.project_name}-${var.environment}-tf-state-${random_id.bucket_suffix.hex}"
  force_destroy = var.force_destroy

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-terraform-state"
    Description = "S3 bucket для зберігання Terraform state файлів"
    Purpose     = "terraform-backend"
    BackupPolicy = "enabled"
  })

  lifecycle {
    prevent_destroy = false  # Встановлюємо false для dev середовища
  }
}

# ===========================================
# S3 Bucket Configuration
# ===========================================

# Налаштування версіонування
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  versioning_configuration {
    status     = var.versioning_enabled ? "Enabled" : "Suspended"
    mfa_delete = var.mfa_delete ? "Enabled" : "Disabled"
  }
}

# Налаштування серверного шифрування (AES256 - безкоштовно)
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    
    bucket_key_enabled = true  # Зменшує витрати на KMS (якщо використовуватимемо)
  }
}

# Блокування публічного доступу (безпека)
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Налаштування CORS (якщо потрібно)
resource "aws_s3_bucket_cors_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }
}

# Налаштування lifecycle для управління старими версіями
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "terraform_state_lifecycle"
    status = "Enabled"

    # Фільтр для всіх об'єктів
    filter {
      prefix = ""
    }

    # Очищення незавершених multipart uploads
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    # Переведення старих версій у дешевший клас зберігання
    # AWS вимагає: expiration_days > transition_days
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 60
      storage_class   = "GLACIER"
    }

    # Видалення старих версій (має бути більше за найбільший transition)
    noncurrent_version_expiration {
      noncurrent_days = 90  # Більше за 60 днів (найбільший transition)
    }
  }

  # Правило для поточних об'єктів
  rule {
    id     = "current_objects_lifecycle"
    status = "Enabled"

    # Фільтр для всіх об'єктів
    filter {
      prefix = ""
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }

    # Видалення поточних об'єктів (опціонально, для економії)
    # expiration {
    #   days = 365  # Зберігаємо state файли рік
    # }
  }
}

# Налаштування логування доступу (опціонально)
resource "aws_s3_bucket_logging" "terraform_state" {
  count = var.environment == "prod" ? 1 : 0

  bucket = aws_s3_bucket.terraform_state.id

  target_bucket = aws_s3_bucket.terraform_state.id
  target_prefix = "access-logs/"
}

# Налаштування notification (опціонально для моніторингу)
resource "aws_s3_bucket_notification" "terraform_state" {
  count = var.environment == "prod" ? 1 : 0

  bucket = aws_s3_bucket.terraform_state.id

  # Тут можна додати SNS/SQS/Lambda notifications
}

# ===========================================
# S3 Bucket Policy (додаткова безпека)
# ===========================================

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureConnections"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid    = "AllowTerraformAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/*"
        ]
      }
    ]
  })
}