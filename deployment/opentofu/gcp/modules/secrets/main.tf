resource "google_secret_manager_secret" "this" {
  for_each = var.secrets

  project   = var.project_id
  secret_id = "${var.name}-${each.key}"

  replication {
    auto {}
  }
}
