resource "aws_ecs_task_definition" "this" {
    family                              = var.name
    container_definitions               = format("[ { \"portMappings\": [ { \"hostPort\": 0, \"protocol\": \"tcp\", \"containerPort\": ${var.container_port} } ], \"cpu\": 250, \"environment\": [], \"memory\": 250, \"image\": \"default\", \"name\": \"%s\" } ]", var.name)
    task_role_arn                       = aws_iam_role.task_role.arn
    execution_role_arn                  = var.execution_role_arn
}

resource "aws_iam_role" "task_role" {
    name                        = format("%s-iam_role", var.name)
    assume_role_policy          = file("./files/task-role-assume-role-policy.json")
}

data "aws_ecs_task_definition" "this" {
  task_definition = aws_ecs_task_definition.this.family
}
locals{
    actual_task_arn = (
        var.force_task_revision != 0
        ?
        format("%s/%s:%s", element(split("/", aws_ecs_task_definition.this.arn), 0), aws_ecs_task_definition.this.family, var.force_task_revision)
        :
        data.aws_ecs_task_definition.this.revision >= aws_ecs_task_definition.this.revision
        ?
        format("%s/%s:%s", element(split("/", aws_ecs_task_definition.this.arn), 0), aws_ecs_task_definition.this.family, data.aws_ecs_task_definition.this.revision)
        :
        aws_ecs_task_definition.this.arn
    )
}

resource "aws_ecs_service" "this" {
    name                                = var.name
    cluster                             = var.ecs_cluster_arn
    desired_count                       = var.desired_count
    deployment_minimum_healthy_percent  = 75
    task_definition                     = local.actual_task_arn

    load_balancer {
        target_group_arn        = aws_lb_target_group.this.arn
        container_name          = var.name
        container_port          = var.container_port
    }

    ordered_placement_strategy {
        type                    = "binpack"
        field                   = "memory"
    }
    ordered_placement_strategy {
        type                    = "spread"
        field                   = "attribute:ecs.availability-zone"
    }
}

resource "aws_cloudwatch_log_group" "this" {
    name                            = format("/ecs/%s", var.name)
    retention_in_days               = var.log_rentention_days
    tags                            = {
        application = format("ecs-%s", var.name)
    }
}

resource "aws_ecr_repository" "this" {
    name                        = format("%s_repository", var.name)
    image_scanning_configuration {
        scan_on_push = true
    }
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keeps only the last 10 images",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                "countNumber": 10
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}