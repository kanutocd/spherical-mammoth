resource "google_sql_database_instance" "this" {
  project             = var.project_id
  region              = var.region
  name                = var.name
  database_version    = "POSTGRES_17"
  deletion_protection = var.deletion_protection

  settings {
    tier              = var.tier
    availability_type = var.availability_type
    disk_type         = "PD_SSD"
    disk_size         = 20
    disk_autoresize   = true
    edition           = "ENTERPRISE"

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = var.network_self_link
      enable_private_path_for_google_cloud_services = true
      ssl_mode                                      = "ENCRYPTED_ONLY"
    }

    backup_configuration {
      enabled                        = true
      start_time                     = "18:00"
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
      backup_retention_settings {
        retained_backups = 14
        retention_unit   = "COUNT"
      }
    }

    database_flags {
      name  = "cloudsql.logical_decoding"
      value = "on"
    }
    database_flags {
      name  = "max_replication_slots"
      value = "10"
    }
    database_flags {
      name  = "max_wal_senders"
      value = "10"
    }

    insights_config {
      query_insights_enabled  = true
      query_plans_per_minute  = 5
      query_string_length     = 1024
      record_application_tags = true
    }

    maintenance_window {
      day          = 7
      hour         = 19
      update_track = "stable"
    }
  }
}

resource "google_sql_database" "mammoth" {
  project  = var.project_id
  instance = google_sql_database_instance.this.name
  name     = var.database_name
}
