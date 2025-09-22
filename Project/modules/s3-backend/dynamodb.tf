# ===========================================
# DynamoDB Table for Terraform State Locking
# ===========================================

resource "aws_dynamodb_table" "terraform_locks" {
  name           = "${var.project_name}-${var.environment}-tf-locks"
  billing_mode   = "PAY_PER_REQUEST"  # Найбільш економічно для низького навантаження
  hash_key       = "LockID"

  # Атрибут для hash key
  attribute {
    name = "LockID"
    type = "S"  # String
  }

  # Налаштування TTL (Time To Live) для автоматичного очищення старих записів
  ttl {
    attribute_name = "expires"
    enabled        = true
  }

  # Point-in-time recovery (додаткова безпека)
  point_in_time_recovery {
    enabled = var.environment == "prod" ? true : false
  }

  # Server-side encryption
  server_side_encryption {
    enabled = true
  }

  # Теги
  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-terraform-locks"
    Description = "DynamoDB таблиця для Terraform state locking"
    Purpose     = "terraform-backend"
    BackupPolicy = var.environment == "prod" ? "enabled" : "disabled"
  })

  lifecycle {
    prevent_destroy = false  # Встановлюємо false для dev середовища
  }
}

# ===========================================
# CloudWatch Alarms для DynamoDB (опціонально)
# ===========================================

# Alarm для високого використання Read Capacity
resource "aws_cloudwatch_metric_alarm" "dynamodb_read_throttle" {
  count = var.environment == "prod" ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-dynamodb-read-throttle"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ReadCapacityUnits"
  namespace           = "AWS/DynamoDB"
  period              = "60"
  statistic           = "Sum"
  threshold           = "80"
  alarm_description   = "This metric monitors dynamodb read capacity"

  dimensions = {
    TableName = aws_dynamodb_table.terraform_locks.name
  }

  tags = var.tags
}

# Alarm для високого використання Write Capacity
resource "aws_cloudwatch_metric_alarm" "dynamodb_write_throttle" {
  count = var.environment == "prod" ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-dynamodb-write-throttle"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "WriteCapacityUnits"
  namespace           = "AWS/DynamoDB"
  period              = "60"
  statistic           = "Sum"
  threshold           = "80"
  alarm_description   = "This metric monitors dynamodb write capacity"

  dimensions = {
    TableName = aws_dynamodb_table.terraform_locks.name
  }

  tags = var.tags
}

# ===========================================
# DynamoDB Backup через Point-in-Time Recovery (для production)
# ===========================================

# Замість aws_dynamodb_backup використовуємо CloudFormation або AWS Backup
# Для dev середовища достатньо point-in-time recovery, яке вже увімкнено вище

# CloudWatch Dashboard для моніторингу (опціонально)
resource "aws_cloudwatch_dashboard" "dynamodb_dashboard" {
  count          = var.environment == "prod" ? 1 : 0
  dashboard_name = "${var.project_name}-${var.environment}-dynamodb-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", aws_dynamodb_table.terraform_locks.name],
            [".", "ConsumedWriteCapacityUnits", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "DynamoDB Capacity Units"
          period  = 300
        }
      }
    ]
  })
}