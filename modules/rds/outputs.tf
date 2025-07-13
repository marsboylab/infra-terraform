# RDS instance outputs
output "db_instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.this.id
}

output "db_instance_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.this.arn
}

output "db_instance_identifier" {
  description = "RDS instance identifier"
  value       = aws_db_instance.this.identifier
}

output "db_instance_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.this.endpoint
}

output "db_instance_hosted_zone_id" {
  description = "RDS instance hosted zone ID"
  value       = aws_db_instance.this.hosted_zone_id
}

output "db_instance_resource_id" {
  description = "RDS instance resource ID"
  value       = aws_db_instance.this.resource_id
}

output "db_instance_status" {
  description = "RDS instance status"
  value       = aws_db_instance.this.status
}

output "db_instance_port" {
  description = "RDS instance port"
  value       = aws_db_instance.this.port
}

output "db_instance_engine" {
  description = "RDS instance engine"
  value       = aws_db_instance.this.engine
}

output "db_instance_engine_version" {
  description = "RDS instance engine version"
  value       = aws_db_instance.this.engine_version
}

output "db_instance_engine_version_actual" {
  description = "RDS instance actual engine version"
  value       = aws_db_instance.this.engine_version_actual
}

output "db_instance_class" {
  description = "RDS instance class"
  value       = aws_db_instance.this.instance_class
}

output "db_instance_allocated_storage" {
  description = "RDS instance allocated storage"
  value       = aws_db_instance.this.allocated_storage
}

output "db_instance_storage_type" {
  description = "RDS instance storage type"
  value       = aws_db_instance.this.storage_type
}

output "db_instance_storage_encrypted" {
  description = "RDS instance storage encrypted"
  value       = aws_db_instance.this.storage_encrypted
}

output "db_instance_kms_key_id" {
  description = "RDS instance KMS key ID"
  value       = aws_db_instance.this.kms_key_id
}

output "db_instance_multi_az" {
  description = "RDS instance multi-AZ"
  value       = aws_db_instance.this.multi_az
}

output "db_instance_availability_zone" {
  description = "RDS instance availability zone"
  value       = aws_db_instance.this.availability_zone
}

output "db_instance_publicly_accessible" {
  description = "RDS instance publicly accessible"
  value       = aws_db_instance.this.publicly_accessible
}

output "db_instance_backup_retention_period" {
  description = "RDS instance backup retention period"
  value       = aws_db_instance.this.backup_retention_period
}

output "db_instance_backup_window" {
  description = "RDS instance backup window"
  value       = aws_db_instance.this.backup_window
}

output "db_instance_maintenance_window" {
  description = "RDS instance maintenance window"
  value       = aws_db_instance.this.maintenance_window
}

output "db_instance_latest_restorable_time" {
  description = "RDS instance latest restorable time"
  value       = aws_db_instance.this.latest_restorable_time
}

output "db_instance_monitoring_interval" {
  description = "RDS instance monitoring interval"
  value       = aws_db_instance.this.monitoring_interval
}

output "db_instance_monitoring_role_arn" {
  description = "RDS instance monitoring role ARN"
  value       = aws_db_instance.this.monitoring_role_arn
}

output "db_instance_performance_insights_enabled" {
  description = "RDS instance Performance Insights enabled"
  value       = aws_db_instance.this.performance_insights_enabled
}

output "db_instance_performance_insights_kms_key_id" {
  description = "RDS instance Performance Insights KMS key ID"
  value       = aws_db_instance.this.performance_insights_kms_key_id
}

output "db_instance_performance_insights_retention_period" {
  description = "RDS instance Performance Insights retention period"
  value       = aws_db_instance.this.performance_insights_retention_period
}

output "db_instance_enabled_cloudwatch_logs_exports" {
  description = "RDS instance enabled CloudWatch logs exports"
  value       = aws_db_instance.this.enabled_cloudwatch_logs_exports
}

output "db_instance_deletion_protection" {
  description = "RDS instance deletion protection"
  value       = aws_db_instance.this.deletion_protection
}

output "db_instance_tags" {
  description = "RDS instance tags"
  value       = aws_db_instance.this.tags_all
}

# Database information
output "db_name" {
  description = "Database name"
  value       = aws_db_instance.this.db_name
}

output "db_username" {
  description = "Database username"
  value       = aws_db_instance.this.username
}

output "db_password" {
  description = "Database password"
  value       = local.db_password
  sensitive   = true
}

output "db_connection_string" {
  description = "Database connection string"
  value       = "${aws_db_instance.this.engine}://${aws_db_instance.this.username}:${local.db_password}@${aws_db_instance.this.endpoint}:${aws_db_instance.this.port}/${aws_db_instance.this.db_name}"
  sensitive   = true
}

# Master user secret
output "master_user_secret" {
  description = "Master user secret"
  value       = var.manage_master_user_password ? aws_db_instance.this.master_user_secret : null
}

# Read replica outputs
output "read_replica_instances" {
  description = "Read replica instances"
  value = var.create_read_replica ? {
    for i, replica in aws_db_instance.read_replica : i => {
      id         = replica.id
      arn        = replica.arn
      identifier = replica.identifier
      endpoint   = replica.endpoint
      port       = replica.port
      status     = replica.status
    }
  } : {}
}

output "read_replica_endpoints" {
  description = "Read replica endpoints"
  value       = var.create_read_replica ? [for replica in aws_db_instance.read_replica : replica.endpoint] : []
}

