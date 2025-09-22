# ===========================================
# RDS Module - Outputs
# ===========================================

# ===========================================
# Database Connection Information
# ===========================================

output "db_instance_id" {
  description = "ID RDS інстанса"
  value       = aws_db_instance.main.id
}

output "db_instance_arn" {
  description = "ARN RDS інстанса"
  value       = aws_db_instance.main.arn
}

output "db_instance_endpoint" {
  description = "RDS інстанс endpoint"
  value       = aws_db_instance.main.endpoint
}

output "db_instance_hosted_zone_id" {
  description = "Hosted zone ID RDS інстанса"
  value       = aws_db_instance.main.hosted_zone_id
}

output "db_instance_port" {
  description = "Порт RDS інстанса"
  value       = aws_db_instance.main.port
}

output "db_name" {
  description = "Назва бази даних"
  value       = aws_db_instance.main.db_name
}

output "db_username" {
  description = "Головний користувач бази даних"
  value       = aws_db_instance.main.username
  sensitive   = true
}

# ===========================================
# Connection String
# ===========================================

output "db_connection_string" {
  description = "PostgreSQL connection string"
  value       = "postgresql://${aws_db_instance.main.username}:${var.db_password != null ? var.db_password : random_password.db_password[0].result}@${aws_db_instance.main.endpoint}:${aws_db_instance.main.port}/${aws_db_instance.main.db_name}"
  sensitive   = true
}

output "db_connection_parameters" {
  description = "Параметри підключення до бази даних"
  value = {
    host     = aws_db_instance.main.address
    port     = aws_db_instance.main.port
    database = aws_db_instance.main.db_name
    username = aws_db_instance.main.username
    password = var.db_password != null ? var.db_password : random_password.db_password[0].result
  }
  sensitive = true
}

# ===========================================
# Django Configuration
# ===========================================

output "django_database_config" {
  description = "Конфігурація бази даних для Django"
  value = {
    ENGINE   = "django.db.backends.postgresql"
    NAME     = aws_db_instance.main.db_name
    USER     = aws_db_instance.main.username
    PASSWORD = var.db_password != null ? var.db_password : random_password.db_password[0].result
    HOST     = aws_db_instance.main.address
    PORT     = aws_db_instance.main.port
  }
  sensitive = true
}

# ===========================================
# Kubernetes ConfigMap/Secret Data
# ===========================================

output "k8s_config_data" {
  description = "Дані для Kubernetes ConfigMap"
  value = {
    DATABASE_HOST = aws_db_instance.main.address
    DATABASE_PORT = tostring(aws_db_instance.main.port)
    DATABASE_NAME = aws_db_instance.main.db_name
    DATABASE_USER = aws_db_instance.main.username
  }
}

output "k8s_secret_data" {
  description = "Дані для Kubernetes Secret"
  value = {
    DATABASE_PASSWORD = base64encode(var.db_password != null ? var.db_password : random_password.db_password[0].result)
    DATABASE_URL      = base64encode("postgresql://${aws_db_instance.main.username}:${var.db_password != null ? var.db_password : random_password.db_password[0].result}@${aws_db_instance.main.endpoint}:${aws_db_instance.main.port}/${aws_db_instance.main.db_name}")
  }
  sensitive = true
}

# ===========================================
# Secrets Manager Information
# ===========================================

output "secrets_manager_secret_arn" {
  description = "ARN Secrets Manager secret"
  value       = var.store_credentials_in_secrets_manager ? aws_secretsmanager_secret.db_credentials[0].arn : null
}

output "secrets_manager_secret_name" {
  description = "Назва Secrets Manager secret"
  value       = var.store_credentials_in_secrets_manager ? aws_secretsmanager_secret.db_credentials[0].name : null
}

# ===========================================
# Security Information
# ===========================================

output "db_security_group_id" {
  description = "ID security group RDS"
  value       = aws_security_group.rds.id
}

output "db_parameter_group_name" {
  description = "Назва parameter group"
  value       = aws_db_parameter_group.main.name
}

