output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "cluster_ca_data" {
  description = "Base64-encoded cluster CA certificate."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "Security group carried by the worker nodes; use it as the source in database ingress rules."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "oidc_provider_arn" {
  description = "IAM OIDC provider for IRSA trust policies."
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_issuer_host" {
  description = "OIDC issuer without the https:// prefix, for the :sub and :aud trust-policy condition keys."
  value       = local.oidc_host
}
