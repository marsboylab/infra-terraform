# General Configuration
variable "environment" {
  description = "Environment name (dev, stg, prod)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "infra"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = ""
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

# Availability Zones
variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = []
}

variable "az_count" {
  description = "Number of availability zones to use (if availability_zones is empty)"
  type        = number
  default     = 2
}

# Subnet Configuration
variable "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = []
}

variable "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  default     = []
}

variable "database_subnet_cidrs" {
  description = "List of database subnet CIDR blocks"
  type        = list(string)
  default     = []
}

variable "public_subnet_suffix" {
  description = "Suffix to append to public subnet names"
  type        = string
  default     = "public"
}

variable "private_subnet_suffix" {
  description = "Suffix to append to private subnet names"
  type        = string
  default     = "private"
}

variable "database_subnet_suffix" {
  description = "Suffix to append to database subnet names"
  type        = string
  default     = "database"
}

# NAT Gateway Configuration
variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use single NAT Gateway for all private subnets"
  type        = bool
  default     = false
}

variable "one_nat_gateway_per_az" {
  description = "Use one NAT Gateway per availability zone"
  type        = bool
  default     = true
}

variable "reuse_nat_ips" {
  description = "Reuse existing Elastic IPs for NAT Gateways"
  type        = bool
  default     = false
}

variable "external_nat_ip_ids" {
  description = "List of external NAT IP IDs to use"
  type        = list(string)
  default     = []
}

# Internet Gateway Configuration
variable "enable_internet_gateway" {
  description = "Enable Internet Gateway"
  type        = bool
  default     = true
}

# VPC Endpoints Configuration
variable "enable_vpc_endpoints" {
  description = "Enable VPC endpoints for AWS services"
  type        = bool
  default     = true
}

variable "vpc_endpoints" {
  description = "Map of VPC endpoints to create"
  type = map(object({
    service             = string
    vpc_endpoint_type   = string
    route_table_ids     = list(string)
    subnet_ids          = list(string)
    security_group_ids  = list(string)
    policy_statements   = list(object({
      effect    = string
      actions   = list(string)
      resources = list(string)
    }))
  }))
  default = {}
}

variable "default_vpc_endpoints" {
  description = "Default VPC endpoints to create"
  type = map(object({
    service           = string
    vpc_endpoint_type = string
  }))
  default = {
    s3 = {
      service           = "s3"
      vpc_endpoint_type = "Gateway"
    }
    dynamodb = {
      service           = "dynamodb"
      vpc_endpoint_type = "Gateway"
    }
    ec2 = {
      service           = "ec2"
      vpc_endpoint_type = "Interface"
    }
    ecr_api = {
      service           = "ecr.api"
      vpc_endpoint_type = "Interface"
    }
    ecr_dkr = {
      service           = "ecr.dkr"
      vpc_endpoint_type = "Interface"
    }
    logs = {
      service           = "logs"
      vpc_endpoint_type = "Interface"
    }
    ssm = {
      service           = "ssm"
      vpc_endpoint_type = "Interface"
    }
    ssm_messages = {
      service           = "ssmmessages"
      vpc_endpoint_type = "Interface"
    }
    ec2_messages = {
      service           = "ec2messages"
      vpc_endpoint_type = "Interface"
    }
    sts = {
      service           = "sts"
      vpc_endpoint_type = "Interface"
    }
  }
}

# Flow Logs Configuration
variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = false
}

variable "flow_logs_destination_type" {
  description = "Type of destination for flow logs (cloud-watch-logs | s3)"
  type        = string
  default     = "cloud-watch-logs"
}

variable "flow_logs_log_group_name" {
  description = "CloudWatch log group name for flow logs"
  type        = string
  default     = ""
}

variable "flow_logs_s3_bucket_arn" {
  description = "S3 bucket ARN for flow logs"
  type        = string
  default     = ""
}

