#!/bin/bash

# store-infrastructure-outputs.sh
# Script to extract Terraform outputs and store them in AWS Parameter Store
# Usage: ./store-infrastructure-outputs.sh [terraform-directory]

set -euo pipefail

# Configuration
TERRAFORM_DIR="${1:-./infra/terraform}"
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

# Function to extract terraform output with error handling
get_terraform_output() {
    local output_name="$1"
    local value
    
    if value=$(terraform -chdir="$TERRAFORM_DIR" output -raw "$output_name" 2>/dev/null); then
        echo "$value"
        return 0
    else
        log_error "Failed to get output: $output_name"
        return 1
    fi
}

# Function to store parameter in SSM
store_parameter() {
    local param_name="$1"
    local param_value="$2"
    
    if aws ssm put-parameter \
        --name "$param_name" \
        --value "$param_value" \
        --type "String" \
        --overwrite \
        --no-cli-pager >/dev/null 2>&1; then
        log_success "Stored parameter: $param_name"
        return 0
    else
        log_error "Failed to store parameter: $param_name"
        return 1
    fi
}

main() {
    log_info "Starting infrastructure outputs storage process..."
    
    # Change to terraform directory if it exists
    if [[ ! -d "$TERRAFORM_DIR" ]]; then
        log_error "Terraform directory not found: $TERRAFORM_DIR"
        exit 1
    fi
    
    # Define outputs to extract
    declare -A outputs=(
        ["s3_bucket_name"]="s3-bucket-name"
        ["cloudfront_distribution_id"]="cloudfront-distribution-id"
        ["cloudfront_domain_name"]="cloudfront-domain-name"
        ["api_gateway_url"]="api-gateway-url"
        ["lambda_function_name"]="lambda-function-name"
        ["dynamodb_table_name"]="dynamodb-table-name"
    )
    
    log_info "Extracting Terraform outputs..."
    
    # Extract and validate all outputs
    declare -A extracted_outputs
    local failed=false
    
    for terraform_output in "${!outputs[@]}"; do
        if value=$(get_terraform_output "$terraform_output"); then
            extracted_outputs["$terraform_output"]="$value"
            log_success "Extracted $terraform_output: $value"
        else
            failed=true
        fi
    done
    
    if [[ "$failed" == "true" ]]; then
        log_error "Failed to extract some outputs. Showing all available outputs:"
        terraform -chdir="$TERRAFORM_DIR" output
        exit 1
    fi
    
    log_info "Storing outputs in Parameter Store..."
    
    # Store all outputs in Parameter Store
    for terraform_output in "${!outputs[@]}"; do
        param_name="${PARAMETER_PREFIX}/${outputs[$terraform_output]}"
        param_value="${extracted_outputs[$terraform_output]}"
        
        if ! store_parameter "$param_name" "$param_value"; then
            failed=true
        fi
    done
    
    if [[ "$failed" == "true" ]]; then
        log_error "Failed to store some parameters"
        exit 1
    fi
    
    log_success "All infrastructure outputs stored successfully!"
    log_info "Summary of stored parameters:"
    
    for terraform_output in "${!outputs[@]}"; do
        param_name="${PARAMETER_PREFIX}/${outputs[$terraform_output]}"
        param_value="${extracted_outputs[$terraform_output]}"
        echo "  📌 $param_name = $param_value"
    done
    
    log_success "Infrastructure outputs storage completed!"
}

# Run main function
main "$@"