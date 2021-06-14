locals{
    base_path_name = format("/%s/", replace(replace(var.name, "-", "_"), "_api", ""))
}

resource "aws_lb_target_group" "this" {
    name                        = format("%s-tg", var.name)
    port                        = 80
    protocol                    = "HTTP"
    vpc_id                      = var.vpc_id
    deregistration_delay        = 45

    health_check {
        enabled                 = true
        interval                = 30
        path                    = local.base_path_name
        port                    = "traffic-port"
        protocol                = "HTTP"
        timeout                 = 5
        healthy_threshold       = 3
        unhealthy_threshold     = 3
        matcher                 = "200"
    }
}

resource "aws_lb_listener_rule" "this" {
    listener_arn                = var.public_alb_listener_arn
    
    action {
        type                    = "forward"
        target_group_arn        = aws_lb_target_group.this.arn
    }

    condition {
        path_pattern {
            values = [ local.base_path_name ]
        }
    }
}