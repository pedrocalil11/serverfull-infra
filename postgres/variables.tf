variable "name" {
    type            = string
}
variable "vpc_id" {
    type            = string
}
variable "source_security_groups" {
    type            = list(string)
    default         = []
}

variable "max_allocated_storage" {
    type            = number
}

variable "allocated_storage" {
    type            = number
}

variable "username" {
    type            = string
    sensitive       = true
}

variable "password" {
    type            = string
    sensitive       = true
}

variable "database_subnets" {
    type            = list(string)
}

variable "maintenance_window" {
    type            = string
}

variable "backup_window" {
    type            = string
}