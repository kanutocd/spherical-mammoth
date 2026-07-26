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
  default = "spherical-mammoth-golden-k3s"
}
variable "k3s_version" {
  type    = string
  default = "v1.36.1+k3s1"
}
variable "helm_version" {
  type    = string
  default = "v4.1.4"
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

source "amazon-ebs" "golden_k3s" {
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
    Name      = "golden-k3s-packer"
    ManagedBy = "packer"
  }

  tags = {
    Name         = var.ami_name_prefix
    Project      = "spherical-mammoth"
    ManagedBy    = "packer"
    Architecture = "poorman-k3s-aws"
    K3sVersion   = var.k3s_version
    SourceAMI    = "{{ .SourceAMI }}"
  }
}

build {
  name    = "golden-k3s"
  sources = ["source.amazon-ebs.golden_k3s"]

  provisioner "shell" {
    script = "${path.root}/scripts/bake.sh"
    environment_vars = [
      "HELM_VERSION=${var.helm_version}",
      "K3S_VERSION=${var.k3s_version}",
      "PRELOAD_IMAGES=${join(" ", var.preload_images)}",
    ]
  }

  provisioner "file" {
    source      = "${path.root}/files/deploy-k3s-chart"
    destination = "/tmp/deploy-k3s-chart"
  }

  provisioner "shell" {
    inline = [
      "sudo install -m 0755 /tmp/deploy-k3s-chart /usr/local/bin/deploy-k3s-chart",
      "sudo cloud-init clean --logs --machine-id",
      "sudo rm -rf /root/.ssh /home/ec2-user/.ssh/authorized_keys",
    ]
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
    custom_data = {
      helm_version = var.helm_version
      k3s_version  = var.k3s_version
      source_ami   = "${build.SourceAMI}"
    }
  }
}
