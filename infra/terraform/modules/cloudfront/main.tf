# CloudFront distribution for website CDN

resource "aws_cloudfront_distribution" "website_cdn" {
  origin {
    domain_name = var.s3_bucket_regional_domain_name
    origin_id   = "s3-${var.s3_bucket_id}"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  # Add custom response headers policy
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-${var.s3_bucket_id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"

    # Associate the response headers policy
    response_headers_policy_id = "67f7725c-6f97-4210-82d7-5512b31e9d03" # AWS Managed SecurityHeadersPolicy
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }
}