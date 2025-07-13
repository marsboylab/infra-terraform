# Security group for RDS
resource "aws_security_group" "this" {
  count = var.create_security_group ? 1 : 0
  
  name        = "${local.name_prefix}-rds-sg"
  description = "Security group for ${local.name_prefix} RDS instance"
  vpc_id      = var.vpc_id
  
  tags = local.security_group_tags
}

# Ingress rule for database access from CIDR blocks
resource "aws_security_group_rule" "cidr_ingress" {
  count = var.create_security_group && length(var.allowed_cidr_blocks) > 0 ? 1 : 0
  
  type              = "ingress"
  from_port         = local.db_port
  to_port           = local.db_port
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = aws_security_group.this[0].id
  description       = "Database access from allowed CIDR blocks"
}

# Ingress rule for database access from security groups
resource "aws_security_group_rule" "sg_ingress" {
  count = var.create_security_group && length(var.allowed_security_group_ids) > 0 ? length(var.allowed_security_group_ids) : 0
  
  type                     = "ingress"
  from_port                = local.db_port
  to_port                  = local.db_port
  protocol                 = "tcp"
  source_security_group_id = var.allowed_security_group_ids[count.index]
  security_group_id        = aws_security_group.this[0].id
  description              = "Database access from security group ${var.allowed_security_group_ids[count.index]}"
}

# Egress rule (allow all outbound traffic)
resource "aws_security_group_rule" "egress" {
  count = var.create_security_group ? 1 : 0
  
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.this[0].id
  description       = "All outbound traffic"
} 