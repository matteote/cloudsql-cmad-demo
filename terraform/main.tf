terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.1"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.1"
    }
  }
}

provider "google" {
  project = var.project_id
}

provider "google-beta" {
  project = var.project_id
}

resource "google_project_service" "compute" {
  project = var.project_id
  service = "compute.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "sqladmin" {
  project = var.project_id
  service = "sqladmin.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "secretmanager" {
  project = var.project_id
  service = "secretmanager.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "servicenetworking" {
  project = var.project_id
  service = "servicenetworking.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service_identity" "sqladmin_service_identity" {
  provider = google-beta
  project  = var.project_id
  service  = "sqladmin.googleapis.com"

  depends_on = [google_project_service.sqladmin]
}

resource "google_secret_manager_secret_iam_member" "sqladmin_service_identity_secret_admin" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.windows_credentials.id
  role      = "roles/secretmanager.admin"
  member    = "serviceAccount:${google_project_service_identity.sqladmin_service_identity.email}"
}

resource "google_compute_global_address" "private_ip_address" {
  project       = var.project_id
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = module.network.network_id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = module.network.network_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]

  depends_on = [google_project_service.servicenetworking]
}

resource "google_secret_manager_secret" "windows_credentials" {
  project   = var.project_id
  secret_id = "windows-credentials"

  replication {
    auto {}
  }
  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "windows_credentials" {
  secret = google_secret_manager_secret.windows_credentials.id
  secret_data = jsonencode({
    credentials = [
      {
        administratorLogin    = "setupadmin",
        administratorPassword = module.windows_vm.setupadmin_password
      }
    ]
  })

  depends_on = [module.windows_vm]
}

module "network" {
  source                 = "./modules/network"
  project_id             = var.project_id
  region                 = substr(var.zone, 0, length(var.zone) - 2)
  compute_api_service_id = google_project_service.compute
}

module "windows_vm" {
  source       = "./modules/windows_vm"
  project_id   = var.project_id
  zone         = var.zone
  network_name = module.network.network_name
  subnet_name  = module.network.subnet_name
}

module "sql_server" {
  source                    = "./modules/sql_server"
  project_id                = var.project_id
  region                    = substr(var.zone, 0, length(var.zone) - 2)
  network_id                = module.network.network_id
  private_vpc_connection_id = google_service_networking_connection.private_vpc_connection.id
}

module "windows_client_vm" {
  source                = "./modules/windows_client_vm"
  project_id            = var.project_id
  zone                  = var.zone
  network_name          = module.network.network_name
  subnet_name           = module.network.subnet_name
  admin_password        = module.windows_vm.admin_password
  windows_vm_ip_address = module.windows_vm.ip_address
}

output "admin_password" {
  description = "The password for the admin user."
  value       = module.windows_vm.admin_password
  sensitive   = true
}

output "setupadmin_password" {
  description = "The password for the setupadmin user."
  value       = module.windows_vm.setupadmin_password
  sensitive   = true
}

output "instance_name" {
  description = "The name of the Windows VM."
  value       = module.windows_vm.instance_name
}

output "client_instance_name" {
  description = "The name of the Windows client VM."
  value       = module.windows_client_vm.instance_name
}

output "sql_server_password" {
  description = "The password for the SQL Server instance."
  value       = module.sql_server.sql_server_password
  sensitive   = true
}

output "sql_server_instance_name" {
  description = "The name of the SQL Server instance."
  value       = module.sql_server.sql_server_instance_name
}

output "sql_server_ip_address" {
  description = "The private IP address of the SQL Server instance."
  value       = module.sql_server.sql_server_ip_address
}

output "zone" {
  description = "The zone of the Windows VM."
  value       = module.windows_vm.zone
}

output "project_id" {
  description = "The project ID."
  value       = var.project_id
}

output "ip_address" {
  description = "The IP address of the Windows VM."
  value       = module.windows_vm.ip_address
}