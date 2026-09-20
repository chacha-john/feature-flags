variable "name" {
  description = "Name prefix; the instance identifier is <name>-db."
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  description = "Isolated database subnets (at least two AZs)."
  type        = list(string)
}

variable "allowed_security_group_id" {
  description = "The only security group allowed to connect on 5432 (the EKS node security group)."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key for storage encryption and for the RDS-managed credentials secret."
  type        = string
}

variable "engine_version" {
  description = "PostgreSQL major (or major.minor) version."
  type        = string
  default     = "17"
}

variable "instance_class" {
  type    = string
  default = "db.t4g.medium"
}

variable "allocated_storage" {
  description = "Initial storage in GiB."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Storage autoscaling ceiling in GiB."
  type        = number
  default     = 100
}

variable "multi_az" {
  description = "Run a synchronous standby in a second AZ."
  type        = bool
  default     = true
}

variable "db_name" {
  description = "Initial database name."
  type        = string
}

variable "username" {
  description = "Master username. The password is generated and stored in Secrets Manager by RDS."
  type        = string
}

variable "backup_retention_days" {
  type    = number
  default = 7
}

variable "deletion_protection" {
  description = "Block accidental deletion. Turn off only to tear down a non-production environment."
  type        = bool
  default     = true
}
