# EKS Cluster outputs
output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.main.arn
}

output "cluster_id" {
  description = "ID of the EKS cluster"
  value       = aws_eks_cluster.main.id
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS cluster API server"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_version" {
  description = "Kubernetes version of the EKS cluster"
  value       = aws_eks_cluster.main.version
}

output "cluster_platform_version" {
  description = "Platform version of the EKS cluster"
  value       = aws_eks_cluster.main.platform_version
}

output "cluster_status" {
  description = "Status of the EKS cluster"
  value       = aws_eks_cluster.main.status
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "cluster_primary_security_group_id" {
  description = "Primary security group ID of the EKS cluster"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "cluster_additional_security_group_ids" {
  description = "Additional security group IDs attached to the EKS cluster"
  value       = concat([aws_security_group.eks_cluster_additional.id], var.additional_security_group_ids)
}

# OIDC Provider outputs
output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider if enabled"
  value       = var.enable_irsa ? aws_iam_openid_connect_provider.eks_oidc_provider[0].arn : null
}

output "oidc_provider_url" {
  description = "URL of the OIDC Provider"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "oidc_provider_url_without_protocol" {
  description = "URL of the OIDC Provider without protocol"
  value       = replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")
}

# Node Group outputs
output "node_groups" {
  description = "Map of node group configurations"
  value = {
    main = {
      arn                = aws_eks_node_group.main.arn
      node_group_name    = aws_eks_node_group.main.node_group_name
      status             = aws_eks_node_group.main.status
      capacity_type      = aws_eks_node_group.main.capacity_type
      instance_types     = aws_eks_node_group.main.instance_types
      ami_type           = aws_eks_node_group.main.ami_type
      disk_size          = aws_eks_node_group.main.disk_size
      scaling_config     = aws_eks_node_group.main.scaling_config
      update_config      = aws_eks_node_group.main.update_config
      labels             = aws_eks_node_group.main.labels
      taints             = aws_eks_node_group.main.taint
      asg_names          = aws_eks_node_group.main.resources[0].autoscaling_groups[0].name
      remote_access_sg   = aws_eks_node_group.main.resources[0].remote_access_security_group_id
    }
  }
}

output "additional_node_groups" {
  description = "Map of additional node group configurations"
  value = {
    for k, v in aws_eks_node_group.additional : k => {
      arn                = v.arn
      node_group_name    = v.node_group_name
      status             = v.status
      capacity_type      = v.capacity_type
      instance_types     = v.instance_types
      ami_type           = v.ami_type
      disk_size          = v.disk_size
      scaling_config     = v.scaling_config
      update_config      = v.update_config
      labels             = v.labels
      taints             = v.taint
      asg_names          = v.resources[0].autoscaling_groups[0].name
      remote_access_sg   = v.resources[0].remote_access_security_group_id
    }
  }
}

# Security Group outputs
output "cluster_additional_security_group_id" {
  description = "ID of the additional security group for EKS cluster"
  value       = aws_security_group.eks_cluster_additional.id
}

output "nodes_additional_security_group_id" {
  description = "ID of the additional security group for EKS nodes"
  value       = aws_security_group.eks_nodes_additional.id
}

# IAM Role outputs
output "cluster_iam_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = aws_iam_role.eks_cluster_role.arn
}

output "cluster_iam_role_name" {
  description = "Name of the EKS cluster IAM role"
  value       = aws_iam_role.eks_cluster_role.name
}

output "node_group_iam_role_arn" {
  description = "ARN of the EKS node group IAM role"
  value       = aws_iam_role.eks_node_group_role.arn
}

output "node_group_iam_role_name" {
  description = "Name of the EKS node group IAM role"
  value       = aws_iam_role.eks_node_group_role.name
}

output "ebs_csi_driver_iam_role_arn" {
  description = "ARN of the EBS CSI driver IAM role"
  value       = aws_iam_role.ebs_csi_driver_role.arn
}

output "ebs_csi_driver_iam_role_name" {
  description = "Name of the EBS CSI driver IAM role"
  value       = aws_iam_role.ebs_csi_driver_role.name
}

# IRSA Role outputs
output "irsa_role_arns" {
  description = "ARNs of the IRSA roles"
  value       = { for k, v in aws_iam_role.irsa_roles : k => v.arn }
}

output "common_irsa_role_arns" {
  description = "ARNs of the common IRSA roles"
  value       = { for k, v in aws_iam_role.common_irsa_roles : k => v.arn }
}

# Add-on outputs
output "cluster_addons" {
  description = "Map of EKS cluster add-ons"
  value = {
    for k, v in aws_eks_addon.cluster_addons : k => {
      arn                      = v.arn
      status                   = v.status
      addon_version            = v.addon_version
      service_account_role_arn = v.service_account_role_arn
    }
  }
}

output "ebs_csi_driver_addon" {
  description = "EBS CSI driver add-on information"
  value = {
    arn                      = aws_eks_addon.ebs_csi_driver.arn
    status                   = aws_eks_addon.ebs_csi_driver.status
    addon_version            = aws_eks_addon.ebs_csi_driver.addon_version
    service_account_role_arn = aws_eks_addon.ebs_csi_driver.service_account_role_arn
  }
}

# CloudWatch Log Group outputs
output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for EKS cluster"
  value       = aws_cloudwatch_log_group.eks_cluster.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for EKS cluster"
  value       = aws_cloudwatch_log_group.eks_cluster.arn
}

# Cluster configuration outputs for kubectl
output "cluster_config" {
  description = "Configuration for kubectl to connect to EKS cluster"
  value = {
    cluster_name     = aws_eks_cluster.main.name
    endpoint         = aws_eks_cluster.main.endpoint
    ca_data          = aws_eks_cluster.main.certificate_authority[0].data
    region           = data.aws_region.current.name
    oidc_issuer_url  = aws_eks_cluster.main.identity[0].oidc[0].issuer
  }
}

# Tagging outputs
output "tags" {
  description = "Tags applied to the EKS cluster and associated resources"
  value       = merge(var.tags, var.cluster_tags)
} 