# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.enable_internet_gateway ? aws_internet_gateway.main[0].id : null
  }

  tags = merge(
    local.public_route_table_tags,
    {
      Name = "${local.vpc_name}-public-rt"
    }
  )
}

# Private Route Tables
resource "aws_route_table" "private" {
  count = local.az_count

  vpc_id = aws_vpc.main.id

  tags = merge(
    local.private_route_table_tags,
    {
      Name = "${local.vpc_name}-private-rt-${count.index + 1}"
    }
  )
}

# Database Route Tables
resource "aws_route_table" "database" {
  count = local.az_count

  vpc_id = aws_vpc.main.id

  tags = merge(
    local.database_route_table_tags,
    {
      Name = "${local.vpc_name}-database-rt-${count.index + 1}"
    }
  )
}

# Routes for private subnets to NAT Gateway
resource "aws_route" "private_nat_gateway" {
  count = var.enable_nat_gateway ? local.az_count : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[var.single_nat_gateway ? 0 : count.index].id

  depends_on = [aws_route_table.private]
}

# Routes for private subnets to NAT Instance
resource "aws_route" "private_nat_instance" {
  count = var.enable_nat_gateway ? 0 : local.az_count

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  instance_id            = aws_instance.nat[var.single_nat_gateway ? 0 : count.index].id

  depends_on = [aws_route_table.private]
}

# Public Subnet Route Table Associations
resource "aws_route_table_association" "public" {
  count = local.az_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Subnet Route Table Associations
resource "aws_route_table_association" "private" {
  count = local.az_count

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Database Subnet Route Table Associations
resource "aws_route_table_association" "database" {
  count = local.az_count

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database[count.index].id
}

# VPC Endpoint Routes for Gateway Endpoints
resource "aws_vpc_endpoint_route_table_association" "gateway" {
  for_each = {
    for k, v in local.gateway_endpoints : k => v
    if length(lookup(v, "route_table_ids", [])) > 0
  }

  vpc_endpoint_id = aws_vpc_endpoint.gateway[each.key].id
  route_table_id  = each.value.route_table_ids[0]
}

# Additional routes for custom requirements
resource "aws_route" "public_internet_gateway" {
  count = var.enable_internet_gateway ? 1 : 0

  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main[0].id

  depends_on = [aws_route_table.public]
}

# VPC Peering Routes (placeholder for future use)
# resource "aws_route" "vpc_peering" {
#   count = length(var.vpc_peering_connections)
#   
#   route_table_id            = aws_route_table.private[count.index].id
#   destination_cidr_block    = var.vpc_peering_connections[count.index].peer_cidr_block
#   vpc_peering_connection_id = var.vpc_peering_connections[count.index].id
#   
#   depends_on = [aws_route_table.private]
# }

# Transit Gateway Routes (placeholder for future use)
# resource "aws_route" "transit_gateway" {
#   count = var.enable_transit_gateway ? local.az_count : 0
#   
#   route_table_id         = aws_route_table.private[count.index].id
#   destination_cidr_block = var.transit_gateway_destination_cidr_block
#   transit_gateway_id     = var.transit_gateway_id
#   
#   depends_on = [aws_route_table.private]
# } 