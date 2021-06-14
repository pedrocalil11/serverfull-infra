############################
#######Security Group#######
############################
resource "aws_security_group" "ecs_cluster" {
  name                  = format("%s-ecs-cluster-sg", var.name)
  vpc_id                = var.vpc_id

    ###EGRESS POINTING TO NAT
    egress = [ {
        cidr_blocks             = [ "0.0.0.0/0" ]
        description             = "For now ECS Cluster can reach all internet"
        from_port               = 0
        to_port                 = 0
        protocol                = "-1" 
        ipv6_cidr_blocks        = []
        prefix_list_ids         = []
        security_groups         = []
        self                    = false
    } ]

    tags = { Name         = format("%s-ecs-cluster-sg", var.name) }
}

resource "aws_security_group_rule" "ingress_public_lb_on_cluster" {
    description                 = "Rule to allow all requests from public alb ingress on ecs cluster"
    security_group_id           = aws_security_group.ecs_cluster.id
    type                        = "ingress"
    source_security_group_id    = aws_security_group.public_alb.id
    from_port                   = 0
    to_port                     = 65535
    protocol                    = "tcp"
}

resource "aws_security_group_rule" "ingress_private_lb_on_cluster" {
    description                 = "Rule to allow all requests from private alb ingress on ecs cluster"
    security_group_id           = aws_security_group.ecs_cluster.id
    type                        = "ingress"
    source_security_group_id    = aws_security_group.private_alb.id
    from_port                   = 0
    to_port                     = 65535
    protocol                    = "tcp"
}
############################
########### Roles ##########
############################
resource "aws_iam_role" "ecs_instance_role" {
  name                          = format("%s_ecs_instance_role", var.name)
  assume_role_policy            = file("./files/ecs-instance-role-assume-role-policy.json")
}

resource "aws_iam_role_policy" "ecs_instance_role_policy" {
  name                          = format("%s_instance_role_policy", var.name)
  role                          = aws_iam_role.ecs_instance_role.id
  policy                        = file("./files/ecs-instance-role-permission-policy.json")
}

resource "aws_iam_instance_profile" "this" {
  name                          = format("%s_instance_profile", var.name)
  role                          = aws_iam_role.ecs_instance_role.name
}

resource "aws_iam_role" "execution_role" {
  name                          = format("%s_execution_role", var.name)
  assume_role_policy            = file("./files/execution-role-assume-role-policy.json")
}

resource "aws_iam_role_policy" "execution_role_policy" {
  name                          = format("%s_execution_role_policy", var.name)
  role                          = aws_iam_role.execution_role.id
  policy                        = file("./files/execution-role-permission-policy.json")
}
############################
######### Cluster ##########
############################
data "aws_ami" "ecs_ami" {
  most_recent = true
  owners      = ["amazon", "aws-marketplace", "591542846629"]

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "this" {
    description                           = "The default launch template for ECS cluster"
    name                                  = format("%s-cluster-launch-template", var.name)
    image_id                              = data.aws_ami.ecs_ami.image_id
    instance_type                         = var.instance_type
    instance_initiated_shutdown_behavior  = "terminate"
    vpc_security_group_ids                = [aws_security_group.ecs_cluster.id]
    user_data                             = base64encode(format("#!/bin/bash\necho ECS_CLUSTER=%s >> /etc/ecs/ecs.config;echo ECS_BACKEND_HOST= >> /etc/ecs/ecs.config;", var.name))
    iam_instance_profile {
      arn = aws_iam_instance_profile.this.arn
    }

}

resource "aws_autoscaling_group" "this" {
  name                                    = format("%s_cluster", var.name)

  vpc_zone_identifier                     = var.private_subnets_id
  max_size                                = var.max_cluster_size
  min_size                                = var.min_cluster_size

  protect_from_scale_in                   = true

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }
}

resource "aws_ecs_cluster" "this" {
  name                            = var.name
}