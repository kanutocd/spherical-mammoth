variable "project_id" { type = string }
variable "region" {
  type    = string
  default = "asia-southeast1"
}
variable "environment" {
  type    = string
  default = "dev"
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "environment must be dev, staging, or production."
  }
}
variable "network_cidr" {
  type    = string
  default = "10.50.0.0/20"
}
variable "pods_cidr" {
  type    = string
  default = "10.52.0.0/14"
}
variable "services_cidr" {
  type    = string
  default = "10.56.0.0/20"
}
variable "master_ipv4_cidr" {
  type    = string
  default = "172.16.0.0/28"
}
variable "master_authorized_networks" {
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}
variable "gke_deletion_protection" {
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
variable "postgres_tier" {
  type    = string
  default = "db-custom-1-3840"
}
variable "postgres_availability_type" {
  type    = string
  default = "ZONAL"
}
variable "postgres_deletion_protection" {
  type    = bool
  default = false
}
variable "mammoth_namespace" {
  type    = string
  default = "mammoth"
}
variable "mammoth_service_account" {
  type    = string
  default = "mammoth"
}
variable "labels" {
  type    = map(string)
  default = {}
}
