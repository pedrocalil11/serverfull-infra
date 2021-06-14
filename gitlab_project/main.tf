terraform {
    required_providers {
      gitlab = {
          source = "gitlabhq/gitlab"
          version = "3.6.0"
      }
    }
}

resource "gitlab_project" "this" {
    count                                       = var.environment == "production" ? 1 : 0
    name                                        = var.name
    merge_requests_enabled                      = true
    pipelines_enabled                           = true
    visibility_level                            = "private"
    only_allow_merge_if_pipeline_succeeds       = true
    initialize_with_readme                      = true
    namespace_id                                = var.gitlab_group
    shared_runners_enabled                      = true
}

data "gitlab_project" "this" {
    count       = var.environment == "production" ? 0 : 1
    id          = format("%s/%s", var.gitlab_group_name, var.name)
}

resource "gitlab_branch_protection" "main" {
    count                               = var.environment == "production" ? 1 : 0
    project                             = gitlab_project.this.0.id
    branch                              = "main"
    push_access_level                   = "developer"
    merge_access_level                  = "developer"
}

resource "gitlab_branch_protection" "release" {
    count                               = var.environment == "production" ? 1 : 0
    project                             = gitlab_project.this.0.id
    branch                              = "release"
    push_access_level                   = "developer"
    merge_access_level                  = "developer"
}

######DIDNT LIKE THIS THING HERE... SHOULD HAVE USED FOR EACH BUT ENVIRONNMENT VARIABLES IS SENSITIVE AND IT CRASHES
resource "gitlab_project_variable" "this" {
    count                       = length(keys(var.environment_variables))
    project                     = var.environment == "production" ? gitlab_project.this.0.id : data.gitlab_project.this.0.id
    key                         = element(keys(var.environment_variables), count.index)
    value                       = var.environment_variables[element(keys(var.environment_variables), count.index)]
}

resource "gitlab_project_variable" "docker_host_address" {
    count                       = var.environment == "production" ? 1 : 0 
    project                     = var.environment == "production" ? gitlab_project.this.0.id : 0
    key                         = "DOCKER_HOST_ADDRESS"
    value                       = "docker"
}