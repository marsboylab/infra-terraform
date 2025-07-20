# DNSSEC Key Signing Keys
resource "aws_route53_key_signing_key" "this" {
  for_each = local.dnssec_key_signing_keys

  hosted_zone_id             = each.value.hosted_zone_id
  key_management_service_arn = each.value.key_management_service_arn
  name                       = each.value.name
  status                     = each.value.status

  depends_on = [
    aws_route53_zone.this
  ]
}

# KMS keys for DNSSEC signing
resource "aws_kms_key" "dnssec" {
  for_each = {
    for k, v in local.zones : k => v
    if v.enable_dnssec
  }

  description = "KMS key for DNSSEC signing for ${each.value.domain_name}"
  key_usage   = "SIGN_VERIFY"
  key_spec    = "ECC_NIST_P256"

  key_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Route53 Service"
        Effect = "Allow"
        Principal = {
          Service = "dnssec-route53.amazonaws.com"
        }
        Action = [
          "kms:DescribeKey",
          "kms:GetPublicKey",
          "kms:Sign",
          "kms:Verify"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name   = "${local.name_prefix}-${each.key}-dnssec-key"
      Type   = "kms-key"
      Domain = each.value.domain_name
    }
  )
}

# KMS key aliases for DNSSEC
resource "aws_kms_alias" "dnssec" {
  for_each = {
    for k, v in local.zones : k => v
    if v.enable_dnssec
  }

  name          = "alias/${local.name_prefix}-${each.key}-dnssec"
  target_key_id = aws_kms_key.dnssec[each.key].key_id
}

# Automatic DNSSEC key signing key creation
resource "aws_route53_key_signing_key" "auto" {
  for_each = {
    for k, v in local.zones : k => v
    if v.enable_dnssec && !contains(keys(local.dnssec_key_signing_keys), k)
  }

  hosted_zone_id             = aws_route53_zone.this[each.key].zone_id
  key_management_service_arn = aws_kms_key.dnssec[each.key].arn
  name                       = "${local.name_prefix}-${each.key}-ksk"
  status                     = "ACTIVE"

  depends_on = [
    aws_route53_zone.this,
    aws_kms_key.dnssec
  ]
}

# CloudWatch alarms for DNSSEC key signing key status
resource "aws_cloudwatch_metric_alarm" "dnssec_key_status" {
  for_each = {
    for k, v in local.zones : k => v
    if v.enable_dnssec && var.create_cloudwatch_alarms
  }

  alarm_name          = "${local.name_prefix}-${each.key}-dnssec-key-status"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "DNSSECKeySigningKeyStatus"
  namespace           = "AWS/Route53"
  period              = 300
  statistic           = "Maximum"
  threshold           = 1
  alarm_description   = "DNSSEC key signing key status alarm for ${each.value.domain_name}"

  dimensions = {
    HostedZoneId = aws_route53_zone.this[each.key].zone_id
  }

  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions

  tags = merge(
    local.common_tags,
    {
      Name   = "${local.name_prefix}-${each.key}-dnssec-key-status"
      Type   = "cloudwatch-alarm"
      Domain = each.value.domain_name
    }
  )

  depends_on = [
    aws_route53_hosted_zone_dnssec.this
  ]
}

# CloudWatch alarms for DNSSEC internal failure
resource "aws_cloudwatch_metric_alarm" "dnssec_internal_failure" {
  for_each = {
    for k, v in local.zones : k => v
    if v.enable_dnssec && var.create_cloudwatch_alarms
  }

  alarm_name          = "${local.name_prefix}-${each.key}-dnssec-internal-failure"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "DNSSECInternalFailure"
  namespace           = "AWS/Route53"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "DNSSEC internal failure alarm for ${each.value.domain_name}"

  dimensions = {
    HostedZoneId = aws_route53_zone.this[each.key].zone_id
  }

  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions

  tags = merge(
    local.common_tags,
    {
      Name   = "${local.name_prefix}-${each.key}-dnssec-internal-failure"
      Type   = "cloudwatch-alarm"
      Domain = each.value.domain_name
    }
  )

  depends_on = [
    aws_route53_hosted_zone_dnssec.this
  ]
}

