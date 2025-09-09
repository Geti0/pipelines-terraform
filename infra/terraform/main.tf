# Main Terraform configuration for AWS CI/CD Assignment

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

# Data source for current AWS region
data "aws_region" "current" {}

provider "aws" {
  region = var.aws_region
}

# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "pipelines-terraform"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

# S3 bucket for website hosting
resource "aws_s3_bucket" "website" {
  bucket = "${var.project_name}-website-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "${var.project_name}-website"
    Environment = var.environment
  }
}

# Enable S3 bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "website_encryption" {
  bucket = aws_s3_bucket.website.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "website_pab" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "website_policy" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website.arn}/*"
      },
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.website_pab]
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "website_cdn" {
  origin {
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id   = "s3-${aws_s3_bucket.website.id}"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  # Add custom response headers policy
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-${aws_s3_bucket.website.id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"

    # Associate the response headers policy
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers.id
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

# CloudFront security headers policy
resource "aws_cloudfront_response_headers_policy" "security_headers" {
  name = "${var.project_name}-security-headers"

  security_headers_config {
    content_type_options {
      override = true
    }
    frame_options {
      frame_option = "DENY"
      override     = true
    }
    referrer_policy {
      referrer_policy = "same-origin"
      override        = true
    }
    xss_protection {
      mode_block = true
      protection = true
      override   = true
    }
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }
  }
}

# DynamoDB Table
resource "aws_dynamodb_table" "contact_submissions" {
  name         = "${var.project_name}-contact-submissions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  # Enable point-in-time recovery
  point_in_time_recovery {
    enabled = true
  }

  # Enable server-side encryption
  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = "${var.project_name}-contact-submissions"
    Environment = var.environment
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "${var.project_name}-lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Attach X-Ray permissions
resource "aws_iam_role_policy_attachment" "lambda_xray_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

resource "aws_iam_role_policy" "lambda_dynamodb_policy" {
  name = "${var.project_name}-lambda-dynamodb-policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:Query"
        ]
        Resource = aws_dynamodb_table.contact_submissions.arn
      }
    ]
  })
}

# Lambda Function
resource "aws_lambda_function" "contact_form" {
  filename         = "lambda_function.zip"
  function_name    = "${var.project_name}-contact-form"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  # Enable X-Ray tracing
  tracing_config {
    mode = "Active"
  }

  # Add timeout configuration
  timeout     = 10  # 10 seconds
  memory_size = 256 # 256 MB

  # Reserved concurrency removed due to AWS account limits
  # reserved_concurrent_executions = 10

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.contact_submissions.name
    }
  }
}

# Lambda deployment package
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "lambda_function.zip"
  source_dir  = "../../web/lambda"
}

# API Gateway
resource "aws_api_gateway_rest_api" "contact_api" {
  name        = "${var.project_name}-contact-api"
  description = "API for contact form submissions"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Add request validator for API Gateway
resource "aws_api_gateway_request_validator" "contact_validator" {
  name                        = "${var.project_name}-contact-validator"
  rest_api_id                 = aws_api_gateway_rest_api.contact_api.id
  validate_request_body       = true
  validate_request_parameters = true
}

resource "aws_api_gateway_resource" "contact" {
  rest_api_id = aws_api_gateway_rest_api.contact_api.id
  parent_id   = aws_api_gateway_rest_api.contact_api.root_resource_id
  path_part   = "contact"
}

resource "aws_api_gateway_method" "post_contact" {
  rest_api_id   = aws_api_gateway_rest_api.contact_api.id
  resource_id   = aws_api_gateway_resource.contact.id
  http_method   = "POST"
  authorization = "NONE"

  request_parameters = {
    "method.request.header.Content-Type" = true
  }

  # Add request validation
  request_validator_id = aws_api_gateway_request_validator.contact_validator.id
}

# Enable CORS
resource "aws_api_gateway_method" "options_contact" {
  rest_api_id   = aws_api_gateway_rest_api.contact_api.id
  resource_id   = aws_api_gateway_resource.contact.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_contact" {
  rest_api_id = aws_api_gateway_rest_api.contact_api.id
  resource_id = aws_api_gateway_resource.contact.id
  http_method = aws_api_gateway_method.options_contact.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_contact" {
  rest_api_id = aws_api_gateway_rest_api.contact_api.id
  resource_id = aws_api_gateway_resource.contact.id
  http_method = aws_api_gateway_method.options_contact.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options_contact" {
  rest_api_id = aws_api_gateway_rest_api.contact_api.id
  resource_id = aws_api_gateway_resource.contact.id
  http_method = aws_api_gateway_method.options_contact.http_method
  status_code = aws_api_gateway_method_response.options_contact.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# Lambda Integration
resource "aws_api_gateway_integration" "lambda_contact" {
  rest_api_id = aws_api_gateway_rest_api.contact_api.id
  resource_id = aws_api_gateway_resource.contact.id
  http_method = aws_api_gateway_method.post_contact.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.contact_form.invoke_arn
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.contact_form.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.contact_api.execution_arn}/*/*"
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "contact_deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_contact,
    aws_api_gateway_integration.options_contact,
  ]

  rest_api_id = aws_api_gateway_rest_api.contact_api.id

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage
resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.contact_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.contact_api.id
  stage_name    = "prod"

  # Enable X-Ray tracing for API Gateway
  xray_tracing_enabled = true
}

# Outputs
output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.website.id
}

output "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID"
  value       = aws_cloudfront_distribution.website_cdn.id
}

output "cloudfront_domain_name" {
  description = "CloudFront Distribution Domain Name"
  value       = aws_cloudfront_distribution.website_cdn.domain_name
}

output "api_gateway_url" {
  description = "API Gateway URL"
  value       = "https://${aws_api_gateway_rest_api.contact_api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${aws_api_gateway_stage.prod.stage_name}/contact"
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.contact_submissions.name
}
