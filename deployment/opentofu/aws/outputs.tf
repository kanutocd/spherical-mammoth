output "region" {
  value = var.aws_region
}

output "vpc_id" {
  value = module.networking.vpc_id
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_kubeconfig_command" {
  value = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "mammoth_service_account_annotation" {
  value = { "eks.amazonaws.com/role-arn" = module.workload_identity.role_arn }
}

output "postgres" {
  value = {
    address           = module.postgres.address
    port              = module.postgres.port
    database          = module.postgres.database_name
    master_secret_arn = module.postgres.master_user_secret_arn
  }
}

output "application_secret_arns" {
  value = module.secrets.secret_arns
}

output "object_storage_bucket" {
  value = module.storage.bucket_name
}
