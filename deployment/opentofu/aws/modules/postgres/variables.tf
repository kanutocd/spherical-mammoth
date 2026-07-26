variable "name" { type = string }
variable "vpc_id" { type = string }
variable "vpc_cidr" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "postgres_version" {
  type    = string
  default = "17"
}
variable "database_name" {
  type    = string
  default = "mammoth"
}
variable "master_username" {
  type    = string
  default = "mammoth_admin"
}
variable "instance_class" {
  type    = string
  default = "db.t4g.micro"
}
variable "allocated_storage" {
  type    = number
  default = 20
}
variable "max_allocated_storage" {
  type    = number
  default = 100
}
variable "multi_az" {
  type    = bool
  default = false
}
variable "deletion_protection" {
  type    = bool
  default = false
}
variable "skip_final_snapshot" {
  type    = bool
  default = true
}
variable "backup_retention_days" {
  type    = number
  default = 7
}
variable "performance_insights" {
  type    = bool
  default = false
}
variable "enhanced_monitoring" {
  type    = bool
  default = false
}
variable "tags" {
  type    = map(string)
  default = {}
}
