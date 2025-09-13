#!/bin/bash

# deploy-application.sh
# Reusable script for deploying the web application
# Usage: ./deploy-application.sh

set -euo pipefail

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

# Function to wait for Lambda to be ready
wait_for_lambda_ready() {
    local func_name="$1"
    local max_attempts=30
    local attempt=1
    
    log_info "Waiting for Lambda function to be ready..."
    while [ $attempt -le $max_attempts ]; do
        status=$(aws lambda get-function --function-name "$func_name" --query 'Configuration.State' --output text --no-cli-pager 2>/dev/null || echo "Failed")
        if [ "$status" = "Active" ]; then
            log_success "Lambda function is ready (attempt $attempt)"
            return 0
        elif [ "$status" = "Failed" ]; then
            log_error "Lambda function is in Failed state"
            return 1
        else
            log_info "Lambda function state: $status (attempt $attempt/$max_attempts)"
            sleep 10
            attempt=$((attempt + 1))
        fi
    done
    log_error "Timeout waiting for Lambda function to be ready"
    return 1
}

# Function to update Lambda with retries
update_lambda_with_retry() {
    local operation="$1"
    local func_name="$2"
    local max_attempts=5
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log_info "Attempting $operation (attempt $attempt/$max_attempts)..."
        
        if [ "$operation" = "code" ]; then
            if aws lambda update-function-code \
                --function-name "$func_name" \
                --zip-file fileb://lambda-deployment.zip \
                --no-cli-pager >/dev/null; then
                log_success "Lambda code updated successfully"
                return 0
            fi
        elif [ "$operation" = "config" ]; then
            if aws lambda update-function-configuration \
                --function-name "$func_name" \
                --environment Variables="{DYNAMODB_TABLE_NAME=$DYNAMODB_TABLE_NAME}" \
                --no-cli-pager >/dev/null; then
                log_success "Lambda configuration updated successfully"
                return 0
            fi
        fi
        
        if [ $attempt -lt $max_attempts ]; then
            log_warning "Update failed, waiting 30 seconds before retry..."
            sleep 30
        fi
        attempt=$((attempt + 1))
    done
    
    log_error "Failed to update Lambda $operation after $max_attempts attempts"
    return 1
}

# Function to build frontend
build_frontend() {
    local frontend_dir="${1:-./web/frontend}"
    
    log_info "Building frontend application..."
    
    cd "$frontend_dir"
    
    # Create .env file with API Gateway URL
    if [[ -n "${API_GATEWAY_URL:-}" ]]; then
        echo "VITE_API_GATEWAY_URL=$API_GATEWAY_URL" > .env
        log_success "Created .env file with API Gateway URL"
    fi
    
    # Build with Vite
    npm run build
    log_success "Frontend build completed!"
}

# Function to deploy Lambda
deploy_lambda() {
    local lambda_dir="${1:-./web/lambda}"
    
    log_info "Deploying Lambda function..."
    
    cd "$lambda_dir"
    
    # Create deployment package
    log_info "Creating deployment package..."
    zip -r lambda-deployment.zip . \
        -x "*.test.js" "jest.config.js" "eslint.config.js" "coverage/*" \
        "node_modules/jest*" "node_modules/@jest*" \
        > /dev/null
    
    # Validate required environment variables
    if [[ -z "${LAMBDA_FUNCTION_NAME:-}" ]]; then
        log_error "LAMBDA_FUNCTION_NAME not set"
        return 1
    fi
    
    if [[ -z "${DYNAMODB_TABLE_NAME:-}" ]]; then
        log_error "DYNAMODB_TABLE_NAME not set"
        return 1
    fi
    
    # Wait for Lambda to be ready before any updates
    wait_for_lambda_ready "$LAMBDA_FUNCTION_NAME"
    
    # Update Lambda function code with retries
    update_lambda_with_retry "code" "$LAMBDA_FUNCTION_NAME"
    
    # Wait for code update to complete before config update
    wait_for_lambda_ready "$LAMBDA_FUNCTION_NAME"
    
    # Update environment variables with retries
    update_lambda_with_retry "config" "$LAMBDA_FUNCTION_NAME"
    
    log_success "Lambda function deployed successfully!"
}

# Function to deploy frontend to S3
deploy_frontend() {
    local frontend_dir="${1:-./web/frontend}"
    
    log_info "Deploying frontend to S3..."
    
    cd "$frontend_dir"
    
    # Validate required environment variables
    if [[ -z "${S3_BUCKET:-}" ]]; then
        log_error "S3_BUCKET not set"
        return 1
    fi
    
    if [[ -z "${CLOUDFRONT_ID:-}" ]]; then
        log_error "CLOUDFRONT_ID not set"
        return 1
    fi
    
    # Sync files to S3
    aws s3 sync dist/ "s3://$S3_BUCKET" --delete --no-cli-pager
    log_success "Frontend files uploaded to S3"
    
    # Invalidate CloudFront cache
    aws cloudfront create-invalidation \
        --distribution-id "$CLOUDFRONT_ID" \
        --paths "/*" \
        --no-cli-pager >/dev/null
    log_success "CloudFront cache invalidated"
}

# Function to show deployment summary
show_summary() {
    log_success "🎉 Web application deployment completed successfully!"
    echo ""
    log_info "📊 Application Details:"
    echo "  🌐 Website URL: https://${CLOUDFRONT_DOMAIN:-unknown}"
    echo "  🔗 API Endpoint: ${API_GATEWAY_URL:-unknown}"
    echo "  💾 S3 Bucket: ${S3_BUCKET:-unknown}"
    echo "  ⚡ Lambda Function: ${LAMBDA_FUNCTION_NAME:-unknown}"
    echo "  🗄️ DynamoDB Table: ${DYNAMODB_TABLE_NAME:-unknown}"
}

main() {
    log_info "Starting web application deployment..."
    
    # Build frontend
    build_frontend
    
    # Deploy Lambda function
    deploy_lambda
    
    # Deploy frontend to S3 and invalidate CloudFront
    deploy_frontend
    
    # Show summary
    show_summary
    
    log_success "Application deployment completed!"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi