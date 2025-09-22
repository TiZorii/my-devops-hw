# ===========================================
# VPC Module - Main VPC Resources
# ===========================================

# Локальні змінні для обчислення CIDR блоків
locals {
  # Назва префікс
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Кількість AZ
  az_count = length(var.availability_zones)
  
  # Автоматичне обчислення CIDR блоків якщо не вказано
  public_subnet_cidrs = length(var.public_subnet_cidrs) > 0 ? var.public_subnet_cidrs : [
    for i in range(local.az_count) : cidrsubnet(var.vpc_cidr, 8, i)
  ]
  
  private_subnet_cidrs = length(var.private_subnet_cidrs) > 0 ? var.private_subnet_cidrs : [
    for i in range(local.az_count) : cidrsubnet(var.vpc_cidr, 8, i + 10)
  ]
  
  database_subnet_cidrs = length(var.database_subnet_cidrs) > 0 ? var.database_subnet_cidrs : [
    for i in range(local.az_count) : cidrsubnet(var.vpc_cidr, 8, i + 20)
  ]
}

# ===========================================
# VPC
# ===========================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  
  tags = merge(var.tags, {
    Name = "${local.name_prefix}-vpc"
    Type = "vpc"
  })
}

# ===========================================
# Internet Gateway
# ===========================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(var.tags, {
    Name = "${local.name_prefix}-igw"
    Type = "internet-gateway"
  })
  
  depends_on = [aws_vpc.main]
}

# ===========================================
# Public Subnets
# ===========================================

resource "aws_subnet" "public" {
  count = local.az_count
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  
  # Автоматичне присвоєння публічних IP для інстансів
  map_public_ip_on_launch = true
  
  tags = merge(
    var.tags,
    var.public_subnet_tags,
    {
      Name = "${local.name_prefix}-public-${substr(var.availability_zones[count.index], -1, 1)}"
      Type = "public"
      AZ   = var.availability_zones[count.index]
      Tier = "public"
    }
  )
  
  depends_on = [aws_vpc.main]
}

# ===========================================
# Private Subnets
# ===========================================

resource "aws_subnet" "private" {
  count = local.az_count
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  
  # Приватні підмережі не отримують публічні IP
  map_public_ip_on_launch = false
  
  tags = merge(
    var.tags,
    var.private_subnet_tags,
    {
      Name = "${local.name_prefix}-private-${substr(var.availability_zones[count.index], -1, 1)}"
      Type = "private"
      AZ   = var.availability_zones[count.index]
      Tier = "private"
    }
  )
  
  depends_on = [aws_vpc.main]
}

# ===========================================
# Database Subnets
# ===========================================

resource "aws_subnet" "database" {
  count = local.az_count
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.database_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  
  # База даних не потребує публічних IP
  map_public_ip_on_launch = false
  
  tags = merge(
    var.tags,
    var.database_subnet_tags,
    {
      Name = "${local.name_prefix}-database-${substr(var.availability_zones[count.index], -1, 1)}"
      Type = "database"
      AZ   = var.availability_zones[count.index]
      Tier = "database"
    }
  )
  
  depends_on = [aws_vpc.main]
}

# ===========================================
# Elastic IPs for NAT Gateways
# ===========================================

resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : local.az_count) : 0
  
  domain = "vpc"
  
  tags = merge(var.tags, {
    Name = var.single_nat_gateway ? "${local.name_prefix}-nat-eip" : "${local.name_prefix}-nat-eip-${count.index + 1}"
    Type = "elastic-ip"
  })
  
  depends_on = [aws_internet_gateway.main]
}

# ===========================================
# NAT Gateways
# ===========================================

resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : local.az_count) : 0
  
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = merge(var.tags, {
    Name = var.single_nat_gateway ? "${local.name_prefix}-nat-gw" : "${local.name_prefix}-nat-gw-${count.index + 1}"
    Type = "nat-gateway"
    AZ   = var.availability_zones[count.index]
  })
  
  depends_on = [aws_internet_gateway.main, aws_eip.nat]
}

# ===========================================
# Database Subnet Group (для RDS)
# ===========================================

resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = aws_subnet.database[*].id
  
  tags = merge(var.tags, {
    Name = "${local.name_prefix}-db-subnet-group"
    Type = "database-subnet-group"
  })
  
  depends_on = [aws_subnet.database]
}

# ===========================================
# VPC Flow Logs (опціонально)
# ===========================================

resource "aws_flow_log" "vpc_flow_log" {
  count = var.enable_flow_logs ? 1 : 0
  
  iam_role_arn    = aws_iam_role.flow_log[0].arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log[0].arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
  
  tags = merge(var.tags, {
    Name = "${local.name_prefix}-vpc-flow-logs"
    Type = "flow-logs"
  })
}

resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  count = var.enable_flow_logs ? 1 : 0
  
  name              = "/aws/vpc/flowlogs/${local.name_prefix}"
  retention_in_days = var.flow_logs_retention_days
  
  tags = merge(var.tags, {
    Name = "${local.name_prefix}-vpc-flow-logs"
    Type = "cloudwatch-log-group"
  })
}

resource "aws_iam_role" "flow_log" {
  count = var.enable_flow_logs ? 1 : 0
  
  name = "${local.name_prefix}-flow-logs-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
  
  tags = var.tags
}

resource "aws_iam_role_policy" "flow_log" {
  count = var.enable_flow_logs ? 1 : 0
  
  name = "${local.name_prefix}-flow-logs-policy"
  role = aws_iam_role.flow_log[0].id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}