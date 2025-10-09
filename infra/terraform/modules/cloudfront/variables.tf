# CloudFront Module Variables

variable "s3_bucket_id" {
  description = "S3 bucket ID"
  type        = string
}

variable "s3_bucket_regional_domain_name" {
  description = "S3 bucket regional domain name"
  type        = string
}

variable "s3_bucket_website_endpoint" {
  description = "S3 bucket website endpoint"
  type        = string
}