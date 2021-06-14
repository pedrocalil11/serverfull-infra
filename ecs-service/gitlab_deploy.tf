terraform {
    required_providers {
      gitlab = {
          source = "gitlabhq/gitlab"
          version = "3.6.0"
      }
    }
}

##### Creating CI User #######
resource "aws_iam_user" "ci_user" {
    name                        = format("%s-ci-user", var.name)
}

resource "aws_iam_access_key" "ci_user" {
    user                        = aws_iam_user.ci_user.name
}

resource "aws_iam_user_policy" "this" {
    name                    = format("%s_policy", var.name)
    user                    = aws_iam_user.ci_user.name
    policy                  = data.aws_iam_policy_document.this.json
}

data "aws_iam_policy_document" "this" {
    statement {
        sid                     = "1"
        effect                  = "Allow"
        actions                 = [ "ecs:UpdateService" ]
        resources               = [ aws_ecs_service.this.id ]
    }

    statement {
        sid                     = "2"
        effect                  = "Allow"
        actions                 = [ "ecr:GetAuthorizationToken" ]
        resources               = [ "*" ]
    }

    statement {
        sid                     = "3"
        effect                  = "Allow"
        actions                 = [ "iam:PassRole" ]
        resources               = [ aws_iam_role.task_role.arn, var.execution_role_arn ]
    }

    statement {
        sid                     = "4"
        effect                  = "Allow"
        actions = [
            "ecr:CompleteLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:InitiateLayerUpload",
            "ecr:BatchCheckLayerAvailability",
            "ecr:PutImage"
        ]
        resources               = [ aws_ecr_repository.this.arn ]
    }

    statement {
        sid                     = "5"
        effect                  = "Allow"
        actions                 = ["ecs:RegisterTaskDefinition"]
        resources               = [ "*" ]
    }
}

data "aws_region" "current" {}
module "gitlab_project" {
    source                      = "../gitlab_project"
    name                        = var.name
    environment                 = var.environment

    environment_variables       = merge(tomap({
        format("%s_SERVICE_NAME", upper(var.environment))           = "${var.name}"
        format("%s_AWS_REGION", upper(var.environment))             = "${data.aws_region.current.name}"
        format("%s_AWS_ACCESS_KEY_ID", upper(var.environment))      = "${aws_iam_access_key.ci_user.id}"
        format("%s_AWS_SECRET_ACCESS_KEY", upper(var.environment))  = "${aws_iam_access_key.ci_user.secret}"
        format("%s_AWS_REGISTRY_IMAGE", upper(var.environment))     = "${aws_ecr_repository.this.repository_url}"
        format("%s_EXECUTION_ROLE_ARN", upper(var.environment))     = "${var.execution_role_arn}"
        format("%s_TASK_ROLE_ARN", upper(var.environment))          = "${aws_iam_role.task_role.arn}"
        format("%s_CLOUDWATCH_LOG_GROUP", upper(var.environment))   = "${aws_cloudwatch_log_group.this.name}"
        format("%s_SERVICE_CLUSTER_ARN", upper(var.environment))    = "${var.ecs_cluster_arn}"
    }), var.extra_variables)

    gitlab_group                = var.gitlab_group
    gitlab_group_name           = var.gitlab_group_name

    providers = {
        gitlab = gitlab
    }
}