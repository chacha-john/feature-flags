output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "kubeconfig_command" {
  description = "Run this to point kubectl at the cluster."
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region}"
}

output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "database_subnet_ids" {
  value = module.network.database_subnet_ids
}

output "db_endpoint" {
  value = module.rds.address
}

output "db_secret_arn" {
  description = "Secrets Manager ARN of the RDS-managed credentials (username + password). Used by environments/production/k8s/externalsecret.yaml."
  value       = module.rds.secret_arn
}

output "eso_reader_role_arn" {
  value = module.app.eso_reader_role_arn
}

output "ci_deployer_service_account" {
  description = "Service account the GitLab pipeline authenticates as (create a token with `kubectl create token`)."
  value       = module.app.ci_deployer_service_account
}
