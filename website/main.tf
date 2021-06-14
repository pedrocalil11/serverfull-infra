terraform {
    required_providers {
      gitlab = {
          source = "gitlabhq/gitlab"
          version = "3.6.0"
      }
    }
}

locals {
    bucket_name = format("%s-%s", var.environment, var.name)
}

data "aws_region" "current" {}
############################
#######CI USER CONFIG#######
############################
resource "aws_iam_user" "ci_user" {
    name                        = format("%s-ci-user", var.name)
}

resource "aws_iam_access_key" "ci_user" {
    user                        = aws_iam_user.ci_user.name
}

resource "aws_iam_user_policy" "ci_user" {
  name = "S3DeployPolicy"
  user = aws_iam_user.ci_user.name

  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "DeployAccess",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:PutObjectAcl"
            ],
            "Resource": [
                "arn:aws:s3:::${local.bucket_name}/*"
            ]
        },
        {
            "Sid": "DeployAccessBucket",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketLocation"
            ],
            "Resource": [
                "arn:aws:s3:::${local.bucket_name}"
            ]
        }
    ]
}
EOF
}
############################
####### DISTRIBUTION #######
############################
resource "aws_s3_bucket" "this" {
  bucket                    = local.bucket_name
  acl                       = "public-read"
  policy                    = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "PublicReadForGetBucketObjects",
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${local.bucket_name}/*"
        }
    ]
}
EOF

  force_destroy             = true

  website {
      index_document        = var.index_document   
      error_document        = var.error_document
  }

  tags                      = { "Name" = format("%s", local.bucket_name) }
}

resource "aws_cloudfront_distribution" "this" {
  origin {
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }

    origin_id                                   = "origin-${var.domain}"
    domain_name                                 = aws_s3_bucket.this.website_endpoint
  }

  enabled                                       = true
  is_ipv6_enabled                               = true
  default_root_object                           = var.index_document

  custom_error_response {
    error_code                                  = 404
    error_caching_min_ttl                       = 60
    response_code                               = var.error_code
    response_page_path                          = "/${var.error_document}"
  }

  aliases                                       = var.alias_domain == "" ? [ var.domain ] : [ var.domain, var.alias_domain ]
  price_class                                   = var.environment == "production" ? "PriceClass_All" : "PriceClass_100"

  default_cache_behavior {
    target_origin_id                            = "origin-${var.domain}"
    allowed_methods                             = ["GET", "HEAD"]
    cached_methods                              = ["GET", "HEAD"]
    compress                                    = true

    forwarded_values {
      query_string                              = false
      cookies {
        forward                                 = "none"
      }
    }

    viewer_protocol_policy                      = "redirect-to-https"
    min_ttl                                     = 60
    default_ttl                                 = 300
    max_ttl                                     = 3600
  }

  restrictions {
    geo_restriction {
      restriction_type                          = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn                         = module.dns_route.certificate_arn
    ssl_support_method                          = "sni-only"
    minimum_protocol_version                    = "TLSv1.1_2016"
  }

  depends_on = [aws_s3_bucket.this]
}
############################
#######  DNS CONFIG  #######
############################
module "dns_route" {
    source                                  = "../dns_route"
    domain                                  = var.domain
    create_ssl_certificate                  = true
    record                                  = aws_cloudfront_distribution.this.domain_name
    dns_zone_id                             = var.dns_zone_id
    ttl                                     = 300
    alternative_domains                     = var.alias_domain == "" ? [] : [ var.alias_domain ]
}

resource "aws_route53_record" "alias" {
    count                                   = var.alias_domain == "" ? 0 : 1
    name                                    = var.alias_domain
    type                                    = "A"
    zone_id                                 = var.dns_zone_id
    
    alias {
      name = aws_cloudfront_distribution.this.domain_name
      zone_id = aws_cloudfront_distribution.this.hosted_zone_id
      evaluate_target_health = false
    }
}
############################
#######    GITLAB    #######
############################
module "gitlab_project" {
    source                      = "../gitlab_project"
    name                        = var.name
    environment                 = var.environment

    environment_variables       = merge(tomap({
        format("%s_SERVICE_NAME", upper(var.environment))           = "${var.name}"
        format("%s_AWS_REGION", upper(var.environment))             = "${data.aws_region.current.name}"
        format("%s_AWS_ACCESS_KEY_ID", upper(var.environment))      = "${aws_iam_access_key.ci_user.id}"
        format("%s_AWS_SECRET_ACCESS_KEY", upper(var.environment))  = "${aws_iam_access_key.ci_user.secret}"
        format("%s_BUCKET_NAME", upper(var.environment))            = "${aws_s3_bucket.this.id}"
    }), var.extra_variables)

    gitlab_group                = var.gitlab_group
    gitlab_group_name           = var.gitlab_group_name

    providers = {
        gitlab = gitlab
    }
}