variable "aws_region" {
  type    = string
  default = "ap-southeast-1"
}
variable "environment" {
  type    = string
  default = "dev"
}
variable "availability_zone" { type = string }
variable "vpc_cidr" {
  type    = string
  default = "10.70.0.0/24"
}
variable "private_subnet_cidr" {
  type    = string
  default = "10.70.0.0/26"
}
variable "ami_id" {
  description = "AMI produced by the sibling Golden K3s Packer factory."
  type        = string
  validation {
    condition     = can(regex("^ami-[0-9a-f]+$", var.ami_id))
    error_message = "ami_id must be a valid AMI ID."
  }
}
variable "instance_type" {
  type    = string
  default = "t3.small"
}
variable "root_volume_size_gib" {
  type    = number
  default = 8
}
variable "data_volume_size_gib" {
  type    = number
  default = 22
}
variable "data_volume_snapshot_id" {
  type    = string
  default = null
}
variable "data_device_name" {
  type    = string
  default = "/dev/sdf"
}
variable "data_mount_path" {
  type    = string
  default = "/srv/mammoth"
}
variable "deployment_prefix" {
  type    = string
  default = "charts"
}
variable "backup_prefix" {
  type    = string
  default = "backups"
}
variable "operator_principal_arns" {
  type    = set(string)
  default = []
}
variable "tags" {
  type    = map(string)
  default = {}
}
