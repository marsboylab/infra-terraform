# DB parameter group
resource "aws_db_parameter_group" "this" {
  count = var.create_db_parameter_group ? 1 : 0
  
  name        = "${local.name_prefix}-db-parameter-group"
  description = "DB parameter group for ${local.name_prefix}"
  family      = local.effective_parameter_group_family
  
  dynamic "parameter" {
    for_each = local.effective_db_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }
  
  tags = local.db_parameter_group_tags
  
  lifecycle {
    create_before_destroy = true
  }
} 