variable "project_id" { type = string }
variable "name" { type = string }
variable "kubernetes_namespace" { type = string }
variable "kubernetes_service_account" { type = string }
variable "secret_ids" { type = list(string) }
variable "bucket_name" { type = string }
