#!/bin/bash
# Ultra-lightweight common functions

# Simple logging (no colors in CI for better performance)
log() { echo "[$(date +'%H:%M:%S')] $1: ${@:2}"; }

# Fast retry without eval
retry() {
    local n=1 max=3 delay=2
    while ! "$@"; do
        ((n==max)) && return 1
        log WARN "Retry $n/$max in ${delay}s..."
        sleep $delay
        ((n++))
    done
}

# Parallel execution helper
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