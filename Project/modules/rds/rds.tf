# ===========================================
# RDS Module - PostgreSQL Database
# ===========================================

# Локальні змінні
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Налаштування для різних середовищ
  is_production = var.environment == "prod"
  
  # Backup налаштування
  backup_retention_period = local.is_production ? 7 : 3
  backup_window          = "03:00-04:00"  # UTC
  maintenance_window     = "sun:04:00-sun:05:00"  # UTC
  
  # Performance налаштування
  performance_insights_enabled = local.is_production ? true : false
  monitoring_interval        = local.is_production ? 60 : 0
}

# ===========================================
# DB Subnet Group (використовуємо з VPC модуля)
# ===========================================

data "aws_db_subnet_group" "main" {
  name = var.db_subnet_group_name
}

# ===========================================
# Security Group для RDS
# ===========================================

resource "aws_security_group" "rds" {
  name_prefix = "${local.name_prefix}-rds-"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = var.vpc_id

  # Вхідний трафік тільки з EKS
  ingress {
    description     = "PostgreSQL from EKS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
  }

  ingress {
    description = "PostgreSQL from private subnets"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-rds-sg"
    Type = "security-group"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ===========================================
# DB Parameter Group
# ===========================================

resource "aws_db_parameter_group" "main" {
  family = "postgres15"
  name   = "${local.name_prefix}-postgres-params"

  # Оптимізації для розробки
  parameter {
    name  = "log_statement"
    value = var.environment == "dev" ? "all" : "ddl"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"  # Log queries longer than 1 second
  }

  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-postgres-params"
    Type = "db-parameter-group"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ===========================================
# Random Password (якщо не вказано)
# ===========================================

resource "random_password" "db_password" {
  count = var.db_password == null ? 1 : 0
  
  length  = 16
  special = true
}

# ===========================================
# RDS Instance
# ===========================================

resource "aws_db_instance" "main" {
  identifier         = "${local.name_prefix}-postgres"
  engine             = "postgres"
  engine_version     = "15.14"      # <- версія, яка є у твоєму регіоні
  instance_class     = var.db_instance_class
  allocated_storage  = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type       = var.db_storage_type
  storage_encrypted  = var.db_storage_encrypted
  kms_key_id         = var.kms_key_id

  db_name   = var.db_name
  username  = var.db_username
  password  = var.db_password != null ? var.db_password : random_password.db_password[0].result

  db_subnet_group_name   = data.aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  port                   = 5432

  backup_retention_period = local.backup_retention_period
  backup_window          = local.backup_window
  copy_tags_to_snapshot  = true
  delete_automated_backups = !local.is_production

  maintenance_window         = local.maintenance_window
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  parameter_group_name       = aws_db_parameter_group.main.name

  performance_insights_enabled    = local.performance_insights_enabled
  performance_insights_kms_key_id = var.kms_key_id

  monitoring_interval = local.monitoring_interval
  monitoring_role_arn = local.monitoring_interval > 0 ? aws_iam_role.rds_enhanced_monitoring[0].arn : null

  multi_az            = local.is_production
  deletion_protection  = local.is_production
  skip_final_snapshot  = !local.is_production
  final_snapshot_identifier = local.is_production ? "${local.name_prefix}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}" : null

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-postgres"
    Type = "rds-instance"
  })

  depends_on = [aws_db_parameter_group.main]
}

# ===========================================
# IAM Role для Enhanced Monitoring
# ===========================================

resource "aws_iam_role" "rds_enhanced_monitoring" {
  count = local.monitoring_interval > 0 ? 1 : 0
  
  name = "${local.name_prefix}-rds-monitoring-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
  
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  count = local.monitoring_interval > 0 ? 1 : 0
  
  role       = aws_iam_role.rds_enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# ===========================================
# Secrets Manager (опціонально)
# ===========================================

resource "aws_secretsmanager_secret" "db_credentials" {
  count = var.store_credentials_in_secrets_manager ? 1 : 0
  
  name                    = "${local.name_prefix}-db-credentials"
  description             = "Database credentials for ${local.name_prefix}"
  recovery_window_in_days = var.environment == "prod" ? 30 : 0
  
  tags = merge(var.tags, {
    Name = "${local.name_prefix}-db-credentials"
    Type = "secret"
  })
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  count = var.store_credentials_in_secrets_manager ? 1 : 0
  
  secret_id = aws_secretsmanager_secret.db_credentials[0].id
  secret_string = jsonencode({
    username = aws_db_instance.main.username
    password = var.db_password != null ? var.db_password : random_password.db_password[0].result
    endpoint = aws_db_instance.main.endpoint
    port     = aws_db_instance.main.port
    dbname   = aws_db_instance.main.db_name
    url      = "postgresql://${aws_db_instance.main.username}:${var.db_password != null ? var.db_password : random_password.db_password[0].result}@${aws_db_instance.main.endpoint}:${aws_db_instance.main.port}/${aws_db_instance.main.db_name}"
  })
}
