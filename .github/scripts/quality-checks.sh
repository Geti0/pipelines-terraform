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
    
    cd "$frontend_dir"
    
    # Install dependencies if needed
    if [[ ! -d "node_modules" ]]; then
        log_info "Installing frontend dependencies..."
        npm ci
    fi
    
    # ESLint
    log_info "Running ESLint..."
    if npx eslint . --ext .js,.html; then
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