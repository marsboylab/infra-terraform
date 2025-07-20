# Route53 Resolver Endpoints
resource "aws_route53_resolver_endpoint" "this" {
  for_each = local.resolver_endpoints

  name      = each.value.name
  direction = each.value.direction

  security_group_ids = each.value.security_group_ids

  dynamic "ip_address" {
    for_each = length(each.value.ip_addresses) > 0 ? each.value.ip_addresses : [
      for idx, subnet_id in each.value.subnet_ids : {
        subnet_id = subnet_id
        ip        = null
      }
    ]
    content {
      subnet_id = ip_address.value.subnet_id
      ip        = ip_address.value.ip
    }
  }

  tags = each.value.tags
}

# Route53 Resolver Rules
resource "aws_route53_resolver_rule" "this" {
  for_each = local.resolver_rules

  domain_name          = each.value.domain_name
  name                 = each.value.name
  rule_type            = each.value.rule_type
  resolver_endpoint_id = each.value.resolver_endpoint_id

  dynamic "target_ip" {
    for_each = each.value.target_ips
    content {
      ip   = target_ip.value.ip
      port = target_ip.value.port
    }
  }

  tags = each.value.tags

  depends_on = [
    aws_route53_resolver_endpoint.this
  ]
}

# Route53 Resolver Rule Associations
resource "aws_route53_resolver_rule_association" "this" {
  for_each = local.resolver_rule_associations

  resolver_rule_id = each.value.resolver_rule_id
  vpc_id           = each.value.vpc_id
  name             = each.value.name

  depends_on = [
    aws_route53_resolver_rule.this
  ]
}

# Route53 Resolver Query Log Configurations
resource "aws_route53_resolver_query_log_config" "this" {
  for_each = {
    for k, v in local.resolver_endpoints : k => v
    if var.create_query_logging
  }

  name            = "${local.name_prefix}-${each.key}-resolver-query-log"
  destination_arn = var.create_query_logging ? aws_cloudwatch_log_group.query_logs[0].arn : null

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-${each.key}-resolver-query-log"
      Type = "resolver-query-log-config"
    }
  )

  depends_on = [
    aws_route53_resolver_endpoint.this,
    aws_cloudwatch_log_group.query_logs
  ]
}

# Route53 Resolver Query Log Config Associations
resource "aws_route53_resolver_query_log_config_association" "this" {
  for_each = {
    for association in flatten([
      for endpoint_key, endpoint_config in local.resolver_endpoints : [
        for idx, subnet_id in endpoint_config.subnet_ids : {
          key                      = "${endpoint_key}-${idx}"
          resolver_query_log_config_id = aws_route53_resolver_query_log_config.this[endpoint_key].id
          resource_id              = data.aws_subnet.resolver_subnets["${endpoint_key}-${idx}"].vpc_id
        }
      ]
    ]) : association.key => association
    if var.create_query_logging
  }

  resolver_query_log_config_id = each.value.resolver_query_log_config_id
  resource_id                  = each.value.resource_id

  depends_on = [
    aws_route53_resolver_query_log_config.this
  ]
}

# Data sources for resolver subnets
data "aws_subnet" "resolver_subnets" {
  for_each = {
    for subnet in flatten([
      for endpoint_key, endpoint_config in local.resolver_endpoints : [
        for idx, subnet_id in endpoint_config.subnet_ids : {
          key       = "${endpoint_key}-${idx}"
          subnet_id = subnet_id
        }
      ]
    ]) : subnet.key => subnet
  }

  id = each.value.subnet_id
}

# Route53 Resolver DNSSEC Config
resource "aws_route53_resolver_dnssec_config" "this" {
  for_each = {
    for k, v in local.resolver_endpoints : k => v
    if v.direction == "INBOUND"
  }

  resource_id = data.aws_subnet.resolver_subnets[keys(data.aws_subnet.resolver_subnets)[0]].vpc_id

  depends_on = [
    aws_route53_resolver_endpoint.this
  ]
}

