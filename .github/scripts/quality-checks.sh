#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/lib/common.sh" 2>/dev/null || {
    log() { echo "[$(date +'%H:%M:%S')] $1: ${@:2}"; }
    run_parallel() {
        local pids=()
        for cmd in "$@"; do
            $cmd & pids+=($!)
        done
        local failed=0
        for pid in "${pids[@]}"; do
            wait "$pid" || ((failed++))
        done
        return $failed
    }
}

check_terraform() {
    cd infra/terraform 2>/dev/null || { log ERROR "Cannot find infra/terraform"; return 1; }
    log INFO "Checking Terraform..."
    terraform fmt -check -diff
    terraform init -backend=false -input=false
    terraform validate
    log INFO "Terraform checks completed"
}

check_frontend() {
    cd web/frontend 2>/dev/null || { log ERROR "Cannot find web/frontend"; return 1; }
    log INFO "Checking Frontend..."
    npm ci --quiet
    npm run lint --silent
    npm test -- --coverage --silent --watchAll=false
    log INFO "Frontend checks completed"
}

check_lambda() {
    cd web/lambda 2>/dev/null || { log ERROR "Cannot find web/lambda"; return 1; }
    log INFO "Checking Lambda..."
    npm ci --quiet
    npm run lint --silent
    npm test -- --coverage --silent --watchAll=false
    log INFO "Lambda checks completed"
}

# Main execution
case "${1:-all}" in
    terraform) check_terraform ;;
    frontend) check_frontend ;;
    lambda) check_lambda ;;
    all) 
        log INFO "Running all checks in parallel..."
        run_parallel check_terraform check_frontend check_lambda
        log INFO "All quality checks completed"
        ;;
    *) echo "Usage: $0 [terraform|frontend|lambda|all]"; exit 1 ;;
esac