# CloudFront Module Outputs

output "distribution_id" {
  description = "CloudFront Distribution ID"
  value       = aws_cloudfront_distribution.website_cdn.id
}

output "domain_name" {
  description = "CloudFront Distribution Domain Name"
  value       = aws_cloudfront_distribution.website_cdn.domain_name
}