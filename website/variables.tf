variable "name" {
    type            = string
}

variable "environment" {
    type            = string
}

variable "domain" {
    type            = string
}

variable "alias_domain" {
    type            = string
    default         = ""
}

variable "dns_zone_id" {
    type            = string
}

variable "index_document" {
    type            = string
    default         = "index.html"
}

variable "error_document" {
    type            = string
    default         = "404.html"
}

variable "error_code" {
    type            = number
    default         = 404
}

variable "extra_variables" {
    type = map(string)
    default = {}
}
variable "gitlab_group" { 
    type = number
}
variable "gitlab_group_name" { 
    type = string
}