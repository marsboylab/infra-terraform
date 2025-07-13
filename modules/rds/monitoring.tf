# CloudWatch log group for RDS logs
resource "aws_cloudwatch_log_group" "this" {
  count = var.create_cloudwatch_log_group ? 1 : 0
  
  name              = local.cloudwatch_log_group_name
  retention_in_days = var.cloudwatch_log_group_retention_in_days
  kms_key_id        = var.cloudwatch_log_group_kms_key_id
  
  tags = merge(
    local.common_tags,
    {
      Name = local.cloudwatch_log_group_name
      Type = "cloudwatch-log-group"
    }
  )
}

# CloudWatch alarms
resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  count = var.create_alarms ? 1 : 0
  
  alarm_name        = "${local.alarm_name_prefix}-cpu-utilization"
  alarm_description = "RDS CPU utilization alarm for ${local.name_prefix}"
  
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = var.cpu_utilization_threshold
  comparison_operator = "GreaterThanThreshold"
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this.id
  }
  
  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions
  
  tags = merge(
    local.common_tags,
    {
      Name = "${local.alarm_name_prefix}-cpu-utilization"
      Type = "cloudwatch-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "database_connections" {
  count = var.create_alarms ? 1 : 0
  
  alarm_name        = "${local.alarm_name_prefix}-database-connections"
  alarm_description = "RDS database connections alarm for ${local.name_prefix}"
  
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = var.database_connections_threshold
  comparison_operator = "GreaterThanThreshold"
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this.id
  }
  
  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions
  
  tags = merge(
    local.common_tags,
    {
      Name = "${local.alarm_name_prefix}-database-connections"
      Type = "cloudwatch-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "free_storage_space" {
  count = var.create_alarms ? 1 : 0
  
  alarm_name        = "${local.alarm_name_prefix}-free-storage-space"
  alarm_description = "RDS free storage space alarm for ${local.name_prefix}"
  
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = var.free_storage_space_threshold
  comparison_operator = "LessThanThreshold"
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this.id
  }
  
  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions
  
  tags = merge(
    local.common_tags,
    {
      Name = "${local.alarm_name_prefix}-free-storage-space"
      Type = "cloudwatch-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "freeable_memory" {
  count = var.create_alarms ? 1 : 0
  
  alarm_name        = "${local.alarm_name_prefix}-freeable-memory"
  alarm_description = "RDS freeable memory alarm for ${local.name_prefix}"
  
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 100000000 # 100MB in bytes
  comparison_operator = "LessThanThreshold"
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this.id
  }
  
  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions
  
  tags = merge(
    local.common_tags,
    {
      Name = "${local.alarm_name_prefix}-freeable-memory"
      Type = "cloudwatch-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "read_latency" {
  count = var.create_alarms ? 1 : 0
  
  alarm_name        = "${local.alarm_name_prefix}-read-latency"
  alarm_description = "RDS read latency alarm for ${local.name_prefix}"
  
  metric_name         = "ReadLatency"
  namespace           = "AWS/RDS"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 0.2 # 200ms
  comparison_operator = "GreaterThanThreshold"
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this.id
  }
  
  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions
  
  tags = merge(
    local.common_tags,
    {
      Name = "${local.alarm_name_prefix}-read-latency"
      Type = "cloudwatch-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "write_latency" {
  count = var.create_alarms ? 1 : 0
  
  alarm_name        = "${local.alarm_name_prefix}-write-latency"
  alarm_description = "RDS write latency alarm for ${local.name_prefix}"
  
  metric_name         = "WriteLatency"
  namespace           = "AWS/RDS"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 0.2 # 200ms
  comparison_operator = "GreaterThanThreshold"
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this.id
  }
  
  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions
  
  tags = merge(
    local.common_tags,
    {
      Name = "${local.alarm_name_prefix}-write-latency"
      Type = "cloudwatch-alarm"
    }
  )
}

# Read replica alarms
resource "aws_cloudwatch_metric_alarm" "read_replica_lag" {
  count = var.create_alarms && var.create_read_replica ? var.read_replica_count : 0
  
  alarm_name        = "${local.alarm_name_prefix}-read-replica-${count.index + 1}-lag"
  alarm_description = "RDS read replica lag alarm for ${local.name_prefix}-read-replica-${count.index + 1}"
  
  metric_name         = "ReplicaLag"
  namespace           = "AWS/RDS"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 30 # 30 seconds
  comparison_operator = "GreaterThanThreshold"
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.read_replica[count.index].id
  }
  
  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions
  
  tags = merge(
    local.common_tags,
    {
      Name = "${local.alarm_name_prefix}-read-replica-${count.index + 1}-lag"
      Type = "cloudwatch-alarm"
    }
  )
} 