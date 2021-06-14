output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}


output "private_subnets_id" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private.*.id
}

output "public_subnets_id" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public.*.id
}

output "database_subnets_id" {
  description = "List of IDs of database subnets"
  value       = aws_subnet.database.*.id
}