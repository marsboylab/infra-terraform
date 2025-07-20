# CloudWatch log group for Route53 query logging
resource "aws_cloudwatch_log_group" "route53_query_logs" {
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

# Query logging configurations for each hosted zone
resource "aws_route53_query_log" "zone_query_logs" {
  for_each = var.create_query_logging ? local.zones : {}

  depends_on = [aws_cloudwatch_log_group.route53_query_logs]

  destination_arn = aws_cloudwatch_log_group.route53_query_logs[0].arn
  zone_id         = aws_route53_zone.this[each.key].zone_id
}

# CloudWatch log metric filters for query analysis
resource "aws_cloudwatch_log_metric_filter" "query_count" {
  count = var.create_query_logging ? 1 : 0

  name           = "${local.name_prefix}-route53-query-count"
  log_group_name = aws_cloudwatch_log_group.route53_query_logs[0].name
  pattern        = "[timestamp, request_id, client_ip, hosted_zone_id, query_name, query_type, response_code, protocol, edge_location]"

  metric_transformation {
    name      = "Route53QueryCount"
    namespace = "AWS/Route53/Custom"
    value     = "1"
    
    default_value = 0
  }
}

# CloudWatch log metric filters for error responses
resource "aws_cloudwatch_log_metric_filter" "query_errors" {
  count = var.create_query_logging ? 1 : 0

  name           = "${local.name_prefix}-route53-query-errors"
  log_group_name = aws_cloudwatch_log_group.route53_query_logs[0].name
  pattern        = "[timestamp, request_id, client_ip, hosted_zone_id, query_name, query_type, response_code != \"NOERROR\", protocol, edge_location]"

  metric_transformation {
    name      = "Route53QueryErrors"
    namespace = "AWS/Route53/Custom"
    value     = "1"
    
    default_value = 0
  }
}

# CloudWatch log metric filters for query types
resource "aws_cloudwatch_log_metric_filter" "query_types" {
  for_each = var.create_query_logging ? toset(["A", "AAAA", "CNAME", "MX", "NS", "PTR", "SOA", "SRV", "TXT"]) : []

  name           = "${local.name_prefix}-route53-query-type-${each.value}"
  log_group_name = aws_cloudwatch_log_group.route53_query_logs[0].name
  pattern        = "[timestamp, request_id, client_ip, hosted_zone_id, query_name, query_type=\"${each.value}\", response_code, protocol, edge_location]"

  metric_transformation {
    name      = "Route53Query${each.value}Count"
    namespace = "AWS/Route53/Custom"
    value     = "1"
    
    default_value = 0
  }
}

# CloudWatch alarms for query volume
resource "aws_cloudwatch_metric_alarm" "high_query_volume" {
  count = var.create_query_logging && var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-route53-high-query-volume"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Route53QueryCount"
  namespace           = "AWS/Route53/Custom"
  period              = 300
  statistic           = "Sum"
  threshold           = 10000
  alarm_description   = "High Route53 query volume alarm"

  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-route53-high-query-volume"
      Type = "cloudwatch-alarm"
    }
  )

  depends_on = [
    aws_cloudwatch_log_metric_filter.query_count
  ]
}

# CloudWatch alarms for query errors
resource "aws_cloudwatch_metric_alarm" "high_query_errors" {
  count = var.create_query_logging && var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-route53-high-query-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Route53QueryErrors"
  namespace           = "AWS/Route53/Custom"
  period              = 300
  statistic           = "Sum"
  threshold           = 100
  alarm_description   = "High Route53 query errors alarm"

  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-route53-high-query-errors"
      Type = "cloudwatch-alarm"
    }
  )

  depends_on = [
    aws_cloudwatch_log_metric_filter.query_errors
  ]
}

# CloudWatch dashboard for Route53 monitoring
resource "aws_cloudwatch_dashboard" "route53" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  dashboard_name = "${local.name_prefix}-route53-dashboard"

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
            ["AWS/Route53", "QueryCount", { "stat" = "Sum" }]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "Route53 Query Count"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = concat(
            var.create_query_logging ? [
              ["AWS/Route53/Custom", "Route53QueryCount", { "stat" = "Sum" }],
              [".", "Route53QueryErrors", { "stat" = "Sum" }]
            ] : [],
            [
              for k, v in local.health_checks : [
                "AWS/Route53",
                "HealthCheckStatus",
                "HealthCheckId",
                aws_route53_health_check.this[k].id,
                { "stat" = "Minimum" }
              ]
            ]
          )
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "Route53 Custom Metrics"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 24
        height = 6
        properties = {
          metrics = [
            for k, v in local.health_checks : [
              "AWS/Route53",
              "HealthCheckPercentHealthy",
              "HealthCheckId",
              aws_route53_health_check.this[k].id
            ]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Health Check Percent Healthy"
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 12
        width  = 24
        height = 6
        properties = {
          query   = var.create_query_logging ? "SOURCE '${aws_cloudwatch_log_group.route53_query_logs[0].name}' | fields @timestamp, client_ip, query_name, query_type, response_code\n| filter response_code != \"NOERROR\"\n| stats count() by response_code\n| sort count desc" : ""
          region  = data.aws_region.current.name
          title   = "Route53 Query Errors"
          view    = "table"
        }
      }
    ]
  })
}

