# Basic Configuration
variable "name" {
  description = "Name of the Route53 resources"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.name))
    error_message = "Name must start with a letter and contain only letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

# Hosted Zone Configuration
variable "zones" {
  description = "Map of hosted zones to create"
  type = map(object({
    domain_name         = string
    comment             = optional(string)
    private_zone        = optional(bool, false)
    vpc_id              = optional(string)
    vpc_region          = optional(string)
    additional_vpc_associations = optional(list(object({
      vpc_id     = string
      vpc_region = optional(string)
    })), [])
    force_destroy       = optional(bool, false)
    delegation_set_id   = optional(string)
    enable_dnssec       = optional(bool, false)
    tags                = optional(map(string), {})
  }))
  default = {}
}

# DNS Records Configuration
variable "records" {
  description = "Map of DNS records to create"
  type = map(object({
    zone_name = string
    name      = string
    type      = string
    ttl       = optional(number, 300)
    records   = optional(list(string))
    
    # Alias configuration
    alias = optional(object({
      name                   = string
      zone_id                = string
      evaluate_target_health = optional(bool, false)
    }))
    
    # Weighted routing policy
    weighted_routing_policy = optional(object({
      weight = number
    }))
    
    # Latency routing policy
    latency_routing_policy = optional(object({
      region = string
    }))
    
    # Failover routing policy
    failover_routing_policy = optional(object({
      type = string # PRIMARY or SECONDARY
    }))
    
    # Geolocation routing policy
    geolocation_routing_policy = optional(object({
      continent   = optional(string)
      country     = optional(string)
      subdivision = optional(string)
    }))
    
    # Multivalue answer routing policy
    multivalue_answer_routing_policy = optional(bool, false)
    
    # Geoproximity routing policy
    geoproximity_routing_policy = optional(object({
      aws_region   = optional(string)
      bias         = optional(number)
      coordinates = optional(object({
        latitude  = string
        longitude = string
      }))
    }))
    
    # Health check
    health_check_id = optional(string)
    
    # Set identifier for routing policies
    set_identifier = optional(string)
    
    # Allow overwrite
    allow_overwrite = optional(bool, false)
    
    tags = optional(map(string), {})
  }))
  default = {}
}

# Health Checks Configuration
variable "health_checks" {
  description = "Map of health checks to create"
  type = map(object({
    type                            = string # HTTP, HTTPS, HTTP_STR_MATCH, HTTPS_STR_MATCH, TCP, CALCULATED, CLOUDWATCH_METRIC
    resource_path                   = optional(string)
    fqdn                           = optional(string)
    ip_address                     = optional(string)
    port                           = optional(number)
    request_interval               = optional(number, 30)
    failure_threshold              = optional(number, 3)
    measure_latency                = optional(bool, false)
    invert_healthcheck             = optional(bool, false)
    disabled                       = optional(bool, false)
    enable_sni                     = optional(bool, true)
    search_string                  = optional(string)
    cloudwatch_alarm_region        = optional(string)
    cloudwatch_alarm_name          = optional(string)
    insufficient_data_health_status = optional(string, "Failure")
    reference_name                 = optional(string)
    
    # Child health checks for calculated health checks
    child_health_checks = optional(list(string), [])
    child_health_threshold = optional(number)
    
    # Regions for health checks
    regions = optional(list(string), [])
    
    tags = optional(map(string), {})
  }))
  default = {}
}

# Route53 Resolver Configuration
variable "resolver_endpoints" {
  description = "Map of Route53 resolver endpoints to create"
  type = map(object({
    direction                = string # INBOUND or OUTBOUND
    security_group_ids      = list(string)
    subnet_ids              = list(string)
    name                    = optional(string)
    ip_addresses            = optional(list(object({
      subnet_id = string
      ip        = optional(string)
    })), [])
    tags                    = optional(map(string), {})
  }))
  default = {}
}

