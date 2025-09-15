#!/bin/bash
set -euo pipefail

log() { echo "[$(date +'%H:%M:%S')] $1: ${@:2}"; }

apply() {
    cd infra/terraform
    
    log INFO "Initializing Terraform..."
    terraform init -input=false
    
    log INFO "Creating Terraform plan..."
    # Use detailed-exitcode: 0=no changes, 1=error, 2=changes needed
    set +e
    terraform plan -out=tfplan -input=false -detailed-exitcode
    exit_code=$?
    set -e
    
    case $exit_code in
        0)
            log INFO "No changes needed - infrastructure is up to date"
            rm -f tfplan
            return 0
            ;;
        1)
            log ERROR "Terraform plan failed"
            rm -f tfplan
            return 1
            ;;
        2)
            log INFO "Changes detected, reviewing plan..."
            
            # Quick check for destructive changes
            if terraform show tfplan | grep -E '# .*(destroy|replace)' > /dev/null 2>&1; then
                log WARN "⚠️  Destructive changes detected:"
                terraform show tfplan | grep -E '# .*(destroy|replace)' | head -5
                
                # In CI/CD, we still apply but log the warning
                if [[ -n "${CI:-}" ]]; then
                    log WARN "Proceeding with deployment (CI/CD mode)"
                else
                    read -p "Continue with these changes? (yes/no): " -r
                    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
                        log INFO "Deployment cancelled"
                        rm -f tfplan
                        return 0
                    fi
                fi
            fi
            
            log INFO "Applying Terraform changes..."
            terraform apply -auto-approve tfplan
            rm -f tfplan
            
            log INFO "Infrastructure deployment completed successfully!"
            
            # Show key outputs
            log INFO "Infrastructure outputs:"
            terraform output -json | jq -r 'to_entries[] | "  \(.key): \(.value.value)"' 2>/dev/null || terraform output
            ;;
    esac
}

# Main execution
apply