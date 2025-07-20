# Hosted Zones
resource "aws_route53_zone" "this" {
  for_each = local.zones

  name              = each.value.domain_name
  comment           = each.value.comment
  force_destroy     = each.value.force_destroy
  delegation_set_id = each.value.delegation_set_id

  dynamic "vpc" {
    for_each = each.value.private_zone && each.value.vpc_id != null ? [1] : []
    content {
      vpc_id     = each.value.vpc_id
      vpc_region = each.value.vpc_region
    }
  }

  tags = each.value.tags

  lifecycle {
    ignore_changes = [
      vpc
    ]
  }
}

# Additional VPC associations for private hosted zones
resource "aws_route53_zone_association" "additional" {
  for_each = {
    for association in flatten([
      for zone_key, zone_config in local.zones : [
        for idx, vpc_config in zone_config.additional_vpc_associations : {
          key        = "${zone_key}-${idx}"
          zone_id    = aws_route53_zone.this[zone_key].zone_id
          vpc_id     = vpc_config.vpc_id
          vpc_region = vpc_config.vpc_region != null ? vpc_config.vpc_region : data.aws_region.current.name
        }
      ]
    ]) : association.key => association
  }

  zone_id    = each.value.zone_id
  vpc_id     = each.value.vpc_id
  vpc_region = each.value.vpc_region
}

# VPC associations (for external zones)
resource "aws_route53_zone_association" "this" {
  for_each = local.vpc_associations

  zone_id    = each.value.zone_id
  vpc_id     = each.value.vpc_id
  vpc_region = each.value.vpc_region
}

# DNSSEC signing
resource "aws_route53_hosted_zone_dnssec" "this" {
  for_each = {
    for k, v in local.zones : k => v
    if v.enable_dnssec
  }

  hosted_zone_id = aws_route53_zone.this[each.key].zone_id

  depends_on = [
    aws_route53_key_signing_key.this
  ]
}

# CloudWatch log group for query logging
resource "aws_cloudwatch_log_group" "query_logs" {
  count = var.create_query_logging ? 1 : 0

  name              = local.query_log_group_name
  retention_in_days = var.query_log_retention_in_days
  kms_key_id        = var.query_log_kms_key_id

  tags = merge(
    local.common_tags,
    {
      Name = local.query_log_group_name
      Type = "cloudwatch-log-group"
    }
  )
}

# Query logging configurations
resource "aws_route53_query_log" "this" {
  for_each = local.query_logging_configs

  depends_on = [aws_cloudwatch_log_group.query_logs]

  destination_arn = each.value.cloudwatch_log_group_arn
  zone_id         = each.value.hosted_zone_id
}

# Domain registration
resource "aws_route53domains_registered_domain" "this" {
  for_each = local.domains

  domain_name           = each.value.domain_name
  duration_in_years     = each.value.duration_in_years
  auto_renew            = each.value.auto_renew
  transfer_lock         = each.value.transfer_lock

  dynamic "name_server" {
    for_each = each.value.name_servers
    content {
      name = name_server.value
    }
  }

  dynamic "registrant_contact" {
    for_each = each.value.registrant_contact != null ? [each.value.registrant_contact] : []
    content {
      first_name        = registrant_contact.value.first_name
      last_name         = registrant_contact.value.last_name
      contact_type      = registrant_contact.value.contact_type
      organization_name = registrant_contact.value.organization_name
      address_line_1    = registrant_contact.value.address_line_1
      address_line_2    = registrant_contact.value.address_line_2
      city              = registrant_contact.value.city
      state             = registrant_contact.value.state
      country_code      = registrant_contact.value.country_code
      zip_code          = registrant_contact.value.zip_code
      phone_number      = registrant_contact.value.phone_number
      email             = registrant_contact.value.email
      fax               = registrant_contact.value.fax
      extra_params      = registrant_contact.value.extra_params
    }
  }

  dynamic "admin_contact" {
    for_each = each.value.admin_contact != null ? [each.value.admin_contact] : []
    content {
      first_name        = admin_contact.value.first_name
      last_name         = admin_contact.value.last_name
      contact_type      = admin_contact.value.contact_type
      organization_name = admin_contact.value.organization_name
      address_line_1    = admin_contact.value.address_line_1
      address_line_2    = admin_contact.value.address_line_2
      city              = admin_contact.value.city
      state             = admin_contact.value.state
      country_code      = admin_contact.value.country_code
      zip_code          = admin_contact.value.zip_code
      phone_number      = admin_contact.value.phone_number
      email             = admin_contact.value.email
      fax               = admin_contact.value.fax
      extra_params      = admin_contact.value.extra_params
    }
  }

  dynamic "tech_contact" {
    for_each = each.value.tech_contact != null ? [each.value.tech_contact] : []
    content {
      first_name        = tech_contact.value.first_name
      last_name         = tech_contact.value.last_name
      contact_type      = tech_contact.value.contact_type
      organization_name = tech_contact.value.organization_name
      address_line_1    = tech_contact.value.address_line_1
      address_line_2    = tech_contact.value.address_line_2
      city              = tech_contact.value.city
      state             = tech_contact.value.state
      country_code      = tech_contact.value.country_code
      zip_code          = tech_contact.value.zip_code
      phone_number      = tech_contact.value.phone_number
      email             = tech_contact.value.email
      fax               = tech_contact.value.fax
      extra_params      = tech_contact.value.extra_params
    }
  }

  privacy_protection = each.value.privacy_protection

  tags = each.value.tags
}