# Security group for resolver endpoints
resource "aws_security_group" "resolver_endpoint" {
  for_each = {
    for k, v in local.resolver_endpoints : k => v
    if length(v.security_group_ids) == 0
  }

  name        = "${local.name_prefix}-${each.key}-resolver-endpoint-sg"
  description = "Security group for Route53 resolver endpoint ${each.key}"
  vpc_id      = data.aws_subnet.resolver_subnets[keys(data.aws_subnet.resolver_subnets)[0]].vpc_id

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "DNS TCP traffic"
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "DNS UDP traffic"
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-${each.key}-resolver-endpoint-sg"
      Type = "security-group"
    }
  )
}

# CloudWatch log group for resolver query logs
resource "aws_cloudwatch_log_group" "resolver_query_logs" {
  count = var.create_query_logging ? 1 : 0

  name              = "${local.query_log_group_name}-resolver"
  retention_in_days = var.query_log_retention_in_days
  kms_key_id        = var.query_log_kms_key_id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.query_log_group_name}-resolver"
      Type = "cloudwatch-log-group"
    }
  )
}

# IAM role for resolver query logging
resource "aws_iam_role" "resolver_query_logging" {
  count = var.create_query_logging ? 1 : 0

  name = "${local.name_prefix}-resolver-query-logging-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "route53resolver.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-resolver-query-logging-role"
      Type = "iam-role"
    }
  )
}

# IAM policy for resolver query logging
resource "aws_iam_role_policy" "resolver_query_logging" {
  count = var.create_query_logging ? 1 : 0

  name = "${local.name_prefix}-resolver-query-logging-policy"
  role = aws_iam_role.resolver_query_logging[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = aws_cloudwatch_log_group.resolver_query_logs[0].arn
      }
    ]
  })
}

# Route53 Resolver Firewall Domain Lists
resource "aws_route53_resolver_firewall_domain_list" "this" {
  for_each = {
    for k, v in local.resolver_endpoints : k => v
    if v.direction == "INBOUND"
  }

  name    = "${local.name_prefix}-${each.key}-firewall-domain-list"
  domains = [
    "example.com",
    "*.malicious-domain.com"
  ]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-${each.key}-firewall-domain-list"
      Type = "resolver-firewall-domain-list"
    }
  )
}

# Route53 Resolver Firewall Rule Groups
resource "aws_route53_resolver_firewall_rule_group" "this" {
  for_each = {
    for k, v in local.resolver_endpoints : k => v
    if v.direction == "INBOUND"
  }

  name = "${local.name_prefix}-${each.key}-firewall-rule-group"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-${each.key}-firewall-rule-group"
      Type = "resolver-firewall-rule-group"
    }
  )
}

# Route53 Resolver Firewall Rules
resource "aws_route53_resolver_firewall_rule" "this" {
  for_each = {
    for k, v in local.resolver_endpoints : k => v
    if v.direction == "INBOUND"
  }

  name                    = "${local.name_prefix}-${each.key}-firewall-rule"
  action                  = "BLOCK"
  firewall_domain_list_id = aws_route53_resolver_firewall_domain_list.this[each.key].id
  firewall_rule_group_id  = aws_route53_resolver_firewall_rule_group.this[each.key].id
  priority                = 100

  block_response = "NODATA"
}

# Route53 Resolver Firewall Rule Group Associations
resource "aws_route53_resolver_firewall_rule_group_association" "this" {
  for_each = {
    for k, v in local.resolver_endpoints : k => v
    if v.direction == "INBOUND"
  }

  name                   = "${local.name_prefix}-${each.key}-firewall-rule-group-association"
  firewall_rule_group_id = aws_route53_resolver_firewall_rule_group.this[each.key].id
  priority               = 100
  vpc_id                 = data.aws_subnet.resolver_subnets[keys(data.aws_subnet.resolver_subnets)[0]].vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-${each.key}-firewall-rule-group-association"
      Type = "resolver-firewall-rule-group-association"
    }
  )
}

# Route53 Resolver Config
resource "aws_route53_resolver_config" "this" {
  for_each = {
    for k, v in local.resolver_endpoints : k => v
    if v.direction == "INBOUND"
  }

  resource_id                = data.aws_subnet.resolver_subnets[keys(data.aws_subnet.resolver_subnets)[0]].vpc_id
  autodefined_reverse_flag   = "ENABLE"
} 