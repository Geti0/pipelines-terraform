#!/bin/bash

# retrieve-infrastructure-data.sh
# Script to retrieve infrastructure data from AWS Parameter Store
# Usage: ./retrieve-infrastructure-data.sh

set -euo pipefail

# Configuration
PARAMETER_PREFIX="/pipelines-terraform"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to retrieve parameter from SSM
get_parameter() {
    local param_name="$1"
    local value
    
    if value=$(aws ssm get-parameter \
        --name "$param_name" \
        --query 'Parameter.Value' \
        --output text \
        --no-cli-pager 2>/dev/null); then
        echo "$value"
        return 0
    else
        log_error "Failed to retrieve parameter: $param_name"
        return 1
    fi
}

# Function to export environment variable for GitHub Actions
export_github_env() {
    local var_name="$1"
    local var_value="$2"
    
    if [[ -n "${GITHUB_ENV:-}" ]]; then
        echo "${var_name}=${var_value}" >> "$GITHUB_ENV"
        log_success "Exported to GitHub env: $var_name"
    else
        export "$var_name"="$var_value"
        log_success "Exported to shell env: $var_name"
    fi
}

main() {
    log_info "Starting infrastructure data retrieval process..."
    
    # Define parameter mappings: parameter-name -> environment-variable
    declare -A parameters=(
        ["s3-bucket-name"]="S3_BUCKET"
        ["cloudfront-distribution-id"]="CLOUDFRONT_ID"
        ["cloudfront-domain-name"]="CLOUDFRONT_DOMAIN"
        ["api-gateway-url"]="API_GATEWAY_URL"
        ["lambda-function-name"]="LAMBDA_FUNCTION_NAME"
        ["dynamodb-table-name"]="DYNAMODB_TABLE_NAME"
    )
    
    log_info "Retrieving parameters from Parameter Store..."
    
    # Retrieve and export all parameters
    local failed=false
    declare -A retrieved_values
    
    for param_suffix in "${!parameters[@]}"; do
        param_name="${PARAMETER_PREFIX}/${param_suffix}"
        env_var="${parameters[$param_suffix]}"
        
        if value=$(get_parameter "$param_name"); then
            retrieved_values["$env_var"]="$value"
            export_github_env "$env_var" "$value"
        else
            failed=true
        fi
    done
    
    if [[ "$failed" == "true" ]]; then
        log_error "Failed to retrieve some parameters"
        exit 1
    fi
    
    log_success "All infrastructure data retrieved successfully!"
    log_info "Summary of retrieved data:"
    
    for env_var in "${parameters[@]}"; do
        value="${retrieved_values[$env_var]}"
        echo "  📌 $env_var = $value"
    done
    
    log_success "Infrastructure data retrieval completed!"
}

# Run main function
main "$@"