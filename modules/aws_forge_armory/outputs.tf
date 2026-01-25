# =============================================================================
# AWS FORGE+ARMORY OUTPUTS
# =============================================================================

# Networking
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "nat_gateway_ips" {
  description = "NAT Gateway public IPs"
  value       = aws_eip.nat[*].public_ip
}

# EKS
output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "EKS cluster CA certificate"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "cluster_oidc_issuer" {
  description = "EKS OIDC issuer URL"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA"
  value       = aws_iam_openid_connect_provider.eks.arn
}

# ECR
output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.main.repository_url
}

# Bedrock IRSA
output "bedrock_irsa_role_arn" {
  description = "IAM role ARN for Bedrock access via IRSA"
  value       = var.enable_bedrock ? aws_iam_role.bedrock_irsa[0].arn : null
}

# kubectl config command
output "eks_update_kubeconfig_command" {
  description = "Command to update kubeconfig for EKS"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.main.name}"
}