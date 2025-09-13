# Output values for the Terraform infrastructure

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.s3.bucket_id
}

output "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID"
  value       = module.cloudfront.distribution_id
}

output "cloudfront_domain_name" {
  description = "CloudFront Distribution Domain Name"
  value       = module.cloudfront.domain_name
}

output "api_gateway_url" {
  description = "API Gateway URL"
  value       = local.api_gateway_url
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = module.dynamodb.table_name
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = module.lambda.function_name
}

output "pipeline_parameter_store_policy_arn" {
  description = "ARN of the Parameter Store policy for CI/CD pipelines"
  value       = module.iam.pipeline_parameter_store_policy_arn
}