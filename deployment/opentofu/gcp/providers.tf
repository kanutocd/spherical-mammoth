provider "google" {
  project = var.project_id
  region  = var.region

  default_labels = merge({
    project     = "spherical-mammoth"
    environment = var.environment
    managed_by  = "opentofu"
  }, var.labels)
}
