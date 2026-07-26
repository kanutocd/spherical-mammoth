resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.tags, { Name = var.name })
}

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.this.id
  availability_zone       = var.availability_zone
  cidr_block              = var.private_subnet_cidr
  map_public_ip_on_launch = false
  tags                    = merge(var.tags, { Name = "${var.name}-private" })
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-sealed" })
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]
  tags              = merge(var.tags, { Name = "${var.name}-s3" })
}

resource "aws_security_group" "eice" {
  name_prefix = "${var.name}-eice-"
  description = "Egress from EC2 Instance Connect Endpoint"
  vpc_id      = aws_vpc.this.id
  tags        = merge(var.tags, { Name = "${var.name}-eice" })

  dynamic "egress" {
    for_each = var.instance_ingress_ports
    content {
      description = "Private tunnel to port ${egress.value}"
      protocol    = "tcp"
      from_port   = egress.value
      to_port     = egress.value
      cidr_blocks = [var.private_subnet_cidr]
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "instance" {
  name_prefix = "${var.name}-instance-"
  description = "Golden Mammoth instance"
  vpc_id      = aws_vpc.this.id
  tags        = merge(var.tags, { Name = "${var.name}-instance" })

  dynamic "ingress" {
    for_each = var.instance_ingress_ports
    content {
      description     = "Port ${ingress.value} only through EICE"
      protocol        = "tcp"
      from_port       = ingress.value
      to_port         = ingress.value
      security_groups = [aws_security_group.eice.id]
    }
  }

  egress {
    description = "HTTPS through allowed VPC endpoints"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ec2_instance_connect_endpoint" "this" {
  subnet_id          = aws_subnet.private.id
  security_group_ids = [aws_security_group.eice.id]
  preserve_client_ip = false
  tags               = merge(var.tags, { Name = var.name })
}

data "aws_region" "current" {}
