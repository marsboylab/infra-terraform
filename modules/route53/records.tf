# DNS Records
resource "aws_route53_record" "this" {
  for_each = local.records

  zone_id = local.hosted_zone_ids[each.value.zone_name]
  name    = each.value.name
  type    = each.value.type
  ttl     = each.value.alias == null ? each.value.ttl : null
  records = each.value.alias == null ? each.value.records : null

  # Alias configuration
  dynamic "alias" {
    for_each = each.value.alias != null ? [each.value.alias] : []
    content {
      name                   = alias.value.name
      zone_id                = alias.value.zone_id
      evaluate_target_health = alias.value.evaluate_target_health
    }
  }

  # Weighted routing policy
  dynamic "weighted_routing_policy" {
    for_each = each.value.weighted_routing_policy != null ? [each.value.weighted_routing_policy] : []
    content {
      weight = weighted_routing_policy.value.weight
    }
  }

  # Latency routing policy
  dynamic "latency_routing_policy" {
    for_each = each.value.latency_routing_policy != null ? [each.value.latency_routing_policy] : []
    content {
      region = latency_routing_policy.value.region
    }
  }

  # Failover routing policy
  dynamic "failover_routing_policy" {
    for_each = each.value.failover_routing_policy != null ? [each.value.failover_routing_policy] : []
    content {
      type = failover_routing_policy.value.type
    }
  }

  # Geolocation routing policy
  dynamic "geolocation_routing_policy" {
    for_each = each.value.geolocation_routing_policy != null ? [each.value.geolocation_routing_policy] : []
    content {
      continent   = geolocation_routing_policy.value.continent
      country     = geolocation_routing_policy.value.country
      subdivision = geolocation_routing_policy.value.subdivision
    }
  }

  # Multivalue answer routing policy
  multivalue_answer_routing_policy = each.value.multivalue_answer_routing_policy

  # Geoproximity routing policy
  dynamic "geoproximity_routing_policy" {
    for_each = each.value.geoproximity_routing_policy != null ? [each.value.geoproximity_routing_policy] : []
    content {
      aws_region = geoproximity_routing_policy.value.aws_region
      bias       = geoproximity_routing_policy.value.bias
      
      dynamic "coordinates" {
        for_each = geoproximity_routing_policy.value.coordinates != null ? [geoproximity_routing_policy.value.coordinates] : []
        content {
          latitude  = coordinates.value.latitude
          longitude = coordinates.value.longitude
        }
      }
    }
  }

  # Health check
  health_check_id = each.value.health_check_id

  # Set identifier for routing policies
  set_identifier = each.value.set_identifier

  # Allow overwrite
  allow_overwrite = each.value.allow_overwrite

  depends_on = [
    aws_route53_zone.this,
    aws_route53_health_check.this
  ]
}

# Common DNS records for infrastructure
resource "aws_route53_record" "alb_records" {
  for_each = {
    for k, v in local.records : k => v
    if v.type == "A" && v.alias != null && can(regex(".*\\.elb\\.amazonaws\\.com$", v.alias.name))
  }

  zone_id = local.hosted_zone_ids[each.value.zone_name]
  name    = each.value.name
  type    = each.value.type

  alias {
    name                   = each.value.alias.name
    zone_id                = each.value.alias.zone_id
    evaluate_target_health = each.value.alias.evaluate_target_health
  }

  depends_on = [
    aws_route53_zone.this
  ]
}

# CloudFront distribution records
resource "aws_route53_record" "cloudfront_records" {
  for_each = {
    for k, v in local.records : k => v
    if v.type == "A" && v.alias != null && can(regex(".*\\.cloudfront\\.net$", v.alias.name))
  }

  zone_id = local.hosted_zone_ids[each.value.zone_name]
  name    = each.value.name
  type    = each.value.type

  alias {
    name                   = each.value.alias.name
    zone_id                = "Z2FDTNDATAQYW2" # CloudFront hosted zone ID
    evaluate_target_health = each.value.alias.evaluate_target_health
  }

  depends_on = [
    aws_route53_zone.this
  ]
}

# S3 website records
resource "aws_route53_record" "s3_website_records" {
  for_each = {
    for k, v in local.records : k => v
    if v.type == "A" && v.alias != null && can(regex(".*\\.s3-website.*\\.amazonaws\\.com$", v.alias.name))
  }

  zone_id = local.hosted_zone_ids[each.value.zone_name]
  name    = each.value.name
  type    = each.value.type

  alias {
    name                   = each.value.alias.name
    zone_id                = each.value.alias.zone_id
    evaluate_target_health = each.value.alias.evaluate_target_health
  }

  depends_on = [
    aws_route53_zone.this
  ]
}

