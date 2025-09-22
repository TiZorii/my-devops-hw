# ===========================================
# VPC Module - Route Tables and Routes
# ===========================================

# ===========================================
# Public Route Table
# ===========================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(var.tags, {
    Name = "${local.name_prefix}-public-rt"
    Type = "public-route-table"
  })
  
  depends_on = [aws_vpc.main]
}

# Route to Internet Gateway for public subnets
resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
  
  depends_on = [aws_route_table.public, aws_internet_gateway.main]
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count = local.az_count
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
  
  depends_on = [aws_subnet.public, aws_route_table.public]
}

# ===========================================
# Private Route Tables
# ===========================================

# Створюємо окрему route table для кожної AZ або одну спільну
resource "aws_route_table" "private" {
  count = var.single_nat_gateway ? 1 : local.az_count
  
  vpc_id = aws_vpc.main.id
  
  tags = merge(var.tags, {
    Name = var.single_nat_gateway ? "${local.name_prefix}-private-rt" : "${local.name_prefix}-private-rt-${count.index + 1}"
    Type = "private-route-table"
    AZ   = var.single_nat_gateway ? "shared" : var.availability_zones[count.index]
  })
  
  depends_on = [aws_vpc.main]
}

# Route to NAT Gateway for private subnets
resource "aws_route" "private_nat_gateway" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : local.az_count) : 0
  
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[count.index].id
  
  depends_on = [aws_route_table.private, aws_nat_gateway.main]
}

# Associate private subnets with private route tables
resource "aws_route_table_association" "private" {
  count = local.az_count
  
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[var.single_nat_gateway ? 0 : count.index].id
  
  depends_on = [aws_subnet.private, aws_route_table.private]
}

# ===========================================
# Database Route Tables
# ===========================================

# Database subnets використовують окремі route tables
resource "aws_route_table" "database" {
  count = var.single_nat_gateway ? 1 : local.az_count
  
  vpc_id = aws_vpc.main.id
  
  tags = merge(var.tags, {
    Name = var.single_nat_gateway ? "${local.name_prefix}-database-rt" : "${local.name_prefix}-database-rt-${count.index + 1}"
    Type = "database-route-table"
    AZ   = var.single_nat_gateway ? "shared" : var.availability_zones[count.index]
  })
  
  depends_on = [aws_vpc.main]
}

# Database subnets можуть мати доступ до інтернету через NAT (для оновлень)
resource "aws_route" "database_nat_gateway" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : local.az_count) : 0
  
  route_table_id         = aws_route_table.database[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[count.index].id
  
  depends_on = [aws_route_table.database, aws_nat_gateway.main]
}

# Associate database subnets with database route tables
resource "aws_route_table_association" "database" {
  count = local.az_count
  
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database[var.single_nat_gateway ? 0 : count.index].id
  
  depends_on = [aws_subnet.database, aws_route_table.database]
}

# ===========================================
# VPN Gateway Routes (опціонально)
# ===========================================

resource "aws_vpn_gateway" "main" {
  count = var.enable_vpn_gateway ? 1 : 0
  
  vpc_id = aws_vpc.main.id
  
  tags = merge(var.tags, {
    Name = "${local.name_prefix}-vpn-gw"
    Type = "vpn-gateway"
  })
  
  depends_on = [aws_vpc.main]
}

resource "aws_vpn_gateway_attachment" "main" {
  count = var.enable_vpn_gateway ? 1 : 0
  
  vpc_id         = aws_vpc.main.id
  vpn_gateway_id = aws_vpn_gateway.main[0].id
  
  depends_on = [aws_vpn_gateway.main]
}

# Propagate VPN gateway routes to route tables
resource "aws_vpn_gateway_route_propagation" "private" {
  count = var.enable_vpn_gateway ? length(aws_route_table.private) : 0
  
  vpn_gateway_id = aws_vpn_gateway.main[0].id
  route_table_id = aws_route_table.private[count.index].id
  
  depends_on = [aws_vpn_gateway.main, aws_route_table.private]
}

resource "aws_vpn_gateway_route_propagation" "database" {
  count = var.enable_vpn_gateway ? length(aws_route_table.database) : 0
  
  vpn_gateway_id = aws_vpn_gateway.main[0].id
  route_table_id = aws_route_table.database[count.index].id
  
  depends_on = [aws_vpn_gateway.main, aws_route_table.database]
}