# VPC
resource "aws_vpc" "main" {
  cidr_block           = local.vpc_cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = local.vpc_tags
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  count = var.enable_internet_gateway ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = local.igw_tags

  depends_on = [aws_vpc.main]
}

# Default Security Group
resource "aws_default_security_group" "default" {
  count = var.manage_default_security_group ? 1 : 0

  vpc_id = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.default_security_group_ingress
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = lookup(ingress.value, "cidr_blocks", null)
      self        = lookup(ingress.value, "self", null)
    }
  }

  dynamic "egress" {
    for_each = var.default_security_group_egress
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = lookup(egress.value, "cidr_blocks", null)
      self        = lookup(egress.value, "self", null)
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-default-sg"
      Type = "Default Security Group"
    }
  )
}

# Default Network ACL
resource "aws_default_network_acl" "default" {
  count = var.manage_default_network_acl ? 1 : 0

  default_network_acl_id = aws_vpc.main.default_network_acl_id

  dynamic "ingress" {
    for_each = var.default_network_acl_ingress
    content {
      rule_no    = ingress.value.rule_no
      action     = ingress.value.action
      from_port  = lookup(ingress.value, "from_port", null)
      to_port    = lookup(ingress.value, "to_port", null)
      protocol   = ingress.value.protocol
      cidr_block = lookup(ingress.value, "cidr_block", null)
    }
  }

  dynamic "egress" {
    for_each = var.default_network_acl_egress
    content {
      rule_no    = egress.value.rule_no
      action     = egress.value.action
      from_port  = lookup(egress.value, "from_port", null)
      to_port    = lookup(egress.value, "to_port", null)
      protocol   = egress.value.protocol
      cidr_block = lookup(egress.value, "cidr_block", null)
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-default-nacl"
      Type = "Default Network ACL"
    }
  )

  lifecycle {
    ignore_changes = [subnet_ids]
  }
}

# DHCP Options Set
resource "aws_vpc_dhcp_options" "main" {
  count = var.enable_dhcp_options ? 1 : 0

  domain_name          = local.dhcp_options_domain_name
  domain_name_servers  = var.dhcp_options_domain_name_servers
  ntp_servers          = var.dhcp_options_ntp_servers
  netbios_name_servers = var.dhcp_options_netbios_name_servers
  netbios_node_type    = var.dhcp_options_netbios_node_type

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-dhcp-options"
      Type = "DHCP Options Set"
    }
  )
}

# DHCP Options Set Association
resource "aws_vpc_dhcp_options_association" "main" {
  count = var.enable_dhcp_options ? 1 : 0

  vpc_id          = aws_vpc.main.id
  dhcp_options_id = aws_vpc_dhcp_options.main[0].id
}

# VPC Flow Logs
resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.enable_flow_logs && var.flow_logs_destination_type == "cloud-watch-logs" ? 1 : 0

  name              = local.flow_logs_log_group_name
  retention_in_days = var.flow_logs_retention_in_days

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-flow-logs"
      Type = "VPC Flow Logs"
    }
  )
}

# IAM Role for VPC Flow Logs
resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs && var.flow_logs_destination_type == "cloud-watch-logs" ? 1 : 0

  name = "${local.vpc_name}-flow-logs-role"

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

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-flow-logs-role"
      Type = "VPC Flow Logs IAM Role"
    }
  )
}

# IAM Policy for VPC Flow Logs
resource "aws_iam_policy" "flow_logs" {
  count = var.enable_flow_logs && var.flow_logs_destination_type == "cloud-watch-logs" ? 1 : 0

  name        = "${local.vpc_name}-flow-logs-policy"
  description = "Policy for VPC Flow Logs"

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
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-flow-logs-policy"
      Type = "VPC Flow Logs IAM Policy"
    }
  )
}

# IAM Role Policy Attachment for VPC Flow Logs
resource "aws_iam_role_policy_attachment" "flow_logs" {
  count = var.enable_flow_logs && var.flow_logs_destination_type == "cloud-watch-logs" ? 1 : 0

  role       = aws_iam_role.flow_logs[0].name
  policy_arn = aws_iam_policy.flow_logs[0].arn
}

# VPC Flow Logs
resource "aws_flow_log" "main" {
  count = var.enable_flow_logs ? 1 : 0

  iam_role_arn         = var.flow_logs_destination_type == "cloud-watch-logs" ? aws_iam_role.flow_logs[0].arn : null
  log_destination      = var.flow_logs_destination_type == "cloud-watch-logs" ? aws_cloudwatch_log_group.flow_logs[0].arn : var.flow_logs_s3_bucket_arn
  log_destination_type = var.flow_logs_destination_type
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-flow-logs"
      Type = "VPC Flow Logs"
    }
  )
} 