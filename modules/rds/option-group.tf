# DB option group
resource "aws_db_option_group" "this" {
  count = var.create_db_option_group ? 1 : 0
  
  name                     = "${local.name_prefix}-db-option-group"
  option_group_description = "DB option group for ${local.name_prefix}"
  engine_name              = var.engine
  major_engine_version     = local.effective_major_engine_version
  
  dynamic "option" {
    for_each = var.db_options
    content {
      option_name = option.value.option_name
      
      dynamic "option_settings" {
        for_each = option.value.option_settings != null ? option.value.option_settings : []
        content {
          name  = option_settings.value.name
          value = option_settings.value.value
        }
      }
      
      db_security_group_memberships  = option.value.db_security_group_memberships
      vpc_security_group_memberships = option.value.vpc_security_group_memberships
    }
  }
  
  tags = local.db_option_group_tags
  
  lifecycle {
    create_before_destroy = true
  }
} 