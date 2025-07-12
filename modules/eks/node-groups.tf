# Default/Main EKS Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-main-nodes"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = var.subnet_ids

  instance_types = var.default_node_group.instance_types
  ami_type       = var.default_node_group.ami_type
  capacity_type  = var.default_node_group.capacity_type
  disk_size      = var.default_node_group.disk_size

  scaling_config {
    desired_size = var.default_node_group.scaling_config.desired_size
    max_size     = var.default_node_group.scaling_config.max_size
    min_size     = var.default_node_group.scaling_config.min_size
  }

  update_config {
    max_unavailable_percentage = var.default_node_group.update_config.max_unavailable_percentage
  }

  # Apply labels
  labels = merge(
    var.default_node_group.labels,
    {
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
      "k8s.io/cluster-autoscaler/enabled"         = "true"
      "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
      "node-group"                                = "main"
      "environment"                               = var.environment
    }
  )

  # Apply taints
  dynamic "taint" {
    for_each = var.default_node_group.taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  tags = merge(
    var.tags,
    var.node_group_tags,
    {
      Name = "${var.cluster_name}-main-nodes"
      Type = "EKS-NodeGroup"
      "k8s.io/cluster-autoscaler/enabled"         = "true"
      "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_read_only,
    aws_iam_role_policy_attachment.eks_ssm_managed_instance_core,
    aws_iam_role_policy_attachment.node_group_custom_policy_attachment,
  ]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# Additional EKS Node Groups
resource "aws_eks_node_group" "additional" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-${each.key}-nodes"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = var.subnet_ids

  instance_types = each.value.instance_types
  ami_type       = each.value.ami_type
  capacity_type  = each.value.capacity_type
  disk_size      = each.value.disk_size

  scaling_config {
    desired_size = each.value.scaling_config.desired_size
    max_size     = each.value.scaling_config.max_size
    min_size     = each.value.scaling_config.min_size
  }

  update_config {
    max_unavailable_percentage = each.value.update_config.max_unavailable_percentage
  }

  # Apply labels
  labels = merge(
    each.value.labels,
    {
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
      "k8s.io/cluster-autoscaler/enabled"         = "true"
      "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
      "node-group"                                = each.key
      "environment"                               = var.environment
    }
  )

  # Apply taints
  dynamic "taint" {
    for_each = each.value.taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  tags = merge(
    var.tags,
    var.node_group_tags,
    each.value.tags,
    {
      Name = "${var.cluster_name}-${each.key}-nodes"
      Type = "EKS-NodeGroup"
      "k8s.io/cluster-autoscaler/enabled"         = "true"
      "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_read_only,
    aws_iam_role_policy_attachment.eks_ssm_managed_instance_core,
    aws_iam_role_policy_attachment.node_group_custom_policy_attachment,
  ]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# Launch template for node groups (optional, for advanced configurations)
resource "aws_launch_template" "node_group_launch_template" {
  count = var.environment == "prod" ? 1 : 0

  name_prefix   = "${var.cluster_name}-node-group-"
  image_id      = data.aws_ami.eks_worker.id
  instance_type = var.default_node_group.instance_types[0]
  key_name      = var.environment == "prod" ? null : "${var.cluster_name}-key"

  vpc_security_group_ids = [aws_security_group.eks_nodes_additional.id]

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    cluster_name        = var.cluster_name
    cluster_endpoint    = aws_eks_cluster.main.endpoint
    cluster_ca_data     = aws_eks_cluster.main.certificate_authority[0].data
    bootstrap_arguments = "--container-runtime containerd"
  }))

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = var.default_node_group.disk_size
      volume_type = "gp3"
      encrypted   = true
    }
  }

  monitoring {
    enabled = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
    http_put_response_hop_limit = 2
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      {
        Name = "${var.cluster_name}-node-group-instance"
      }
    )
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Data source for EKS optimized AMI
data "aws_ami" "eks_worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.cluster_version}-v*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI Account ID
}

# Auto Scaling Group tags for cluster autoscaler
resource "aws_autoscaling_group_tag" "cluster_autoscaler_enabled" {
  for_each = toset(concat(
    [aws_eks_node_group.main.resources[0].autoscaling_groups[0].name],
    [for k, v in aws_eks_node_group.additional : v.resources[0].autoscaling_groups[0].name]
  ))

  autoscaling_group_name = each.value

  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "true"
    propagate_at_launch = false
  }
}

resource "aws_autoscaling_group_tag" "cluster_autoscaler_cluster_name" {
  for_each = toset(concat(
    [aws_eks_node_group.main.resources[0].autoscaling_groups[0].name],
    [for k, v in aws_eks_node_group.additional : v.resources[0].autoscaling_groups[0].name]
  ))

  autoscaling_group_name = each.value

  tag {
    key                 = "k8s.io/cluster-autoscaler/${var.cluster_name}"
    value               = "owned"
    propagate_at_launch = false
  }
} 