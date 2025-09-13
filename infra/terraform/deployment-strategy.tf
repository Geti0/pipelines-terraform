# Deployment Strategy Configuration
# This file contains configuration to control how infrastructure changes are applied

locals {
  # Deployment strategy settings
  deployment_strategy = {
    # Set to true during major infrastructure changes
    force_recreation = false

    # Lambda deployment settings
    lambda_update_strategy = "code_only" # Options: "code_only", "config_only", "full"

    # Database protection
    protect_data_resources = true

    # API Gateway deployment
    api_gateway_auto_deploy = true
  }

  # Resource naming strategy - change version to force recreation
  resource_versions = {
    infrastructure = "v1"
    lambda         = "v1"
    database       = "v1"
    api_gateway    = "v1"
  }
}

# Output deployment strategy for other modules
output "deployment_strategy" {
  value = local.deployment_strategy
}

output "resource_versions" {
  value = local.resource_versions
}