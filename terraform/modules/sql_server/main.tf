
resource "random_password" "sql_password" {
  length  = 16
  special = true
}

resource "google_sql_database_instance" "sql_server_instance" {
  project            = var.project_id
  name               = "sql-server-instance"
  region             = var.region
  database_version   = "SQLSERVER_2019_ENTERPRISE"
  root_password      = random_password.sql_password.result
  deletion_protection = false

  settings {
    tier = "db-custom-2-8192"
    ip_configuration {
      ipv4_enabled    = false
      private_network = var.network_id
      require_ssl     = true
      ssl_mode        = "ENCRYPTED_ONLY"
      server_ca_mode  = "GOOGLE_MANAGED_CAS_CA"
    }
  }

  depends_on = [var.private_vpc_connection_id]
}
