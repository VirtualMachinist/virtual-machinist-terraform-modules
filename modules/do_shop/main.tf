# =============================================================================
# DIGITALOCEAN SHOP - Production Environment
# Full Stack Virtual Machinist
# 
# CERT ALIGNMENT:
# - CKA/CKAD: DOKS cluster management, workloads, services
# - Terraform Associate: Module composition, count, for_each
#
# BUSINESS FOCUS:
# - Fast, lean production deployment
# - Cost-effective hosting for SaaS, info products, bots
# - Easy shipping of vibe-coded apps
# =============================================================================

locals {
  environment = "shop"
  
  common_tags = concat(var.tags, [
    "environment:${local.environment}",
    "managed-by:terraform",
    "project:virtual-machinist"
  ])
}

# -----------------------------------------------------------------------------
# NETWORKING (VPC)
# -----------------------------------------------------------------------------

resource "digitalocean_vpc" "main" {
  name     = "${var.environment_name}-vpc"
  region   = var.region
  ip_range = var.vpc_cidr
}

# -----------------------------------------------------------------------------
# KUBERNETES CLUSTER (DOKS - CKA/CKAD practice)
# -----------------------------------------------------------------------------

resource "digitalocean_kubernetes_cluster" "main" {
  name    = var.environment_name
  region  = var.region
  version = var.k8s_version

  vpc_uuid = digitalocean_vpc.main.id

  # Auto-upgrade for security patches
  auto_upgrade = true

  # Maintenance window
  maintenance_policy {
    day        = "sunday"
    start_time = "04:00"
  }

  # Node pool
  node_pool {
    name       = "${var.environment_name}-workers"
    size       = var.node_size
    auto_scale = true
    min_nodes  = var.min_nodes
    max_nodes  = var.max_nodes

    tags   = local.common_tags
    labels = var.node_labels
  }

  tags = local.common_tags
}

# Additional node pool for specific workloads (optional)
resource "digitalocean_kubernetes_node_pool" "high_memory" {
  count      = var.enable_high_memory_pool ? 1 : 0
  cluster_id = digitalocean_kubernetes_cluster.main.id
  name       = "${var.environment_name}-high-memory"
  size       = var.high_memory_node_size
  auto_scale = true
  min_nodes  = 0
  max_nodes  = var.high_memory_max_nodes

  labels = {
    workload = "high-memory"
  }

  taint {
    key    = "workload"
    value  = "high-memory"
    effect = "NoSchedule"
  }

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# CONTAINER REGISTRY
# -----------------------------------------------------------------------------

resource "digitalocean_container_registry" "main" {
  count                  = var.enable_registry ? 1 : 0
  name                   = replace(var.environment_name, "-", "")
  subscription_tier_slug = var.registry_tier
  region                 = var.region
}

# Connect registry to cluster
resource "digitalocean_container_registry_docker_credentials" "main" {
  count           = var.enable_registry ? 1 : 0
  registry_name   = digitalocean_container_registry.main[0].name
  write           = true
  expiry_seconds  = 31536000  # 1 year
}

# -----------------------------------------------------------------------------
# DATABASES (Optional - for SaaS/info products)
# -----------------------------------------------------------------------------

# PostgreSQL for application data
resource "digitalocean_database_cluster" "postgres" {
  count      = var.enable_postgres ? 1 : 0
  name       = "${var.environment_name}-postgres"
  engine     = "pg"
  version    = var.postgres_version
  size       = var.postgres_size
  region     = var.region
  node_count = var.postgres_node_count

  private_network_uuid = digitalocean_vpc.main.id

  maintenance_window {
    day  = "sunday"
    hour = "02:00:00"
  }

  tags = local.common_tags
}

# Redis for caching/sessions
resource "digitalocean_database_cluster" "redis" {
  count      = var.enable_redis ? 1 : 0
  name       = "${var.environment_name}-redis"
  engine     = "redis"
  version    = var.redis_version
  size       = var.redis_size
  region     = var.region
  node_count = 1

  private_network_uuid = digitalocean_vpc.main.id

  tags = local.common_tags
}

# Database firewall - only allow from DOKS
resource "digitalocean_database_firewall" "postgres" {
  count      = var.enable_postgres ? 1 : 0
  cluster_id = digitalocean_database_cluster.postgres[0].id

  rule {
    type  = "k8s"
    value = digitalocean_kubernetes_cluster.main.id
  }
}

resource "digitalocean_database_firewall" "redis" {
  count      = var.enable_redis ? 1 : 0
  cluster_id = digitalocean_database_cluster.redis[0].id

  rule {
    type  = "k8s"
    value = digitalocean_kubernetes_cluster.main.id
  }
}

# -----------------------------------------------------------------------------
# SPACES (Object Storage - for static assets, backups)
# -----------------------------------------------------------------------------

resource "digitalocean_spaces_bucket" "assets" {
  count  = var.enable_spaces ? 1 : 0
  name   = "${var.environment_name}-assets"
  region = var.spaces_region

  acl = "private"

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = var.spaces_cors_origins
    max_age_seconds = 3600
  }

  lifecycle_rule {
    enabled = true

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      days = 30
    }
  }
}

