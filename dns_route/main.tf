resource "aws_acm_certificate" "this" {
  count                       = var.create_ssl_certificate ? 1 : 0
  domain_name                 = var.domain
  subject_alternative_names   = var.alternative_domains
  validation_method           = "DNS"
}

resource "aws_acm_certificate_validation" "cert" {
  count                     = var.create_ssl_certificate ? 1 : 0
  certificate_arn           = aws_acm_certificate.this.0.arn
  validation_record_fqdns   = aws_route53_record.validation_record.*.fqdn
  depends_on = [ aws_route53_record.validation_record ]
}

resource "aws_route53_record" "this" {
  name        = var.domain
  type        = var.record_type
  zone_id     = var.dns_zone_id
  records     = [ var.record ]
  ttl         = var.ttl
}

resource "aws_route53_record" "validation_record" {
  count     = var.create_ssl_certificate ? length(var.alternative_domains) + 1 : 0
  allow_overwrite = true 
  name      = element(aws_acm_certificate.this.0.domain_validation_options.*.resource_record_name, count.index)
  type      = element(aws_acm_certificate.this.0.domain_validation_options.*.resource_record_type, count.index)
  zone_id   = var.dns_zone_id
  records   = [ element(aws_acm_certificate.this.0.domain_validation_options.*.resource_record_value, count.index) ]
  ttl       = 60
}