locals {
  name = "spherical-mammoth-${var.environment}"
  required_services = toset([
    "artifactregistry.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "iamcredentials.googleapis.com",
    "secretmanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
  ])
}

resource "google_project_service" "required" {
  for_each = local.required_services

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

module "networking" {
  source = "./modules/networking"

  project_id    = var.project_id
  region        = var.region
  name          = local.name
  network_cidr  = var.network_cidr
  pods_cidr     = var.pods_cidr
  services_cidr = var.services_cidr

  depends_on = [google_project_service.required]
}

module "secrets" {
  source = "./modules/secrets"

  project_id = var.project_id
  name       = local.name
  secrets = {
    "postgres-admin"       = "Cloud SQL administrator bootstrap credentials."
    "postgres-replication" = "Mammoth logical replication credentials."
    "webhook-signing"      = "Webhook signing material."
  }

  depends_on = [google_project_service.required]
}

module "storage" {
  source = "./modules/storage"

  project_id = var.project_id
  region     = var.region
  name       = local.name
  labels     = var.labels

  depends_on = [google_project_service.required]
}

module "gke" {
  source = "./modules/gke"

  project_id                 = var.project_id
  region                     = var.region
  name                       = local.name
  network_self_link          = module.networking.network_self_link
  subnetwork_self_link       = module.networking.subnetwork_self_link
  pods_range_name            = module.networking.pods_range_name
  services_range_name        = module.networking.services_range_name
  master_ipv4_cidr           = var.master_ipv4_cidr
  master_authorized_networks = var.master_authorized_networks
  deletion_protection        = var.gke_deletion_protection
  node_machine_type          = var.node_machine_type
  node_spot                  = var.node_spot
  node_min_count             = var.node_min_count
  node_max_count             = var.node_max_count
}

module "postgres" {
  source = "./modules/postgres"

  project_id          = var.project_id
  region              = var.region
  name                = local.name
  network_self_link   = module.networking.network_self_link
  tier                = var.postgres_tier
  availability_type   = var.postgres_availability_type
  deletion_protection = var.postgres_deletion_protection

  depends_on = [module.networking]
}

module "workload_identity" {
  source = "./modules/workload-identity"

  project_id                 = var.project_id
  name                       = local.name
  kubernetes_namespace       = var.mammoth_namespace
  kubernetes_service_account = var.mammoth_service_account
  secret_ids                 = values(module.secrets.secret_ids)
  bucket_name                = module.storage.bucket_name
}
