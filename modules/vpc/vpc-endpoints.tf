# Security Group for VPC Endpoints
resource "aws_security_group" "vpc_endpoints" {
  count = length(local.interface_endpoints) > 0 ? 1 : 0

  name_prefix = "${local.vpc_name}-vpce-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-vpce-sg"
      Type = "VPC Endpoints Security Group"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Gateway VPC Endpoints (S3, DynamoDB)
resource "aws_vpc_endpoint" "gateway" {
  for_each = local.gateway_endpoints

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.${each.value.service}"
  vpc_endpoint_type   = "Gateway"
  route_table_ids     = length(lookup(each.value, "route_table_ids", [])) > 0 ? each.value.route_table_ids : concat(aws_route_table.private[*].id, aws_route_table.database[*].id, [aws_route_table.public.id])

  policy = length(lookup(each.value, "policy_statements", [])) > 0 ? jsonencode({
    Version = "2012-10-17"
    Statement = [
      for statement in each.value.policy_statements : {
        Effect   = statement.effect
        Action   = statement.actions
        Resource = statement.resources
      }
    ]
  }) : null

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-vpce-${each.key}"
      Type = "Gateway VPC Endpoint"
    }
  )
}

# Interface VPC Endpoints (EC2, ECR, etc.)
resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_endpoints

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.${each.value.service}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = length(lookup(each.value, "subnet_ids", [])) > 0 ? each.value.subnet_ids : aws_subnet.private[*].id
  security_group_ids  = length(lookup(each.value, "security_group_ids", [])) > 0 ? each.value.security_group_ids : [aws_security_group.vpc_endpoints[0].id]
  
  private_dns_enabled = true

  policy = length(lookup(each.value, "policy_statements", [])) > 0 ? jsonencode({
    Version = "2012-10-17"
    Statement = [
      for statement in each.value.policy_statements : {
        Effect   = statement.effect
        Action   = statement.actions
        Resource = statement.resources
      }
    ]
  }) : null

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-vpce-${each.key}"
      Type = "Interface VPC Endpoint"
    }
  )
}

# Custom VPC Endpoints from variables
resource "aws_vpc_endpoint" "custom" {
  for_each = var.vpc_endpoints

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.${each.value.service}"
  vpc_endpoint_type   = each.value.vpc_endpoint_type
  route_table_ids     = each.value.vpc_endpoint_type == "Gateway" ? each.value.route_table_ids : null
  subnet_ids          = each.value.vpc_endpoint_type == "Interface" ? each.value.subnet_ids : null
  security_group_ids  = each.value.vpc_endpoint_type == "Interface" ? each.value.security_group_ids : null
  
  private_dns_enabled = each.value.vpc_endpoint_type == "Interface" ? true : null

  policy = length(each.value.policy_statements) > 0 ? jsonencode({
    Version = "2012-10-17"
    Statement = [
      for statement in each.value.policy_statements : {
        Effect   = statement.effect
        Action   = statement.actions
        Resource = statement.resources
      }
    ]
  }) : null

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-vpce-custom-${each.key}"
      Type = "Custom VPC Endpoint"
    }
  )
}

# VPC Endpoint for ECR (Docker)
resource "aws_vpc_endpoint" "ecr_docker" {
  count = var.enable_vpc_endpoints && contains(keys(local.interface_endpoints), "ecr_dkr") ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  
  private_dns_enabled = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-vpce-ecr-dkr"
      Type = "ECR Docker VPC Endpoint"
    }
  )
}

# VPC Endpoint for ECS
resource "aws_vpc_endpoint" "ecs" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  
  private_dns_enabled = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-vpce-ecs"
      Type = "ECS VPC Endpoint"
    }
  )
}

# VPC Endpoint for ECS Agent
resource "aws_vpc_endpoint" "ecs_agent" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecs-agent"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  
  private_dns_enabled = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-vpce-ecs-agent"
      Type = "ECS Agent VPC Endpoint"
    }
  )
}

# VPC Endpoint for ECS Telemetry
resource "aws_vpc_endpoint" "ecs_telemetry" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecs-telemetry"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  
  private_dns_enabled = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-vpce-ecs-telemetry"
      Type = "ECS Telemetry VPC Endpoint"
    }
  )
}

# VPC Endpoint for EKS
resource "aws_vpc_endpoint" "eks" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.eks"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  
  private_dns_enabled = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-vpce-eks"
      Type = "EKS VPC Endpoint"
    }
  )
} 