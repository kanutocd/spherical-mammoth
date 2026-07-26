variable "name" { type = string }
variable "kubernetes_version" {
  type    = string
  default = null
}
variable "private_subnet_ids" { type = list(string) }
variable "cluster_public_access" {
  type    = bool
  default = true
}
variable "cluster_public_access_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}
variable "node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}
variable "node_capacity_type" {
  type    = string
  default = "ON_DEMAND"
}
variable "node_min_size" {
  type    = number
  default = 1
}
variable "node_desired_size" {
  type    = number
  default = 2
}
variable "node_max_size" {
  type    = number
  default = 4
}
variable "cluster_admin_principal_arns" {
  type    = set(string)
  default = []
}
variable "log_retention_days" {
  type    = number
  default = 30
}
variable "tags" {
  type    = map(string)
  default = {}
}
