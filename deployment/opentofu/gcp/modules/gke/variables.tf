variable "project_id" { type = string }
variable "region" { type = string }
variable "name" { type = string }
variable "network_self_link" { type = string }
variable "subnetwork_self_link" { type = string }
variable "pods_range_name" { type = string }
variable "services_range_name" { type = string }
variable "master_ipv4_cidr" { type = string }
variable "master_authorized_networks" {
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}
variable "deletion_protection" {
  type    = bool
  default = false
}
variable "node_machine_type" {
  type    = string
  default = "e2-standard-2"
}
variable "node_spot" {
  type    = bool
  default = true
}
variable "node_min_count" {
  type    = number
  default = 1
}
variable "node_max_count" {
  type    = number
  default = 4
}
