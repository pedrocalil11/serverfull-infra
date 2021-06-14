provider "aws" {
    region     = "us-east-1"
}
provider "gitlab" {
    token = var.gitlab_token
}
terraform {
    required_providers {
      aws = {
        version = "3.0.0"
      }

      gitlab = {
          source = "gitlabhq/gitlab"
          version = "3.6.0"
      }
    }
}
locals {
    gitlab_group                            = var.gitlab_group
    gitlab_group_name                       = "sample"
    vpc_cidr                                = "10.0.0.0/16"
    database_subnets                        = ["10.0.200.0/24",   "10.0.201.0/24"]
    private_subnets                         = ["10.0.1.0/24",     "10.0.2.0/24",    "10.0.3.0/24"]
    public_subnets                          = ["10.0.101.0/24",   "10.0.102.0/24",  "10.0.103.0/24"]
    azs                                     = ["us-east-1a",      "us-east-1b",     "us-east-1c"]
}

module "base_vpc" {
    source                                  = "./network"
    name                                    = "sample-vpc"
    cidr                                    = local.vpc_cidr

    database_subnets                        = local.database_subnets
    private_subnets                         = local.private_subnets
    public_subnets                          = local.public_subnets
    azs                                     = local.azs
}

data "aws_route53_zone" "public" {
  name                  = var.domain_name
  private_zone          = false
}

module "public_alb_route" {
  source                            = "./dns_route"
  domain                            = format("api.%s", var.domain_name)
  create_ssl_certificate            = true
  record                            = module.ecs_cluster.public_alb_url
  dns_zone_id                       = data.aws_route53_zone.public.id
}

module "ecs_cluster" {
    source                                  = "./ecs-cluster"
    name                                    = "sample"
    vpc_id                                  = module.base_vpc.vpc_id
    public_subnets_id                       = module.base_vpc.public_subnets_id
    private_subnets_id                      = module.base_vpc.public_subnets_id
    private_subnets_cidr                    = local.public_subnets
    instance_type                           = "t3.micro"
    max_cluster_size                        = 0
    min_cluster_size                        = 0
    public_alb_ssl_certificate_arn          = module.public_alb_route.certificate_arn
}

module "external-api" {
    source                                  = "./ecs-service"
    name                                    = "cattle-batches-api"
    ecs_cluster_arn                         = module.ecs_cluster.cluster_arn
    execution_role_arn                      = module.ecs_cluster.execution_role_arn
    desired_count                           = 0
    log_rentention_days                     = 5
    health_check_grace_period_seconds       = 300
    environment                             = var.environment
    vpc_id                                  = module.base_vpc.vpc_id
    public_alb_listener_arn                 = module.ecs_cluster.public_alb_default_listener_arn

    gitlab_group                            = local.gitlab_group
    gitlab_group_name                       = local.gitlab_group_name

    providers = {
        gitlab = gitlab
    }
}

module "postgres" {
    source                                  = "./postgres"
    name                                    = "sample"
    vpc_id                                  = module.base_vpc.vpc_id
    username                                = var.database_username
    password                                = var.database_password
    max_allocated_storage                   = 30
    allocated_storage                       = 20
    maintenance_window                      = "Mon:00:00-Mon:03:00"
    backup_window                           = "03:00-03:30"
    database_subnets                        = module.base_vpc.public_subnets
    source_security_groups                  = [module.ecs_cluster.security_group_id]
}   

module "site" {
    source                          = "./website"
    name                            = "sample-website"
    environment                     = var.environment
    dns_zone_id                     = data.aws_route53_zone.public.id
    domain                          = format("www.%s", var.domain_name)
    alias_domain                    = var.domain_name

    gitlab_group                    = local.gitlab_group
    gitlab_group_name               = local.gitlab_group_name

    providers = {
        gitlab = gitlab
    }
}
