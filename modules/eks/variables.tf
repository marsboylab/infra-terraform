# General Configuration
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "environment" {
  description = "Environment name (dev, stg, prod)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

# VPC Configuration
variable "vpc_id" {
  description = "VPC ID for the EKS cluster"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "control_plane_subnet_ids" {
  description = "List of subnet IDs for the EKS control plane"
  type        = list(string)
  default     = []
}

# EKS Configuration
variable "cluster_endpoint_private_access" {
  description = "Whether the EKS cluster API server endpoint is private"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Whether the EKS cluster API server endpoint is public"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks that can access the EKS cluster API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_service_ipv4_cidr" {
  description = "The CIDR block to assign Kubernetes service IP addresses from"
  type        = string
  default     = "172.20.0.0/16"
}

variable "cluster_ip_family" {
  description = "The IP family used to assign Kubernetes pod and service addresses"
  type        = string
  default     = "ipv4"
}

# Node Group Configuration
variable "node_groups" {
  description = "Map of EKS node group configurations"
  type = map(object({
    instance_types = list(string)
    ami_type       = string
    capacity_type  = string
    disk_size      = number
    
    scaling_config = object({
      desired_size = number
      max_size     = number
      min_size     = number
    })
    
    update_config = object({
      max_unavailable_percentage = number
    })
    
    labels = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
    
    tags = map(string)
  }))
  default = {}
}

variable "default_node_group" {
  description = "Default node group configuration"
  type = object({
    instance_types = list(string)
    ami_type       = string
    capacity_type  = string
    disk_size      = number
    
    scaling_config = object({
      desired_size = number
      max_size     = number
      min_size     = number
    })
    
    update_config = object({
      max_unavailable_percentage = number
    })
    
    labels = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
  })
  default = {
    instance_types = ["t3.medium"]
    ami_type       = "AL2_x86_64"
    capacity_type  = "ON_DEMAND"
    disk_size      = 20
    
    scaling_config = {
      desired_size = 2
      max_size     = 10
      min_size     = 1
    }
    
    update_config = {
      max_unavailable_percentage = 25
    }
    
    labels = {}
    taints = []
  }
}

# IRSA Configuration
variable "enable_irsa" {
  description = "Whether to enable IRSA (IAM Roles for Service Accounts)"
  type        = bool
  default     = true
}

variable "irsa_roles" {
  description = "Map of IRSA roles to create"
  type = map(object({
    namespace                    = string
    service_account_name        = string
    role_policy_arns           = list(string)
    inline_policy_statements   = list(object({
      effect    = string
      actions   = list(string)
      resources = list(string)
    }))
  }))
  default = {}
}

# EKS Add-ons
variable "cluster_addons" {
  description = "Map of EKS cluster add-ons"
  type = map(object({
    version = string
    resolve_conflicts = string
    service_account_role_arn = string
  }))
  default = {}
}

variable "default_addons" {
  description = "Default EKS add-ons to install"
  type = map(object({
    version = string
    resolve_conflicts = string
  }))
  default = {
    coredns = {
      version = "v1.10.1-eksbuild.2"
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {
      version = "v1.28.1-eksbuild.1"
      resolve_conflicts = "OVERWRITE"
    }
    vpc-cni = {
      version = "v1.13.4-eksbuild.1"
      resolve_conflicts = "OVERWRITE"
    }
    aws-ebs-csi-driver = {
      version = "v1.22.0-eksbuild.2"
      resolve_conflicts = "OVERWRITE"
    }
  }
}

# Security Groups
variable "additional_security_group_ids" {
  description = "List of additional security group IDs to associate with the EKS cluster"
  type        = list(string)
  default     = []
}

variable "cluster_security_group_additional_rules" {
  description = "Map of additional security group rules to add to the cluster security group"
  type = map(object({
    description = string
    protocol    = string
    from_port   = number
    to_port     = number
    type        = string
    cidr_blocks = list(string)
    source_security_group_id = string
  }))
  default = {}
}

# Logging
variable "cluster_enabled_log_types" {
  description = "List of control plane logging types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Number of days to retain log events in CloudWatch"
  type        = number
  default     = 14
}

variable "cloudwatch_log_group_kms_key_id" {
  description = "KMS Key ID to use for encrypting CloudWatch log groups"
  type        = string
  default     = ""
}

# Encryption
variable "cluster_encryption_config" {
  description = "Configuration block with encryption configuration for the cluster"
  type = list(object({
    provider_key_arn = string
    resources        = list(string)
  }))
  default = []
}

# Tags
variable "tags" {
  description = "Map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "cluster_tags" {
  description = "Map of tags to apply to the EKS cluster"
  type        = map(string)
  default     = {}
}

variable "node_group_tags" {
  description = "Map of tags to apply to all node groups"
  type        = map(string)
  default     = {}
} 