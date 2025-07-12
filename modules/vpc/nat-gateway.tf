# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway && !var.reuse_nat_ips ? local.nat_gateway_count : 0

  domain = "vpc"

  tags = merge(
    local.nat_eip_tags,
    {
      Name = "${local.vpc_name}-nat-eip-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# NAT Gateways
resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? local.nat_gateway_count : 0

  allocation_id = var.reuse_nat_ips ? var.external_nat_ip_ids[count.index] : aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[var.single_nat_gateway ? 0 : count.index].id

  tags = merge(
    local.nat_gateway_tags,
    {
      Name = "${local.vpc_name}-nat-gw-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# NAT Instance (alternative to NAT Gateway for cost optimization)
resource "aws_instance" "nat" {
  count = var.enable_nat_gateway ? 0 : local.nat_gateway_count

  ami                         = data.aws_ami.nat.id
  instance_type               = "t3.micro"
  key_name                    = var.environment == "prod" ? null : "${local.vpc_name}-nat-key"
  subnet_id                   = aws_subnet.public[var.single_nat_gateway ? 0 : count.index].id
  vpc_security_group_ids      = [aws_security_group.nat[0].id]
  associate_public_ip_address = true
  source_dest_check           = false

  user_data = base64encode(templatefile("${path.module}/nat-instance-user-data.sh", {}))

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-nat-instance-${count.index + 1}"
      Type = "NAT Instance"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group for NAT Instance
resource "aws_security_group" "nat" {
  count = var.enable_nat_gateway ? 0 : 1

  name_prefix = "${local.vpc_name}-nat-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr_block]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr_block]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.vpc_name}-nat-sg"
      Type = "NAT Instance Security Group"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Data source for NAT Instance AMI
data "aws_ami" "nat" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-vpc-nat-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Elastic IP for NAT Instance
resource "aws_eip" "nat_instance" {
  count = var.enable_nat_gateway ? 0 : local.nat_gateway_count

  instance = aws_instance.nat[count.index].id
  domain   = "vpc"

  tags = merge(
    local.nat_eip_tags,
    {
      Name = "${local.vpc_name}-nat-instance-eip-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.main]
} 