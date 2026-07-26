packer {
  required_version = ">= 1.11.0"

  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1.8"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "ap-southeast-1"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ami_name_prefix" {
  type    = string
  default = "spherical-mammoth-golden"
}

variable "compose_version" {
  type    = string
  default = "v5.1.4"
}

variable "preload_images" {
  type = list(string)
  default = [
    "postgres:17",
    "oryd/kratos:v1.3.1",
    "axllent/mailpit:latest",
    "ghcr.io/kanutocd/mammoth:v1.5.3",
  ]
}

variable "ssh_cidr" {
  description = "CIDR allowed to SSH to the temporary Packer builder."
  type        = string
}

source "amazon-ebs" "golden_mammoth" {
  region                                = var.aws_region
  instance_type                         = var.instance_type
  ssh_username                          = "ec2-user"
  associate_public_ip_address           = true
  ssh_clear_authorized_keys             = true
  ssh_interface                         = "public_ip"
  temporary_security_group_source_cidrs = [var.ssh_cidr]

  ami_name = "${var.ami_name_prefix}-{{timestamp}}"

  source_ami_filter {
    filters = {
      name                = "al2023-ami-2023.*-kernel-6.1-x86_64"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["amazon"]
    most_recent = true
  }

  launch_block_device_mappings {
    device_name           = "/dev/xvda"
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true
    encrypted             = true
  }

  imds_support = "v2.0"

  run_tags = {
    Name      = "golden-mammoth-packer"
    ManagedBy = "packer"
  }

  tags = {
    Name         = "${var.ami_name_prefix}"
    Project      = "spherical-mammoth"
    ManagedBy    = "packer"
    Architecture = "poorman-aws"
    SourceAMI    = "{{ .SourceAMI }}"
  }
}

build {
  name    = "golden-mammoth"
  sources = ["source.amazon-ebs.golden_mammoth"]

  provisioner "shell" {
    script = "${path.root}/scripts/bake.sh"
    environment_vars = [
      "COMPOSE_VERSION=${var.compose_version}",
      "PRELOAD_IMAGES=${join(" ", var.preload_images)}",
    ]
  }

  provisioner "file" {
    source      = "${path.root}/files/activate-mammoth-release"
    destination = "/tmp/activate-mammoth-release"
  }

  provisioner "shell" {
    inline = [
      "sudo install -m 0755 /tmp/activate-mammoth-release /usr/local/bin/activate-mammoth-release",
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo cloud-init clean --logs --machine-id",
      "sudo rm -rf /root/.ssh /home/ec2-user/.ssh/authorized_keys",
    ]
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
    custom_data = {
      compose_version = var.compose_version
      source_ami      = "${build.SourceAMI}"
    }
  }
}
