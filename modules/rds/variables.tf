# Basic Configuration
variable "name" {
  description = "Name of the RDS instance"
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

# Database Configuration
variable "engine" {
  description = "Database engine"
  type        = string
  default     = "mysql"
  validation {
    condition     = contains(["mysql", "postgres", "mariadb", "oracle-ee", "sqlserver-ex", "sqlserver-web", "sqlserver-se", "sqlserver-ee"], var.engine)
    error_message = "Engine must be one of: mysql, postgres, mariadb, oracle-ee, sqlserver-ex, sqlserver-web, sqlserver-se, sqlserver-ee."
  }
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
  default     = null
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
  validation {
    condition     = var.allocated_storage >= 20 && var.allocated_storage <= 65536
    error_message = "Allocated storage must be between 20 and 65536 GB."
  }
}

variable "max_allocated_storage" {
  description = "Maximum allocated storage for autoscaling"
  type        = number
  default     = 100
  validation {
    condition     = var.max_allocated_storage >= 20 && var.max_allocated_storage <= 65536
    error_message = "Max allocated storage must be between 20 and 65536 GB."
  }
}

variable "storage_type" {
  description = "Storage type (standard, gp2, gp3, io1, io2)"
  type        = string
  default     = "gp3"
  validation {
    condition     = contains(["standard", "gp2", "gp3", "io1", "io2"], var.storage_type)
    error_message = "Storage type must be one of: standard, gp2, gp3, io1, io2."
  }
}

variable "storage_encrypted" {
  description = "Enable storage encryption"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
  default     = null
}

variable "iops" {
  description = "IOPS for io1/io2 storage"
  type        = number
  default     = null
}

variable "storage_throughput" {
  description = "Storage throughput for gp3"
  type        = number
  default     = null
}

# Database Settings
variable "db_name" {
  description = "Database name"
  type        = string
  default     = null
}

variable "username" {
  description = "Master username"
  type        = string
  default     = "admin"
}

variable "password" {
  description = "Master password"
  type        = string
  default     = null
  sensitive   = true
}

variable "manage_master_user_password" {
  description = "Set to true to allow RDS to manage the master user password in Secrets Manager"
  type        = bool
  default     = false
}

variable "master_user_secret_kms_key_id" {
  description = "KMS key ID for master user password in Secrets Manager"
  type        = string
  default     = null
}

variable "port" {
  description = "Database port"
  type        = number
  default     = null
}

# Network Configuration
variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for DB subnet group"
  type        = list(string)
}

variable "db_subnet_group_name" {
  description = "Name of existing DB subnet group (optional)"
  type        = string
  default     = null
}

variable "publicly_accessible" {
  description = "Make the instance publicly accessible"
  type        = bool
  default     = false
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
  default     = []
}

variable "create_security_group" {
  description = "Create security group for RDS"
  type        = bool
  default     = true
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect to RDS"
  type        = list(string)
  default     = []
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to connect to RDS"
  type        = list(string)
  default     = []
}

# Backup Configuration
variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
  validation {
    condition     = var.backup_retention_period >= 0 && var.backup_retention_period <= 35
    error_message = "Backup retention period must be between 0 and 35 days."
  }
}

variable "backup_window" {
  description = "Backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Maintenance window"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "copy_tags_to_snapshot" {
  description = "Copy tags to snapshots"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when deleting"
  type        = bool
  default     = false
}

variable "final_snapshot_identifier" {
  description = "Final snapshot identifier"
  type        = string
  default     = null
}

variable "snapshot_identifier" {
  description = "Snapshot identifier to restore from"
  type        = string
  default     = null
}

variable "delete_automated_backups" {
  description = "Delete automated backups immediately"
  type        = bool
  default     = true
}

# High Availability
variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false
}

variable "availability_zone" {
  description = "Availability zone for single-AZ deployment"
  type        = string
  default     = null
}

# Read Replicas
variable "create_read_replica" {
  description = "Create read replica"
  type        = bool
  default     = false
}

variable "read_replica_count" {
  description = "Number of read replicas"
  type        = number
  default     = 1
  validation {
    condition     = var.read_replica_count >= 1 && var.read_replica_count <= 5
    error_message = "Read replica count must be between 1 and 5."
  }
}

variable "read_replica_instance_class" {
  description = "Instance class for read replicas"
  type        = string
  default     = null
}

variable "read_replica_multi_az" {
  description = "Enable Multi-AZ for read replicas"
  type        = bool
  default     = false
}

# Parameter Groups
variable "create_db_parameter_group" {
  description = "Create DB parameter group"
  type        = bool
  default     = true
}

variable "db_parameter_group_name" {
  description = "Name of existing DB parameter group"
  type        = string
  default     = null
}

variable "db_parameter_group_family" {
  description = "DB parameter group family"
  type        = string
  default     = null
}

