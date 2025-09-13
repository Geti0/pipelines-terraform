#!/bin/bash

# quality-checks.sh
# Reusable script for running quality checks on different parts of the project
# Usage: ./quality-checks.sh [terraform|frontend|lambda]

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

# Function to run terraform quality checks
terraform_checks() {
    local terraform_dir="${1:-./infra/terraform}"
    
    log_info "Running Terraform quality checks..."
    
    # Handle both relative and absolute paths
    if [[ ! -d "$terraform_dir" ]]; then
        # Try from repository root
        terraform_dir="$(pwd)/infra/terraform"
        if [[ ! -d "$terraform_dir" ]]; then
            # Try going up directories to find the right path
            for i in {1..3}; do
                test_dir="../"
                for j in $(seq 1 $i); do
                    test_dir="../$test_dir"
                done
                test_dir="${test_dir}infra/terraform"
                if [[ -d "$test_dir" ]]; then
                    terraform_dir="$test_dir"
                    break
                fi
            done
        fi
    fi
    
    if [[ ! -d "$terraform_dir" ]]; then
        log_error "Cannot find Terraform directory: $terraform_dir"
        log_error "Current directory: $(pwd)"
        log_error "Directory contents: $(ls -la)"
        return 1
    fi
    
    log_info "Using Terraform directory: $terraform_dir"
    cd "$terraform_dir"
    
    # Format check
    log_info "Checking Terraform format..."
    if terraform fmt -check; then
        log_success "Terraform format check passed"
    else
        log_warning "Terraform format issues found, running terraform fmt..."
        terraform fmt
        log_success "Files formatted"
    fi
    
    # Validation
    log_info "Running Terraform validation..."
    terraform init -backend=false
    terraform validate
    log_success "Terraform validation passed"
    
    # TFLint (optional)
    if command -v tflint >/dev/null 2>&1; then
        log_info "Running TFLint..."
        tflint --init 2>/dev/null || true
        if tflint; then
            log_success "TFLint passed"
        else
            log_warning "TFLint found issues"
        fi
    else
        log_warning "TFLint not installed, skipping..."
    fi
    
    # Checkov (optional)
    if command -v checkov >/dev/null 2>&1; then
        log_info "Running Checkov security scan..."
        if checkov -d . --quiet; then
            log_success "Checkov security scan passed"
        else
            log_warning "Checkov found security issues"
        fi
    else
        log_warning "Checkov not installed, skipping..."
    fi
}

# Function to run frontend quality checks
frontend_checks() {
    local frontend_dir="${1:-./web/frontend}"
    
    log_info "Running Frontend quality checks..."
    
    # Handle both relative and absolute paths
    if [[ ! -d "$frontend_dir" ]]; then
        # Try from repository root
        frontend_dir="$(pwd)/web/frontend"
        if [[ ! -d "$frontend_dir" ]]; then
            # Try going up directories to find the right path
            for i in {1..3}; do
                test_dir="../"
                for j in $(seq 1 $i); do
                    test_dir="../$test_dir"
                done
                test_dir="${test_dir}web/frontend"
                if [[ -d "$test_dir" ]]; then
                    frontend_dir="$test_dir"
                    break
                fi
            done
        fi
    fi
    
    if [[ ! -d "$frontend_dir" ]]; then
        log_error "Cannot find Frontend directory: $frontend_dir"
        log_error "Current directory: $(pwd)"
        log_error "Directory contents: $(ls -la)"
        return 1
    fi
    
    log_info "Using Frontend directory: $frontend_dir"
    cd "$frontend_dir"
    
    # Install dependencies if needed
    if [[ ! -d "node_modules" ]]; then
        log_info "Installing frontend dependencies..."
        npm ci
    fi
    
    # ESLint
    log_info "Running ESLint..."
    if npx eslint . --ext .js; then
        log_success "ESLint passed"
    else
        log_warning "ESLint found issues"
    fi
    
    # Tests with coverage
    log_info "Running frontend tests..."
    npm test -- --coverage --coverageReporters=text-summary
    log_success "Frontend tests completed"
}

# Function to run lambda quality checks
lambda_checks() {
    local lambda_dir="${1:-./web/lambda}"
    
    log_info "Running Lambda quality checks..."
    
    # Handle both relative and absolute paths
    if [[ ! -d "$lambda_dir" ]]; then
        # Try from repository root
        lambda_dir="$(pwd)/web/lambda"
        if [[ ! -d "$lambda_dir" ]]; then
            # Try going up directories to find the right path
            for i in {1..3}; do
                test_dir="../"
                for j in $(seq 1 $i); do
                    test_dir="../$test_dir"
                done
                test_dir="${test_dir}web/lambda"
                if [[ -d "$test_dir" ]]; then
                    lambda_dir="$test_dir"
                    break
                fi
            done
        fi
    fi
    
    if [[ ! -d "$lambda_dir" ]]; then
        log_error "Cannot find Lambda directory: $lambda_dir"
        log_error "Current directory: $(pwd)"
        log_error "Directory contents: $(ls -la)"
        return 1
    fi
    
    log_info "Using Lambda directory: $lambda_dir"
    cd "$lambda_dir"
    
    # Install dependencies if needed
    if [[ ! -d "node_modules" ]]; then
        log_info "Installing lambda dependencies..."
        npm ci
    fi
    
    # ESLint
    log_info "Running ESLint..."
    if npx eslint .; then
        log_success "ESLint passed"
    else
        log_warning "ESLint found issues"
    fi
    
    # Tests with coverage
    log_info "Running lambda tests..."
    npm test -- --coverage --coverageReporters=text-summary
    log_success "Lambda tests completed"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [terraform|frontend|lambda|all]"
    echo ""
    echo "Options:"
    echo "  terraform  Run Terraform quality checks"
    echo "  frontend   Run Frontend quality checks"
    echo "  lambda     Run Lambda quality checks"
    echo "  all        Run all quality checks"
    echo ""
    echo "Examples:"
    echo "  $0 terraform"
    echo "  $0 frontend"
    echo "  $0 all"
}

main() {
    local check_type="${1:-}"
    
    if [[ -z "$check_type" ]]; then
        show_usage
        exit 1
    fi
    
    case "$check_type" in
        terraform)
            terraform_checks
            ;;
        frontend)
            frontend_checks
            ;;
        lambda)
            lambda_checks
            ;;
        all)
            terraform_checks
            frontend_checks
            lambda_checks
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            log_error "Unknown check type: $check_type"
            show_usage
            exit 1
            ;;
    esac
    
    log_success "Quality checks completed!"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi