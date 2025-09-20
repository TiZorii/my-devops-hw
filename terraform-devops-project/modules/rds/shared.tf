# modules/rds/shared.tf

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name    = "${var.project_name}-db-subnet-group"
    Project = var.project_name
  }
}

# Security Group для БД
resource "aws_security_group" "db_sg" {
  name_prefix = "${var.project_name}-db-sg"
  vpc_id      = var.vpc_id

  # Вхідний трафік з приватних підмереж
  ingress {
    from_port   = var.port
    to_port     = var.port
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
    description = "Database access from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-db-security-group"
    Project = var.project_name
  }
}

# Data source для VPC CIDR
data "aws_vpc" "main" {
  id = var.vpc_id
}

# Parameter Group для звичайної RDS
resource "aws_db_parameter_group" "main" {
  count = var.use_aurora ? 0 : 1

  family = var.parameter_group_family
  name   = "${var.project_name}-db-params"

  dynamic "parameter" {
    for_each = var.db_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = {
    Name    = "${var.project_name}-db-parameter-group"
    Project = var.project_name
  }
}

# Cluster Parameter Group для Aurora
resource "aws_rds_cluster_parameter_group" "main" {
  count = var.use_aurora ? 1 : 0

  family = var.parameter_group_family
  name   = "${var.project_name}-aurora-cluster-params"

  dynamic "parameter" {
    for_each = var.db_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = {
    Name    = "${var.project_name}-aurora-cluster-parameter-group"
    Project = var.project_name
  }
}

# DB Parameter Group для Aurora instances
resource "aws_db_parameter_group" "aurora_instance" {
  count = var.use_aurora ? 1 : 0

  family = var.parameter_group_family
  name   = "${var.project_name}-aurora-instance-params"

  dynamic "parameter" {
    for_each = var.instance_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = {
    Name    = "${var.project_name}-aurora-instance-parameter-group"
    Project = var.project_name
  }
}

# Random password для БД
resource "random_password" "db_password" {
  length  = 16
  special = true
}