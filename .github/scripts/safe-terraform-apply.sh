#!/bin/bash

# safe-terraform-apply.sh
# Script for safe Terraform operations that minimize recreation
# Usage: ./safe-terraform-apply.sh [plan|apply|destroy]

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

# Function to check for destructive changes
check_destructive_changes() {
    local plan_file="$1"
    
    log_info "Analyzing plan for destructive changes..."
    
    # Check for resources being destroyed or recreated
    local destructive_count
    destructive_count=$(terraform show -json "$plan_file" | jq -r '
        .resource_changes[] | 
        select(.change.actions[] | . == "delete" or . == "create") |
        select(.change.actions | length > 1 or (length == 1 and .[0] != "create")) |
        .address' | wc -l)
    
    if [[ "$destructive_count" -gt 0 ]]; then
        log_warning "Found $destructive_count potentially destructive changes:"
        terraform show -json "$plan_file" | jq -r '
            .resource_changes[] | 
            select(.change.actions[] | . == "delete" or . == "create") |
            select(.change.actions | length > 1 or (length == 1 and .[0] != "create")) |
            "  - \(.address): \(.change.actions | join(", "))"'
        
        echo ""
        log_warning "These changes might cause:"
        echo "  🔄 Resource recreation (downtime)"
        echo "  💾 Data loss (DynamoDB, S3 content)"
        echo "  🌐 Service interruption"
        echo ""
        
        read -p "Do you want to continue? (yes/no): " -r
        if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
            log_info "Operation cancelled"
            exit 0
        fi
    else
        log_success "No destructive changes detected"
    fi
}

# Function to check for sensitive resource changes
check_sensitive_resources() {
    local plan_file="$1"
    
    log_info "Checking for changes to sensitive resources..."
    
    # List of sensitive resources that should rarely change
    local sensitive_patterns=(
        "aws_dynamodb_table"
        "aws_s3_bucket"
        "random_id"
    )
    
    local sensitive_changes=false
    
    for pattern in "${sensitive_patterns[@]}"; do
        local changes
        changes=$(terraform show -json "$plan_file" | jq -r --arg pattern "$pattern" '
            .resource_changes[] | 
            select(.type == $pattern and (.change.actions[] | . != "no-op")) |
            .address')
        
        if [[ -n "$changes" ]]; then
            sensitive_changes=true
            log_warning "Sensitive resource changes detected for $pattern:"
            echo "$changes" | sed 's/^/  - /'
        fi
    done
    
    if [[ "$sensitive_changes" == true ]]; then
        echo ""
        log_warning "Changes to sensitive resources detected!"
        echo "  💡 Consider using terraform import for existing resources"
        echo "  🔒 Backup data before proceeding"
        echo "  📋 Review the full plan carefully"
        echo ""
    fi
}

# Function to create a detailed plan summary
create_plan_summary() {
    local plan_file="$1"
    
    log_info "Creating plan summary..."
    
    # Count changes by action
    local to_add to_change to_destroy
    to_add=$(terraform show -json "$plan_file" | jq '[.resource_changes[] | select(.change.actions[] == "create")] | length')
    to_change=$(terraform show -json "$plan_file" | jq '[.resource_changes[] | select(.change.actions[] == "update")] | length')
    to_destroy=$(terraform show -json "$plan_file" | jq '[.resource_changes[] | select(.change.actions[] == "delete")] | length')
    
    echo ""
    log_info "📊 Plan Summary:"
    echo "  ➕ Resources to add: $to_add"
    echo "  🔄 Resources to change: $to_change"
    echo "  ❌ Resources to destroy: $to_destroy"
    echo ""
    
    # Show resource-by-resource breakdown
    if [[ "$to_change" -gt 0 || "$to_destroy" -gt 0 ]]; then
        log_info "📋 Detailed changes:"
        terraform show -json "$plan_file" | jq -r '
            .resource_changes[] | 
            select(.change.actions[] != "no-op") |
            "  \(.change.actions | join(", ") | ascii_upcase): \(.address)"'
    fi
}

# Function to perform safe terraform plan
safe_plan() {
    log_info "Creating Terraform plan with safety checks..."
    
    # Initialize if needed
    if [[ ! -d ".terraform" ]]; then
        log_info "Initializing Terraform..."
        terraform init
    fi
    
    # Create plan
    local plan_file="tfplan-$(date +%Y%m%d-%H%M%S)"
    
    log_info "Generating plan..."
    terraform plan -out="$plan_file" -detailed-exitcode
    local plan_exit_code=$?
    
    if [[ $plan_exit_code -eq 0 ]]; then
        log_success "No changes needed"
        rm -f "$plan_file"
        return 0
    elif [[ $plan_exit_code -eq 2 ]]; then
        log_info "Changes detected, analyzing..."
        
        # Analyze the plan
        create_plan_summary "$plan_file"
        check_sensitive_resources "$plan_file"
        check_destructive_changes "$plan_file"
        
        log_success "Plan file created: $plan_file"
        log_info "Run './safe-terraform-apply.sh apply $plan_file' to apply changes"
        
        return 0
    else
        log_error "Plan failed with exit code $plan_exit_code"
        return $plan_exit_code
    fi
}

# Function to apply a plan
safe_apply() {
    local plan_file="${1:-}"
    
    if [[ -z "$plan_file" ]]; then
        log_error "Plan file required for apply operation"
        log_info "Usage: $0 apply <plan-file>"
        log_info "First run: $0 plan"
        return 1
    fi
    
    if [[ ! -f "$plan_file" ]]; then
        log_error "Plan file not found: $plan_file"
        return 1
    fi
    
    log_info "Applying Terraform plan: $plan_file"
    
    # Final confirmation
    echo ""
    log_warning "About to apply infrastructure changes!"
    read -p "Are you sure you want to proceed? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log_info "Apply cancelled"
        return 0
    fi
    
    # Apply with progress monitoring
    log_info "Applying changes..."
    terraform apply "$plan_file"
    
    if [[ $? -eq 0 ]]; then
        log_success "Apply completed successfully!"
        
        # Clean up plan file
        rm -f "$plan_file"
        
        # Show outputs
        log_info "Infrastructure outputs:"
        terraform output
    else
        log_error "Apply failed!"
        return 1
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [plan|apply|destroy]"
    echo ""
    echo "Commands:"
    echo "  plan                 Create a safe execution plan"
    echo "  apply <plan-file>    Apply a previously created plan"
    echo "  destroy              Safely destroy infrastructure (with confirmations)"
    echo ""
    echo "Examples:"
    echo "  $0 plan              # Create and analyze a plan"
    echo "  $0 apply tfplan-123  # Apply specific plan file"
    echo "  $0 destroy           # Destroy infrastructure"
}

main() {
    local command="${1:-}"
    
    case "$command" in
        plan)
            safe_plan
            ;;
        apply)
            safe_apply "${2:-}"
            ;;
        destroy)
            log_warning "Destroy operation - use with extreme caution!"
            terraform plan -destroy
            read -p "Proceed with destroy? (yes/no): " -r
            if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
                terraform destroy
            fi
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        "")
            show_usage
            exit 1
            ;;
        *)
            log_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Check dependencies
if ! command -v terraform >/dev/null 2>&1; then
    log_error "Terraform not found. Please install Terraform."
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    log_warning "jq not found. Advanced plan analysis will be limited."
fi

# Run main function
main "$@"