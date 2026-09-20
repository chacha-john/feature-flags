variable "name" {
  description = "Cluster name and name prefix for related resources."
  type        = string
}

variable "tags" {
  description = "Tags applied to node instances (provider default_tags do not propagate to instances launched by the node group)."
  type        = map(string)
  default     = {}
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnets for the control-plane ENIs and the worker nodes."
  type        = list(string)
}

variable "kms_key_arn" {
  description = "KMS key used for Kubernetes Secrets envelope encryption."
  type        = string
}

variable "public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public API endpoint. 0.0.0.0/0 is rejected."
  type        = list(string)

  validation {
    condition     = length(var.public_access_cidrs) > 0 && !contains(var.public_access_cidrs, "0.0.0.0/0")
    error_message = "Provide at least one CIDR and do not use 0.0.0.0/0."
  }
}

variable "admin_principal_arns" {
  description = "IAM role/user ARNs granted cluster-admin through EKS access entries (in addition to the identity running Terraform)."
  type        = list(string)
  default     = []
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
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