# Traffic policies
resource "aws_route53_traffic_policy" "this" {
  for_each = local.traffic_policies

  name     = each.value.name
  comment  = each.value.comment
  document = each.value.document
  type     = each.value.type
}

# Traffic policy instances
resource "aws_route53_traffic_policy_instance" "this" {
  for_each = local.traffic_policy_instances

  hosted_zone_id         = each.value.hosted_zone_id
  name                   = each.value.name
  ttl                    = each.value.ttl
  traffic_policy_id      = each.value.traffic_policy_id
  traffic_policy_version = each.value.traffic_policy_version
}

# Certificate validations
resource "aws_route53_record" "certificate_validation" {
  for_each = {
    for validation in flatten([
      for cert_key, cert_config in local.certificate_validations : [
        for dvo in data.aws_acm_certificate.validation[cert_key].domain_validation_options : {
          key         = "${cert_key}-${dvo.domain_name}"
          name        = dvo.resource_record_name
          record      = dvo.resource_record_value
          type        = dvo.resource_record_type
          zone_id     = data.aws_route53_zone.certificate_validation[cert_key].zone_id
        }
      ]
    ]) : validation.key => validation
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = each.value.zone_id
}

# Data sources for certificate validation
data "aws_acm_certificate" "validation" {
  for_each = local.certificate_validations

  arn = each.value.certificate_arn
}

data "aws_route53_zone" "certificate_validation" {
  for_each = local.certificate_validations

  name = regex(".*\\.([^.]+\\.[^.]+)$", data.aws_acm_certificate.validation[each.key].domain_name)[0]
}

# Certificate validation completion
resource "aws_acm_certificate_validation" "this" {
  for_each = local.certificate_validations

  certificate_arn = each.value.certificate_arn
  validation_record_fqdns = length(each.value.validation_record_fqdns) > 0 ? each.value.validation_record_fqdns : [
    for record in aws_route53_record.certificate_validation :
    record.fqdn
    if startswith(record.name, data.aws_acm_certificate.validation[each.key].domain_name)
  ]

  dynamic "timeouts" {
    for_each = each.value.timeouts != null ? [each.value.timeouts] : []
    content {
      create = timeouts.value.create
    }
  }
}

# Resource Access Manager (RAM) resource shares for Route53 Resolver rules
resource "aws_ram_resource_share" "resolver_rules" {
  for_each = {
    for k, v in local.resolver_rules : k => v
    if v.rule_type == "FORWARD"
  }

  name                      = "${local.name_prefix}-${each.key}-resolver-rule-share"
  allow_external_principals = false

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-${each.key}-resolver-rule-share"
      Type = "ram-resource-share"
    }
  )
}

resource "aws_ram_resource_association" "resolver_rules" {
  for_each = {
    for k, v in local.resolver_rules : k => v
    if v.rule_type == "FORWARD"
  }

  resource_arn       = aws_route53_resolver_rule.this[each.key].arn
  resource_share_arn = aws_ram_resource_share.resolver_rules[each.key].arn
} 