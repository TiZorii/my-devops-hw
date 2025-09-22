# ===========================================
# VPC Module - Outputs
# ===========================================

# ===========================================
# VPC Outputs
# ===========================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.main.arn
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "vpc_enable_dns_hostnames" {
  description = "Whether DNS hostnames are enabled"
  value       = aws_vpc.main.enable_dns_hostnames
}

output "vpc_enable_dns_support" {
  description = "Whether DNS support is enabled"
  value       = aws_vpc.main.enable_dns_support
}

# ===========================================
# Internet Gateway Outputs
# ===========================================

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "internet_gateway_arn" {
  description = "ARN of the Internet Gateway"
  value       = aws_internet_gateway.main.arn
}

# ===========================================
# Subnet Outputs
# ===========================================

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "public_subnet_arns" {
  description = "ARNs of the public subnets"
  value       = aws_subnet.public[*].arn
}

output "public_subnet_cidr_blocks" {
  description = "CIDR blocks of the public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "public_subnet_availability_zones" {
  description = "Availability zones of the public subnets"
  value       = aws_subnet.public[*].availability_zone
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "private_subnet_arns" {
  description = "ARNs of the private subnets"
  value       = aws_subnet.private[*].arn
}

output "private_subnet_cidr_blocks" {
  description = "CIDR blocks of the private subnets"
  value       = aws_subnet.private[*].cidr_block
}

output "private_subnet_availability_zones" {
  description = "Availability zones of the private subnets"
  value       = aws_subnet.private[*].availability_zone
}

output "database_subnet_ids" {
  description = "IDs of the database subnets"
  value       = aws_subnet.database[*].id
}

output "database_subnet_arns" {
  description = "ARNs of the database subnets"
  value       = aws_subnet.database[*].arn
}

output "database_subnet_cidr_blocks" {
  description = "CIDR blocks of the database subnets"
  value       = aws_subnet.database[*].cidr_block
}

output "database_subnet_group_id" {
  description = "ID of the database subnet group"
  value       = aws_db_subnet_group.main.id
}

output "database_subnet_group_name" {
  description = "Name of the database subnet group"
  value       = aws_db_subnet_group.main.name
}

# ===========================================
# NAT Gateway Outputs
# ===========================================

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

output "nat_gateway_public_ips" {
  description = "Public IPs of the NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

output "elastic_ip_ids" {
  description = "IDs of the Elastic IPs for NAT Gateways"
  value       = aws_eip.nat[*].id
}

# ===========================================
# Route Table Outputs
# ===========================================

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "IDs of the private route tables"
  value       = aws_route_table.private[*].id
}

output "database_route_table_ids" {
  description = "IDs of the database route tables"
  value       = aws_route_table.database[*].id
}

# ===========================================
# Security Group Outputs (тільки EKS - якщо створені)
# ===========================================

output "eks_cluster_security_group_id" {
  description = "ID of the EKS cluster security group"
  value       = var.create_eks_security_group ? aws_security_group.eks_cluster[0].id : null
}

output "eks_nodes_security_group_id" {
  description = "ID of the EKS nodes security group"
  value       = var.create_eks_security_group ? aws_security_group.eks_nodes[0].id : null
}

# ===========================================
# VPN Gateway Outputs
# ===========================================

output "vpn_gateway_id" {
  description = "ID of the VPN Gateway"
  value       = var.enable_vpn_gateway ? aws_vpn_gateway.main[0].id : null
}

# ===========================================
# Availability Zone Information
# ===========================================

output "availability_zones" {
  description = "List of availability zones used"
  value       = var.availability_zones
}

output "azs_count" {
  description = "Number of availability zones"
  value       = length(var.availability_zones)
}

# ===========================================
# CIDR Information
# ===========================================

output "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  value       = local.public_subnet_cidrs
}

output "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  value       = local.private_subnet_cidrs
}

output "database_subnet_cidrs" {
  description = "CIDR blocks for database subnets"
  value       = local.database_subnet_cidrs
}

# ===========================================
# Cost Information
# ===========================================

output "estimated_monthly_cost" {
  description = "Estimated monthly cost breakdown"
  value = {
    nat_gateway     = var.enable_nat_gateway ? (var.single_nat_gateway ? "$45" : "$${length(var.availability_zones) * 45}") : "$0"
    elastic_ips     = var.enable_nat_gateway ? (var.single_nat_gateway ? "$0" : "$${length(var.availability_zones) * 3.6}") : "$0"
    vpc_flow_logs   = var.enable_flow_logs ? "$5-10" : "$0"
    total_estimated = var.enable_nat_gateway ? "$45-60" : "$0"
    note           = "NAT Gateway is the main cost component. Consider single_nat_gateway=true for cost savings."
  }
}

# ===========================================
# Summary Information
# ===========================================

output "vpc_summary" {
  description = "Summary of VPC configuration"
  value = {
    vpc_id                = aws_vpc.main.id
    vpc_cidr             = aws_vpc.main.cidr_block
    availability_zones   = var.availability_zones
    public_subnets       = length(aws_subnet.public)
    private_subnets      = length(aws_subnet.private)
    database_subnets     = length(aws_subnet.database)
    nat_gateways         = length(aws_nat_gateway.main)
    single_nat_gateway   = var.single_nat_gateway
    enable_flow_logs     = var.enable_flow_logs
    enable_vpn_gateway   = var.enable_vpn_gateway
  }
}