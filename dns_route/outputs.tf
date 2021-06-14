output "certificate_arn" {
    value = var.create_ssl_certificate ? aws_acm_certificate.this.0.arn : ""
}