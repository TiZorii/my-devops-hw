# modules/rds/rds.tf

resource "aws_db_instance" "main" {
  count = var.use_aurora ? 0 : 1

  identifier = "${var.project_name}-database"

  # Engine settings
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  # Database settings
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted

  # Database configuration
  db_name  = var.database_name
  username = var.username
  password = random_password.db_password.result

  # Network & Security
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  publicly_accessible    = false

  # Parameter group
  parameter_group_name = aws_db_parameter_group.main[0].name

  # Backup settings
  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window     = var.maintenance_window

  # Monitoring
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? aws_iam_role.rds_monitoring[0].arn : null

  # Other settings
  multi_az               = var.multi_az
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  deletion_protection    = var.deletion_protection
  skip_final_snapshot    = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.project_name}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  tags = {
    Name    = "${var.project_name}-database"
    Project = var.project_name
    Engine  = var.engine
  }

  depends_on = [
    aws_db_subnet_group.main,
    aws_security_group.db_sg,
    aws_db_parameter_group.main
  ]
}

# IAM role для RDS monitoring
resource "aws_iam_role" "rds_monitoring" {
  count = !var.use_aurora && var.monitoring_interval > 0 ? 1 : 0

  name = "${var.project_name}-rds-monitoring-role"

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

  tags = {
    Name    = "${var.project_name}-rds-monitoring-role"
    Project = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count = !var.use_aurora && var.monitoring_interval > 0 ? 1 : 0

  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}