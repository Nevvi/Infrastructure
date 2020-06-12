data "aws_caller_identity" "current" {}

data "template_file" "bucket_policy" {
  template = "${file("${path.module}/bucket_policy.json")}"
  vars = {
    origin_access_identity_arn = aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn
    bucket = "${var.site_name}-source"
    account_arn = data.aws_caller_identity.current.arn
  }
}

resource "aws_s3_bucket" "site_logs" {
  bucket = "${var.site_name}-site-logs"
  acl = "log-delivery-write"
}

resource "aws_s3_bucket_public_access_block" "site_logs_public_block" {
  bucket = aws_s3_bucket.site_logs.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "site" {
  bucket = "${var.site_name}-source"
  policy = data.template_file.bucket_policy.rendered
}

resource "aws_s3_bucket_public_access_block" "site_public_block" {
  bucket = aws_s3_bucket.site.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "${var.environment} cloudfront origin access identity"
}

// Create this manually
data "aws_acm_certificate" "site_cert" {
  domain   = var.site_cert_name
  statuses = ["ISSUED"]
}

resource "aws_cloudfront_distribution" "website_cdn" {
  enabled      = true
  price_class  = "PriceClass_100"
  aliases = var.cloudfront_cname_aliases
  is_ipv6_enabled     = true

  origin {
    origin_id   = "S3-${aws_s3_bucket.site.id}"
    domain_name = aws_s3_bucket.site.bucket_domain_name

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  origin {
    origin_id   = "apigw"
    domain_name = var.backend_domain

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_root_object = "index.html"

  custom_error_response {
    error_caching_min_ttl = 300
    error_code = 403
    response_code = 200
    response_page_path = "/index.html"
  }

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.site_logs.bucket_domain_name
  }

  default_cache_behavior {
    allowed_methods = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods  = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.site.id}"

    min_ttl          = "0"
    default_ttl      = "300"                                              //3600
    max_ttl          = "1200"                                             //86400

    // This redirects any HTTP request to HTTPS. Security first!
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  ordered_cache_behavior {
    path_pattern     = "/api/*"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "apigw"

    default_ttl = 0
    min_ttl     = 0
    max_ttl     = 0

    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
    }

    // Hardcoded for now to point to manually created lambda that maps api.nevvi.net/api/* -> api.nevvi.net/*
    lambda_function_association {
      event_type   = "origin-request"
      include_body = true
      lambda_arn   = "arn:aws:lambda:us-east-1:275527036335:function:cloudfront-request:5"
    }

    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = data.aws_acm_certificate.site_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2018"
  }

}

data "aws_route53_zone" "site" {
  name         = var.site_zone
}

resource "aws_route53_record" "site" {
  zone_id = data.aws_route53_zone.site.zone_id
  name = var.site_name
  type = "A"
  alias {
    name = aws_cloudfront_distribution.website_cdn.domain_name
    zone_id  = aws_cloudfront_distribution.website_cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_site" {
  count = var.create_www_alias ? 1 : 0
  zone_id = data.aws_route53_zone.site.zone_id
  name = "www.${var.site_name}"
  type = "A"
  alias {
    name = aws_cloudfront_distribution.website_cdn.domain_name
    zone_id  = aws_cloudfront_distribution.website_cdn.hosted_zone_id
    evaluate_target_health = false
  }
}