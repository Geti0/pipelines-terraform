#!/bin/bash

# store-infrastructure-outputs.sh
# Script to extract Terraform outputs and store them in AWS Parameter Store
# Usage: ./store-infrastructure-outputs.sh [terraform-directory]

set -euo pipefail

# Configuration
TERRAFORM_DIR="${1:-./infra/terraform}"
PARAMETER_PREFIX="/pipelines-terraform"

# Robust path resolution for TERRAFORM_DIR
if [[ ! -d "$TERRAFORM_DIR" ]]; then
    # Try from repository root
    TERRAFORM_DIR="$(pwd)/infra/terraform"
    if [[ ! -d "$TERRAFORM_DIR" ]]; then
        # Try going up directories to find the right path
        for i in {1..3}; do
            test_dir="../"
            for j in $(seq 1 $i); do
                test_dir="../$test_dir"
            done
            test_dir="${test_dir}infra/terraform"
            if [[ -d "$test_dir" ]]; then
                TERRAFORM_DIR="$test_dir"
                break
            fi
        done
    fi
fi

if [[ ! -d "$TERRAFORM_DIR" ]]; then
    echo -e "\033[0;31m❌ Terraform directory not found: $TERRAFORM_DIR\033[0m"
    echo -e "Current directory: $(pwd)"
    echo -e "Directory contents: $(ls -la)"
    exit 1
fi

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
        if [[ -n "$value" ]]; then
            echo "$value"
            return 0
        else
            log_warning "Output '$output_name' is empty"
            return 1
        fi
    else
        log_warning "Failed to get output: $output_name (may not exist or no state)"
        return 1
    fi
}

# Function to check if terraform state exists and has outputs
check_terraform_state() {
    if [[ ! -f "$TERRAFORM_DIR/terraform.tfstate" ]] && [[ ! -f "$TERRAFORM_DIR/.terraform/terraform.tfstate" ]]; then
        log_warning "No terraform state found - infrastructure may not be deployed yet"
        return 1
    fi
    
    # Check if there are any outputs available
    local output_list
    if ! output_list=$(terraform -chdir="$TERRAFORM_DIR" output 2>/dev/null); then
        log_warning "Cannot retrieve terraform outputs - state may be empty"
        return 1
    fi
    
    if [[ -z "$output_list" ]] || [[ "$output_list" == *"No outputs found"* ]]; then
        log_warning "No terraform outputs found - infrastructure may not be fully deployed"
        return 1
    fi
    
    return 0
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
    
    # Handle both relative and absolute paths
    if [[ ! -d "$TERRAFORM_DIR" ]]; then
        # Try from repository root
        TERRAFORM_DIR="$(pwd)/infra/terraform"
        if [[ ! -d "$TERRAFORM_DIR" ]]; then
            # Try going up directories to find the right path
            for i in {1..3}; do
                test_dir="../"
                for j in $(seq 1 $i); do
                    test_dir="../$test_dir"
                done
                test_dir="${test_dir}infra/terraform"
                if [[ -d "$test_dir" ]]; then
                    TERRAFORM_DIR="$test_dir"
                    break
                fi
            done
        fi
    fi
    
    if [[ ! -d "$TERRAFORM_DIR" ]]; then
        log_error "Terraform directory not found: $TERRAFORM_DIR"
        log_error "Current directory: $(pwd)"
        log_error "Directory contents: $(ls -la)"
        exit 1
    fi
    
    log_info "Using Terraform directory: $TERRAFORM_DIR"
    
    # Define outputs to extract
    declare -A outputs=(
        ["s3_bucket_name"]="s3-bucket-name"
        ["cloudfront_distribution_id"]="cloudfront-distribution-id"
        ["cloudfront_domain_name"]="cloudfront-domain-name"
        ["api_gateway_url"]="api-gateway-url"
        ["lambda_function_name"]="lambda-function-name"
        ["dynamodb_table_name"]="dynamodb-table-name"
    )
    
    # Check if terraform state exists and has outputs
    if ! check_terraform_state; then
        log_warning "Infrastructure not deployed yet or no outputs available"
        log_info "This is normal for the first deployment - outputs will be stored after 'terraform apply'"
        exit 0
    fi
    
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