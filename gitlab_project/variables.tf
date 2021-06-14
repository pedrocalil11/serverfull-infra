variable "name" {
    type = string
}
 variable "environment" {
    type            = string
}
variable "environment_variables" {
    type            = map(string)
    default         = {}
}
variable "gitlab_group" { 
    type = number
}
 variable "gitlab_group_name"{
     type = string
 }