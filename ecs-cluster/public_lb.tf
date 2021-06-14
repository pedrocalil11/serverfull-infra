
resource "aws_security_group" "public_alb" {
    name = "public_alb_sg"
    vpc_id = var.vpc_id

    ingress = [ {
        cidr_blocks                 = [ "0.0.0.0/0" ]
        description                 = "All Internet can reach Public ALB"
        from_port                   = 443
        to_port                     = 443
        protocol                    = "tcp"
        ipv6_cidr_blocks            = null
        prefix_list_ids             = null
        security_groups             = null
        self                        = null
    } ]
    tags = {
        Name        = "public_alb_sg"
    }
}

resource "aws_security_group_rule" "egress_rule_public" {
    description                 = "All requests on Public ALB is forwarded to ECS Cluster"
    security_group_id           = aws_security_group.public_alb.id
    type                        = "egress"
    source_security_group_id    = aws_security_group.ecs_cluster.id
    from_port                   = 0
    to_port                     = 65535
    protocol                    = "tcp"
}

resource "aws_lb" "public" {
    name                    = "public-alb"
    internal                = false
    load_balancer_type      = "application"
    security_groups         = [aws_security_group.public_alb.id]
    idle_timeout            = 180
    subnets                 = var.public_subnets_id
}

resource "aws_lb_listener" "public" {
  load_balancer_arn     = aws_lb.public.arn
  port                  = 443
  protocol              = "HTTPS"
  ssl_policy            = "ELBSecurityPolicy-2016-08"
  certificate_arn       = var.public_alb_ssl_certificate_arn

  default_action {
    type        = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Resource not Found - Please define HOST header"
      status_code  = "404"
    }
  }
}