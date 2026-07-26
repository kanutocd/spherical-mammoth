locals {
  name = "spherical-mammoth-${var.environment}"

  common_tags = merge({
    Project     = "spherical-mammoth"
    Environment = var.environment
    ManagedBy   = "opentofu"
  }, var.tags)
}

module "networking" {
  source = "./modules/networking"

  name               = local.name
  vpc_cidr           = var.vpc_cidr
  az_count           = var.az_count
  single_nat_gateway = var.single_nat_gateway
  tags               = local.common_tags
}

module "secrets" {
  source = "./modules/secrets"

  name = local.name
  secrets = {
    "postgres-replication" = "Credentials for Mammoth's least-privilege PostgreSQL replication role."
    "webhook-signing"      = "Signing material used by the delivery and webhook boundary."
  }
  tags = local.common_tags
}

module "storage" {
  source = "./modules/storage"

  name = local.name
  tags = local.common_tags
}

module "eks" {
  source = "./modules/eks"

  name                         = local.name
  kubernetes_version           = var.kubernetes_version
  private_subnet_ids           = module.networking.private_subnet_ids
  cluster_public_access        = var.cluster_public_access
  cluster_public_access_cidrs  = var.cluster_public_access_cidrs
  node_instance_types          = var.node_instance_types
  node_capacity_type           = var.node_capacity_type
  node_min_size                = var.node_min_size
  node_desired_size            = var.node_desired_size
  node_max_size                = var.node_max_size
  cluster_admin_principal_arns = var.cluster_admin_principal_arns
  tags                         = local.common_tags
}

module "postgres" {
  source = "./modules/postgres"

  name                  = local.name
  vpc_id                = module.networking.vpc_id
  vpc_cidr              = module.networking.vpc_cidr
  private_subnet_ids    = module.networking.private_subnet_ids
  postgres_version      = var.postgres_version
  instance_class        = var.postgres_instance_class
  multi_az              = var.postgres_multi_az
  deletion_protection   = var.postgres_deletion_protection
  skip_final_snapshot   = var.postgres_skip_final_snapshot
  backup_retention_days = var.postgres_backup_retention_days
  performance_insights  = var.environment != "dev"
  enhanced_monitoring   = var.environment != "dev"
  tags                  = local.common_tags
}

module "workload_identity" {
  source = "./modules/workload-identity"

  name                       = local.name
  oidc_provider_arn          = module.eks.oidc_provider_arn
  oidc_issuer_url            = module.eks.oidc_issuer_url
  kubernetes_namespace       = var.mammoth_namespace
  kubernetes_service_account = var.mammoth_service_account
  secret_arns = concat(
    values(module.secrets.secret_arns),
    [module.postgres.master_user_secret_arn],
  )
  kms_key_arns = [
    module.secrets.kms_key_arn,
    module.postgres.kms_key_arn,
    module.storage.kms_key_arn,
  ]
  bucket_arn = module.storage.bucket_arn
  tags       = local.common_tags
}
