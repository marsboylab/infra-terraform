# Hosted Zone Outputs
output "hosted_zones" {
  description = "Map of hosted zone configurations"
  value = {
    for k, zone in aws_route53_zone.this : k => {
      zone_id      = zone.zone_id
      name         = zone.name
      name_servers = zone.name_servers
      arn          = zone.arn
      comment      = zone.comment
      private_zone = zone.vpc != null ? true : false
      tags         = zone.tags
    }
  }
}

output "hosted_zone_ids" {
  description = "Map of hosted zone IDs"
  value       = local.hosted_zone_ids
}

output "hosted_zone_name_servers" {
  description = "Map of hosted zone name servers"
  value = {
    for k, zone in aws_route53_zone.this : k => zone.name_servers
  }
}

output "hosted_zone_arns" {
  description = "Map of hosted zone ARNs"
  value = {
    for k, zone in aws_route53_zone.this : k => zone.arn
  }
}

# DNS Records Outputs
output "dns_records" {
  description = "Map of DNS records"
  value = {
    for k, record in aws_route53_record.this : k => {
      name    = record.name
      type    = record.type
      ttl     = record.ttl
      records = record.records
      fqdn    = record.fqdn
      zone_id = record.zone_id
    }
  }
}

output "dns_record_fqdns" {
  description = "Map of DNS record FQDNs"
  value = {
    for k, record in aws_route53_record.this : k => record.fqdn
  }
}

# Health Check Outputs
output "health_checks" {
  description = "Map of health check configurations"
  value = {
    for k, hc in aws_route53_health_check.this : k => {
      id                = hc.id
      arn               = hc.arn
      type              = hc.type
      fqdn              = hc.fqdn
      ip_address        = hc.ip_address
      port              = hc.port
      resource_path     = hc.resource_path
      failure_threshold = hc.failure_threshold
      request_interval  = hc.request_interval
      status            = hc.status
      tags              = hc.tags
    }
  }
}

output "health_check_ids" {
  description = "Map of health check IDs"
  value       = local.health_check_ids
}

output "health_check_arns" {
  description = "Map of health check ARNs"
  value = {
    for k, hc in aws_route53_health_check.this : k => hc.arn
  }
}

# Resolver Outputs
output "resolver_endpoints" {
  description = "Map of Route53 resolver endpoints"
  value = {
    for k, endpoint in aws_route53_resolver_endpoint.this : k => {
      id                 = endpoint.id
      arn                = endpoint.arn
      name               = endpoint.name
      direction          = endpoint.direction
      ip_addresses       = endpoint.ip_address
      security_group_ids = endpoint.security_group_ids
      host_vpc_id        = endpoint.host_vpc_id
    }
  }
}

output "resolver_endpoint_ids" {
  description = "Map of resolver endpoint IDs"
  value       = local.resolver_endpoint_ids
}

output "resolver_rules" {
  description = "Map of Route53 resolver rules"
  value = {
    for k, rule in aws_route53_resolver_rule.this : k => {
      id                   = rule.id
      arn                  = rule.arn
      name                 = rule.name
      domain_name          = rule.domain_name
      rule_type            = rule.rule_type
      resolver_endpoint_id = rule.resolver_endpoint_id
      target_ip            = rule.target_ip
      owner_id             = rule.owner_id
      share_status         = rule.share_status
    }
  }
}

output "resolver_rule_ids" {
  description = "Map of resolver rule IDs"
  value       = local.resolver_rule_ids
}

output "resolver_rule_associations" {
  description = "Map of resolver rule associations"
  value = {
    for k, assoc in aws_route53_resolver_rule_association.this : k => {
      id               = assoc.id
      resolver_rule_id = assoc.resolver_rule_id
      vpc_id           = assoc.vpc_id
      name             = assoc.name
    }
  }
}

