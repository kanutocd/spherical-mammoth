variable "name" { type = string }
variable "availability_zone" { type = string }
variable "data_volume_size_gib" { type = number }
variable "data_volume_snapshot_id" {
  type    = string
  default = null
}
variable "force_destroy_bucket" {
  type    = bool
  default = false
}
variable "tags" {
  type    = map(string)
  default = {}
}
