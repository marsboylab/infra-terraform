# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_region" "current" {}

# Local values and calculations
locals {
  # VPC name calculation
  vpc_name = var.vpc_name != "" ? var.vpc_name : "${var.project_name}-${var.environment}-vpc"
  
  # Availability zones
  availability_zones = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, var.az_count)
  az_count          = length(local.availability_zones)
  
  # CIDR calculations
  vpc_cidr_block = var.vpc_cidr
  
  # Calculate subnet CIDRs if not provided
  public_subnet_cidrs = length(var.public_subnet_cidrs) > 0 ? var.public_subnet_cidrs : [
    for i in range(local.az_count) : cidrsubnet(local.vpc_cidr_block, 8, i)
  ]
  
  private_subnet_cidrs = length(var.private_subnet_cidrs) > 0 ? var.private_subnet_cidrs : [
    for i in range(local.az_count) : cidrsubnet(local.vpc_cidr_block, 8, i + 10)
  ]
  
  database_subnet_cidrs = length(var.database_subnet_cidrs) > 0 ? var.database_subnet_cidrs : [
    for i in range(local.az_count) : cidrsubnet(local.vpc_cidr_block, 8, i + 20)
  ]
  
  # NAT Gateway configuration
  nat_gateway_count = var.single_nat_gateway ? 1 : (var.one_nat_gateway_per_az ? local.az_count : local.az_count)
  
  # Common tags
  common_tags = merge(
    var.tags,
    {
      Environment   = var.environment
      Project       = var.project_name
      ManagedBy     = "terraform"
      Region        = data.aws_region.current.name
    }
  )
  
  # VPC tags
  vpc_tags = merge(
    local.common_tags,
    var.vpc_tags,
    {
      Name = local.vpc_name
      Type = "VPC"
    }
  )
  
  # Subnet tags
  public_subnet_tags = merge(
    local.common_tags,
    var.public_subnet_tags,
    {
      Type = "Public"
      "kubernetes.io/role/elb" = "1"
    }
  )
  
  private_subnet_tags = merge(
    local.common_tags,
    var.private_subnet_tags,
    {
      Type = "Private"
      "kubernetes.io/role/internal-elb" = "1"
    }
  )
  
  database_subnet_tags = merge(
    local.common_tags,
    var.database_subnet_tags,
    {
      Type = "Database"
    }
  )
  
  # Internet Gateway tags
  igw_tags = merge(
    local.common_tags,
    var.igw_tags,
    {
      Name = "${local.vpc_name}-igw"
      Type = "Internet Gateway"
    }
  )
  
  # NAT Gateway tags
  nat_gateway_tags = merge(
    local.common_tags,
    var.nat_gateway_tags,
    {
      Type = "NAT Gateway"
    }
  )
  
  # NAT EIP tags
  nat_eip_tags = merge(
    local.common_tags,
    var.nat_eip_tags,
    {
      Type = "NAT Gateway EIP"
    }
  )
  
  # Route table tags
  public_route_table_tags = merge(
    local.common_tags,
    var.public_route_table_tags,
    {
      Type = "Public Route Table"
    }
  )
  
  private_route_table_tags = merge(
    local.common_tags,
    var.private_route_table_tags,
    {
      Type = "Private Route Table"
    }
  )
  
  database_route_table_tags = merge(
    local.common_tags,
    var.database_route_table_tags,
    {
      Type = "Database Route Table"
    }
  )
  
  # VPC endpoints configuration
  vpc_endpoints_config = var.enable_vpc_endpoints ? merge(var.default_vpc_endpoints, var.vpc_endpoints) : var.vpc_endpoints
  
  # Gateway endpoints (S3, DynamoDB)
  gateway_endpoints = {
    for k, v in local.vpc_endpoints_config : k => v
    if v.vpc_endpoint_type == "Gateway"
  }
  
  # Interface endpoints (EC2, ECR, etc.)
  interface_endpoints = {
    for k, v in local.vpc_endpoints_config : k => v
    if v.vpc_endpoint_type == "Interface"
  }
  
  # Flow logs configuration
  flow_logs_log_group_name = var.flow_logs_log_group_name != "" ? var.flow_logs_log_group_name : "/aws/vpc/${local.vpc_name}/flow-logs"
  
  # DHCP options domain name
  dhcp_options_domain_name = var.dhcp_options_domain_name != "" ? var.dhcp_options_domain_name : "${data.aws_region.current.name}.compute.internal"
} 