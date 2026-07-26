resource "aws_iam_role" "instance" {
  name = "${var.name}-instance"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "instance" {
  name = "charts-and-backups"
  role = aws_iam_role.instance.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetBucketLocation", "s3:ListBucket"]
        Resource = var.deployment_bucket_arn
        Condition = {
          StringLike = {
            "s3:prefix" = [
              var.deployment_prefix,
              "${var.deployment_prefix}/*",
              var.backup_prefix,
              "${var.backup_prefix}/*",
            ]
          }
        }
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:GetObjectVersion"]
        Resource = "${var.deployment_bucket_arn}/${var.deployment_prefix}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:AbortMultipartUpload", "s3:GetObject", "s3:ListMultipartUploadParts", "s3:PutObject"]
        Resource = "${var.deployment_bucket_arn}/${var.backup_prefix}/*"
      },
    ]
  })
}

resource "aws_iam_instance_profile" "this" {
  name = var.name
  role = aws_iam_role.instance.name
  tags = var.tags
}

resource "aws_launch_template" "this" {
  name_prefix   = "${var.name}-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  user_data = base64encode(templatefile("${path.module}/user-data.sh.tftpl", {
    data_device_name = var.data_device_name
    data_device_path = "/dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_${replace(var.data_volume_id, "-", "")}"
    data_mount_path  = var.data_mount_path
  }))

  iam_instance_profile {
    arn = aws_iam_instance_profile.this.arn
  }

  network_interfaces {
    associate_public_ip_address = false
    delete_on_termination       = true
    device_index                = 0
    security_groups             = [var.security_group_id]
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_protocol_ipv6          = "disabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "required"
    instance_metadata_tags      = "enabled"
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      delete_on_termination = true
      encrypted             = true
      volume_size           = var.root_volume_size_gib
      volume_type           = "gp3"
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = var.name
      Role = "golden-mammoth-k3s"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(var.tags, {
      Name        = "${var.name}-root"
      Persistence = "disposable"
    })
  }

  tags = var.tags
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "this" {
  name                      = var.name
  min_size                  = 1
  max_size                  = 1
  desired_capacity          = 1
  vpc_zone_identifier       = [var.subnet_id]
  health_check_type         = "EC2"
  health_check_grace_period = 420
  default_instance_warmup   = 420

  initial_lifecycle_hook {
    name                 = "attach-persistent-volume"
    default_result       = "ABANDON"
    heartbeat_timeout    = 900
    lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
  }

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = merge(var.tags, {
      Name = var.name
      Role = "golden-mammoth-k3s"
    })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 0
      instance_warmup        = 420
    }
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}
