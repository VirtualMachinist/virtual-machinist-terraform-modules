# GKE Autopilot Cluster
resource "google_container_cluster" "autopilot" {
  project  = var.project_id
  name     = var.cluster_name
  location = var.region

  # Autopilot mode - Google manages nodes
  enable_autopilot = true

  # Network configuration
  network    = var.network
  subnetwork = var.subnetwork

  # Private cluster configuration
  private_cluster_config {
    enable_private_nodes    = var.enable_private_nodes
    enable_private_endpoint = false  # Allow public access to control plane
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  # IP allocation policy (required for VPC-native clusters)
  ip_allocation_policy {
    # Let GKE auto-allocate secondary ranges
  }

  # Release channel for auto-upgrades
  release_channel {
    channel = "REGULAR"
  }

  # Deletion protection
  deletion_protection = var.deletion_protection
}