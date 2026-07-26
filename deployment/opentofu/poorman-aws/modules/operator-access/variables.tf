variable "name" { type = string }
variable "eice_arn" { type = string }
variable "autoscaling_group_name" { type = string }
variable "deployment_bucket_arn" { type = string }
variable "deployment_prefix" { type = string }
variable "allowed_tunnel_ports" {
  type    = set(number)
  default = [22]
}
variable "operator_principal_arns" {
  type    = set(string)
  default = []

  validation {
    condition     = alltrue([for arn in var.operator_principal_arns : can(regex(":role/.+$", arn))])
    error_message = "operator_principal_arns currently supports IAM role ARNs only."
  }
}
variable "tags" {
  type    = map(string)
  default = {}
}