variable "db_parameters" {
  description = "Database parameters"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

# Option Groups
variable "create_db_option_group" {
  description = "Create DB option group"
  type        = bool
  default     = false
}

variable "db_option_group_name" {
  description = "Name of existing DB option group"
  type        = string
  default     = null
}

variable "major_engine_version" {
  description = "Major engine version for option group"
  type        = string
  default     = null
}

variable "db_options" {
  description = "Database options"
  type = list(object({
    option_name = string
    option_settings = optional(list(object({
      name  = string
      value = string
    })))
    db_security_group_memberships  = optional(list(string))
    vpc_security_group_memberships = optional(list(string))
  }))
  default = []
}

# Monitoring
variable "monitoring_interval" {
  description = "Enhanced monitoring interval (0, 1, 5, 10, 15, 30, 60)"
  type        = number
  default     = 60
  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "Monitoring interval must be one of: 0, 1, 5, 10, 15, 30, 60."
  }
}

variable "monitoring_role_arn" {
  description = "IAM role ARN for enhanced monitoring"
  type        = string
  default     = null
}

variable "create_monitoring_role" {
  description = "Create IAM role for enhanced monitoring"
  type        = bool
  default     = true
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = false
}

variable "performance_insights_retention_period" {
  description = "Performance Insights retention period"
  type        = number
  default     = 7
  validation {
    condition     = contains([7, 731], var.performance_insights_retention_period)
    error_message = "Performance Insights retention period must be 7 or 731 days."
  }
}

variable "performance_insights_kms_key_id" {
  description = "KMS key ID for Performance Insights"
  type        = string
  default     = null
}

variable "create_cloudwatch_log_group" {
  description = "Create CloudWatch log group"
  type        = bool
  default     = false
}

variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch"
  type        = list(string)
  default     = []
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "CloudWatch log group retention period"
  type        = number
  default     = 7
}

variable "cloudwatch_log_group_kms_key_id" {
  description = "KMS key ID for CloudWatch log group"
  type        = string
  default     = null
}

# Alarms
variable "create_alarms" {
  description = "Create CloudWatch alarms"
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

variable "cpu_utilization_threshold" {
  description = "CPU utilization threshold for alarm"
  type        = number
  default     = 80
}

variable "database_connections_threshold" {
  description = "Database connections threshold for alarm"
  type        = number
  default     = 80
}

variable "free_storage_space_threshold" {
  description = "Free storage space threshold for alarm (in bytes)"
  type        = number
  default     = 2000000000 # 2GB
}

# Auto Minor Version Upgrade
variable "auto_minor_version_upgrade" {
  description = "Enable auto minor version upgrade"
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Apply changes immediately"
  type        = bool
  default     = false
}

variable "allow_major_version_upgrade" {
  description = "Allow major version upgrade"
  type        = bool
  default     = false
}

# Deletion Protection
variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

# Blue/Green Deployment
variable "blue_green_update" {
  description = "Enable blue/green deployment for updates"
  type        = map(string)
  default     = {}
}

# Restore Configuration
variable "restore_to_point_in_time" {
  description = "Restore to point in time configuration"
  type = object({
    restore_time                             = optional(string)
    source_db_instance_identifier           = optional(string)
    source_db_instance_automated_backups_arn = optional(string)
    source_dbi_resource_id                   = optional(string)
    use_latest_restorable_time               = optional(bool)
  })
  default = null
}

variable "s3_import" {
  description = "S3 import configuration"
  type = object({
    source_engine         = string
    source_engine_version = string
    bucket_name           = string
    bucket_prefix         = optional(string)
    ingestion_role        = string
  })
  default = null
}

# Replica Configuration
variable "replicate_source_db" {
  description = "Source database identifier for read replica"
  type        = string
  default     = null
}

# Global cluster
variable "global_cluster_identifier" {
  description = "Global cluster identifier"
  type        = string
  default     = null
}

# Domain (Microsoft SQL Server)
variable "domain" {
  description = "Active Directory domain"
  type        = string
  default     = null
}

variable "domain_iam_role_name" {
  description = "IAM role name for Active Directory domain"
  type        = string
  default     = null
}

# Character set
variable "character_set_name" {
  description = "Character set name (Oracle only)"
  type        = string
  default     = null
}

variable "nchar_character_set_name" {
  description = "National character set name (Oracle only)"
  type        = string
  default     = null
}

# Timezone
variable "timezone" {
  description = "Timezone (SQL Server only)"
  type        = string
  default     = null
}

# License
variable "license_model" {
  description = "License model"
  type        = string
  default     = null
}

# Network type
variable "network_type" {
  description = "Network type (IPV4 or DUAL)"
  type        = string
  default     = "IPV4"
  validation {
    condition     = contains(["IPV4", "DUAL"], var.network_type)
    error_message = "Network type must be IPV4 or DUAL."
  }
}

# Common tags
variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}

variable "db_instance_tags" {
  description = "Additional tags for DB instance"
  type        = map(string)
  default     = {}
}

variable "db_subnet_group_tags" {
  description = "Additional tags for DB subnet group"
  type        = map(string)
  default     = {}
}

variable "db_parameter_group_tags" {
  description = "Additional tags for DB parameter group"
  type        = map(string)
  default     = {}
}

variable "db_option_group_tags" {
  description = "Additional tags for DB option group"
  type        = map(string)
  default     = {}
}

variable "security_group_tags" {
  description = "Additional tags for security group"
  type        = map(string)
  default     = {}
} 