variable "region" {
  description = "AWS region to deploy into. Pick the closest region that offers EKS and RDS for PostgreSQL."
  type        = string
  default     = "eu-west-1"
}

variable "project" {
  description = "Project name, used as a prefix for resource names."
  type        = string
  default     = "feature-flags"
}

variable "environment" {
  description = "Environment name (for example prod, staging)."
  type        = string
  default     = "prod"
}

variable "app_namespace" {
  description = "Kubernetes namespace the app runs in. Must match K8S_NAMESPACE in .gitlab-ci.yml."
  type        = string
  default     = "feature-flags"
}

# ---------------------------------------------------------------- network

variable "vpc_cidr" {
  description = "CIDR block of the VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "az_count" {
  description = "Number of Availability Zones to spread subnets across (minimum 2, required by RDS)."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count must be 2 or 3."
  }
}

variable "single_nat_gateway" {
  description = "Use one shared NAT gateway (cheaper, single-AZ egress) instead of one per AZ."
  type        = bool
  default     = false
}

# ---------------------------------------------------------------- EKS

variable "kubernetes_version" {
  description = "EKS Kubernetes version. Check the EKS release calendar and use a version in standard support."
  type        = string
  default     = "1.34"
}

variable "cluster_public_access_cidrs" {
  description = <<-EOT
    CIDR blocks allowed to reach the public EKS API endpoint (your office/VPN egress IPs and the
    GitLab runner egress IPs). Required: there is deliberately no default, and 0.0.0.0/0 is rejected.
  EOT
  type        = list(string)

  validation {
    condition     = length(var.cluster_public_access_cidrs) > 0 && !contains(var.cluster_public_access_cidrs, "0.0.0.0/0")
    error_message = "Provide at least one CIDR and do not use 0.0.0.0/0."
  }
}

variable "admin_principal_arns" {
  description = "IAM role/user ARNs granted cluster-admin through EKS access entries (in addition to the identity running Terraform)."
  type        = list(string)
  default     = []
}

variable "node_instance_types" {
  description = "Instance types for the managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 4
}

variable "external_secrets_chart_version" {
  description = "External Secrets Operator Helm chart version (must serve the external-secrets.io/v1 API). Verify the latest 1.x release before applying."
  type        = string
  default     = "1.0.0"
}

# ---------------------------------------------------------------- database

variable "db_engine_version" {
  description = "PostgreSQL major (or major.minor) version. The app is developed against PostgreSQL 17."
  type        = string
  default     = "17"
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.medium"
}

variable "db_allocated_storage" {
  description = "Initial storage in GiB."
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Storage autoscaling ceiling in GiB."
  type        = number
  default     = 100
}

variable "db_multi_az" {
  description = "Run a synchronous standby in a second AZ."
  type        = bool
  default     = true
}

variable "db_name" {
  description = "Initial database name (matches POSTGRES_DB in compose)."
  type        = string
  default     = "flags"
}

variable "db_username" {
  description = "Master username (matches POSTGRES_USER in compose). The password is generated and stored in Secrets Manager by RDS."
  type        = string
  default     = "flags"
}

variable "db_backup_retention_days" {
  type    = number
  default = 7
}

variable "db_deletion_protection" {
  description = "Block accidental deletion of the database. Turn off only to tear down a non-production environment."
  type        = bool
  default     = true
}
