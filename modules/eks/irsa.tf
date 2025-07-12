# IRSA roles for service accounts
resource "aws_iam_role" "irsa_roles" {
  for_each = var.irsa_roles

  name = "${var.cluster_name}-irsa-${each.key}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = var.enable_irsa ? aws_iam_openid_connect_provider.eks_oidc_provider[0].arn : null
        }
        Condition = {
          StringEquals = {
            "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:${each.value.namespace}:${each.value.service_account_name}"
            "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-irsa-${each.key}"
      Type = "IRSA-Role"
      ServiceAccount = each.value.service_account_name
      Namespace = each.value.namespace
    }
  )
}

# Attach AWS managed policies to IRSA roles
resource "aws_iam_role_policy_attachment" "irsa_role_policy_attachments" {
  for_each = {
    for combination in flatten([
      for role_name, role_config in var.irsa_roles : [
        for policy_arn in role_config.role_policy_arns : {
          role_name  = role_name
          policy_arn = policy_arn
        }
      ]
    ]) : "${combination.role_name}-${replace(combination.policy_arn, "/[^a-zA-Z0-9]/", "-")}" => combination
  }

  role       = aws_iam_role.irsa_roles[each.value.role_name].name
  policy_arn = each.value.policy_arn
}

# Create inline policies for IRSA roles
resource "aws_iam_policy" "irsa_inline_policies" {
  for_each = {
    for role_name, role_config in var.irsa_roles : 
    role_name => role_config 
    if length(role_config.inline_policy_statements) > 0
  }

  name        = "${var.cluster_name}-irsa-${each.key}-inline-policy"
  description = "Inline policy for IRSA role ${each.key}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      for statement in each.value.inline_policy_statements : {
        Effect   = statement.effect
        Action   = statement.actions
        Resource = statement.resources
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-irsa-${each.key}-inline-policy"
      Type = "IRSA-Policy"
    }
  )
}

# Attach inline policies to IRSA roles
resource "aws_iam_role_policy_attachment" "irsa_inline_policy_attachments" {
  for_each = {
    for role_name, role_config in var.irsa_roles : 
    role_name => role_config 
    if length(role_config.inline_policy_statements) > 0
  }

  role       = aws_iam_role.irsa_roles[each.key].name
  policy_arn = aws_iam_policy.irsa_inline_policies[each.key].arn
}