# DNSSEC Outputs
output "dnssec_configurations" {
  description = "Map of DNSSEC configurations"
  value = {
    for k, dnssec in aws_route53_hosted_zone_dnssec.this : k => {
      id                     = dnssec.id
      hosted_zone_id         = dnssec.hosted_zone_id
      signing_status         = dnssec.signing_status
      status_message         = dnssec.status_message
      key_signing_keys       = dnssec.key_signing_keys
    }
  }
}

output "key_signing_keys" {
  description = "Map of key signing keys"
  value = {
    for k, ksk in aws_route53_key_signing_key.this : k => {
      id                             = ksk.id
      hosted_zone_id                 = ksk.hosted_zone_id
      key_management_service_arn     = ksk.key_management_service_arn
      name                           = ksk.name
      status                         = ksk.status
      flag                           = ksk.flag
      key_tag                        = ksk.key_tag
      public_key                     = ksk.public_key
      signing_algorithm_mnemonic     = ksk.signing_algorithm_mnemonic
      signing_algorithm_type         = ksk.signing_algorithm_type
      digest_algorithm_mnemonic      = ksk.digest_algorithm_mnemonic
      digest_algorithm_type          = ksk.digest_algorithm_type
      digest_value                   = ksk.digest_value
      ds_record                      = ksk.ds_record
      dnskey_record                  = ksk.dnskey_record
      status_message                 = ksk.status_message
    }
  }
}

output "dnssec_kms_keys" {
  description = "Map of KMS keys for DNSSEC"
  value = {
    for k, key in aws_kms_key.dnssec : k => {
      id          = key.id
      arn         = key.arn
      key_id      = key.key_id
      description = key.description
      key_usage   = key.key_usage
      key_spec    = key.key_spec
    }
  }
}

# Domain Registration Outputs
output "registered_domains" {
  description = "Map of registered domains"
  value = {
    for k, domain in aws_route53domains_registered_domain.this : k => {
      id                = domain.id
      domain_name       = domain.domain_name
      expiration_date   = domain.expiration_date
      auto_renew        = domain.auto_renew
      transfer_lock     = domain.transfer_lock
      name_server       = domain.name_server
      abuse_contact_email = domain.abuse_contact_email
      abuse_contact_phone = domain.abuse_contact_phone
      admin_privacy     = domain.admin_privacy
      registrant_privacy = domain.registrant_privacy
      tech_privacy      = domain.tech_privacy
      status_list       = domain.status_list
      tags              = domain.tags
    }
  }
}

# Traffic Policy Outputs
output "traffic_policies" {
  description = "Map of traffic policies"
  value = {
    for k, policy in aws_route53_traffic_policy.this : k => {
      id       = policy.id
      name     = policy.name
      comment  = policy.comment
      document = policy.document
      type     = policy.type
      version  = policy.version
    }
  }
}

output "traffic_policy_instances" {
  description = "Map of traffic policy instances"
  value = {
    for k, instance in aws_route53_traffic_policy_instance.this : k => {
      id                     = instance.id
      hosted_zone_id         = instance.hosted_zone_id
      name                   = instance.name
      ttl                    = instance.ttl
      traffic_policy_id      = instance.traffic_policy_id
      traffic_policy_version = instance.traffic_policy_version
    }
  }
}

# Query Logging Outputs
output "query_logging_configs" {
  description = "Map of query logging configurations"
  value = {
    for k, config in aws_route53_query_log.this : k => {
      id              = config.id
      arn             = config.arn
      zone_id         = config.zone_id
      destination_arn = config.destination_arn
    }
  }
}

output "query_log_groups" {
  description = "CloudWatch log groups for query logging"
  value = var.create_query_logging ? {
    route53 = {
      name = aws_cloudwatch_log_group.route53_query_logs[0].name
      arn  = aws_cloudwatch_log_group.route53_query_logs[0].arn
    }
    resolver = var.create_query_logging ? {
      name = aws_cloudwatch_log_group.resolver_query_logs[0].name
      arn  = aws_cloudwatch_log_group.resolver_query_logs[0].arn
    } : null
  } : {}
}

