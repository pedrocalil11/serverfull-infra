variable "record" {
    type                = string
}

variable "domain" {
    type                = string
}

variable "create_ssl_certificate" {
    type                = string
}

variable "dns_zone_id" {
    type                = string
}

variable "ttl" {
    type                = number
    default             = 60
}

variable "alternative_domains" {
    type                = list(string)
    default             = []
}

variable "record_type" {
    type                = string
    default             = "CNAME"
}