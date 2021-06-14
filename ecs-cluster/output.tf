output "cluster_arn" {
    description = "The ARN of cluster"
    value       = aws_ecs_cluster.this.arn
}

output "execution_role_arn" {
    description = "The ARN of Tasks Execution Role"
    value       = aws_iam_role.execution_role.arn
}

output "public_alb_url"{
    description = "The URL of public ALB"
    value       = aws_lb.public.dns_name
}

output "public_alb_default_listener_arn"{
    description = "The ARN of public ALB listener"
    value       = aws_lb_listener.public.arn
}

output "security_group_id"{
    description = "The ID of ECS Cluster SG"
    value       = aws_security_group.ecs_cluster.id
}