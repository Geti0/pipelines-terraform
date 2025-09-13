# Local values for computed and reused expressions

locals {
  # Common tags applied to all resources
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Repository  = "pipelines-terraform"
  }

  # Naming conventions
  resource_prefix = "${var.project_name}-${var.deployment_id}"

  # API Gateway URL construction
  api_gateway_url = "https://${module.api_gateway.rest_api_id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.prod.stage_name}/contact"
}