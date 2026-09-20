variable "name" {
  description = "Name prefix for all resources."
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name, used for the kubernetes.io/cluster subnet tag so load balancers find the subnets."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC."
  type        = string
}

variable "az_count" {
  description = "Number of Availability Zones to spread subnets across (2 or 3; RDS needs at least 2)."
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
