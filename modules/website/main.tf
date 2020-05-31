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

  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.site_logs.bucket_domain_name
  }

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD", "POST", "PUT", "PATCH", "DELETE"]
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