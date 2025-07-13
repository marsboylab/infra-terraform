# Data sources
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_partition" "current" {}

# Generate random password if not provided
resource "random_password" "master_password" {
  count = var.password == null && !var.manage_master_user_password ? 1 : 0
  
  length  = 16
  special = true
}

# Local values
locals {
  # Basic configuration
  name_prefix = "${var.name}-${var.environment}"
  
  # Database configuration
  engine_family_mapping = {
    mysql      = "mysql8.0"
    postgres   = "postgres14"
    mariadb    = "mariadb10.6"
    oracle-ee  = "oracle-ee-19"
    sqlserver-ex = "sqlserver-ex-15.0"
    sqlserver-web = "sqlserver-web-15.0"
    sqlserver-se = "sqlserver-se-15.0"
    sqlserver-ee = "sqlserver-ee-15.0"
  }
  
  default_port_mapping = {
    mysql      = 3306
    postgres   = 5432
    mariadb    = 3306
    oracle-ee  = 1521
    sqlserver-ex = 1433
    sqlserver-web = 1433
    sqlserver-se = 1433
    sqlserver-ee = 1433
  }
  
  # Database parameters
  db_parameter_group_family = var.db_parameter_group_family != null ? var.db_parameter_group_family : local.engine_family_mapping[var.engine]
  
  # Database port
  db_port = var.port != null ? var.port : local.default_port_mapping[var.engine]
  
  # Database password
  db_password = var.password != null ? var.password : (
    var.manage_master_user_password ? null : random_password.master_password[0].result
  )
  
  # DB subnet group
  db_subnet_group_name = var.db_subnet_group_name != null ? var.db_subnet_group_name : aws_db_subnet_group.this[0].name
  
  # Parameter group
  db_parameter_group_name = var.db_parameter_group_name != null ? var.db_parameter_group_name : (
    var.create_db_parameter_group ? aws_db_parameter_group.this[0].name : null
  )
  
  # Option group
  db_option_group_name = var.db_option_group_name != null ? var.db_option_group_name : (
    var.create_db_option_group ? aws_db_option_group.this[0].name : null
  )
  
  # Major engine version for option group
  major_engine_version = var.major_engine_version != null ? var.major_engine_version : (
    var.engine_version != null ? join(".", slice(split(".", var.engine_version), 0, 2)) : null
  )
  
  # Security groups
  security_group_ids = var.create_security_group ? concat([aws_security_group.this[0].id], var.security_group_ids) : var.security_group_ids
  
  # Enhanced monitoring
  monitoring_role_arn = var.monitoring_role_arn != null ? var.monitoring_role_arn : (
    var.create_monitoring_role && var.monitoring_interval > 0 ? aws_iam_role.monitoring[0].arn : null
  )
  
  # CloudWatch logs
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports != null ? var.enabled_cloudwatch_logs_exports : (
    var.engine == "mysql" ? ["error", "general", "slow-query"] : (
      var.engine == "postgres" ? ["postgresql", "upgrade"] : (
        var.engine == "mariadb" ? ["error", "general", "slow-query"] : (
          var.engine == "oracle-ee" ? ["alert", "audit", "listener", "trace"] : (
            contains(["sqlserver-ex", "sqlserver-web", "sqlserver-se", "sqlserver-ee"], var.engine) ? ["agent", "error"] : []
          )
        )
      )
    )
  )
  
  # CloudWatch log group name
  cloudwatch_log_group_name = "/aws/rds/instance/${local.name_prefix}/logs"
  
  # Read replica configuration
  read_replica_instance_class = var.read_replica_instance_class != null ? var.read_replica_instance_class : var.instance_class
  
  # Final snapshot identifier
  final_snapshot_identifier = var.final_snapshot_identifier != null ? var.final_snapshot_identifier : (
    var.skip_final_snapshot ? null : "${local.name_prefix}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  )
  
  # Backup retention period
  backup_retention_period = var.backup_retention_period == 0 ? 0 : max(1, var.backup_retention_period)
  
  # Engine specific defaults
  engine_defaults = {
    mysql = {
      engine_version = "8.0.35"
      parameter_group_family = "mysql8.0"
      major_engine_version = "8.0"
      default_db_name = "mydb"
      default_parameters = [
        {
          name  = "innodb_buffer_pool_size"
          value = "{DBInstanceClassMemory*3/4}"
        }
      ]
    }
    postgres = {
      engine_version = "14.10"
      parameter_group_family = "postgres14"
      major_engine_version = "14"
      default_db_name = "postgres"
      default_parameters = [
        {
          name  = "shared_preload_libraries"
          value = "pg_stat_statements"
        }
      ]
    }
    mariadb = {
      engine_version = "10.6.16"
      parameter_group_family = "mariadb10.6"
      major_engine_version = "10.6"
      default_db_name = "mydb"
      default_parameters = [
        {
          name  = "innodb_buffer_pool_size"
          value = "{DBInstanceClassMemory*3/4}"
        }
      ]
    }
    oracle-ee = {
      engine_version = "19.0.0.0.ru-2023-10.rur-2023-10.r1"
      parameter_group_family = "oracle-ee-19"
      major_engine_version = "19"
      default_db_name = "ORCL"
      default_parameters = []
    }
    sqlserver-ex = {
      engine_version = "15.00.4322.2.v1"
      parameter_group_family = "sqlserver-ex-15.0"
      major_engine_version = "15.0"
      default_db_name = null
      default_parameters = []
    }
    sqlserver-web = {
      engine_version = "15.00.4322.2.v1"
      parameter_group_family = "sqlserver-web-15.0"
      major_engine_version = "15.0"
      default_db_name = null
      default_parameters = []
    }
    sqlserver-se = {
      engine_version = "15.00.4322.2.v1"
      parameter_group_family = "sqlserver-se-15.0"
      major_engine_version = "15.0"
      default_db_name = null
      default_parameters = []
    }
    sqlserver-ee = {
      engine_version = "15.00.4322.2.v1"
      parameter_group_family = "sqlserver-ee-15.0"
      major_engine_version = "15.0"
      default_db_name = null
      default_parameters = []
    }
  }
  
  # Apply engine defaults
  effective_engine_version = var.engine_version != null ? var.engine_version : local.engine_defaults[var.engine].engine_version
  effective_parameter_group_family = var.db_parameter_group_family != null ? var.db_parameter_group_family : local.engine_defaults[var.engine].parameter_group_family
  effective_major_engine_version = var.major_engine_version != null ? var.major_engine_version : local.engine_defaults[var.engine].major_engine_version
  effective_db_name = var.db_name != null ? var.db_name : local.engine_defaults[var.engine].default_db_name
  effective_db_parameters = length(var.db_parameters) > 0 ? var.db_parameters : local.engine_defaults[var.engine].default_parameters
  
  # Tags
  common_tags = merge(
    var.tags,
    {
      Name        = local.name_prefix
      Environment = var.environment
      ManagedBy   = "terraform"
      Engine      = var.engine
      Region      = data.aws_region.current.name
    }
  )
  
  db_instance_tags = merge(
    local.common_tags,
    var.db_instance_tags,
    {
      Type = "rds-instance"
    }
  )
  
  db_subnet_group_tags = merge(
    local.common_tags,
    var.db_subnet_group_tags,
    {
      Type = "db-subnet-group"
    }
  )
  
  db_parameter_group_tags = merge(
    local.common_tags,
    var.db_parameter_group_tags,
    {
      Type = "db-parameter-group"
    }
  )
  
  db_option_group_tags = merge(
    local.common_tags,
    var.db_option_group_tags,
    {
      Type = "db-option-group"
    }
  )
  
  security_group_tags = merge(
    local.common_tags,
    var.security_group_tags,
    {
      Type = "security-group"
    }
  )
  
  # Alarm configuration
  alarm_name_prefix = "${local.name_prefix}-rds"
  
  # Multi-AZ availability zones
  availability_zones = var.availability_zone != null ? [var.availability_zone] : []
  
  # Storage configuration
  storage_iops = var.storage_type == "io1" || var.storage_type == "io2" ? var.iops : null
  storage_throughput = var.storage_type == "gp3" ? var.storage_throughput : null
  
  # Performance Insights
  performance_insights_kms_key_id = var.performance_insights_kms_key_id != null ? var.performance_insights_kms_key_id : (
    var.performance_insights_enabled ? "alias/aws/rds" : null
  )
  
  # Encryption
  kms_key_id = var.kms_key_id != null ? var.kms_key_id : (
    var.storage_encrypted ? "alias/aws/rds" : null
  )
  
  # Blue/Green deployment
  blue_green_update_enabled = length(var.blue_green_update) > 0
  
  # Restore configuration
  restore_to_point_in_time_enabled = var.restore_to_point_in_time != null
  s3_import_enabled = var.s3_import != null
  
  # Replica configuration
  is_read_replica = var.replicate_source_db != null
  
  # License model defaults
  license_model = var.license_model != null ? var.license_model : (
    var.engine == "oracle-ee" ? "bring-your-own-license" : (
      contains(["sqlserver-ex", "sqlserver-web", "sqlserver-se", "sqlserver-ee"], var.engine) ? "license-included" : null
    )
  )
} 