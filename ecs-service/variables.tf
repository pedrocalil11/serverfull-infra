variable "name" {
    type = string
}

variable "vpc_id" {
    type = string
}

variable "extra_variables" {
    type = map(string)
    default = {}
}

variable "environment" {
    type = string
}

variable "log_rentention_days" {
    type = number
}

variable "ecs_cluster_arn" {
    type = string
}

variable "desired_count" {
    type = number
}

variable "health_check_grace_period_seconds" {
    type = number
}

variable "execution_role_arn" {
    type = string
}
variable "gitlab_group" { 
    type = number
}
variable "gitlab_group_name"{
    type = string
}
variable "force_task_revision" {
    type = number
    default = 0
}

variable "public_alb_listener_arn"{
    type = string
}

variable "container_port"{
    type = number
    default = 3000
}