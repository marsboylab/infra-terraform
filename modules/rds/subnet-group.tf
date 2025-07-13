# DB subnet group
resource "aws_db_subnet_group" "this" {
  count = var.db_subnet_group_name == null ? 1 : 0
  
  name        = "${local.name_prefix}-db-subnet-group"
  description = "DB subnet group for ${local.name_prefix}"
  subnet_ids  = var.subnet_ids
  
  tags = local.db_subnet_group_tags
} 