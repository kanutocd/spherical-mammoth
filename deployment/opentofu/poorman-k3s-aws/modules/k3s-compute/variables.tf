variable "name" { type = string }
variable "ami_id" { type = string }
variable "instance_type" { type = string }
variable "subnet_id" { type = string }
variable "security_group_id" { type = string }
variable "deployment_bucket_arn" { type = string }
variable "deployment_prefix" { type = string }
variable "backup_prefix" { type = string }
variable "root_volume_size_gib" { type = number }
variable "data_volume_id" { type = string }
variable "data_device_name" { type = string }
variable "data_mount_path" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}
