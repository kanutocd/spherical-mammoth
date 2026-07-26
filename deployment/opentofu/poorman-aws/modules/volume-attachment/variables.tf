variable "name" { type = string }
variable "autoscaling_group_name" { type = string }
variable "data_volume_arn" { type = string }
variable "data_volume_id" { type = string }
variable "data_device_name" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}
