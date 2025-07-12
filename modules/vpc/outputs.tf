# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.main.arn
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "vpc_name" {
  description = "Name of the VPC"
  value       = local.vpc_name
}

output "vpc_enable_dns_support" {
  description = "Whether DNS support is enabled for the VPC"
  value       = aws_vpc.main.enable_dns_support
}

output "vpc_enable_dns_hostnames" {
  description = "Whether DNS hostnames are enabled for the VPC"
  value       = aws_vpc.main.enable_dns_hostnames
}

output "vpc_main_route_table_id" {
  description = "ID of the main route table associated with the VPC"
  value       = aws_vpc.main.main_route_table_id
}

output "vpc_default_network_acl_id" {
  description = "ID of the default network ACL"
  value       = aws_vpc.main.default_network_acl_id
}

output "vpc_default_security_group_id" {
  description = "ID of the default security group"
  value       = aws_vpc.main.default_security_group_id
}

output "vpc_instance_tenancy" {
  description = "Tenancy of instances spin up within VPC"
  value       = aws_vpc.main.instance_tenancy
}

# Internet Gateway Outputs
output "igw_id" {
  description = "ID of the Internet Gateway"
  value       = var.enable_internet_gateway ? aws_internet_gateway.main[0].id : null
}

output "igw_arn" {
  description = "ARN of the Internet Gateway"
  value       = var.enable_internet_gateway ? aws_internet_gateway.main[0].arn : null
}

# Subnet Outputs
output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "List of IDs of database subnets"
  value       = aws_subnet.database[*].id
}

output "public_subnets" {
  description = "List of public subnets"
  value = [
    for subnet in aws_subnet.public : {
      id                = subnet.id
      arn               = subnet.arn
      cidr_block        = subnet.cidr_block
      availability_zone = subnet.availability_zone
    }
  ]
}

output "private_subnets" {
  description = "List of private subnets"
  value = [
    for subnet in aws_subnet.private : {
      id                = subnet.id
      arn               = subnet.arn
      cidr_block        = subnet.cidr_block
      availability_zone = subnet.availability_zone
    }
  ]
}

output "database_subnets" {
  description = "List of database subnets"
  value = [
    for subnet in aws_subnet.database : {
      id                = subnet.id
      arn               = subnet.arn
      cidr_block        = subnet.cidr_block
      availability_zone = subnet.availability_zone
    }
  ]
}

output "public_subnet_cidrs" {
  description = "List of CIDR blocks of public subnets"
  value       = local.public_subnet_cidrs
}

output "private_subnet_cidrs" {
  description = "List of CIDR blocks of private subnets"
  value       = local.private_subnet_cidrs
}

output "database_subnet_cidrs" {
  description = "List of CIDR blocks of database subnets"
  value       = local.database_subnet_cidrs
}

# Availability Zone Outputs
output "availability_zones" {
  description = "List of availability zones"
  value       = local.availability_zones
}

output "az_count" {
  description = "Number of availability zones"
  value       = local.az_count
}

# Route Table Outputs
output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = aws_route_table.private[*].id
}

output "database_route_table_ids" {
  description = "List of IDs of database route tables"
  value       = aws_route_table.database[*].id
}

output "public_route_table_association_ids" {
  description = "List of IDs of public route table associations"
  value       = aws_route_table_association.public[*].id
}

output "private_route_table_association_ids" {
  description = "List of IDs of private route table associations"
  value       = aws_route_table_association.private[*].id
}

output "database_route_table_association_ids" {
  description = "List of IDs of database route table associations"
  value       = aws_route_table_association.database[*].id
}

# NAT Gateway Outputs
output "nat_gateway_ids" {
  description = "List of IDs of NAT Gateways"
  value       = var.enable_nat_gateway ? aws_nat_gateway.main[*].id : null
}

output "nat_gateway_public_ips" {
  description = "List of public IP addresses of NAT Gateways"
  value       = var.enable_nat_gateway ? aws_nat_gateway.main[*].public_ip : null
}

output "nat_eip_ids" {
  description = "List of IDs of NAT Gateway Elastic IPs"
  value       = var.enable_nat_gateway && !var.reuse_nat_ips ? aws_eip.nat[*].id : null
}

output "nat_eip_public_ips" {
  description = "List of public IP addresses of NAT Gateway Elastic IPs"
  value       = var.enable_nat_gateway && !var.reuse_nat_ips ? aws_eip.nat[*].public_ip : null
}

# NAT Instance Outputs
output "nat_instance_ids" {
  description = "List of IDs of NAT instances"
  value       = var.enable_nat_gateway ? null : aws_instance.nat[*].id
}

output "nat_instance_public_ips" {
  description = "List of public IP addresses of NAT instances"
  value       = var.enable_nat_gateway ? null : aws_instance.nat[*].public_ip
}

output "nat_instance_private_ips" {
  description = "List of private IP addresses of NAT instances"
  value       = var.enable_nat_gateway ? null : aws_instance.nat[*].private_ip
}

# Database Subnet Group Outputs
output "database_subnet_group_id" {
  description = "ID of the database subnet group"
  value       = local.az_count > 0 ? aws_db_subnet_group.database[0].id : null
}

