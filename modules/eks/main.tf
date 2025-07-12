# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# TLS certificate for EKS OIDC issuer
data "tls_certificate" "eks_oidc_issuer" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# CloudWatch Log Group for EKS cluster
resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.cloudwatch_log_group_retention_in_days
  kms_key_id        = var.cloudwatch_log_group_kms_key_id != "" ? var.cloudwatch_log_group_kms_key_id : null

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-cluster-log-group"
    }
  )
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = length(var.control_plane_subnet_ids) > 0 ? var.control_plane_subnet_ids : var.subnet_ids
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
    security_group_ids      = concat([aws_security_group.eks_cluster_additional.id], var.additional_security_group_ids)
  }

  kubernetes_network_config {
    service_ipv4_cidr = var.cluster_service_ipv4_cidr
    ip_family         = var.cluster_ip_family
  }

  # Enable CloudWatch Logs
  enabled_cluster_log_types = var.cluster_enabled_log_types

  # Encryption configuration
  dynamic "encryption_config" {
    for_each = var.cluster_encryption_config
    content {
      provider {
        key_arn = encryption_config.value.provider_key_arn
      }
      resources = encryption_config.value.resources
    }
  }

  tags = merge(
    var.tags,
    var.cluster_tags,
    {
      Name = var.cluster_name
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller,
    aws_cloudwatch_log_group.eks_cluster,
  ]
}

# EKS OIDC Identity Provider
resource "aws_iam_openid_connect_provider" "eks_oidc_provider" {
  count = var.enable_irsa ? 1 : 0

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc_issuer.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-irsa-oidc-provider"
    }
  )
}

# EKS Add-ons
resource "aws_eks_addon" "cluster_addons" {
  for_each = merge(var.default_addons, var.cluster_addons)

  cluster_name             = aws_eks_cluster.main.name
  addon_name               = each.key
  addon_version            = each.value.version
  resolve_conflicts        = each.value.resolve_conflicts
  service_account_role_arn = lookup(each.value, "service_account_role_arn", null)

  depends_on = [
    aws_eks_node_group.main,
    aws_eks_node_group.additional,
  ]

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-${each.key}-addon"
    }
  )
}

# EKS Add-on for EBS CSI Driver with custom service account role
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = var.default_addons["aws-ebs-csi-driver"].version
  resolve_conflicts        = var.default_addons["aws-ebs-csi-driver"].resolve_conflicts
  service_account_role_arn = aws_iam_role.ebs_csi_driver_role.arn

  depends_on = [
    aws_eks_node_group.main,
    aws_eks_node_group.additional,
  ]

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-ebs-csi-driver-addon"
    }
  )
} 