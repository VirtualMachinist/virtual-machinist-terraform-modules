# =============================================================================
# GCP FOUNDRY OUTPUTS
# =============================================================================

# Networking
output "vpc_id" {
  description = "VPC ID"
  value       = google_compute_network.vpc.id
}

output "vpc_self_link" {
  description = "VPC self-link"
  value       = google_compute_network.vpc.self_link
}

output "gke_subnet_id" {
  description = "GKE subnet ID"
  value       = google_compute_subnetwork.gke.id
}

output "workloads_subnet_id" {
  description = "Workloads subnet ID"
  value       = google_compute_subnetwork.workloads.id
}

# GKE
output "cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.autopilot.name
}

output "cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = google_container_cluster.autopilot.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "GKE cluster CA certificate"
  value       = google_container_cluster.autopilot.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "workload_identity_pool" {
  description = "Workload Identity pool"
  value       = "${var.project_id}.svc.id.goog"
}

# Artifact Registry
output "container_registry_url" {
  description = "Artifact Registry URL for containers"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.containers.repository_id}"
}

output "python_registry_url" {
  description = "Artifact Registry URL for Python packages"
  value       = "https://${var.region}-python.pkg.dev/${var.project_id}/${google_artifact_registry_repository.python.repository_id}/simple/"
}

# kubectl config command
output "gke_connect_command" {
  description = "Command to connect kubectl to the cluster"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.autopilot.name} --region ${var.region} --project ${var.project_id}"
}