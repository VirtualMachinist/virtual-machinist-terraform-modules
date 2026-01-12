# VPC Network
resource "google_compute_network" "vpc" {
  project                 = var.project_id
  name                    = var.vpc_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

# Public Subnet (for bastion, NAT, load balancers)
resource "google_compute_subnetwork" "public" {
  project       = var.project_id
  name          = "${var.vpc_name}-public"
  ip_cidr_range = var.public_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
}

# Private Subnet (for VMs, GKE, databases)
resource "google_compute_subnetwork" "private" {
  project                  = var.project_id
  name                     = "${var.vpc_name}-private"
  ip_cidr_range            = var.private_cidr
  region                   = var.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true
}

# Firewall: Allow IAP for SSH (secure access without public IP)
resource "google_compute_firewall" "allow_iap_ssh" {
  project = var.project_id
  name    = "${var.vpc_name}-allow-iap-ssh"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]  # IAP's IP range
  target_tags   = ["allow-iap-ssh"]
}

# Firewall: Allow internal traffic within VPC
resource "google_compute_firewall" "allow_internal" {
  project = var.project_id
  name    = "${var.vpc_name}-allow-internal"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.public_cidr, var.private_cidr]
}