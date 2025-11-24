resource "google_compute_network" "vpc_network" {
  name                    = "windows-vm-network"
  project                 = var.project_id
  auto_create_subnetworks = false

  depends_on = [
    var.compute_api_service_id
  ]
}

resource "google_compute_subnetwork" "subnet" {
  name          = "windows-vm-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id
  project       = var.project_id
}

resource "google_compute_firewall" "allow_rdp" {
  name    = "allow-rdp"
  network = google_compute_network.vpc_network.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["windows-vm"]
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc_network.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["windows-vm"]
}


resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal"
  network = google_compute_network.vpc_network.name
  project = var.project_id

  allow {
    protocol = "all"
  }

  source_ranges = ["10.0.0.0/8"]
}

resource "google_compute_router" "router" {
  name    = "nat-router"
  network = google_compute_network.vpc_network.id
  region  = google_compute_subnetwork.subnet.region
  project = var.project_id
}

resource "google_compute_router_nat" "nat" {
  name                               = "nat-gateway"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  project                            = var.project_id
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  nat_ip_allocate_option             = "AUTO_ONLY"
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
