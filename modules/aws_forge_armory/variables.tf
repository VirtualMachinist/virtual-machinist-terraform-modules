# =============================================================================
# AWS FORGE+ARMORY VARIABLES
# =============================================================================

variable "environment_name" {
  description = "Environment name prefix"
  type        = string
  default     = "forge-armory"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

# Networking
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.10.0.0/16"
}

variable "single_nat_gateway" {
  description = "Use single NAT gateway (cost savings vs HA)"
  type        = bool
  default     = true
}

# EKS
variable "eks_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.29"
}

variable "eks_public_access_cidrs" {
  description = "CIDRs allowed to access EKS API publicly"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "eks_encryption_key_arn" {
  description = "KMS key ARN for EKS secrets encryption (creates one if null)"
  type        = string
  default     = null
}

variable "eks_node_instance_types" {
  description = "EC2 instance types for EKS nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_node_capacity_type" {
  description = "EKS node capacity type (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
}

variable "eks_node_desired_size" {
  description = "Desired number of EKS nodes"
  type        = number
  default     = 2
}

variable "eks_node_min_size" {
  description = "Minimum number of EKS nodes"
  type        = number
  default     = 1
}

variable "eks_node_max_size" {
  description = "Maximum number of EKS nodes"
  type        = number
  default     = 5
}

# AI/ML
variable "enable_bedrock" {
  description = "Enable Bedrock access for AI workloads"
  type        = bool
  default     = true
}

# Kubernetes
variable "k8s_namespace" {
  description = "Kubernetes namespace for IRSA"
  type        = string
  default     = "default"
}

variable "k8s_service_account" {
  description = "Kubernetes service account for IRSA"
  type        = string
  default     = "default"
}

# Secrets
variable "secret_names" {
  description = "List of secret names to create"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}