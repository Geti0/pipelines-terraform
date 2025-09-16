# Variables for the Terraform configuration

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
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

variable "deployment_id" {
  description = "Unique deployment identifier"
  type        = string
  default     = "deploy"
}

# SSM parameter values for each module
variable "ssm_value_api_gateway" {
  description = "SSM value for API Gateway module."
  type        = string
  default     = "api-gateway-parameter-value"
}

variable "ssm_value_cloudfront" {
  description = "SSM value for CloudFront module."
  type        = string
  default     = "cloudfront-parameter-value"
}

variable "ssm_value_dynamodb" {
  description = "SSM value for DynamoDB module."
  type        = string
  default     = "dynamodb-parameter-value"
}

variable "ssm_value_iam" {
  description = "SSM value for IAM module."
  type        = string
  default     = "iam-parameter-value"
}

variable "ssm_value_lambda" {
  description = "SSM value for Lambda module."
  type        = string
  default     = "lambda-parameter-value"
}

variable "ssm_value_s3" {
  description = "SSM value for S3 module."
  type        = string
  default     = "s3-parameter-value"
}