# Subnet group outputs
output "db_subnet_group_id" {
  description = "DB subnet group ID"
  value       = var.db_subnet_group_name != null ? var.db_subnet_group_name : aws_db_subnet_group.this[0].id
}

output "db_subnet_group_name" {
  description = "DB subnet group name"
  value       = var.db_subnet_group_name != null ? var.db_subnet_group_name : aws_db_subnet_group.this[0].name
}

output "db_subnet_group_arn" {
  description = "DB subnet group ARN"
  value       = var.db_subnet_group_name != null ? null : aws_db_subnet_group.this[0].arn
}

# Parameter group outputs
output "db_parameter_group_id" {
  description = "DB parameter group ID"
  value       = var.create_db_parameter_group ? aws_db_parameter_group.this[0].id : var.db_parameter_group_name
}

output "db_parameter_group_name" {
  description = "DB parameter group name"
  value       = var.create_db_parameter_group ? aws_db_parameter_group.this[0].name : var.db_parameter_group_name
}

output "db_parameter_group_arn" {
  description = "DB parameter group ARN"
  value       = var.create_db_parameter_group ? aws_db_parameter_group.this[0].arn : null
}

# Option group outputs
output "db_option_group_id" {
  description = "DB option group ID"
  value       = var.create_db_option_group ? aws_db_option_group.this[0].id : var.db_option_group_name
}

output "db_option_group_name" {
  description = "DB option group name"
  value       = var.create_db_option_group ? aws_db_option_group.this[0].name : var.db_option_group_name
}

output "db_option_group_arn" {
  description = "DB option group ARN"
  value       = var.create_db_option_group ? aws_db_option_group.this[0].arn : null
}

# Security group outputs
output "security_group_id" {
  description = "Security group ID"
  value       = var.create_security_group ? aws_security_group.this[0].id : null
}

output "security_group_name" {
  description = "Security group name"
  value       = var.create_security_group ? aws_security_group.this[0].name : null
}

output "security_group_arn" {
  description = "Security group ARN"
  value       = var.create_security_group ? aws_security_group.this[0].arn : null
}

output "security_group_ids" {
  description = "List of security group IDs"
  value       = local.security_group_ids
}

# Monitoring outputs
output "monitoring_role_arn" {
  description = "Monitoring role ARN"
  value       = local.monitoring_role_arn
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name"
  value       = var.create_cloudwatch_log_group ? aws_cloudwatch_log_group.this[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "CloudWatch log group ARN"
  value       = var.create_cloudwatch_log_group ? aws_cloudwatch_log_group.this[0].arn : null
}

# Alarm outputs
output "cloudwatch_alarms" {
  description = "CloudWatch alarms"
  value = var.create_alarms ? {
    cpu_utilization = {
      name = aws_cloudwatch_metric_alarm.cpu_utilization[0].alarm_name
      arn  = aws_cloudwatch_metric_alarm.cpu_utilization[0].arn
    }
    database_connections = {
      name = aws_cloudwatch_metric_alarm.database_connections[0].alarm_name
      arn  = aws_cloudwatch_metric_alarm.database_connections[0].arn
    }
    free_storage_space = {
      name = aws_cloudwatch_metric_alarm.free_storage_space[0].alarm_name
      arn  = aws_cloudwatch_metric_alarm.free_storage_space[0].arn
    }
    freeable_memory = {
      name = aws_cloudwatch_metric_alarm.freeable_memory[0].alarm_name
      arn  = aws_cloudwatch_metric_alarm.freeable_memory[0].arn
    }
    read_latency = {
      name = aws_cloudwatch_metric_alarm.read_latency[0].alarm_name
      arn  = aws_cloudwatch_metric_alarm.read_latency[0].arn
    }
    write_latency = {
      name = aws_cloudwatch_metric_alarm.write_latency[0].alarm_name
      arn  = aws_cloudwatch_metric_alarm.write_latency[0].arn
    }
  } : {}
}

output "read_replica_alarms" {
  description = "Read replica CloudWatch alarms"
  value = var.create_alarms && var.create_read_replica ? {
    for i, alarm in aws_cloudwatch_metric_alarm.read_replica_lag : i => {
      name = alarm.alarm_name
      arn  = alarm.arn
    }
  } : {}
}

# Configuration outputs
output "engine_defaults" {
  description = "Engine default configuration"
  value       = local.engine_defaults[var.engine]
}

output "effective_configuration" {
  description = "Effective configuration values"
  value = {
    engine_version             = local.effective_engine_version
    parameter_group_family     = local.effective_parameter_group_family
    major_engine_version       = local.effective_major_engine_version
    db_name                   = local.effective_db_name
    db_port                   = local.db_port
    db_parameter_group_name   = local.db_parameter_group_name
    db_option_group_name      = local.db_option_group_name
    db_subnet_group_name      = local.db_subnet_group_name
    security_group_ids        = local.security_group_ids
    backup_retention_period   = local.backup_retention_period
    final_snapshot_identifier = local.final_snapshot_identifier
    kms_key_id               = local.kms_key_id
    license_model            = local.license_model
  }
}

# Common tags
output "common_tags" {
  description = "Common tags applied to all resources"
  value       = local.common_tags
}

# Random password
output "random_password_result" {
  description = "Random password result (only if generated)"
  value       = var.password == null && !var.manage_master_user_password ? random_password.master_password[0].result : null
  sensitive   = true
} 