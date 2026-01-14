variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
}

variable "region" {
  description = "GCP region for the cluster"
  type        = string
}

variable "network" {
  description = "VPC network self-link or ID"
  type        = string
}

variable "subnetwork" {
  description = "Subnetwork self-link or ID for the cluster"
  type        = string
}

variable "enable_private_nodes" {
  description = "Enable private nodes (no public IPs on nodes)"
  type        = bool
  default     = true
}

variable "master_ipv4_cidr_block" {
  description = "CIDR block for GKE master (control plane) VPC peering"
  type        = string
  default     = "172.16.0.0/28"
}

variable "deletion_protection" {
  description = "Prevent accidental cluster deletion"
  type        = bool
  default     = false
}