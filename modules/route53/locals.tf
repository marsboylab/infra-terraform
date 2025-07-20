# Data sources
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_partition" "current" {}

# Local values
locals {
  # Basic configuration
  name_prefix = "${var.name}-${var.environment}"
  
  # Common tags
  common_tags = merge(
    var.tags,
    {
      Name        = local.name_prefix
      Environment = var.environment
      ManagedBy   = "terraform"
      Module      = "route53"
      Region      = data.aws_region.current.name
    }
  )
  
  # Hosted zone tags
  hosted_zone_tags = merge(
    local.common_tags,
    var.hosted_zone_tags,
    {
      Type = "hosted-zone"
    }
  )
  
  # DNS record tags
  record_tags = merge(
    local.common_tags,
    var.record_tags,
    {
      Type = "dns-record"
    }
  )
  
  # Health check tags
  health_check_tags = merge(
    local.common_tags,
    var.health_check_tags,
    {
      Type = "health-check"
    }
  )
  
  # Process zones with defaults
  zones = {
    for k, v in var.zones : k => {
      domain_name         = v.domain_name
      comment             = v.comment != null ? v.comment : "Managed by Terraform - ${local.name_prefix}"
      private_zone        = v.private_zone
      vpc_id              = v.vpc_id
      vpc_region          = v.vpc_region != null ? v.vpc_region : data.aws_region.current.name
      additional_vpc_associations = v.additional_vpc_associations
      force_destroy       = v.force_destroy
      delegation_set_id   = v.delegation_set_id
      enable_dnssec       = v.enable_dnssec
      tags = merge(
        local.hosted_zone_tags,
        v.tags,
        {
          Name        = "${local.name_prefix}-${k}"
          Domain      = v.domain_name
          PrivateZone = v.private_zone ? "true" : "false"
        }
      )
    }
  }
  
  # Process records with defaults
  records = {
    for k, v in var.records : k => {
      zone_name   = v.zone_name
      name        = v.name
      type        = v.type
      ttl         = v.ttl != null ? v.ttl : var.default_ttl
      records     = v.records
      alias       = v.alias
      weighted_routing_policy = v.weighted_routing_policy
      latency_routing_policy = v.latency_routing_policy
      failover_routing_policy = v.failover_routing_policy
      geolocation_routing_policy = v.geolocation_routing_policy
      multivalue_answer_routing_policy = v.multivalue_answer_routing_policy
      geoproximity_routing_policy = v.geoproximity_routing_policy
      health_check_id = v.health_check_id
      set_identifier = v.set_identifier
      allow_overwrite = v.allow_overwrite
      tags = merge(
        local.record_tags,
        v.tags,
        {
          Name       = "${local.name_prefix}-${k}"
          RecordType = v.type
          Zone       = v.zone_name
        }
      )
    }
  }
  
  # Process health checks with defaults
  health_checks = {
    for k, v in var.health_checks : k => {
      type                            = v.type
      resource_path                   = v.resource_path
      fqdn                           = v.fqdn
      ip_address                     = v.ip_address
      port                           = v.port
      request_interval               = v.request_interval
      failure_threshold              = v.failure_threshold
      measure_latency                = v.measure_latency
      invert_healthcheck             = v.invert_healthcheck
      disabled                       = v.disabled
      enable_sni                     = v.enable_sni
      search_string                  = v.search_string
      cloudwatch_alarm_region        = v.cloudwatch_alarm_region != null ? v.cloudwatch_alarm_region : data.aws_region.current.name
      cloudwatch_alarm_name          = v.cloudwatch_alarm_name
      insufficient_data_health_status = v.insufficient_data_health_status
      reference_name                 = v.reference_name != null ? v.reference_name : "${local.name_prefix}-${k}"
      child_health_checks = v.child_health_checks
      child_health_threshold = v.child_health_threshold
      regions = length(v.regions) > 0 ? v.regions : [
        "us-east-1",
        "us-west-1",
        "eu-west-1"
      ]
      tags = merge(
        local.health_check_tags,
        v.tags,
        {
          Name        = "${local.name_prefix}-${k}"
          HealthType  = v.type
          Reference   = v.reference_name != null ? v.reference_name : "${local.name_prefix}-${k}"
        }
      )
    }
  }
  
  # Process resolver endpoints with defaults
  resolver_endpoints = {
    for k, v in var.resolver_endpoints : k => {
      direction          = v.direction
      security_group_ids = v.security_group_ids
      subnet_ids         = v.subnet_ids
      name               = v.name != null ? v.name : "${local.name_prefix}-${k}-resolver-endpoint"
      ip_addresses       = v.ip_addresses
      tags = merge(
        local.common_tags,
        v.tags,
        {
          Name      = v.name != null ? v.name : "${local.name_prefix}-${k}-resolver-endpoint"
          Type      = "resolver-endpoint"
          Direction = v.direction
        }
      )
    }
  }
  
  # Process resolver rules with defaults
  resolver_rules = {
    for k, v in var.resolver_rules : k => {
      domain_name          = v.domain_name
      rule_type            = v.rule_type
      resolver_endpoint_id = v.resolver_endpoint_id
      target_ips           = v.target_ips
      name                 = v.name != null ? v.name : "${local.name_prefix}-${k}-resolver-rule"
      tags = merge(
        local.common_tags,
        v.tags,
        {
          Name       = v.name != null ? v.name : "${local.name_prefix}-${k}-resolver-rule"
          Type       = "resolver-rule"
          RuleType   = v.rule_type
          Domain     = v.domain_name
        }
      )
    }
  }
  
  # Process resolver rule associations with defaults
  resolver_rule_associations = {
    for k, v in var.resolver_rule_associations : k => {
      resolver_rule_id = v.resolver_rule_id
      vpc_id           = v.vpc_id
      name             = v.name != null ? v.name : "${local.name_prefix}-${k}-resolver-rule-association"
    }
  }
  
  # Process DNSSEC key signing keys with defaults
  dnssec_key_signing_keys = {
    for k, v in var.dnssec_key_signing_keys : k => {
      hosted_zone_id             = v.hosted_zone_id
      key_management_service_arn = v.key_management_service_arn
      name                       = v.name
      status                     = v.status
    }
  }
  
  # Process query logging configs with defaults
  query_logging_configs = {
    for k, v in var.query_logging_configs : k => {
      hosted_zone_id           = v.hosted_zone_id
      cloudwatch_log_group_arn = v.cloudwatch_log_group_arn
      name                     = v.name != null ? v.name : "${local.name_prefix}-${k}-query-logging"
    }
  }
  
  # Process VPC associations with defaults
  vpc_associations = {
    for k, v in var.vpc_associations : k => {
      zone_id    = v.zone_id
      vpc_id     = v.vpc_id
      vpc_region = v.vpc_region != null ? v.vpc_region : data.aws_region.current.name
    }
  }
  
  # Process domains with defaults
  domains = {
    for k, v in var.domains : k => {
      domain_name           = v.domain_name
      duration_in_years     = v.duration_in_years
      auto_renew            = v.auto_renew
      transfer_lock         = v.transfer_lock
      name_servers          = v.name_servers
      registrant_contact    = v.registrant_contact
      admin_contact         = v.admin_contact
      tech_contact          = v.tech_contact
      privacy_protection    = v.privacy_protection
      tags = merge(
        local.common_tags,
        v.tags,
        {
          Name     = "${local.name_prefix}-${k}"
          Type     = "domain-registration"
          Domain   = v.domain_name
          AutoRenew = v.auto_renew ? "true" : "false"
        }
      )
    }
  }
  
  # Process traffic policies with defaults
  traffic_policies = {
    for k, v in var.traffic_policies : k => {
      name     = v.name
      comment  = v.comment != null ? v.comment : "Managed by Terraform - ${local.name_prefix}"
      document = v.document
      type     = v.type
    }
  }
  
  # Process traffic policy instances with defaults
  traffic_policy_instances = {
    for k, v in var.traffic_policy_instances : k => {
      hosted_zone_id         = v.hosted_zone_id
      name                   = v.name
      ttl                    = v.ttl
      traffic_policy_id      = v.traffic_policy_id
      traffic_policy_version = v.traffic_policy_version
    }
  }
  
  # Process health check alarm configs with defaults
  health_check_alarm_configs = {
    for k, v in var.health_check_alarm_configs : k => {
      health_check_id           = v.health_check_id
      comparison_operator       = v.comparison_operator
      evaluation_periods        = v.evaluation_periods
      metric_name               = v.metric_name
      namespace                 = v.namespace
      period                    = v.period
      statistic                 = v.statistic
      threshold                 = v.threshold
      alarm_description         = v.alarm_description != null ? v.alarm_description : "Health check alarm for ${local.name_prefix}-${k}"
      alarm_name                = v.alarm_name != null ? v.alarm_name : "${local.name_prefix}-${k}-health-check-alarm"
      insufficient_data_actions = v.insufficient_data_actions
      treat_missing_data       = v.treat_missing_data
      tags = merge(
        local.common_tags,
        v.tags,
        {
          Name           = v.alarm_name != null ? v.alarm_name : "${local.name_prefix}-${k}-health-check-alarm"
          Type           = "cloudwatch-alarm"
          HealthCheckId  = v.health_check_id
        }
      )
    }
  }
  
  # Process certificate validations with defaults
  certificate_validations = {
    for k, v in var.certificate_validations : k => {
      certificate_arn         = v.certificate_arn
      validation_record_fqdns = v.validation_record_fqdns
      timeouts                = v.timeouts
    }
  }
  
  # CloudWatch log group for query logging
  query_log_group_name = "/aws/route53/${local.name_prefix}/query-logs"
  
  # Route53 health check regions mapping
  health_check_regions = {
    "us-east-1"      = "us-east-1"
    "us-west-1"      = "us-west-1"
    "us-west-2"      = "us-west-2"
    "eu-west-1"      = "eu-west-1"
    "eu-central-1"   = "eu-central-1"
    "ap-southeast-1" = "ap-southeast-1"
    "ap-southeast-2" = "ap-southeast-2"
    "ap-northeast-1" = "ap-northeast-1"
    "sa-east-1"      = "sa-east-1"
  }
  
  # Default health check regions
  default_health_check_regions = [
    "us-east-1",
    "us-west-1",
    "eu-west-1"
  ]
  
  # Route53 record types that support alias
  alias_supported_types = [
    "A",
    "AAAA"
  ]
  
  # Route53 record types that support routing policies
  routing_policy_supported_types = [
    "A",
    "AAAA",
    "CNAME",
    "MX",
    "NS",
    "PTR",
    "SRV",
    "TXT"
  ]
  
  # Health check types that require FQDN
  fqdn_required_types = [
    "HTTP",
    "HTTPS",
    "HTTP_STR_MATCH",
    "HTTPS_STR_MATCH"
  ]
  
  # Health check types that require IP address
  ip_required_types = [
    "TCP"
  ]
  
  # Health check types that support search string
  search_string_supported_types = [
    "HTTP_STR_MATCH",
    "HTTPS_STR_MATCH"
  ]
  
  # Default health check ports by type
  default_health_check_ports = {
    "HTTP"             = 80
    "HTTPS"            = 443
    "HTTP_STR_MATCH"   = 80
    "HTTPS_STR_MATCH"  = 443
    "TCP"              = 80
  }
  
  # Create lookup map for hosted zone IDs
  hosted_zone_ids = {
    for k, zone in aws_route53_zone.this : k => zone.zone_id
  }
  
  # Create lookup map for health check IDs
  health_check_ids = {
    for k, hc in aws_route53_health_check.this : k => hc.id
  }
  
  # Create lookup map for resolver endpoint IDs
  resolver_endpoint_ids = {
    for k, ep in aws_route53_resolver_endpoint.this : k => ep.id
  }
  
  # Create lookup map for resolver rule IDs
  resolver_rule_ids = {
    for k, rule in aws_route53_resolver_rule.this : k => rule.id
  }
} 