variable "resolver_rules" {
  description = "Map of Route53 resolver rules to create"
  type = map(object({
    domain_name          = string
    rule_type            = string # FORWARD, SYSTEM, RECURSIVE
    resolver_endpoint_id = optional(string)
    target_ips = optional(list(object({
      ip   = string
      port = optional(number, 53)
    })), [])
    name = optional(string)
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "resolver_rule_associations" {
  description = "Map of Route53 resolver rule associations"
  type = map(object({
    resolver_rule_id = string
    vpc_id           = string
    name             = optional(string)
  }))
  default = {}
}

# DNSSEC Configuration
variable "dnssec_key_signing_keys" {
  description = "Map of DNSSEC key signing keys"
  type = map(object({
    hosted_zone_id             = string
    key_management_service_arn = string
    name                       = string
    status                     = optional(string, "ACTIVE")
  }))
  default = {}
}

# Query Logging Configuration
variable "query_logging_configs" {
  description = "Map of query logging configurations"
  type = map(object({
    hosted_zone_id              = string
    cloudwatch_log_group_arn    = string
    name                        = optional(string)
  }))
  default = {}
}

# VPC Association Configuration
variable "vpc_associations" {
  description = "Map of VPC associations for private hosted zones"
  type = map(object({
    zone_id    = string
    vpc_id     = string
    vpc_region = optional(string)
  }))
  default = {}
}

# Domain Registration Configuration
variable "domains" {
  description = "Map of domains to register"
  type = map(object({
    domain_name           = string
    duration_in_years     = optional(number, 1)
    auto_renew            = optional(bool, true)
    transfer_lock         = optional(bool, true)
    
    # Name servers
    name_servers = optional(list(string), [])
    
    # Registrant contact
    registrant_contact = optional(object({
      first_name        = string
      last_name         = string
      contact_type      = optional(string, "PERSON")
      organization_name = optional(string)
      address_line_1    = string
      address_line_2    = optional(string)
      city              = string
      state             = optional(string)
      country_code      = string
      zip_code          = string
      phone_number      = string
      email             = string
      fax               = optional(string)
      extra_params      = optional(map(string), {})
    }))
    
    # Admin contact
    admin_contact = optional(object({
      first_name        = string
      last_name         = string
      contact_type      = optional(string, "PERSON")
      organization_name = optional(string)
      address_line_1    = string
      address_line_2    = optional(string)
      city              = string
      state             = optional(string)
      country_code      = string
      zip_code          = string
      phone_number      = string
      email             = string
      fax               = optional(string)
      extra_params      = optional(map(string), {})
    }))
    
    # Tech contact
    tech_contact = optional(object({
      first_name        = string
      last_name         = string
      contact_type      = optional(string, "PERSON")
      organization_name = optional(string)
      address_line_1    = string
      address_line_2    = optional(string)
      city              = string
      state             = optional(string)
      country_code      = string
      zip_code          = string
      phone_number      = string
      email             = string
      fax               = optional(string)
      extra_params      = optional(map(string), {})
    }))
    
    # Privacy protection
    privacy_protection = optional(bool, true)
    
    tags = optional(map(string), {})
  }))
  default = {}
}

# Traffic Policy Configuration
variable "traffic_policies" {
  description = "Map of traffic policies to create"
  type = map(object({
    name     = string
    comment  = optional(string)
    document = string
    type     = optional(string, "A")
  }))
  default = {}
}

variable "traffic_policy_instances" {
  description = "Map of traffic policy instances"
  type = map(object({
    hosted_zone_id   = string
    name             = string
    ttl              = number
    traffic_policy_id = string
    traffic_policy_version = number
  }))
  default = {}
}

# Monitoring Configuration
variable "create_cloudwatch_alarms" {
  description = "Create CloudWatch alarms for Route53"
  type        = bool
  default     = false
}

variable "alarm_actions" {
  description = "List of alarm actions"
  type        = list(string)
  default     = []
}

variable "ok_actions" {
  description = "List of OK actions"
  type        = list(string)
  default     = []
}

variable "health_check_alarm_configs" {
  description = "Map of health check alarm configurations"
  type = map(object({
    health_check_id                = string
    comparison_operator           = optional(string, "LessThanThreshold")
    evaluation_periods            = optional(number, 2)
    metric_name                   = optional(string, "HealthCheckStatus")
    namespace                     = optional(string, "AWS/Route53")
    period                        = optional(number, 300)
    statistic                     = optional(string, "Minimum")
    threshold                     = optional(number, 1)
    alarm_description             = optional(string)
    alarm_name                    = optional(string)
    insufficient_data_actions     = optional(list(string), [])
    treat_missing_data           = optional(string, "breaching")
    tags                         = optional(map(string), {})
  }))
  default = {}
}

# Certificate Validation Configuration
variable "certificate_validations" {
  description = "Map of certificate validations using Route53"
  type = map(object({
    certificate_arn         = string
    validation_record_fqdns = optional(list(string), [])
    timeouts = optional(object({
      create = optional(string, "5m")
    }), {})
  }))
  default = {}
}

# Common Configuration
variable "create_query_logging" {
  description = "Create CloudWatch log group for query logging"
  type        = bool
  default     = false
}

variable "query_log_retention_in_days" {
  description = "CloudWatch log group retention period for query logs"
  type        = number
  default     = 7
  validation {
    condition = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.query_log_retention_in_days)
    error_message = "Query log retention period must be a valid CloudWatch retention period."
  }
}

variable "query_log_kms_key_id" {
  description = "KMS key ID for query log encryption"
  type        = string
  default     = null
}

# Default TTL values
variable "default_ttl" {
  description = "Default TTL for DNS records"
  type        = number
  default     = 300
  validation {
    condition     = var.default_ttl >= 0 && var.default_ttl <= 2147483647
    error_message = "TTL must be between 0 and 2147483647 seconds."
  }
}

# Common tags
variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}

variable "hosted_zone_tags" {
  description = "Additional tags for hosted zones"
  type        = map(string)
  default     = {}
}

variable "record_tags" {
  description = "Additional tags for DNS records"
  type        = map(string)
  default     = {}
}

variable "health_check_tags" {
  description = "Additional tags for health checks"
  type        = map(string)
  default     = {}
} 