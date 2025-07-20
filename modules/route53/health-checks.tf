# Route53 Health Checks
resource "aws_route53_health_check" "this" {
  for_each = local.health_checks

  type                            = each.value.type
  resource_path                   = each.value.resource_path
  fqdn                           = each.value.fqdn
  ip_address                     = each.value.ip_address
  port                           = each.value.port != null ? each.value.port : (
    contains(keys(local.default_health_check_ports), each.value.type) ? 
    local.default_health_check_ports[each.value.type] : 80
  )
  request_interval               = each.value.request_interval
  failure_threshold              = each.value.failure_threshold
  measure_latency                = each.value.measure_latency
  invert_healthcheck             = each.value.invert_healthcheck
  disabled                       = each.value.disabled
  enable_sni                     = each.value.enable_sni
  search_string                  = each.value.search_string
  cloudwatch_alarm_region        = each.value.cloudwatch_alarm_region
  cloudwatch_alarm_name          = each.value.cloudwatch_alarm_name
  insufficient_data_health_status = each.value.insufficient_data_health_status
  reference_name                 = each.value.reference_name
  child_health_threshold         = each.value.child_health_threshold

  # Child health checks for calculated health checks
  child_health_checks = each.value.child_health_checks

  # Regions for health checks
  regions = each.value.regions

  tags = each.value.tags

  lifecycle {
    create_before_destroy = true
  }
}

# CloudWatch alarms for health checks
resource "aws_cloudwatch_metric_alarm" "health_check_status" {
  for_each = var.create_cloudwatch_alarms ? local.health_check_alarm_configs : {}

  alarm_name          = each.value.alarm_name
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  alarm_description   = each.value.alarm_description

  dimensions = {
    HealthCheckId = each.value.health_check_id
  }

  alarm_actions             = var.alarm_actions
  ok_actions                = var.ok_actions
  insufficient_data_actions = each.value.insufficient_data_actions
  treat_missing_data       = each.value.treat_missing_data

  tags = each.value.tags

  depends_on = [
    aws_route53_health_check.this
  ]
}

# Health check status alarms for each health check
resource "aws_cloudwatch_metric_alarm" "health_check_alarm" {
  for_each = var.create_cloudwatch_alarms ? local.health_checks : {}

  alarm_name          = "${local.name_prefix}-${each.key}-health-check-status"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = 300
  statistic           = "Minimum"
  threshold           = 1
  alarm_description   = "Health check status alarm for ${each.value.reference_name}"

  dimensions = {
    HealthCheckId = aws_route53_health_check.this[each.key].id
  }

  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions

  tags = merge(
    local.common_tags,
    {
      Name          = "${local.name_prefix}-${each.key}-health-check-status"
      Type          = "cloudwatch-alarm"
      HealthCheckId = aws_route53_health_check.this[each.key].id
    }
  )

  depends_on = [
    aws_route53_health_check.this
  ]
}

# Health check percentage healthy alarms
resource "aws_cloudwatch_metric_alarm" "health_check_percentage_healthy" {
  for_each = var.create_cloudwatch_alarms ? local.health_checks : {}

  alarm_name          = "${local.name_prefix}-${each.key}-health-check-percentage-healthy"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthCheckPercentHealthy"
  namespace           = "AWS/Route53"
  period              = 300
  statistic           = "Average"
  threshold           = 50
  alarm_description   = "Health check percentage healthy alarm for ${each.value.reference_name}"

  dimensions = {
    HealthCheckId = aws_route53_health_check.this[each.key].id
  }

  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions

  tags = merge(
    local.common_tags,
    {
      Name          = "${local.name_prefix}-${each.key}-health-check-percentage-healthy"
      Type          = "cloudwatch-alarm"
      HealthCheckId = aws_route53_health_check.this[each.key].id
    }
  )

  depends_on = [
    aws_route53_health_check.this
  ]
}