variable "flow_logs_retention_in_days" {
  description = "Number of days to retain flow logs"
  type        = number
  default     = 7
}

# DHCP Options Configuration
variable "enable_dhcp_options" {
  description = "Enable DHCP options set"
  type        = bool
  default     = false
}

variable "dhcp_options_domain_name" {
  description = "Domain name for DHCP options"
  type        = string
  default     = ""
}

variable "dhcp_options_domain_name_servers" {
  description = "Domain name servers for DHCP options"
  type        = list(string)
  default     = ["AmazonProvidedDNS"]
}

variable "dhcp_options_ntp_servers" {
  description = "NTP servers for DHCP options"
  type        = list(string)
  default     = []
}

variable "dhcp_options_netbios_name_servers" {
  description = "NetBIOS name servers for DHCP options"
  type        = list(string)
  default     = []
}

variable "dhcp_options_netbios_node_type" {
  description = "NetBIOS node type for DHCP options"
  type        = string
  default     = ""
}

# Security Groups Configuration
variable "default_security_group_ingress" {
  description = "List of ingress rules for default security group"
  type        = list(map(string))
  default     = []
}

variable "default_security_group_egress" {
  description = "List of egress rules for default security group"
  type        = list(map(string))
  default     = []
}

variable "manage_default_security_group" {
  description = "Should be true to adopt and manage default security group"
  type        = bool
  default     = true
}

# Network ACLs Configuration
variable "manage_default_network_acl" {
  description = "Should be true to adopt and manage default network ACL"
  type        = bool
  default     = true
}

variable "default_network_acl_ingress" {
  description = "List of ingress rules for default network ACL"
  type        = list(map(string))
  default = [
    {
      rule_no    = 100
      action     = "allow"
      from_port  = 0
      to_port    = 0
      protocol   = "-1"
      cidr_block = "0.0.0.0/0"
    },
  ]
}

variable "default_network_acl_egress" {
  description = "List of egress rules for default network ACL"
  type        = list(map(string))
  default = [
    {
      rule_no    = 100
      action     = "allow"
      from_port  = 0
      to_port    = 0
      protocol   = "-1"
      cidr_block = "0.0.0.0/0"
    },
  ]
}

variable "public_dedicated_network_acl" {
  description = "Create dedicated network ACL for public subnets"
  type        = bool
  default     = false
}

variable "private_dedicated_network_acl" {
  description = "Create dedicated network ACL for private subnets"
  type        = bool
  default     = false
}

variable "database_dedicated_network_acl" {
  description = "Create dedicated network ACL for database subnets"
  type        = bool
  default     = false
}

# Route Tables Configuration
variable "public_route_table_tags" {
  description = "Additional tags for public route tables"
  type        = map(string)
  default     = {}
}

variable "private_route_table_tags" {
  description = "Additional tags for private route tables"
  type        = map(string)
  default     = {}
}

variable "database_route_table_tags" {
  description = "Additional tags for database route tables"
  type        = map(string)
  default     = {}
}

# Tags Configuration
variable "tags" {
  description = "Map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_tags" {
  description = "Additional tags for VPC"
  type        = map(string)
  default     = {}
}

variable "public_subnet_tags" {
  description = "Additional tags for public subnets"
  type        = map(string)
  default     = {}
}

variable "private_subnet_tags" {
  description = "Additional tags for private subnets"
  type        = map(string)
  default     = {}
}

variable "database_subnet_tags" {
  description = "Additional tags for database subnets"
  type        = map(string)
  default     = {}
}

variable "igw_tags" {
  description = "Additional tags for Internet Gateway"
  type        = map(string)
  default     = {}
}

variable "nat_gateway_tags" {
  description = "Additional tags for NAT Gateways"
  type        = map(string)
  default     = {}
}

variable "nat_eip_tags" {
  description = "Additional tags for NAT Gateway Elastic IPs"
  type        = map(string)
  default     = {}
} 