# CloudWatch alarms for DNSSEC key signing key age
resource "aws_cloudwatch_metric_alarm" "dnssec_key_age" {
  for_each = {
    for k, v in local.zones : k => v
    if v.enable_dnssec && var.create_cloudwatch_alarms
  }

  alarm_name          = "${local.name_prefix}-${each.key}-dnssec-key-age"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "DNSSECKeyAge"
  namespace           = "AWS/Route53"
  period              = 86400 # 24 hours
  statistic           = "Maximum"
  threshold           = 2592000 # 30 days in seconds
  alarm_description   = "DNSSEC key age alarm for ${each.value.domain_name}"

  dimensions = {
    HostedZoneId = aws_route53_zone.this[each.key].zone_id
  }

  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions

  tags = merge(
    local.common_tags,
    {
      Name   = "${local.name_prefix}-${each.key}-dnssec-key-age"
      Type   = "cloudwatch-alarm"
      Domain = each.value.domain_name
    }
  )

  depends_on = [
    aws_route53_hosted_zone_dnssec.this
  ]
}

# DS record for parent zone delegation
resource "aws_route53_record" "ds_record" {
  for_each = {
    for k, v in local.zones : k => v
    if v.enable_dnssec && !v.private_zone
  }

  zone_id = aws_route53_zone.this[each.key].zone_id
  name    = each.value.domain_name
  type    = "DS"
  ttl     = 300
  records = [
    # This would typically be populated with actual DS record data
    # For now, this is a placeholder
    "12345 7 1 1234567890ABCDEF1234567890ABCDEF12345678"
  ]

  depends_on = [
    aws_route53_hosted_zone_dnssec.this
  ]
}

# DNSKEY record
resource "aws_route53_record" "dnskey_record" {
  for_each = {
    for k, v in local.zones : k => v
    if v.enable_dnssec
  }

  zone_id = aws_route53_zone.this[each.key].zone_id
  name    = each.value.domain_name
  type    = "DNSKEY"
  ttl     = 300
  records = [
    # This would typically be populated with actual DNSKEY record data
    # For now, this is a placeholder
    "257 3 7 AwEAAaX2mfDtxUAE...example"
  ]

  depends_on = [
    aws_route53_hosted_zone_dnssec.this
  ]
}

# NSEC3PARAM record for NSEC3 support
resource "aws_route53_record" "nsec3param_record" {
  for_each = {
    for k, v in local.zones : k => v
    if v.enable_dnssec
  }

  zone_id = aws_route53_zone.this[each.key].zone_id
  name    = each.value.domain_name
  type    = "NSEC3PARAM"
  ttl     = 300
  records = [
    "1 0 100 ABEDEF1234567890"
  ]

  depends_on = [
    aws_route53_hosted_zone_dnssec.this
  ]
}

# CloudWatch dashboard for DNSSEC monitoring
resource "aws_cloudwatch_dashboard" "dnssec" {
  count = var.create_cloudwatch_alarms && length([for k, v in local.zones : k if v.enable_dnssec]) > 0 ? 1 : 0

  dashboard_name = "${local.name_prefix}-dnssec-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            for k, v in local.zones : [
              "AWS/Route53",
              "DNSSECKeySigningKeyStatus",
              "HostedZoneId",
              aws_route53_zone.this[k].zone_id
            ]
            if v.enable_dnssec
          ]
          period = 300
          stat   = "Maximum"
          region = data.aws_region.current.name
          title  = "DNSSEC Key Signing Key Status"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            for k, v in local.zones : [
              "AWS/Route53",
              "DNSSECInternalFailure",
              "HostedZoneId",
              aws_route53_zone.this[k].zone_id
            ]
            if v.enable_dnssec
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "DNSSEC Internal Failures"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          metrics = [
            for k, v in local.zones : [
              "AWS/Route53",
              "DNSSECKeyAge",
              "HostedZoneId",
              aws_route53_zone.this[k].zone_id
            ]
            if v.enable_dnssec
          ]
          period = 86400
          stat   = "Maximum"
          region = data.aws_region.current.name
          title  = "DNSSEC Key Age"
        }
      }
    ]
  })
}

# SNS topic for DNSSEC alerts
resource "aws_sns_topic" "dnssec_alerts" {
  count = var.create_cloudwatch_alarms && length([for k, v in local.zones : k if v.enable_dnssec]) > 0 && length(var.alarm_actions) == 0 ? 1 : 0

  name = "${local.name_prefix}-dnssec-alerts"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-dnssec-alerts"
      Type = "sns-topic"
    }
  )
}

# SNS topic policy for DNSSEC alerts
resource "aws_sns_topic_policy" "dnssec_alerts" {
  count = var.create_cloudwatch_alarms && length([for k, v in local.zones : k if v.enable_dnssec]) > 0 && length(var.alarm_actions) == 0 ? 1 : 0

  arn = aws_sns_topic.dnssec_alerts[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action = "sns:Publish"
        Resource = aws_sns_topic.dnssec_alerts[0].arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
} 