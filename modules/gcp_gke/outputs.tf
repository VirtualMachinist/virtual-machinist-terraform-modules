output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = google_container_cluster.autopilot.name
}

output "cluster_endpoint" {
  description = "Endpoint for the GKE cluster control plane"
  value       = google_container_cluster.autopilot.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Base64 encoded CA certificate for the cluster"
  value       = google_container_cluster.autopilot.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "cluster_location" {
  description = "Location (region) of the cluster"
  value       = google_container_cluster.autopilot.location
}