# ===========================================
# Monitoring Information
# ===========================================

output "db_instance_status" {
  description = "Статус RDS інстанса"
  value       = aws_db_instance.main.status
}

output "db_instance_class" {
  description = "Клас RDS інстанса"
  value       = aws_db_instance.main.instance_class
}

output "db_engine_version" {
  description = "Версія PostgreSQL"
  value       = aws_db_instance.main.engine_version
}

output "db_allocated_storage" {
  description = "Виділене сховище (GB)"
  value       = aws_db_instance.main.allocated_storage
}

output "db_storage_encrypted" {
  description = "Чи шифроване сховище"
  value       = aws_db_instance.main.storage_encrypted
}

# ===========================================
# Backup Information
# ===========================================

output "db_backup_retention_period" {
  description = "Період зберігання backup"
  value       = aws_db_instance.main.backup_retention_period
}

output "db_backup_window" {
  description = "Вікно backup"
  value       = aws_db_instance.main.backup_window
}

output "db_maintenance_window" {
  description = "Вікно обслуговування"
  value       = aws_db_instance.main.maintenance_window
}

# ===========================================
# Cost Information
# ===========================================

output "estimated_monthly_cost" {
  description = "Приблизна щомісячна вартість RDS"
  value = {
    instance_hours = "${var.db_instance_class == "db.t3.micro" ? "15-20" : "40-60"}/month"
    storage_gb     = "$0.115/GB/month for gp3"
    backup_storage = "$0.095/GB/month (beyond free tier)"
    data_transfer  = "$0.09/GB (out to internet)"
    free_tier      = var.db_instance_class == "db.t3.micro" ? "750 hours/month free (12 months)" : "Not eligible"
    estimated_total = var.db_instance_class == "db.t3.micro" ? "$0-25/month (with free tier)" : "$50-80/month"
    optimization   = "Use db.t3.micro and gp3 storage for cost savings"
  }
}

# ===========================================
# Management URLs
# ===========================================

output "management_urls" {
  description = "Посилання для управління в AWS Console"
  value = {
    rds_instance = "https://${data.aws_region.current.name}.console.aws.amazon.com/rds/home?region=${data.aws_region.current.name}#database:id=${aws_db_instance.main.id}"
    parameter_group = "https://${data.aws_region.current.name}.console.aws.amazon.com/rds/home?region=${data.aws_region.current.name}#parameter-groups:id=${aws_db_parameter_group.main.name}"
    security_group = "https://${data.aws_region.current.name}.console.aws.amazon.com/ec2/v2/home?region=${data.aws_region.current.name}#SecurityGroups:search=${aws_security_group.rds.id}"
    secrets_manager = var.store_credentials_in_secrets_manager ? "https://${data.aws_region.current.name}.console.aws.amazon.com/secretsmanager/home?region=${data.aws_region.current.name}#/secret?name=${aws_secretsmanager_secret.db_credentials[0].name}" : null
  }
}

# ===========================================
# Summary Information
# ===========================================

output "rds_summary" {
  description = "Підсумок конфігурації RDS"
  value = {
    instance_id      = aws_db_instance.main.id
    endpoint         = aws_db_instance.main.endpoint
    port            = aws_db_instance.main.port
    database_name   = aws_db_instance.main.db_name
    engine_version  = aws_db_instance.main.engine_version
    instance_class  = aws_db_instance.main.instance_class
    allocated_storage = aws_db_instance.main.allocated_storage
    storage_encrypted = aws_db_instance.main.storage_encrypted
    multi_az        = aws_db_instance.main.multi_az
    backup_retention = aws_db_instance.main.backup_retention_period
    secrets_stored  = var.store_credentials_in_secrets_manager
    estimated_cost  = var.db_instance_class == "db.t3.micro" ? "$0-25/month" : "$50-80/month"
  }
}

# ===========================================
# Data sources
# ===========================================

data "aws_region" "current" {}