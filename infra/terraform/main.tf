# Main Terraform configuration for AWS CI/CD Assignment.
# Shared Resources Module.
module "shared" {
  source = "./shared"
}

# S3 Module
module "s3" {
  source = "./modules/s3"

  project_name  = var.project_name
  environment   = var.environment
  bucket_suffix = module.shared.bucket_suffix
  ssm_value     = var.ssm_value_s3
}

# CloudFront Module
module "cloudfront" {
  source = "./modules/cloudfront"

  s3_bucket_id                   = module.s3.bucket_id
  s3_bucket_regional_domain_name = module.s3.bucket_regional_domain_name
  ssm_value                      = var.ssm_value_cloudfront
}

# DynamoDB Module
module "dynamodb" {
  source = "./modules/dynamodb"

  project_name    = var.project_name
  deployment_id   = var.deployment_id
  environment     = var.environment
  resource_suffix = module.shared.resource_suffix
  ssm_value       = var.ssm_value_dynamodb
}

# API Gateway Module (created before Lambda to avoid circular dependency)
module "api_gateway" {
  source = "./modules/api-gateway"

  project_name    = var.project_name
  deployment_id   = var.deployment_id
  resource_suffix = module.shared.resource_suffix
  aws_region      = var.aws_region
  ssm_value       = var.ssm_value_api_gateway
}

# Lambda Module (references API Gateway execution ARN)
module "lambda" {
  source = "./modules/lambda"

  project_name              = var.project_name
  deployment_id             = var.deployment_id
  resource_suffix           = module.shared.resource_suffix
  dynamodb_table_name       = module.dynamodb.table_name
  dynamodb_table_arn        = module.dynamodb.table_arn
  lambda_zip_hash           = data.archive_file.lambda_zip.output_base64sha256
  api_gateway_execution_arn = module.api_gateway.execution_arn
  ssm_value                 = var.ssm_value_lambda
}

# IAM Module
module "iam" {
  source = "./modules/iam"

  project_name    = var.project_name
  deployment_id   = var.deployment_id
  environment     = var.environment
  resource_suffix = module.shared.resource_suffix
  aws_region      = var.aws_region
  account_id      = data.aws_caller_identity.current.account_id
  ssm_value       = var.ssm_value_iam
}
