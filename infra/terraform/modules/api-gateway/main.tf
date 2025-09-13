# API Gateway resources for contact form API

resource "aws_api_gateway_rest_api" "contact_api" {
  name        = "${var.project_name}-${var.deployment_id}-contact-api-${var.resource_suffix}"
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
  name                        = "${var.project_name}-${var.deployment_id}-contact-validator-${var.resource_suffix}"
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

# Add POST method response for CORS
resource "aws_api_gateway_method_response" "post_contact" {
  rest_api_id = aws_api_gateway_rest_api.contact_api.id
  resource_id = aws_api_gateway_resource.contact.id
  http_method = aws_api_gateway_method.post_contact.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
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
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# Lambda Integration will be created separately to avoid circular dependency

# API Gateway Deployment will be created separately after Lambda integration