# VPC Association Outputs
output "vpc_associations" {
  description = "Map of VPC associations"
  value = {
    for k, assoc in aws_route53_zone_association.this : k => {
      id         = assoc.id
      zone_id    = assoc.zone_id
      vpc_id     = assoc.vpc_id
      vpc_region = assoc.vpc_region
    }
  }
}

output "additional_vpc_associations" {
  description = "Map of additional VPC associations"
  value = {
    for k, assoc in aws_route53_zone_association.additional : k => {
      id         = assoc.id
      zone_id    = assoc.zone_id
      vpc_id     = assoc.vpc_id
      vpc_region = assoc.vpc_region
    }
  }
}

# Certificate Validation Outputs
output "certificate_validations" {
  description = "Map of certificate validations"
  value = {
    for k, validation in aws_acm_certificate_validation.this : k => {
      certificate_arn         = validation.certificate_arn
      validation_record_fqdns = validation.validation_record_fqdns
    }
  }
}

# Monitoring Outputs
output "cloudwatch_alarms" {
  description = "Map of CloudWatch alarms"
  value = var.create_cloudwatch_alarms ? {
    health_checks = {
      for k, alarm in aws_cloudwatch_metric_alarm.health_check_alarm : k => {
        name = alarm.alarm_name
        arn  = alarm.arn
      }
    }
    health_check_percentage = {
      for k, alarm in aws_cloudwatch_metric_alarm.health_check_percentage_healthy : k => {
        name = alarm.alarm_name
        arn  = alarm.arn
      }
    }
    dnssec_key_status = {
      for k, alarm in aws_cloudwatch_metric_alarm.dnssec_key_status : k => {
        name = alarm.alarm_name
        arn  = alarm.arn
      }
    }
    query_volume = var.create_query_logging ? {
      high_volume = {
        name = aws_cloudwatch_metric_alarm.high_query_volume[0].alarm_name
        arn  = aws_cloudwatch_metric_alarm.high_query_volume[0].arn
      }
      high_errors = {
        name = aws_cloudwatch_metric_alarm.high_query_errors[0].alarm_name
        arn  = aws_cloudwatch_metric_alarm.high_query_errors[0].arn
      }
    } : {}
  } : {}
}

output "cloudwatch_dashboards" {
  description = "CloudWatch dashboards"
  value = var.create_cloudwatch_alarms ? {
    route53 = {
      name = aws_cloudwatch_dashboard.route53[0].dashboard_name
      arn  = aws_cloudwatch_dashboard.route53[0].dashboard_arn
    }
    dnssec = length([for k, v in local.zones : k if v.enable_dnssec]) > 0 ? {
      name = aws_cloudwatch_dashboard.dnssec[0].dashboard_name
      arn  = aws_cloudwatch_dashboard.dnssec[0].dashboard_arn
    } : null
  } : {}
}

output "sns_topics" {
  description = "SNS topics for notifications"
  value = var.create_cloudwatch_alarms && length(var.alarm_actions) == 0 ? {
    health_checks = length(local.health_checks) > 0 ? {
      name = aws_sns_topic.health_check_notifications[0].name
      arn  = aws_sns_topic.health_check_notifications[0].arn
    } : null
    dnssec = length([for k, v in local.zones : k if v.enable_dnssec]) > 0 ? {
      name = aws_sns_topic.dnssec_alerts[0].name
      arn  = aws_sns_topic.dnssec_alerts[0].arn
    } : null
    monitoring = {
      name = aws_sns_topic.route53_monitoring[0].name
      arn  = aws_sns_topic.route53_monitoring[0].arn
    }
  } : {}
}

