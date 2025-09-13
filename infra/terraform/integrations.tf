# API Gateway Lambda Integration and Deployment
# This file handles the integration between API Gateway and Lambda
# Created separately to avoid circular dependency between modules

# Lambda Integration
resource "aws_api_gateway_integration" "lambda_contact" {
  rest_api_id = module.api_gateway.rest_api_id
  resource_id = module.api_gateway.contact_resource_id
  http_method = "POST"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.lambda.invoke_arn
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "contact_deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_contact,
  ]

  rest_api_id = module.api_gateway.rest_api_id

  # Prevent recreation unless API structure actually changes
  triggers = {
    redeployment = sha1(jsonencode([
      module.api_gateway.rest_api_id,
      module.api_gateway.contact_resource_id,
      aws_api_gateway_integration.lambda_contact.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage
resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.contact_deployment.id
  rest_api_id   = module.api_gateway.rest_api_id
  stage_name    = "prod"

  # Enable X-Ray tracing for API Gateway
  xray_tracing_enabled = true
}