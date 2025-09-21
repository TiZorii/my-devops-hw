# modules/rds/aurora.tf

resource "aws_rds_cluster" "main" {
  count = var.use_aurora ? 1 : 0

  cluster_identifier = "${var.project_name}-aurora-cluster"

  # Engine settings
  engine         = var.engine
  engine_version = var.engine_version
  engine_mode    = "provisioned"

  # Database configuration
  database_name   = var.database_name
  master_username = var.username
  master_password = random_password.db_password.result

  # Network & Security
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  # Parameter groups
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main[0].name

  # Backup settings
  backup_retention_period = var.backup_retention_period
  preferred_backup_window = var.backup_window
  preferred_maintenance_window = var.maintenance_window

  # Other settings
  storage_encrypted   = var.storage_encrypted
  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.project_name}-aurora-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  tags = {
    Name    = "${var.project_name}-aurora-cluster"
    Project = var.project_name
    Engine  = var.engine
  }

  depends_on = [
    aws_db_subnet_group.main,
    aws_security_group.db_sg,
    aws_rds_cluster_parameter_group.main
  ]
}

# Aurora Cluster Instances
resource "aws_rds_cluster_instance" "cluster_instances" {
  count = var.use_aurora ? var.aurora_instance_count : 0

  identifier         = "${var.project_name}-aurora-instance-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.main[0].id
  instance_class     = var.instance_class
  engine             = aws_rds_cluster.main[0].engine
  engine_version     = aws_rds_cluster.main[0].engine_version

  # Parameter group
  db_parameter_group_name = aws_db_parameter_group.aurora_instance[0].name

  # Monitoring
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? aws_iam_role.aurora_monitoring[0].arn : null

  # Other settings
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  publicly_accessible       = false

  tags = {
    Name    = "${var.project_name}-aurora-instance-${count.index + 1}"
    Project = var.project_name
    Engine  = var.engine
  }
}

# IAM role для Aurora monitoring
resource "aws_iam_role" "aurora_monitoring" {
  count = var.use_aurora && var.monitoring_interval > 0 ? 1 : 0

  name = "${var.project_name}-aurora-monitoring-role"

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
    Name    = "${var.project_name}-aurora-monitoring-role"
    Project = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "aurora_monitoring" {
  count = var.use_aurora && var.monitoring_interval > 0 ? 1 : 0

  role       = aws_iam_role.aurora_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}