# CloudWatch Insights queries for Route53 analysis
resource "aws_cloudwatch_query_definition" "top_queried_domains" {
  count = var.create_query_logging ? 1 : 0

  name = "${local.name_prefix}-route53-top-queried-domains"

  log_group_names = [
    aws_cloudwatch_log_group.route53_query_logs[0].name
  ]

  query_string = <<EOF
fields @timestamp, query_name, query_type, response_code
| filter @message like /NOERROR/
| stats count() as query_count by query_name
| sort query_count desc
| limit 20
EOF
}

resource "aws_cloudwatch_query_definition" "query_errors_analysis" {
  count = var.create_query_logging ? 1 : 0

  name = "${local.name_prefix}-route53-query-errors-analysis"

  log_group_names = [
    aws_cloudwatch_log_group.route53_query_logs[0].name
  ]

  query_string = <<EOF
fields @timestamp, client_ip, query_name, query_type, response_code
| filter response_code != "NOERROR"
| stats count() as error_count by response_code, query_name
| sort error_count desc
| limit 50
EOF
}

resource "aws_cloudwatch_query_definition" "client_ip_analysis" {
  count = var.create_query_logging ? 1 : 0

  name = "${local.name_prefix}-route53-client-ip-analysis"

  log_group_names = [
    aws_cloudwatch_log_group.route53_query_logs[0].name
  ]

  query_string = <<EOF
fields @timestamp, client_ip, query_name, query_type
| stats count() as query_count by client_ip
| sort query_count desc
| limit 20
EOF
}

resource "aws_cloudwatch_query_definition" "query_type_distribution" {
  count = var.create_query_logging ? 1 : 0

  name = "${local.name_prefix}-route53-query-type-distribution"

  log_group_names = [
    aws_cloudwatch_log_group.route53_query_logs[0].name
  ]

  query_string = <<EOF
fields @timestamp, query_type
| stats count() as query_count by query_type
| sort query_count desc
EOF
}

# IAM role for Route53 query logging
resource "aws_iam_role" "route53_query_logging" {
  count = var.create_query_logging ? 1 : 0

  name = "${local.name_prefix}-route53-query-logging-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "route53.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-route53-query-logging-role"
      Type = "iam-role"
    }
  )
}

# IAM policy for Route53 query logging
resource "aws_iam_role_policy" "route53_query_logging" {
  count = var.create_query_logging ? 1 : 0

  name = "${local.name_prefix}-route53-query-logging-policy"
  role = aws_iam_role.route53_query_logging[0].id

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
        Resource = aws_cloudwatch_log_group.route53_query_logs[0].arn
      }
    ]
  })
}

# SNS topic for Route53 monitoring alerts
resource "aws_sns_topic" "route53_monitoring" {
  count = var.create_cloudwatch_alarms && length(var.alarm_actions) == 0 ? 1 : 0

  name = "${local.name_prefix}-route53-monitoring"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-route53-monitoring"
      Type = "sns-topic"
    }
  )
}

# SNS topic policy
resource "aws_sns_topic_policy" "route53_monitoring" {
  count = var.create_cloudwatch_alarms && length(var.alarm_actions) == 0 ? 1 : 0

  arn = aws_sns_topic.route53_monitoring[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action = "sns:Publish"
        Resource = aws_sns_topic.route53_monitoring[0].arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# CloudWatch composite alarms for Route53 health
resource "aws_cloudwatch_composite_alarm" "route53_health" {
  count = var.create_cloudwatch_alarms && length(local.health_checks) > 0 ? 1 : 0

  alarm_name        = "${local.name_prefix}-route53-overall-health"
  alarm_description = "Composite alarm for overall Route53 health"

  alarm_rule = join(" OR ", [
    for k, v in local.health_checks :
    "ALARM(${aws_cloudwatch_metric_alarm.health_check_alarm[k].alarm_name})"
  ])

  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-route53-overall-health"
      Type = "cloudwatch-composite-alarm"
    }
  )

  depends_on = [
    aws_cloudwatch_metric_alarm.health_check_alarm
  ]
} 