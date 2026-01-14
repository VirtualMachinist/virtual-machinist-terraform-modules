variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "vm_name" {
  description = "Name of the VM instance"
  type        = string
}

variable "zone" {
  description = "GCP zone for the VM (e.g., us-central1-a)"
  type        = string
}

variable "machine_type" {
  description = "Machine type for the VM"
  type        = string
  default     = "e2-medium"
}

variable "image" {
  description = "Boot disk image (e.g., debian-cloud/debian-11, rocky-linux-cloud/rocky-linux-9)"
  type        = string
  default     = "rocky-linux-cloud/rocky-linux-9"
}

variable "disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 20
}

variable "network" {
  description = "VPC network self-link or name"
  type        = string
}

variable "subnetwork" {
  description = "Subnetwork self-link or name"
  type        = string
}

variable "tags" {
  description = "Network tags for firewall rules"
  type        = list(string)
  default     = ["allow-iap-ssh"]
}

variable "enable_public_ip" {
  description = "Assign an external (public) IP address"
  type        = bool
  default     = false
}

variable "service_account_email" {
  description = "Service account email for the VM (optional, uses default if not set)"
  type        = string
  default     = null
}

variable "service_account_scopes" {
  description = "OAuth scopes for the service account"
  type        = list(string)
  default     = ["cloud-platform"]
}

variable "metadata" {
  description = "Metadata key-value pairs for the VM"
  type        = map(string)
  default     = {}
}

variable "startup_script" {
  description = "Startup script to run on boot"
  type        = string
  default     = null
}

variable "labels" {
  description = "Labels to apply to the VM"
  type        = map(string)
  default     = {}
}