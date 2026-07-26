output "gke_cluster_name" { value = module.gke.cluster_name }
output "gke_credentials_command" {
  value = "gcloud container clusters get-credentials ${module.gke.cluster_name} --region ${var.region} --project ${var.project_id}"
}
output "mammoth_service_account_annotation" {
  value = { "iam.gke.io/gcp-service-account" = module.workload_identity.service_account_email }
}
output "postgres" {
  value = {
    private_ip      = module.postgres.private_ip
    database        = module.postgres.database_name
    connection_name = module.postgres.connection_name
  }
}
output "application_secret_ids" { value = module.secrets.secret_ids }
output "object_storage_bucket" { value = module.storage.bucket_name }
