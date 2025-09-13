# API Gateway Module Outputs

output "rest_api_id" {
  description = "API Gateway REST API ID"
  value       = aws_api_gateway_rest_api.contact_api.id
}

output "execution_arn" {
  description = "API Gateway execution ARN"
  value       = aws_api_gateway_rest_api.contact_api.execution_arn
}

output "contact_resource_id" {
  description = "API Gateway contact resource ID"
  value       = aws_api_gateway_resource.contact.id
}