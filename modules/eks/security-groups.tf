# Additional security group for EKS cluster
resource "aws_security_group" "eks_cluster_additional" {
  name_prefix = "${var.cluster_name}-cluster-additional-"
  vpc_id      = var.vpc_id

  description = "Additional security group for EKS cluster ${var.cluster_name}"

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-cluster-additional-sg"
      Type = "EKS-Cluster-Additional"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Additional security group for EKS nodes
resource "aws_security_group" "eks_nodes_additional" {
  name_prefix = "${var.cluster_name}-nodes-additional-"
  vpc_id      = var.vpc_id

  description = "Additional security group for EKS nodes ${var.cluster_name}"

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-nodes-additional-sg"
      Type = "EKS-Nodes-Additional"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Ingress rule: Allow nodes to communicate with each other
resource "aws_security_group_rule" "nodes_internal_communication" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  source_security_group_id = aws_security_group.eks_nodes_additional.id
  security_group_id        = aws_security_group.eks_nodes_additional.id
  description              = "Allow nodes to communicate with each other"
}

# Ingress rule: Allow pods to communicate with the cluster API Server
resource "aws_security_group_rule" "cluster_api_server_ingress" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_nodes_additional.id
  security_group_id        = aws_security_group.eks_cluster_additional.id
  description              = "Allow pods to communicate with the cluster API Server"
}

# Ingress rule: Allow cluster to communicate with nodes
resource "aws_security_group_rule" "cluster_to_nodes_ingress" {
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster_additional.id
  security_group_id        = aws_security_group.eks_nodes_additional.id
  description              = "Allow cluster to communicate with nodes"
}

# Ingress rule: Allow cluster to communicate with nodes on port 443
resource "aws_security_group_rule" "cluster_to_nodes_443_ingress" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster_additional.id
  security_group_id        = aws_security_group.eks_nodes_additional.id
  description              = "Allow cluster to communicate with nodes on port 443"
}

# Ingress rule: Allow nodes to communicate with cluster API Server
resource "aws_security_group_rule" "nodes_to_cluster_api_server" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_nodes_additional.id
  security_group_id        = aws_security_group.eks_cluster_additional.id
  description              = "Allow nodes to communicate with cluster API Server"
}

# Ingress rule: Allow cluster to communicate with nodes for webhooks
resource "aws_security_group_rule" "cluster_to_nodes_webhooks" {
  type                     = "ingress"
  from_port                = 9443
  to_port                  = 9443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster_additional.id
  security_group_id        = aws_security_group.eks_nodes_additional.id
  description              = "Allow cluster to communicate with nodes for webhooks"
}

# Ingress rule: Allow HTTP traffic to load balancers
resource "aws_security_group_rule" "nodes_http_ingress" {
  count             = var.environment == "prod" ? 0 : 1
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_nodes_additional.id
  description       = "Allow HTTP traffic to load balancers"
}

# Ingress rule: Allow HTTPS traffic to load balancers
resource "aws_security_group_rule" "nodes_https_ingress" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_nodes_additional.id
  description       = "Allow HTTPS traffic to load balancers"
}

# Ingress rule: Allow SSH access (optional, for debugging)
resource "aws_security_group_rule" "nodes_ssh_ingress" {
  count             = var.environment == "prod" ? 0 : 1
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
  security_group_id = aws_security_group.eks_nodes_additional.id
  description       = "Allow SSH access from VPC"
}

# Egress rule: Allow all outbound traffic from cluster
resource "aws_security_group_rule" "cluster_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_cluster_additional.id
  description       = "Allow all outbound traffic from cluster"
}

# Egress rule: Allow all outbound traffic from nodes
resource "aws_security_group_rule" "nodes_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_nodes_additional.id
  description       = "Allow all outbound traffic from nodes"
}

# Custom security group rules from variables
resource "aws_security_group_rule" "cluster_additional_rules" {
  for_each = var.cluster_security_group_additional_rules

  type                     = each.value.type
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  cidr_blocks              = each.value.cidr_blocks
  source_security_group_id = each.value.source_security_group_id
  security_group_id        = aws_security_group.eks_cluster_additional.id
  description              = each.value.description
} 