output "namespace" {
  value = kubernetes_namespace_v1.app.metadata[0].name
}

output "eso_reader_role_arn" {
  value = aws_iam_role.eso_reader.arn
}

output "ci_deployer_service_account" {
  description = "Service account the GitLab pipeline authenticates as (create a token with `kubectl create token`)."
  value       = "${kubernetes_namespace_v1.app.metadata[0].name}/${kubernetes_service_account_v1.ci_deployer.metadata[0].name}"
}
