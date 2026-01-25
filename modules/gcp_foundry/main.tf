# =============================================================================
# GCP FOUNDRY - Development & Testing Environment
# Full Stack Virtual Machinist
# 
# CERT ALIGNMENT:
# - GCP Cloud Professional: VPC, IAM, networking, private Google access
# - GCP DevOps Professional: Cloud Build, Artifact Registry, Cloud Deploy
# - GCP ML Professional: Vertex AI Workbench, model serving foundations
# - CKA/CKAD/CKS: GKE Autopilot, workloads, RBAC, network policies
# - Terraform Associate: Module composition, for_each, dynamic blocks
# =============================================================================

locals {
  environment = "foundry"
  labels = merge(var.labels, {
    environment = local.environment
    managed_by  = "terraform"
    project     = "virtual-machinist"
  })
}

# -----------------------------------------------------------------------------
# NETWORKING (GCP Cloud Pro: VPC design, private subnets, Cloud NAT)
# -----------------------------------------------------------------------------

resource "google_compute_network" "vpc" {
  project                 = var.project_id
  name                    = "${var.environment_name}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"  # Required for multi-region GKE
}

# GKE Subnet with secondary ranges for pods/services
resource "google_compute_subnetwork" "gke" {
  project       = var.project_id
  name          = "${var.environment_name}-gke"
  ip_cidr_range = var.gke_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id

  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_cidr
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_cidr
  }

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Workloads subnet (VMs, Vertex AI)
resource "google_compute_subnetwork" "workloads" {
  project                  = var.project_id
  name                     = "${var.environment_name}-workloads"
  ip_cidr_range            = var.workloads_cidr
  region                   = var.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true
}

# Cloud Router for NAT
resource "google_compute_router" "router" {
  project = var.project_id
  name    = "${var.environment_name}-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

# Cloud NAT for egress (GCP Cloud Pro: NAT configuration)
resource "google_compute_router_nat" "nat" {
  project                            = var.project_id
  name                               = "${var.environment_name}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# -----------------------------------------------------------------------------
# FIREWALL RULES (GCP Cloud Pro: Security, IAP)
# -----------------------------------------------------------------------------

resource "google_compute_firewall" "allow_iap_ssh" {
  project = var.project_id
  name    = "${var.environment_name}-allow-iap-ssh"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["allow-iap-ssh"]
}

resource "google_compute_firewall" "allow_internal" {
  project = var.project_id
  name    = "${var.environment_name}-allow-internal"
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

  source_ranges = [
    var.gke_subnet_cidr,
    var.workloads_cidr,
    var.pods_cidr,
    var.services_cidr
  ]
}

# -----------------------------------------------------------------------------
# GKE AUTOPILOT (CKA/CKAD/CKS: Cluster management, RBAC, network policies)
# -----------------------------------------------------------------------------

resource "google_container_cluster" "autopilot" {
  project  = var.project_id
  name     = "${var.environment_name}-cluster"
  location = var.region

  # Autopilot mode - Google manages nodes
  enable_autopilot = true

  network    = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.gke.id

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Private cluster (CKS: Security best practices)
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false  # Allow kubectl from authorized networks
    master_ipv4_cidr_block  = var.master_cidr
  }

  # Authorized networks for API access
  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.authorized_networks
      content {
        cidr_block   = cidr_blocks.value.cidr
        display_name = cidr_blocks.value.name
      }
    }
  }

  # Workload Identity (CKS: Secure pod authentication)
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Logging and monitoring
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]
    managed_prometheus {
      enabled = true
    }
  }

  # Binary Authorization (CKS: Supply chain security)
  binary_authorization {
    evaluation_mode = var.enable_binary_auth ? "PROJECT_SINGLETON_POLICY_ENFORCE" : "DISABLED"
  }

  release_channel {
    channel = "REGULAR"
  }

  resource_labels = local.labels

  # Deletion protection for production
  deletion_protection = var.deletion_protection
}

# -----------------------------------------------------------------------------
# ARTIFACT REGISTRY (GCP DevOps Pro: Container registry)
# -----------------------------------------------------------------------------

resource "google_artifact_registry_repository" "containers" {
  project       = var.project_id
  location      = var.region
  repository_id = "${var.environment_name}-containers"
  format        = "DOCKER"
  description   = "Container images for Virtual Machinist Foundry"

  labels = local.labels

  cleanup_policies {
    id     = "keep-recent"
    action = "KEEP"
    most_recent_versions {
      keep_count = 10
    }
  }
}

resource "google_artifact_registry_repository" "python" {
  project       = var.project_id
  location      = var.region
  repository_id = "${var.environment_name}-python"
  format        = "PYTHON"
  description   = "Python packages for Virtual Machinist"

  labels = local.labels
}

# -----------------------------------------------------------------------------
# CLOUD BUILD (GCP DevOps Pro: CI/CD pipelines)
# -----------------------------------------------------------------------------

resource "google_cloudbuild_trigger" "main" {
  count    = var.enable_cloud_build ? 1 : 0
  project  = var.project_id
  name     = "${var.environment_name}-main-trigger"
  location = var.region

  github {
    owner = var.github_owner
    name  = var.github_repo

    push {
      branch = "^main$"
    }
  }

  filename = "cloudbuild.yaml"

  substitutions = {
    _REGION     = var.region
    _PROJECT_ID = var.project_id
    _CLUSTER    = google_container_cluster.autopilot.name
  }
}

# Cloud Build service account permissions
resource "google_project_iam_member" "cloudbuild_gke" {
  count   = var.enable_cloud_build ? 1 : 0
  project = var.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${var.project_number}@cloudbuild.gserviceaccount.com"
}

resource "google_project_iam_member" "cloudbuild_artifact" {
  count   = var.enable_cloud_build ? 1 : 0
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${var.project_number}@cloudbuild.gserviceaccount.com"
}

# -----------------------------------------------------------------------------
# VERTEX AI WORKBENCH (GCP ML Pro: ML development environment)
# -----------------------------------------------------------------------------

resource "google_workbench_instance" "ml_workbench" {
  count    = var.enable_vertex_workbench ? 1 : 0
  project  = var.project_id
  name     = "${var.environment_name}-ml-workbench"
  location = var.zone

  gce_setup {
    machine_type = var.workbench_machine_type

    vm_image {
      project = "deeplearning-platform-release"
      family  = "common-cpu-notebooks"
    }

    boot_disk {
      disk_size_gb = 100
      disk_type    = "PD_SSD"
    }

    network_interfaces {
      network  = google_compute_network.vpc.id
      subnet   = google_compute_subnetwork.workloads.id
      nic_type = "GVNIC"
    }

    disable_public_ip = true

    service_accounts {
      email = var.workbench_service_account
    }

    metadata = {
      terraform = "true"
    }

    enable_ip_forwarding = false
  }

  labels = local.labels
}

# -----------------------------------------------------------------------------
# SECRET MANAGER (GCP DevOps Pro: Secrets management)
# -----------------------------------------------------------------------------

resource "google_secret_manager_secret" "app_secrets" {
  for_each  = toset(var.secret_names)
  project   = var.project_id
  secret_id = "${var.environment_name}-${each.key}"

  replication {
    auto {}
  }

  labels = local.labels
}

# Allow GKE workload identity to access secrets
resource "google_secret_manager_secret_iam_member" "workload_access" {
  for_each  = toset(var.secret_names)
  project   = var.project_id
  secret_id = google_secret_manager_secret.app_secrets[each.key].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.project_id}.svc.id.goog[${var.k8s_namespace}/${var.k8s_service_account}]"
}