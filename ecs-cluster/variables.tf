variable "name" {
    type = string
}

variable "vpc_id" {
    type = string
}

variable "public_subnets_id" {
  description = "A list of public subnets inside the VPC"
  type        = list(string)
}

variable "private_subnets_id" {
  description = "A list of public subnets inside the VPC"
  type        = list(string)
}

variable "private_subnets_cidr" {
  description = "A list of cidr blocks of private subnets inside the VPC"
  type        = list(string)
}

variable "instance_type" {
    type = string
}
variable "max_cluster_size" {
    type = number
}
variable "min_cluster_size" {
    type = number
}

variable "public_alb_ssl_certificate_arn" {
  type = string
}