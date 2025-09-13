# Local values for computed and reused expressions

locals {
  # API Gateway URL construction
  api_gateway_url = "https://${module.api_gateway.rest_api_id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.prod.stage_name}/contact"
}