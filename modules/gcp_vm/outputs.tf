output "vm_name" {
  description = "Name of the VM instance"
  value       = google_compute_instance.vm.name
}

output "vm_id" {
  description = "Instance ID of the VM"
  value       = google_compute_instance.vm.instance_id
}

output "vm_self_link" {
  description = "Self-link of the VM instance"
  value       = google_compute_instance.vm.self_link
}

output "internal_ip" {
  description = "Internal (private) IP address of the VM"
  value       = google_compute_instance.vm.network_interface[0].network_ip
}

output "external_ip" {
  description = "External (public) IP address of the VM (if assigned)"
  value       = var.enable_public_ip ? google_compute_instance.vm.network_interface[0].access_config[0].nat_ip : null
}

output "zone" {
  description = "Zone where the VM is deployed"
  value       = google_compute_instance.vm.zone
}