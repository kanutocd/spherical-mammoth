variable "project_id" { type = string }
variable "region" { type = string }
variable "name" { type = string }
variable "network_self_link" { type = string }
variable "tier" { type = string }
variable "availability_type" { type = string }
variable "deletion_protection" { type = bool }
variable "database_name" {
  type    = string
  default = "mammoth"
}
