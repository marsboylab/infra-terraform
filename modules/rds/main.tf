# Main RDS instance
resource "aws_db_instance" "this" {
  # Basic configuration
  identifier = local.name_prefix
  engine     = var.engine
  engine_version = local.effective_engine_version
  instance_class = var.instance_class
  
  # Database configuration
  db_name  = local.effective_db_name
  username = var.username
  password = local.db_password
  port     = local.db_port
  
  # Storage configuration
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted
  kms_key_id           = local.kms_key_id
  iops                 = local.storage_iops
  storage_throughput   = local.storage_throughput
  
  # Network configuration
  db_subnet_group_name   = local.db_subnet_group_name
  vpc_security_group_ids = local.security_group_ids
  publicly_accessible    = var.publicly_accessible
  availability_zone      = var.availability_zone
  multi_az              = var.multi_az
  network_type          = var.network_type
  
  # Backup configuration
  backup_retention_period = local.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window     = var.maintenance_window
  copy_tags_to_snapshot  = var.copy_tags_to_snapshot
  skip_final_snapshot    = var.skip_final_snapshot
  final_snapshot_identifier = local.final_snapshot_identifier
  delete_automated_backups = var.delete_automated_backups
  
  # Parameter and option groups
  parameter_group_name = local.db_parameter_group_name
  option_group_name    = local.db_option_group_name
  
  # Monitoring
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = local.monitoring_role_arn
  
  # Performance Insights
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_retention_period
  performance_insights_kms_key_id       = local.performance_insights_kms_key_id
  
  # CloudWatch logs
  enabled_cloudwatch_logs_exports = var.create_cloudwatch_log_group ? local.enabled_cloudwatch_logs_exports : []
  
  # Upgrades
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  allow_major_version_upgrade = var.allow_major_version_upgrade
  apply_immediately = var.apply_immediately
  
  # Deletion protection
  deletion_protection = var.deletion_protection
  
  # Master user password management
  manage_master_user_password = var.manage_master_user_password
  master_user_secret_kms_key_id = var.master_user_secret_kms_key_id
  
  # Restore configuration
  snapshot_identifier = var.snapshot_identifier
  
  dynamic "restore_to_point_in_time" {
    for_each = local.restore_to_point_in_time_enabled ? [var.restore_to_point_in_time] : []
    content {
      restore_time                             = restore_to_point_in_time.value.restore_time
      source_db_instance_identifier           = restore_to_point_in_time.value.source_db_instance_identifier
      source_db_instance_automated_backups_arn = restore_to_point_in_time.value.source_db_instance_automated_backups_arn
      source_dbi_resource_id                   = restore_to_point_in_time.value.source_dbi_resource_id
      use_latest_restorable_time               = restore_to_point_in_time.value.use_latest_restorable_time
    }
  }
  
  dynamic "s3_import" {
    for_each = local.s3_import_enabled ? [var.s3_import] : []
    content {
      source_engine         = s3_import.value.source_engine
      source_engine_version = s3_import.value.source_engine_version
      bucket_name           = s3_import.value.bucket_name
      bucket_prefix         = s3_import.value.bucket_prefix
      ingestion_role        = s3_import.value.ingestion_role
    }
  }
  
  # Blue/Green deployment
  dynamic "blue_green_update" {
    for_each = local.blue_green_update_enabled ? [var.blue_green_update] : []
    content {
      enabled = lookup(blue_green_update.value, "enabled", true)
    }
  }
  
  # Replica configuration
  replicate_source_db = var.replicate_source_db
  
  # Global cluster
  global_cluster_identifier = var.global_cluster_identifier
  
  # Domain (Microsoft SQL Server)
  domain               = var.domain
  domain_iam_role_name = var.domain_iam_role_name
  
  # Character set (Oracle)
  character_set_name       = var.character_set_name
  nchar_character_set_name = var.nchar_character_set_name
  
  # Timezone (SQL Server)
  timezone = var.timezone
  
  # License model
  license_model = local.license_model
  
  # Tags
  tags = local.db_instance_tags
  
  # Dependencies
  depends_on = [
    aws_db_subnet_group.this,
    aws_db_parameter_group.this,
    aws_db_option_group.this,
    aws_security_group.this,
    aws_iam_role.monitoring,
    aws_cloudwatch_log_group.this
  ]
  
  lifecycle {
    ignore_changes = [
      password,
      snapshot_identifier,
      latest_restorable_time
    ]
  }
  
  timeouts {
    create = "40m"
    delete = "60m"
    update = "80m"
  }
}

# Read replicas
resource "aws_db_instance" "read_replica" {
  count = var.create_read_replica ? var.read_replica_count : 0
  
  # Basic configuration
  identifier = "${local.name_prefix}-read-replica-${count.index + 1}"
  replicate_source_db = aws_db_instance.this.identifier
  instance_class = local.read_replica_instance_class
  
  # Network configuration
  publicly_accessible = var.publicly_accessible
  multi_az            = var.read_replica_multi_az
  
  # Monitoring
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = local.monitoring_role_arn
  
  # Performance Insights
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_retention_period
  performance_insights_kms_key_id       = local.performance_insights_kms_key_id
  
  # CloudWatch logs
  enabled_cloudwatch_logs_exports = var.create_cloudwatch_log_group ? local.enabled_cloudwatch_logs_exports : []
  
  # Upgrades
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately = var.apply_immediately
  
  # Deletion protection
  deletion_protection = var.deletion_protection
  
  # Parameter group
  parameter_group_name = local.db_parameter_group_name
  
  # Tags
  tags = merge(
    local.db_instance_tags,
    {
      Name = "${local.name_prefix}-read-replica-${count.index + 1}"
      Type = "rds-read-replica"
    }
  )
  
  depends_on = [
    aws_db_instance.this,
    aws_db_parameter_group.this,
    aws_iam_role.monitoring,
    aws_cloudwatch_log_group.this
  ]
  
  lifecycle {
    ignore_changes = [
      latest_restorable_time
    ]
  }
  
  timeouts {
    create = "40m"
    delete = "60m"
    update = "80m"
  }
}

# IAM role for enhanced monitoring
resource "aws_iam_role" "monitoring" {
  count = var.create_monitoring_role && var.monitoring_interval > 0 ? 1 : 0
  
  name = "${local.name_prefix}-rds-monitoring-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
  
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-rds-monitoring-role"
      Type = "iam-role"
    }
  )
}

# Attach policy to monitoring role
resource "aws_iam_role_policy_attachment" "monitoring" {
  count = var.create_monitoring_role && var.monitoring_interval > 0 ? 1 : 0
  
  role       = aws_iam_role.monitoring[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
} 