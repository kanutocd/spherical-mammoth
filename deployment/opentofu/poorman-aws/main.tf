locals {
  name = "spherical-mammoth-${var.environment}-poorman"
  tags = merge({
    Project     = "spherical-mammoth"
    Environment = var.environment
    ManagedBy   = "opentofu"
    CostModel   = "poorman"
  }, var.tags)
}

module "networking" {
  source = "./modules/networking"

  name                = local.name
  availability_zone   = var.availability_zone
  vpc_cidr            = var.vpc_cidr
  private_subnet_cidr = var.private_subnet_cidr
  tags                = local.tags
}

module "storage" {
  source = "./modules/storage"

  name                    = local.name
  availability_zone       = var.availability_zone
  data_volume_size_gib    = var.data_volume_size_gib
  data_volume_snapshot_id = var.data_volume_snapshot_id
  tags                    = local.tags
}

module "compute" {
  source = "./modules/compute"

  name                      = local.name
  ami_id                    = var.ami_id
  instance_type             = var.instance_type
  subnet_id                 = module.networking.private_subnet_id
  security_group_id         = module.networking.instance_security_group_id
  deployment_bucket_arn     = module.storage.bucket_arn
  deployment_prefix         = var.deployment_prefix
  backup_prefix             = var.backup_prefix
  root_volume_size_gib      = var.root_volume_size_gib
  data_volume_id            = module.storage.data_volume_id
  data_device_name          = var.data_device_name
  data_mount_path           = var.data_mount_path
  health_check_grace_period = var.asg_health_check_grace_period
  tags                      = local.tags

  depends_on = [module.volume_attachment]
}

module "volume_attachment" {
  source = "./modules/volume-attachment"

  name                   = local.name
  autoscaling_group_name = local.name
  data_volume_arn        = module.storage.data_volume_arn
  data_volume_id         = module.storage.data_volume_id
  data_device_name       = var.data_device_name
  tags                   = local.tags
}

module "operator_access" {
  source = "./modules/operator-access"

  name                    = local.name
  eice_arn                = module.networking.eice_arn
  autoscaling_group_name  = module.compute.autoscaling_group_name
  deployment_bucket_arn   = module.storage.bucket_arn
  deployment_prefix       = var.deployment_prefix
  operator_principal_arns = var.operator_principal_arns
  tags                    = local.tags
}
