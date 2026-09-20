output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Subnets for EKS nodes and pods (egress through NAT)."
  value       = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "Isolated subnets with no internet route, for RDS."
  value       = aws_subnet.database[*].id
}
