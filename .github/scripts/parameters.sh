#!/bin/bash
set -euo pipefail

PREFIX="/pipelines-terraform"

log() { echo "[$(date +'%H:%M:%S')] $1: ${@:2}"; }

store() {
    log INFO "Storing Terraform outputs to Parameter Store..."
    cd infra/terraform
    
    # Check if state exists
    if ! terraform output -json > /dev/null 2>&1; then
        log WARN "No Terraform outputs found (infrastructure may not be deployed yet)"
        exit 0
    fi
    
    # Store each output as a parameter
    for output in $(terraform output -json | jq -r 'keys[]'); do
        value=$(terraform output -raw "$output" 2>/dev/null || echo "")
        if [[ -n "$value" ]]; then
            param_name="$PREFIX/${output//_/-}"
            aws ssm put-parameter \
                --name "$param_name" \
                --value "$value" \
                --type String \
                --overwrite \
                --region eu-north-1 \
                --no-cli-pager > /dev/null 2>&1 || log WARN "Failed to store $param_name"
            log INFO "Stored: $param_name"
        fi
    done
    log INFO "All parameters stored"
}

retrieve() {
    log INFO "Retrieving parameters from Parameter Store..."
    
    # Use AWS CLI's batch operation for efficiency
    params=$(aws ssm get-parameters-by-path \
        --path "$PREFIX" \
        --query 'Parameters[*].[Name,Value]' \
        --output text \
        --region eu-north-1 2>/dev/null || echo "")
    
    if [[ -z "$params" ]]; then
        log WARN "No parameters found at $PREFIX"
        log WARN "Infrastructure may not be deployed yet. Using defaults for local testing."
        
        # Set default values for local testing or first deployment
        if [[ -n "${GITHUB_ENV:-}" ]]; then
            echo "S3_BUCKET=pending-deployment" >> "$GITHUB_ENV"
            echo "CLOUDFRONT_ID=pending-deployment" >> "$GITHUB_ENV"
            echo "CLOUDFRONT_DOMAIN=pending-deployment" >> "$GITHUB_ENV"
            echo "API_GATEWAY_URL=https://pending-deployment" >> "$GITHUB_ENV"
            echo "LAMBDA_FUNCTION_NAME=pending-deployment" >> "$GITHUB_ENV"
            echo "DYNAMODB_TABLE_NAME=pending-deployment" >> "$GITHUB_ENV"
        fi
        
        # Don't fail, just warn
        log WARN "Using placeholder values. Deploy infrastructure first for actual values."
        return 0
    fi
    
    # Export parameters as environment variables
    while IFS=$'\t' read -r name value; do
        # Convert parameter name to environment variable format
        var_name=$(echo "${name##*/}" | tr '[:lower:]-' '[:upper:]_')
        
        # Handle specific mappings
        case "${name##*/}" in
            "s3-bucket-name") var_name="S3_BUCKET" ;;
            "cloudfront-distribution-id") var_name="CLOUDFRONT_ID" ;;
            "cloudfront-domain-name") var_name="CLOUDFRONT_DOMAIN" ;;
            "api-gateway-url") var_name="API_GATEWAY_URL" ;;
            "lambda-function-name") var_name="LAMBDA_FUNCTION_NAME" ;;
            "dynamodb-table-name") var_name="DYNAMODB_TABLE_NAME" ;;
        esac
        
        if [[ -n "${GITHUB_ENV:-}" ]]; then
            echo "${var_name}=${value}" >> "$GITHUB_ENV"
            export "${var_name}=${value}"
            log INFO "Exported to GitHub and shell: $var_name"
        else
            export "${var_name}=${value}"
            log INFO "Exported to shell: $var_name"
        fi
    done <<< "$params"
    
    log INFO "All parameters retrieved"
}

# Main execution
case "${1:-}" in
    store) store ;;
    retrieve) retrieve ;;
    *) 
        echo "Usage: $0 [store|retrieve]"
        echo "  store    - Store Terraform outputs to Parameter Store"
        echo "  retrieve - Retrieve parameters and export as environment variables"
        exit 1 
        ;;
esac