# Health check connection time alarms
resource "aws_cloudwatch_metric_alarm" "health_check_connection_time" {
  for_each = {
    for k, v in local.health_checks : k => v
    if var.create_cloudwatch_alarms && v.measure_latency
  }

  alarm_name          = "${local.name_prefix}-${each.key}-health-check-connection-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ConnectionTime"
  namespace           = "AWS/Route53"
  period              = 300
  statistic           = "Average"
  threshold           = 5000 # 5 seconds in milliseconds
  alarm_description   = "Health check connection time alarm for ${each.value.reference_name}"

  dimensions = {
    HealthCheckId = aws_route53_health_check.this[each.key].id
  }

  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions

  tags = merge(
    local.common_tags,
    {
      Name          = "${local.name_prefix}-${each.key}-health-check-connection-time"
      Type          = "cloudwatch-alarm"
      HealthCheckId = aws_route53_health_check.this[each.key].id
    }
  )

  depends_on = [
    aws_route53_health_check.this
  ]
}

# Health check time to first byte alarms
resource "aws_cloudwatch_metric_alarm" "health_check_time_to_first_byte" {
  for_each = {
    for k, v in local.health_checks : k => v
    if var.create_cloudwatch_alarms && v.measure_latency && contains(["HTTP", "HTTPS", "HTTP_STR_MATCH", "HTTPS_STR_MATCH"], v.type)
  }

  alarm_name          = "${local.name_prefix}-${each.key}-health-check-time-to-first-byte"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TimeToFirstByte"
  namespace           = "AWS/Route53"
  period              = 300
  statistic           = "Average"
  threshold           = 10000 # 10 seconds in milliseconds
  alarm_description   = "Health check time to first byte alarm for ${each.value.reference_name}"

  dimensions = {
    HealthCheckId = aws_route53_health_check.this[each.key].id
  }

  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions

  tags = merge(
    local.common_tags,
    {
      Name          = "${local.name_prefix}-${each.key}-health-check-time-to-first-byte"
      Type          = "cloudwatch-alarm"
      HealthCheckId = aws_route53_health_check.this[each.key].id
    }
  )

  depends_on = [
    aws_route53_health_check.this
  ]
}

# Calculated health checks
resource "aws_route53_health_check" "calculated" {
  for_each = {
    for k, v in local.health_checks : k => v
    if v.type == "CALCULATED"
  }

  type                   = "CALCULATED"
  child_health_checks    = each.value.child_health_checks
  child_health_threshold = each.value.child_health_threshold
  reference_name         = each.value.reference_name
  
  measure_latency        = each.value.measure_latency
  invert_healthcheck     = each.value.invert_healthcheck
  disabled               = each.value.disabled

  tags = each.value.tags

  depends_on = [
    aws_route53_health_check.this
  ]
}

# CloudWatch metric health checks
resource "aws_route53_health_check" "cloudwatch_metric" {
  for_each = {
    for k, v in local.health_checks : k => v
    if v.type == "CLOUDWATCH_METRIC"
  }

  type                            = "CLOUDWATCH_METRIC"
  cloudwatch_alarm_region         = each.value.cloudwatch_alarm_region
  cloudwatch_alarm_name           = each.value.cloudwatch_alarm_name
  insufficient_data_health_status = each.value.insufficient_data_health_status
  reference_name                  = each.value.reference_name
  
  invert_healthcheck = each.value.invert_healthcheck
  disabled           = each.value.disabled

  tags = each.value.tags
}

# Health check tags
resource "aws_route53_health_check_tags" "this" {
  for_each = local.health_checks

  health_check_id = aws_route53_health_check.this[each.key].id
  tags            = each.value.tags
}

# Create SNS topic for health check notifications
resource "aws_sns_topic" "health_check_notifications" {
  count = var.create_cloudwatch_alarms && length(var.alarm_actions) == 0 ? 1 : 0

  name = "${local.name_prefix}-health-check-notifications"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-health-check-notifications"
      Type = "sns-topic"
    }
  )
}

# Create SNS topic policy
resource "aws_sns_topic_policy" "health_check_notifications" {
  count = var.create_cloudwatch_alarms && length(var.alarm_actions) == 0 ? 1 : 0

  arn = aws_sns_topic.health_check_notifications[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action = "sns:Publish"
        Resource = aws_sns_topic.health_check_notifications[0].arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# Create email subscription for health check notifications
resource "aws_sns_topic_subscription" "health_check_email" {
  count = var.create_cloudwatch_alarms && length(var.alarm_actions) == 0 ? 1 : 0

  topic_arn = aws_sns_topic.health_check_notifications[0].arn
  protocol  = "email"
  endpoint  = "devops@${local.zones[keys(local.zones)[0]].domain_name}"

  depends_on = [
    aws_sns_topic.health_check_notifications
  ]
} 