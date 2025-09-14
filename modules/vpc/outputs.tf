output "vpc_id" {
  description = "ID створеного VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR блок VPC"
  value       = aws_vpc.main.cidr_block
}

output "internet_gateway_id" {
  description = "ID Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "public_subnet_ids" {
  description = "IDs публічних підмереж"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs приватних підмереж"
  value       = aws_subnet.private[*].id
}

output "nat_gateway_ids" {
  description = "IDs NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

output "public_route_table_id" {
  description = "ID публічної route table"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "IDs приватних route tables"
  value       = aws_route_table.private[*].id
}