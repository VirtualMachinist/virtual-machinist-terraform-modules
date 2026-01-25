# =============================================================================
# GCP FOUNDRY VARIABLES
# =============================================================================

# Project
variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "project_number" {
  description = "GCP project number (for service account references)"
  type        = string
  default     = null
}

variable "environment_name" {
  description = "Environment name prefix"
  type        = string
  default     = "foundry"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone (for zonal resources)"
  type        = string
  default     = "us-central1-a"
}

# Networking
variable "gke_subnet_cidr" {
  description = "CIDR for GKE nodes"
  type        = string
  default     = "10.0.0.0/20"
}

variable "pods_cidr" {
  description = "CIDR for GKE pods (secondary range)"
  type        = string
  default     = "10.4.0.0/14"
}

variable "services_cidr" {
  description = "CIDR for GKE services (secondary range)"
  type        = string
  default     = "10.8.0.0/20"
}

variable "workloads_cidr" {
  description = "CIDR for workloads subnet (VMs, Vertex AI)"
  type        = string
  default     = "10.1.0.0/20"
}

variable "master_cidr" {
  description = "CIDR for GKE master (must be /28)"
  type        = string
  default     = "172.16.0.0/28"
}

variable "authorized_networks" {
  description = "List of authorized networks for GKE API access"
  type = list(object({
    cidr = string
    name = string
  }))
  default = []
}

# GKE
variable "deletion_protection" {
  description = "Enable deletion protection for GKE cluster"
  type        = bool
  default     = false
}

variable "enable_binary_auth" {
  description = "Enable Binary Authorization for GKE"
  type        = bool
  default     = false
}

# Cloud Build
variable "enable_cloud_build" {
  description = "Enable Cloud Build trigger"
  type        = bool
  default     = false
}

variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
  default     = "VirtualMachinist"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "virtual-machinist-ai-crypto-hub"
}

# Vertex AI
variable "enable_vertex_workbench" {
  description = "Enable Vertex AI Workbench instance"
  type        = bool
  default     = false
}

variable "workbench_machine_type" {
  description = "Machine type for Vertex AI Workbench"
  type        = string
  default     = "e2-standard-4"
}

variable "workbench_service_account" {
  description = "Service account for Vertex AI Workbench"
  type        = string
  default     = null
}

# Secrets
variable "secret_names" {
  description = "List of secret names to create"
  type        = list(string)
  default     = []
}

variable "k8s_namespace" {
  description = "Kubernetes namespace for workload identity"
  type        = string
  default     = "default"
}

variable "k8s_service_account" {
  description = "Kubernetes service account for workload identity"
  type        = string
  default     = "default"
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}