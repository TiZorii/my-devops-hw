# modules/rds/outputs.tf

# RDS Instance outputs
output "endpoint" {
  description = "Database endpoint"
  value = var.use_aurora ? (
    length(aws_rds_cluster.main) > 0 ? aws_rds_cluster.main[0].endpoint : ""
  ) : (
    length(aws_db_instance.main) > 0 ? aws_db_instance.main[0].endpoint : ""
  )
}

output "reader_endpoint" {
  description = "Aurora cluster reader endpoint (Aurora only)"
  value = var.use_aurora && length(aws_rds_cluster.main) > 0 ? aws_rds_cluster.main[0].reader_endpoint : null
}

output "port" {
  description = "Database port"
  value = var.use_aurora ? (
    length(aws_rds_cluster.main) > 0 ? aws_rds_cluster.main[0].port : var.port
  ) : (
    length(aws_db_instance.main) > 0 ? aws_db_instance.main[0].port : var.port
  )
}

output "database_name" {
  description = "Name of the database"
  value = var.database_name
}

output "username" {
  description = "Database master username"
  value = var.username
}

output "password" {
  description = "Database master password"
  value = random_password.db_password.result
  sensitive = true
}

# Connection string
output "connection_string" {
  description = "Database connection string"
  value = var.use_aurora ? (
    length(aws_rds_cluster.main) > 0 ? 
    "postgresql://${var.username}:${random_password.db_password.result}@${aws_rds_cluster.main[0].endpoint}:${aws_rds_cluster.main[0].port}/${var.database_name}" :
    ""
  ) : (
    length(aws_db_instance.main) > 0 ? 
    "${var.engine}://${var.username}:${random_password.db_password.result}@${aws_db_instance.main[0].endpoint}:${aws_db_instance.main[0].port}/${var.database_name}" :
    ""
  )
  sensitive = true
}

# Resource identifiers
output "db_instance_identifier" {
  description = "RDS instance identifier"
  value = var.use_aurora ? null : (
    length(aws_db_instance.main) > 0 ? aws_db_instance.main[0].identifier : null
  )
}

output "cluster_identifier" {
  description = "Aurora cluster identifier"
  value = var.use_aurora ? (
    length(aws_rds_cluster.main) > 0 ? aws_rds_cluster.main[0].cluster_identifier : null
  ) : null
}

output "cluster_members" {
  description = "Aurora cluster member identifiers"
  value = var.use_aurora ? (
    length(aws_rds_cluster.main) > 0 ? aws_rds_cluster.main[0].cluster_members : []
  ) : []
}

# Security and Networking
output "security_group_id" {
  description = "ID of the database security group"
  value = aws_security_group.db_sg.id
}

output "subnet_group_name" {
  description = "Name of the DB subnet group"
  value = aws_db_subnet_group.main.name
}

# Additional info
output "engine" {
  description = "Database engine"
  value = var.engine
}

output "engine_version" {
  description = "Database engine version"
  value = var.engine_version
}

output "instance_class" {
  description = "Database instance class"
  value = var.instance_class
}

output "storage_encrypted" {
  description = "Whether storage is encrypted"
  value = var.storage_encrypted
}