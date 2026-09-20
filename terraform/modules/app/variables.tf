variable "name" {
  description = "Name prefix for IAM roles."
  type        = string
}

variable "region" {
  description = "AWS region (pins the kms:ViaService condition to this region's Secrets Manager)."
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace the app runs in. Must match K8S_NAMESPACE in .gitlab-ci.yml."
  type        = string
}

variable "oidc_provider_arn" {
  description = "IAM OIDC provider of the EKS cluster (from the eks module)."
  type        = string
}

variable "oidc_issuer_host" {
  description = "OIDC issuer host without https:// (from the eks module)."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key that encrypts the database credentials secret."
  type        = string
}

variable "db_secret_arn" {
  description = "Secrets Manager ARN of the database credentials. The only secret the reader role can read."
  type        = string
}

variable "db_address" {
  description = "Database host name (non-secret; goes into the ConfigMap)."
  type        = string
}

variable "db_port" {
  type    = number
  default = 5432
}

variable "db_name" {
  type = string
}

variable "external_secrets_chart_version" {
  description = "External Secrets Operator Helm chart version (must serve the external-secrets.io/v1 API)."
  type        = string
}
