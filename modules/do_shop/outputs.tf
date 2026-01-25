# =============================================================================
# DIGITALOCEAN SHOP OUTPUTS
# =============================================================================

# Networking
output "vpc_id" {
  description = "VPC ID"
  value       = digitalocean_vpc.main.id
}

output "vpc_urn" {
  description = "VPC URN"
  value       = digitalocean_vpc.main.urn
}

# Kubernetes
output "cluster_id" {
  description = "DOKS cluster ID"
  value       = digitalocean_kubernetes_cluster.main.id
}

output "cluster_name" {
  description = "DOKS cluster name"
  value       = digitalocean_kubernetes_cluster.main.name
}

output "cluster_endpoint" {
  description = "DOKS cluster endpoint"
  value       = digitalocean_kubernetes_cluster.main.endpoint
  sensitive   = true
}

output "cluster_token" {
  description = "DOKS cluster token"
  value       = digitalocean_kubernetes_cluster.main.kube_config[0].token
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "DOKS cluster CA certificate"
  value       = digitalocean_kubernetes_cluster.main.kube_config[0].cluster_ca_certificate
  sensitive   = true
}

output "kubeconfig" {
  description = "Raw kubeconfig for DOKS"
  value       = digitalocean_kubernetes_cluster.main.kube_config[0].raw_config
  sensitive   = true
}

# Registry
output "registry_endpoint" {
  description = "Container registry endpoint"
  value       = var.enable_registry ? digitalocean_container_registry.main[0].endpoint : null
}

output "registry_server_url" {
  description = "Container registry server URL"
  value       = var.enable_registry ? digitalocean_container_registry.main[0].server_url : null
}

# Databases
output "postgres_host" {
  description = "PostgreSQL host"
  value       = var.enable_postgres ? digitalocean_database_cluster.postgres[0].private_host : null
  sensitive   = true
}

output "postgres_port" {
  description = "PostgreSQL port"
  value       = var.enable_postgres ? digitalocean_database_cluster.postgres[0].port : null
}

output "postgres_database" {
  description = "PostgreSQL default database"
  value       = var.enable_postgres ? digitalocean_database_cluster.postgres[0].database : null
}

output "postgres_user" {
  description = "PostgreSQL default user"
  value       = var.enable_postgres ? digitalocean_database_cluster.postgres[0].user : null
  sensitive   = true
}

output "postgres_password" {
  description = "PostgreSQL password"
  value       = var.enable_postgres ? digitalocean_database_cluster.postgres[0].password : null
  sensitive   = true
}

output "redis_host" {
  description = "Redis host"
  value       = var.enable_redis ? digitalocean_database_cluster.redis[0].private_host : null
  sensitive   = true
}

output "redis_port" {
  description = "Redis port"
  value       = var.enable_redis ? digitalocean_database_cluster.redis[0].port : null
}

# Spaces
output "spaces_bucket_name" {
  description = "Spaces bucket name"
  value       = var.enable_spaces ? digitalocean_spaces_bucket.assets[0].name : null
}

output "spaces_bucket_domain" {
  description = "Spaces bucket domain"
  value       = var.enable_spaces ? digitalocean_spaces_bucket.assets[0].bucket_domain_name : null
}

output "cdn_domain" {
  description = "CDN domain"
  value       = var.enable_spaces && var.enable_cdn ? digitalocean_cdn.assets[0].endpoint : null
}

# Load Balancer
output "lb_ip" {
  description = "Load balancer IP"
  value       = var.enable_external_lb ? digitalocean_loadbalancer.main[0].ip : null
}

# doctl command
output "doctl_save_kubeconfig_command" {
  description = "Command to save kubeconfig using doctl"
  value       = "doctl kubernetes cluster kubeconfig save ${digitalocean_kubernetes_cluster.main.id}"
}