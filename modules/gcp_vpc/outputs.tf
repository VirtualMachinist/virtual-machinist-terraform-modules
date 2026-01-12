output "vpc_id" {
  description = "The ID of the VPC"
  value       = google_compute_network.vpc.id
}

output "vpc_name" {
  description = "The name of the VPC"
  value       = google_compute_network.vpc.name
}

output "vpc_self_link" {
  description = "The self-link of the VPC"
  value       = google_compute_network.vpc.self_link
}

output "public_subnet_id" {
  description = "The ID of the public subnet"
  value       = google_compute_subnetwork.public.id
}

output "private_subnet_id" {
  description = "The ID of the private subnet"
  value       = google_compute_subnetwork.private.id
}

output "public_subnet_cidr" {
  description = "The CIDR of the public subnet"
  value       = google_compute_subnetwork.public.ip_cidr_range
}

output "private_subnet_cidr" {
  description = "The CIDR of the private subnet"
  value       = google_compute_subnetwork.private.ip_cidr_range
}