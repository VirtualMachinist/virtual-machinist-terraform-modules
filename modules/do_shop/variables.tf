# =============================================================================
# DIGITALOCEAN SHOP VARIABLES
# =============================================================================

variable "environment_name" {
  description = "Environment name prefix"
  type        = string
  default     = "shop"
}

variable "region" {
  description = "DigitalOcean region"
  type        = string
  default     = "nyc1"
}

# Networking
variable "vpc_cidr" {
  description = "VPC IP range"
  type        = string
  default     = "10.20.0.0/16"
}

# Kubernetes
variable "k8s_version" {
  description = "Kubernetes version prefix (e.g., '1.29')"
  type        = string
  default     = "1.29"
}

variable "node_size" {
  description = "Droplet size for worker nodes"
  type        = string
  default     = "s-2vcpu-4gb"
}

variable "min_nodes" {
  description = "Minimum number of nodes"
  type        = number
  default     = 2
}

variable "max_nodes" {
  description = "Maximum number of nodes"
  type        = number
  default     = 5
}

variable "node_labels" {
  description = "Labels for node pool"
  type        = map(string)
  default     = {}
}

# High memory pool (optional)
variable "enable_high_memory_pool" {
  description = "Enable high memory node pool"
  type        = bool
  default     = false
}

variable "high_memory_node_size" {
  description = "Droplet size for high memory nodes"
  type        = string
  default     = "m-2vcpu-16gb"
}

variable "high_memory_max_nodes" {
  description = "Max nodes for high memory pool"
  type        = number
  default     = 3
}

# Registry
variable "enable_registry" {
  description = "Enable container registry"
  type        = bool
  default     = true
}

variable "registry_tier" {
  description = "Registry subscription tier"
  type        = string
  default     = "starter"
}

# PostgreSQL
variable "enable_postgres" {
  description = "Enable PostgreSQL database"
  type        = bool
  default     = false
}

variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "15"
}

variable "postgres_size" {
  description = "PostgreSQL droplet size"
  type        = string
  default     = "db-s-1vcpu-1gb"
}

variable "postgres_node_count" {
  description = "PostgreSQL node count"
  type        = number
  default     = 1
}

# Redis
variable "enable_redis" {
  description = "Enable Redis database"
  type        = bool
  default     = false
}

variable "redis_version" {
  description = "Redis version"
  type        = string
  default     = "7"
}

variable "redis_size" {
  description = "Redis droplet size"
  type        = string
  default     = "db-s-1vcpu-1gb"
}

# Spaces (Object Storage)
variable "enable_spaces" {
  description = "Enable Spaces bucket"
  type        = bool
  default     = false
}

variable "spaces_region" {
  description = "Spaces region (may differ from droplet region)"
  type        = string
  default     = "nyc3"
}

variable "spaces_cors_origins" {
  description = "CORS allowed origins for Spaces"
  type        = list(string)
  default     = ["*"]
}

variable "enable_cdn" {
  description = "Enable CDN for Spaces"
  type        = bool
  default     = false
}

variable "cdn_custom_domain" {
  description = "Custom domain for CDN"
  type        = string
  default     = null
}

variable "cdn_ttl" {
  description = "CDN TTL in seconds"
  type        = number
  default     = 3600
}

# Load Balancer
variable "enable_external_lb" {
  description = "Enable external load balancer"
  type        = bool
  default     = false
}

variable "lb_certificate_name" {
  description = "SSL certificate name for LB"
  type        = string
  default     = null
}

# DNS
variable "domain_name" {
  description = "Domain name to manage (optional)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = list(string)
  default     = []
}