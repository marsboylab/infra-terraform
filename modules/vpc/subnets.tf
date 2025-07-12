# Public Subnets
resource "aws_subnet" "public" {
  count = local.az_count

  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_subnet_cidrs[count.index]
  availability_zone       = local.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    local.public_subnet_tags,
    {
      Name = "${local.vpc_name}-${var.public_subnet_suffix}-${substr(local.availability_zones[count.index], -1, 1)}"
      AZ   = local.availability_zones[count.index]
    }
  )
}

# Private Subnets
resource "aws_subnet" "private" {
  count = local.az_count

  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_subnet_cidrs[count.index]
  availability_zone = local.availability_zones[count.index]

  tags = merge(
    local.private_subnet_tags,
    {
      Name = "${local.vpc_name}-${var.private_subnet_suffix}-${substr(local.availability_zones[count.index], -1, 1)}"
      AZ   = local.availability_zones[count.index]
    }
  )
}

# Database Subnets
resource "aws_subnet" "database" {
  count = local.az_count

  vpc_id            = aws_vpc.main.id
  cidr_block        = local.database_subnet_cidrs[count.index]
  availability_zone = local.availability_zones[count.index]

  tags = merge(
    local.database_subnet_tags,
    {
      Name = "${local.vpc_name}-${var.database_subnet_suffix}-${substr(local.availability_zones[count.index], -1, 1)}"
      AZ   = local.availability_zones[count.index]
    }
  )
}

# Database Subnet Group
resource "aws_db_subnet_group" "database" {
  count = local.az_count > 0 ? 1 : 0

  name       = "${local.vpc_name}-database-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-database-subnet-group"
      Type = "Database Subnet Group"
    }
  )
}

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "database" {
  count = local.az_count > 0 ? 1 : 0

  name       = "${local.vpc_name}-elasticache-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-elasticache-subnet-group"
      Type = "ElastiCache Subnet Group"
    }
  )
}

# Redshift Subnet Group
resource "aws_redshift_subnet_group" "database" {
  count = local.az_count > 0 ? 1 : 0

  name       = "${local.vpc_name}-redshift-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-redshift-subnet-group"
      Type = "Redshift Subnet Group"
    }
  )
}

# Neptune Subnet Group
resource "aws_neptune_subnet_group" "database" {
  count = local.az_count > 0 ? 1 : 0

  name       = "${local.vpc_name}-neptune-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-neptune-subnet-group"
      Type = "Neptune Subnet Group"
    }
  )
}

# DocDB Subnet Group
resource "aws_docdb_subnet_group" "database" {
  count = local.az_count > 0 ? 1 : 0

  name       = "${local.vpc_name}-docdb-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-docdb-subnet-group"
      Type = "DocumentDB Subnet Group"
    }
  )
}

# Public Network ACL
resource "aws_network_acl" "public" {
  count = var.public_dedicated_network_acl ? 1 : 0

  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.public[*].id

  ingress {
    rule_no    = 100
    action     = "allow"
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
  }

  egress {
    rule_no    = 100
    action     = "allow"
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-public-nacl"
      Type = "Public Network ACL"
    }
  )
}

# Private Network ACL
resource "aws_network_acl" "private" {
  count = var.private_dedicated_network_acl ? 1 : 0

  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.private[*].id

  ingress {
    rule_no    = 100
    action     = "allow"
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
    cidr_block = local.vpc_cidr_block
  }

  egress {
    rule_no    = 100
    action     = "allow"
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
    cidr_block = "0.0.0.0/0"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-private-nacl"
      Type = "Private Network ACL"
    }
  )
}

# Database Network ACL
resource "aws_network_acl" "database" {
  count = var.database_dedicated_network_acl ? 1 : 0

  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.database[*].id

  ingress {
    rule_no    = 100
    action     = "allow"
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
    cidr_block = local.vpc_cidr_block
  }

  egress {
    rule_no    = 100
    action     = "allow"
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
    cidr_block = local.vpc_cidr_block
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-database-nacl"
      Type = "Database Network ACL"
    }
  )
} 