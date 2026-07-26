variable "project_id" { type = string }
variable "region" { type = string }
variable "name" { type = string }
variable "force_destroy" {
  type    = bool
  default = false
}
variable "labels" {
  type    = map(string)
  default = {}
}
