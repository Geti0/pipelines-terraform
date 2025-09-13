# Lambda Module Variables

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "deployment_id" {
  description = "Unique deployment identifier"
  type        = string
}

variable "resource_suffix" {
  description = "Random suffix for resource naming"
  type        = string
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "DynamoDB table ARN"
  type        = string
}

variable "lambda_zip_hash" {
  description = "Lambda deployment package hash"
  type        = string
}

variable "api_gateway_execution_arn" {
  description = "API Gateway execution ARN for Lambda permission"
  type        = string
}