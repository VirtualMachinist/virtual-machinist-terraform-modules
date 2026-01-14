# Compute Engine VM Instance
resource "google_compute_instance" "vm" {
  project      = var.project_id
  name         = var.vm_name
  zone         = var.zone
  machine_type = var.machine_type

  tags   = var.tags
  labels = var.labels

  # Boot disk
  boot_disk {
    initialize_params {
      image = var.image
      size  = var.disk_size_gb
      type  = "pd-balanced"
    }
  }

  # Network interface
  network_interface {
    network    = var.network
    subnetwork = var.subnetwork

    # Conditionally assign public IP
    dynamic "access_config" {
      for_each = var.enable_public_ip ? [1] : []
      content {
        # Ephemeral public IP
      }
    }
  }

  # Service account
  service_account {
    email  = var.service_account_email
    scopes = var.service_account_scopes
  }

  # Metadata (including startup script if provided)
  metadata = merge(
    var.metadata,
    var.startup_script != null ? { startup-script = var.startup_script } : {}
  )

  # Allow stopping for updates (machine type, etc.)
  allow_stopping_for_update = true

  # Shielded VM settings (security best practice)
  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }
}