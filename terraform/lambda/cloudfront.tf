resource "aws_cloudfront_distribution" "website_cdn" {
  origin {
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id   = "s3-website"
  }
  enabled             = true
  default_root_object = "index.html"
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-website"
    viewer_protocol_policy = "redirect-to-https"
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    response_headers_policy_id = "" # Add your response headers policy ID if available
  }
  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US"] # Example: restrict to US
    }
  }
  logging_config {
    bucket = "my-website-logs-bucket.s3.amazonaws.com" # Create this bucket for logs
    include_cookies = false
    prefix = "cloudfront-logs/"
  }
  viewer_certificate {
    acm_certificate_arn            = "arn:aws:acm:us-east-2:YOUR_ACCOUNT_ID:certificate/YOUR_CERT_ID" # Replace with your ACM cert
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2019"
  }
  web_acl_id = "arn:aws:wafv2:us-east-2:YOUR_ACCOUNT_ID:regional/webacl/YOUR_WAF_ID" # Replace with your WAF WebACL
  origin_group {
    origin_id = "origin-group-1"
    failover_criteria {
      status_codes = [403, 404, 500, 502, 503, 504]
    }
    member {
      origin_id = "s3-website"
    }
    # Add a second origin for failover if available
  }
}
