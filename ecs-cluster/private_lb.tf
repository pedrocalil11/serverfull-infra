
resource "aws_security_group" "private_alb" {
    name = "private_alb_sg"
    vpc_id = var.vpc_id

    ingress = [ {
        cidr_blocks                 = var.private_subnets_cidr
        description                 = "CIDR blocks from private subnets can reach LB"
        from_port                   = 443
        to_port                     = 443
        protocol                    = "tcp"
        ipv6_cidr_blocks            = null
        prefix_list_ids             = null
        security_groups             = null
        self                        = null
    } ]
    tags = {
        Name        = "private_alb_sg"
    }
}
resource "aws_security_group_rule" "egress_rule_private" {
    description                 = "All requests on Private ALB is forwarded to ECS Cluster"
    security_group_id           = aws_security_group.private_alb.id
    type                        = "egress"
    source_security_group_id    = aws_security_group.ecs_cluster.id
    from_port                   = 0
    to_port                     = 65535
    protocol                    = "tcp"
}

resource "aws_lb" "private" {
    name                    = "private-alb"
    internal                = true
    load_balancer_type      = "application"
    security_groups         = [aws_security_group.private_alb.id]
    idle_timeout            = 180
    subnets                 = var.private_subnets_id
}