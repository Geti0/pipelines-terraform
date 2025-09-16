#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/lib/common.sh" 2>/dev/null || {
    log() { echo "[$(date +'%H:%M:%S')] $1: ${@:2}"; }
}

# Build and deploy in parallel where possible
deploy() {
    log INFO "Starting deployment..."
    
    # Check if this is a placeholder deployment (infrastructure not ready)
    if [[ "${S3_BUCKET:-}" == "pending-deployment" ]]; then
        log WARN "Infrastructure not deployed yet. Skipping application deployment."
        log INFO "Please deploy infrastructure first using the Infrastructure Pipeline."
        exit 0
    fi
    
    # Validate required environment variables
    : "${S3_BUCKET:?S3_BUCKET not set}"
    : "${CLOUDFRONT_ID:?CLOUDFRONT_ID not set}"
    : "${API_GATEWAY_URL:?API_GATEWAY_URL not set}"
    : "${LAMBDA_FUNCTION_NAME:?LAMBDA_FUNCTION_NAME not set}"
    : "${DYNAMODB_TABLE_NAME:?DYNAMODB_TABLE_NAME not set}"
    
    # Build frontend
    log INFO "Building frontend..."
    (
        cd web/frontend
        echo "VITE_API_GATEWAY_URL=${API_GATEWAY_URL}" > .env
        npm run build
    ) &
    frontend_pid=$!
    
    # Package Lambda
    log INFO "Packaging Lambda..."
    (
        cd web/lambda
        zip -qr /tmp/lambda.zip . -x "*.test.js" "coverage/*" ".*" "node_modules/jest*" "node_modules/@jest*"
    ) &
    lambda_pid=$!
    
    # Wait for builds to complete
    wait $frontend_pid && log INFO "Frontend build completed"
    wait $lambda_pid && log INFO "Lambda package created"
    
    # Check if Lambda function exists before trying to update
    if ! aws lambda get-function --function-name "${LAMBDA_FUNCTION_NAME}" --no-cli-pager > /dev/null 2>&1; then
        log ERROR "Lambda function ${LAMBDA_FUNCTION_NAME} does not exist."
        log ERROR "Please deploy infrastructure first."
        exit 1
    fi
    
    # Deploy Lambda code
    log INFO "Deploying Lambda function..."
    aws lambda update-function-code \
        --function-name "${LAMBDA_FUNCTION_NAME}" \
        --zip-file fileb:///tmp/lambda.zip \
        --no-cli-pager > /dev/null &
    lambda_deploy_pid=$!
    
    # Check if S3 bucket exists before trying to sync
    if ! aws s3 ls "s3://${S3_BUCKET}" --no-cli-pager > /dev/null 2>&1; then
        log ERROR "S3 bucket ${S3_BUCKET} does not exist."
        log ERROR "Please deploy infrastructure first."
        exit 1
    fi
    
    # Deploy Frontend to S3
    log INFO "Deploying frontend to S3..."
    aws s3 sync web/frontend/dist/ "s3://${S3_BUCKET}" \
        --delete --no-progress &
    s3_deploy_pid=$!
    
    # Wait for deployments
    wait $lambda_deploy_pid && log INFO "Lambda code deployed"
    wait $s3_deploy_pid && log INFO "Frontend deployed to S3"
    
    # Update Lambda configuration (must be done after code update)
    log INFO "Updating Lambda configuration..."
    aws lambda wait function-updated --function-name "${LAMBDA_FUNCTION_NAME}"
    aws lambda update-function-configuration \
        --function-name "${LAMBDA_FUNCTION_NAME}" \
        --environment "Variables={DYNAMODB_TABLE_NAME=${DYNAMODB_TABLE_NAME}}" \
        --no-cli-pager > /dev/null
    
    # Check if CloudFront distribution exists
    if ! aws cloudfront get-distribution --id "${CLOUDFRONT_ID}" --no-cli-pager > /dev/null 2>&1; then
        log WARN "CloudFront distribution ${CLOUDFRONT_ID} not found. Skipping invalidation."
    else
        # Invalidate CloudFront
        log INFO "Invalidating CloudFront cache..."
        aws cloudfront create-invalidation \
            --distribution-id "${CLOUDFRONT_ID}" \
            --paths "/*" \
            --no-cli-pager > /dev/null
    fi
    
    log INFO "Deployment completed successfully!"
    log INFO "Website: https://${CLOUDFRONT_DOMAIN:-$CLOUDFRONT_ID.cloudfront.net}"
    log INFO "API: ${API_GATEWAY_URL}"
}

# Single execution
deploy