# CDN for assets bucket
resource "digitalocean_cdn" "assets" {
  count  = var.enable_spaces && var.enable_cdn ? 1 : 0
  origin = digitalocean_spaces_bucket.assets[0].bucket_domain_name

  custom_domain = var.cdn_custom_domain
  ttl           = var.cdn_ttl
}

# -----------------------------------------------------------------------------
# LOAD BALANCER (for non-K8s ingress if needed)
# -----------------------------------------------------------------------------

resource "digitalocean_loadbalancer" "main" {
  count  = var.enable_external_lb ? 1 : 0
  name   = "${var.environment_name}-lb"
  region = var.region

  vpc_uuid = digitalocean_vpc.main.id

  forwarding_rule {
    entry_port     = 443
    entry_protocol = "https"

    target_port     = 80
    target_protocol = "http"

    certificate_name = var.lb_certificate_name
  }

  forwarding_rule {
    entry_port     = 80
    entry_protocol = "http"

    target_port     = 80
    target_protocol = "http"
  }

  healthcheck {
    port     = 80
    protocol = "http"
    path     = "/health"
  }

  redirect_http_to_https = true
  enable_proxy_protocol  = false

  droplet_tag = "${var.environment_name}-web"
}

# -----------------------------------------------------------------------------
# DNS (if managing domain)
# -----------------------------------------------------------------------------

resource "digitalocean_domain" "main" {
  count = var.domain_name != null ? 1 : 0
  name  = var.domain_name
}

resource "digitalocean_record" "app" {
  count  = var.domain_name != null && var.enable_external_lb ? 1 : 0
  domain = digitalocean_domain.main[0].id
  type   = "A"
  name   = "@"
  value  = digitalocean_loadbalancer.main[0].ip
  ttl    = 300
}

resource "digitalocean_record" "www" {
  count  = var.domain_name != null ? 1 : 0
  domain = digitalocean_domain.main[0].id
  type   = "CNAME"
  name   = "www"
  value  = "@"
  ttl    = 300
}

# -----------------------------------------------------------------------------
# PROJECT (organize resources)
# -----------------------------------------------------------------------------

resource "digitalocean_project" "main" {
  name        = "Virtual Machinist - ${title(local.environment)}"
  description = "Production environment for Virtual Machinist products"
  purpose     = "Service or API"
  environment = "Production"

  resources = concat(
    [digitalocean_kubernetes_cluster.main.urn],
    var.enable_postgres ? [digitalocean_database_cluster.postgres[0].urn] : [],
    var.enable_redis ? [digitalocean_database_cluster.redis[0].urn] : [],
    var.enable_spaces ? [digitalocean_spaces_bucket.assets[0].urn] : [],
    var.enable_external_lb ? [digitalocean_loadbalancer.main[0].urn] : []
  )
}