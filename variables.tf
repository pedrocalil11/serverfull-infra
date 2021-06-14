variable "database_username" {
    type = string
    sensitive   = true
}

variable "database_password" { 
    type = string
    sensitive   = true
}

variable "environment" { 
    type = string
}

variable "gitlab_token" { 
    type = string
    sensitive   = true
}

variable "gitlab_group" { 
    type = number
}

variable "domain_name" { 
    type = string
}