# CloudWatch Insights Queries Outputs
output "cloudwatch_insights_queries" {
  description = "CloudWatch Insights query definitions"
  value = var.create_query_logging ? {
    top_queried_domains = {
      name = aws_cloudwatch_query_definition.top_queried_domains[0].name
      query_definition_id = aws_cloudwatch_query_definition.top_queried_domains[0].query_definition_id
    }
    query_errors_analysis = {
      name = aws_cloudwatch_query_definition.query_errors_analysis[0].name
      query_definition_id = aws_cloudwatch_query_definition.query_errors_analysis[0].query_definition_id
    }
    client_ip_analysis = {
      name = aws_cloudwatch_query_definition.client_ip_analysis[0].name
      query_definition_id = aws_cloudwatch_query_definition.client_ip_analysis[0].query_definition_id
    }
    query_type_distribution = {
      name = aws_cloudwatch_query_definition.query_type_distribution[0].name
      query_definition_id = aws_cloudwatch_query_definition.query_type_distribution[0].query_definition_id
    }
  } : {}
}

# Security Group Outputs
output "resolver_security_groups" {
  description = "Security groups for resolver endpoints"
  value = {
    for k, sg in aws_security_group.resolver_endpoint : k => {
      id   = sg.id
      arn  = sg.arn
      name = sg.name
    }
  }
}

# IAM Role Outputs
output "iam_roles" {
  description = "IAM roles created by the module"
  value = {
    route53_query_logging = var.create_query_logging ? {
      name = aws_iam_role.route53_query_logging[0].name
      arn  = aws_iam_role.route53_query_logging[0].arn
    } : null
    resolver_query_logging = var.create_query_logging ? {
      name = aws_iam_role.resolver_query_logging[0].name
      arn  = aws_iam_role.resolver_query_logging[0].arn
    } : null
  }
}

# Firewall Outputs
output "resolver_firewall_configs" {
  description = "Route53 Resolver firewall configurations"
  value = {
    domain_lists = {
      for k, list in aws_route53_resolver_firewall_domain_list.this : k => {
        id      = list.id
        name    = list.name
        domains = list.domains
      }
    }
    rule_groups = {
      for k, group in aws_route53_resolver_firewall_rule_group.this : k => {
        id   = group.id
        name = group.name
      }
    }
    rules = {
      for k, rule in aws_route53_resolver_firewall_rule.this : k => {
        id                      = rule.id
        name                    = rule.name
        action                  = rule.action
        firewall_rule_group_id  = rule.firewall_rule_group_id
        firewall_domain_list_id = rule.firewall_domain_list_id
        priority                = rule.priority
      }
    }
    associations = {
      for k, assoc in aws_route53_resolver_firewall_rule_group_association.this : k => {
        id                     = assoc.id
        name                   = assoc.name
        firewall_rule_group_id = assoc.firewall_rule_group_id
        vpc_id                 = assoc.vpc_id
        priority               = assoc.priority
      }
    }
  }
}

# Summary Outputs
output "module_summary" {
  description = "Summary of resources created by this module"
  value = {
    hosted_zones_count           = length(aws_route53_zone.this)
    dns_records_count           = length(aws_route53_record.this)
    health_checks_count         = length(aws_route53_health_check.this)
    resolver_endpoints_count    = length(aws_route53_resolver_endpoint.this)
    resolver_rules_count        = length(aws_route53_resolver_rule.this)
    dnssec_enabled_zones        = length([for k, v in local.zones : k if v.enable_dnssec])
    private_zones_count         = length([for k, v in local.zones : k if v.private_zone])
    public_zones_count          = length([for k, v in local.zones : k if !v.private_zone])
    query_logging_enabled       = var.create_query_logging
    monitoring_enabled          = var.create_cloudwatch_alarms
    registered_domains_count    = length(aws_route53domains_registered_domain.this)
    traffic_policies_count      = length(aws_route53_traffic_policy.this)
  }
}

# Configuration Outputs
output "effective_configuration" {
  description = "Effective configuration values"
  value = {
    name_prefix                     = local.name_prefix
    query_log_group_name           = local.query_log_group_name
    create_query_logging           = var.create_query_logging
    create_cloudwatch_alarms       = var.create_cloudwatch_alarms
    query_log_retention_in_days    = var.query_log_retention_in_days
    default_ttl                    = var.default_ttl
    default_health_check_regions   = local.default_health_check_regions
  }
}

# Common Tags
output "common_tags" {
  description = "Common tags applied to all resources"
  value       = local.common_tags
} 