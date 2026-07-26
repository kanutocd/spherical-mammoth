variable "name" { type = string }
variable "oidc_provider_arn" { type = string }
variable "oidc_issuer_url" { type = string }
variable "kubernetes_namespace" { type = string }
variable "kubernetes_service_account" { type = string }
variable "secret_arns" { type = list(string) }
variable "kms_key_arns" { type = list(string) }
variable "bucket_arn" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}