# API Gateway records
resource "aws_route53_record" "api_gateway_records" {
  for_each = {
    for k, v in local.records : k => v
    if v.type == "A" && v.alias != null && can(regex(".*\\.execute-api\\..*\\.amazonaws\\.com$", v.alias.name))
  }

  zone_id = local.hosted_zone_ids[each.value.zone_name]
  name    = each.value.name
  type    = each.value.type

  alias {
    name                   = each.value.alias.name
    zone_id                = each.value.alias.zone_id
    evaluate_target_health = each.value.alias.evaluate_target_health
  }

  depends_on = [
    aws_route53_zone.this
  ]
}

# Data source for existing hosted zones (for reference)
data "aws_route53_zone" "existing" {
  for_each = {
    for k, v in local.records : v.zone_name => v
    if !contains(keys(local.zones), v.zone_name)
  }

  name = each.value.zone_name
}

# Create CNAME records for www subdomain
resource "aws_route53_record" "www_redirect" {
  for_each = {
    for k, v in local.zones : k => v
    if !v.private_zone && !startswith(v.domain_name, "www.")
  }

  zone_id = aws_route53_zone.this[each.key].zone_id
  name    = "www.${each.value.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [each.value.domain_name]

  depends_on = [
    aws_route53_zone.this
  ]
}

# Create TXT records for domain verification
resource "aws_route53_record" "domain_verification" {
  for_each = {
    for k, v in local.zones : k => v
    if !v.private_zone && var.create_query_logging
  }

  zone_id = aws_route53_zone.this[each.key].zone_id
  name    = "_terraform-verification.${each.value.domain_name}"
  type    = "TXT"
  ttl     = 300
  records = ["terraform-managed-zone"]

  depends_on = [
    aws_route53_zone.this
  ]
}

# Create NS records for subdomain delegation
resource "aws_route53_record" "subdomain_delegation" {
  for_each = {
    for delegation in flatten([
      for zone_key, zone_config in local.zones : [
        for record_key, record_config in local.records : {
          key           = "${zone_key}-${record_key}"
          parent_zone   = zone_key
          subdomain     = record_config.name
          name_servers  = record_config.records
        }
        if record_config.zone_name == zone_key && record_config.type == "NS" && record_config.name != zone_config.domain_name
      ]
    ]) : delegation.key => delegation
  }

  zone_id = aws_route53_zone.this[each.value.parent_zone].zone_id
  name    = each.value.subdomain
  type    = "NS"
  ttl     = 300
  records = each.value.name_servers

  depends_on = [
    aws_route53_zone.this
  ]
}

# Create MX records for email routing
resource "aws_route53_record" "mx_records" {
  for_each = {
    for k, v in local.records : k => v
    if v.type == "MX"
  }

  zone_id = local.hosted_zone_ids[each.value.zone_name]
  name    = each.value.name
  type    = "MX"
  ttl     = each.value.ttl
  records = each.value.records

  depends_on = [
    aws_route53_zone.this
  ]
}

# Create SPF records for email authentication
resource "aws_route53_record" "spf_records" {
  for_each = {
    for k, v in local.records : k => v
    if v.type == "TXT" && can(regex("^v=spf1", join("", v.records)))
  }

  zone_id = local.hosted_zone_ids[each.value.zone_name]
  name    = each.value.name
  type    = "TXT"
  ttl     = each.value.ttl
  records = each.value.records

  depends_on = [
    aws_route53_zone.this
  ]
}

# Create DKIM records for email authentication
resource "aws_route53_record" "dkim_records" {
  for_each = {
    for k, v in local.records : k => v
    if v.type == "TXT" && can(regex(".*\\._domainkey\\..*", v.name))
  }

  zone_id = local.hosted_zone_ids[each.value.zone_name]
  name    = each.value.name
  type    = "TXT"
  ttl     = each.value.ttl
  records = each.value.records

  depends_on = [
    aws_route53_zone.this
  ]
}

# Create DMARC records for email authentication
resource "aws_route53_record" "dmarc_records" {
  for_each = {
    for k, v in local.records : k => v
    if v.type == "TXT" && can(regex("^_dmarc\\..*", v.name))
  }

  zone_id = local.hosted_zone_ids[each.value.zone_name]
  name    = each.value.name
  type    = "TXT"
  ttl     = each.value.ttl
  records = each.value.records

  depends_on = [
    aws_route53_zone.this
  ]
}

# Create SRV records for service discovery
resource "aws_route53_record" "srv_records" {
  for_each = {
    for k, v in local.records : k => v
    if v.type == "SRV"
  }

  zone_id = local.hosted_zone_ids[each.value.zone_name]
  name    = each.value.name
  type    = "SRV"
  ttl     = each.value.ttl
  records = each.value.records

  depends_on = [
    aws_route53_zone.this
  ]
}

# Create CAA records for certificate authority authorization
resource "aws_route53_record" "caa_records" {
  for_each = {
    for k, v in local.records : k => v
    if v.type == "CAA"
  }

  zone_id = local.hosted_zone_ids[each.value.zone_name]
  name    = each.value.name
  type    = "CAA"
  ttl     = each.value.ttl
  records = each.value.records

  depends_on = [
    aws_route53_zone.this
  ]
} 