output "database_subnet_group_arn" {
  description = "ARN of the database subnet group"
  value       = local.az_count > 0 ? aws_db_subnet_group.database[0].arn : null
}

output "elasticache_subnet_group_name" {
  description = "Name of the ElastiCache subnet group"
  value       = local.az_count > 0 ? aws_elasticache_subnet_group.database[0].name : null
}

output "redshift_subnet_group_id" {
  description = "ID of the Redshift subnet group"
  value       = local.az_count > 0 ? aws_redshift_subnet_group.database[0].id : null
}

output "neptune_subnet_group_id" {
  description = "ID of the Neptune subnet group"
  value       = local.az_count > 0 ? aws_neptune_subnet_group.database[0].id : null
}

output "docdb_subnet_group_id" {
  description = "ID of the DocumentDB subnet group"
  value       = local.az_count > 0 ? aws_docdb_subnet_group.database[0].id : null
}

# VPC Endpoint Outputs
output "vpc_endpoint_s3_id" {
  description = "ID of the S3 VPC endpoint"
  value       = var.enable_vpc_endpoints && contains(keys(local.gateway_endpoints), "s3") ? aws_vpc_endpoint.gateway["s3"].id : null
}

output "vpc_endpoint_dynamodb_id" {
  description = "ID of the DynamoDB VPC endpoint"
  value       = var.enable_vpc_endpoints && contains(keys(local.gateway_endpoints), "dynamodb") ? aws_vpc_endpoint.gateway["dynamodb"].id : null
}

output "vpc_endpoint_ec2_id" {
  description = "ID of the EC2 VPC endpoint"
  value       = var.enable_vpc_endpoints && contains(keys(local.interface_endpoints), "ec2") ? aws_vpc_endpoint.interface["ec2"].id : null
}

output "vpc_endpoint_ecr_api_id" {
  description = "ID of the ECR API VPC endpoint"
  value       = var.enable_vpc_endpoints && contains(keys(local.interface_endpoints), "ecr_api") ? aws_vpc_endpoint.interface["ecr_api"].id : null
}

output "vpc_endpoint_ecr_dkr_id" {
  description = "ID of the ECR DKR VPC endpoint"
  value       = var.enable_vpc_endpoints && contains(keys(local.interface_endpoints), "ecr_dkr") ? aws_vpc_endpoint.interface["ecr_dkr"].id : null
}

output "vpc_endpoint_logs_id" {
  description = "ID of the CloudWatch Logs VPC endpoint"
  value       = var.enable_vpc_endpoints && contains(keys(local.interface_endpoints), "logs") ? aws_vpc_endpoint.interface["logs"].id : null
}

output "vpc_endpoint_ssm_id" {
  description = "ID of the SSM VPC endpoint"
  value       = var.enable_vpc_endpoints && contains(keys(local.interface_endpoints), "ssm") ? aws_vpc_endpoint.interface["ssm"].id : null
}

output "vpc_endpoint_eks_id" {
  description = "ID of the EKS VPC endpoint"
  value       = var.enable_vpc_endpoints ? aws_vpc_endpoint.eks[0].id : null
}

# Security Group Outputs
output "default_security_group_id" {
  description = "ID of the default security group"
  value       = var.manage_default_security_group ? aws_default_security_group.default[0].id : aws_vpc.main.default_security_group_id
}

output "vpc_endpoints_security_group_id" {
  description = "ID of the VPC endpoints security group"
  value       = length(local.interface_endpoints) > 0 ? aws_security_group.vpc_endpoints[0].id : null
}

output "nat_instance_security_group_id" {
  description = "ID of the NAT instance security group"
  value       = var.enable_nat_gateway ? null : aws_security_group.nat[0].id
}

# Network ACL Outputs
output "default_network_acl_id" {
  description = "ID of the default network ACL"
  value       = var.manage_default_network_acl ? aws_default_network_acl.default[0].id : aws_vpc.main.default_network_acl_id
}

output "public_network_acl_id" {
  description = "ID of the public network ACL"
  value       = var.public_dedicated_network_acl ? aws_network_acl.public[0].id : null
}

output "private_network_acl_id" {
  description = "ID of the private network ACL"
  value       = var.private_dedicated_network_acl ? aws_network_acl.private[0].id : null
}

output "database_network_acl_id" {
  description = "ID of the database network ACL"
  value       = var.database_dedicated_network_acl ? aws_network_acl.database[0].id : null
}

# DHCP Options Outputs
output "dhcp_options_id" {
  description = "ID of the DHCP options set"
  value       = var.enable_dhcp_options ? aws_vpc_dhcp_options.main[0].id : null
}

# Flow Logs Outputs
output "vpc_flow_log_id" {
  description = "ID of the VPC Flow Log"
  value       = var.enable_flow_logs ? aws_flow_log.main[0].id : null
}

output "vpc_flow_log_cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for VPC Flow Logs"
  value       = var.enable_flow_logs && var.flow_logs_destination_type == "cloud-watch-logs" ? aws_cloudwatch_log_group.flow_logs[0].name : null
}

# Common Outputs
output "tags" {
  description = "Tags applied to the VPC and associated resources"
  value       = local.common_tags
}

output "region" {
  description = "AWS region"
  value       = data.aws_region.current.name
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
} 