# Common IRSA roles for essential services
locals {
  common_irsa_roles = {
    # AWS Load Balancer Controller
    aws_load_balancer_controller = {
      namespace                    = "kube-system"
      service_account_name        = "aws-load-balancer-controller"
      role_policy_arns           = []
      inline_policy_statements   = [
        {
          effect = "Allow"
          actions = [
            "iam:CreateServiceLinkedRole",
            "ec2:DescribeAccountAttributes",
            "ec2:DescribeAddresses",
            "ec2:DescribeAvailabilityZones",
            "ec2:DescribeInternetGateways",
            "ec2:DescribeVpcs",
            "ec2:DescribeVpcPeeringConnections",
            "ec2:DescribeSubnets",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeInstances",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DescribeTags",
            "ec2:GetCoipPoolUsage",
            "ec2:GetManagedPrefixListEntries",
            "ec2:DescribeCoipPools",
            "elasticloadbalancing:DescribeLoadBalancers",
            "elasticloadbalancing:DescribeLoadBalancerAttributes",
            "elasticloadbalancing:DescribeListeners",
            "elasticloadbalancing:DescribeListenerCertificates",
            "elasticloadbalancing:DescribeSSLPolicies",
            "elasticloadbalancing:DescribeRules",
            "elasticloadbalancing:DescribeTargetGroups",
            "elasticloadbalancing:DescribeTargetGroupAttributes",
            "elasticloadbalancing:DescribeTargetHealth",
            "elasticloadbalancing:DescribeTags"
          ]
          resources = ["*"]
        },
        {
          effect = "Allow"
          actions = [
            "cognito-idp:DescribeUserPoolClient",
            "acm:ListCertificates",
            "acm:DescribeCertificate",
            "iam:ListServerCertificates",
            "iam:GetServerCertificate",
            "waf-regional:GetWebACL",
            "waf-regional:GetWebACLForResource",
            "waf-regional:AssociateWebACL",
            "waf-regional:DisassociateWebACL",
            "wafv2:GetWebACL",
            "wafv2:GetWebACLForResource",
            "wafv2:AssociateWebACL",
            "wafv2:DisassociateWebACL",
            "shield:DescribeProtection",
            "shield:GetSubscriptionState",
            "shield:DescribeSubscription",
            "shield:CreateProtection",
            "shield:DeleteProtection"
          ]
          resources = ["*"]
        },
        {
          effect = "Allow"
          actions = [
            "ec2:AuthorizeSecurityGroupIngress",
            "ec2:RevokeSecurityGroupIngress",
            "ec2:CreateSecurityGroup",
            "elasticloadbalancing:CreateLoadBalancer",
            "elasticloadbalancing:CreateTargetGroup"
          ]
          resources = ["*"]
        },
        {
          effect = "Allow"
          actions = [
            "elasticloadbalancing:CreateRule",
            "elasticloadbalancing:DeleteRule"
          ]
          resources = ["*"]
        },
        {
          effect = "Allow"
          actions = [
            "elasticloadbalancing:AddTags",
            "elasticloadbalancing:RemoveTags"
          ]
          resources = [
            "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
            "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
            "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
          ]
        },
        {
          effect = "Allow"
          actions = [
            "elasticloadbalancing:ModifyLoadBalancerAttributes",
            "elasticloadbalancing:SetIpAddressType",
            "elasticloadbalancing:SetSecurityGroups",
            "elasticloadbalancing:SetSubnets",
            "elasticloadbalancing:DeleteLoadBalancer",
            "elasticloadbalancing:ModifyTargetGroup",
            "elasticloadbalancing:ModifyTargetGroupAttributes",
            "elasticloadbalancing:DeleteTargetGroup"
          ]
          resources = ["*"]
        },
        {
          effect = "Allow"
          actions = [
            "elasticloadbalancing:RegisterTargets",
            "elasticloadbalancing:DeregisterTargets"
          ]
          resources = ["arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"]
        },
        {
          effect = "Allow"
          actions = [
            "elasticloadbalancing:SetWebAcl",
            "elasticloadbalancing:ModifyListener",
            "elasticloadbalancing:AddListenerCertificates",
            "elasticloadbalancing:RemoveListenerCertificates",
            "elasticloadbalancing:ModifyRule"
          ]
          resources = ["*"]
        }
      ]
    }

    # External DNS
    external_dns = {
      namespace                    = "kube-system"
      service_account_name        = "external-dns"
      role_policy_arns           = []
      inline_policy_statements   = [
        {
          effect = "Allow"
          actions = [
            "route53:ChangeResourceRecordSets",
            "route53:ListHostedZones",
            "route53:ListResourceRecordSets",
            "route53:ListHostedZonesByName"
          ]
          resources = ["*"]
        }
      ]
    }

    # Cluster Autoscaler
    cluster_autoscaler = {
      namespace                    = "kube-system"
      service_account_name        = "cluster-autoscaler"
      role_policy_arns           = []
      inline_policy_statements   = [
        {
          effect = "Allow"
          actions = [
            "autoscaling:DescribeAutoScalingGroups",
            "autoscaling:DescribeAutoScalingInstances",
            "autoscaling:DescribeLaunchConfigurations",
            "autoscaling:DescribeTags",
            "autoscaling:SetDesiredCapacity",
            "autoscaling:TerminateInstanceInAutoScalingGroup",
            "ec2:DescribeLaunchTemplateVersions"
          ]
          resources = ["*"]
        }
      ]
    }

    # External Secrets Operator
    external_secrets = {
      namespace                    = "external-secrets-system"
      service_account_name        = "external-secrets"
      role_policy_arns           = []
      inline_policy_statements   = [
        {
          effect = "Allow"
          actions = [
            "secretsmanager:GetSecretValue",
            "secretsmanager:DescribeSecret",
            "ssm:GetParameter",
            "ssm:GetParameters",
            "ssm:GetParametersByPath"
          ]
          resources = ["*"]
        }
      ]
    }
  }
}

# Create common IRSA roles
resource "aws_iam_role" "common_irsa_roles" {
  for_each = local.common_irsa_roles

  name = "${var.cluster_name}-${each.key}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = var.enable_irsa ? aws_iam_openid_connect_provider.eks_oidc_provider[0].arn : null
        }
        Condition = {
          StringEquals = {
            "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:${each.value.namespace}:${each.value.service_account_name}"
            "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-${each.key}"
      Type = "IRSA-Role"
      ServiceAccount = each.value.service_account_name
      Namespace = each.value.namespace
    }
  )
}

# Create inline policies for common IRSA roles
resource "aws_iam_policy" "common_irsa_policies" {
  for_each = local.common_irsa_roles

  name        = "${var.cluster_name}-${each.key}-policy"
  description = "Policy for ${each.key} service account"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      for statement in each.value.inline_policy_statements : {
        Effect   = statement.effect
        Action   = statement.actions
        Resource = statement.resources
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-${each.key}-policy"
      Type = "IRSA-Policy"
    }
  )
}

# Attach inline policies to common IRSA roles
resource "aws_iam_role_policy_attachment" "common_irsa_policy_attachments" {
  for_each = local.common_irsa_roles

  role       = aws_iam_role.common_irsa_roles[each.key].name
  policy_arn = aws_iam_policy.common_irsa_policies[each.key].arn
} 