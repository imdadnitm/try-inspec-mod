#!/bin/bash
################################################################################
# Structured Logging Helper for Validators
################################################################################
# Purpose: Provide consistent logging format across validation operations
# Usage: source this file to use log_operation, log_result functions
# Output: JSON-formatted structured logs with op, status, elapsed_ms fields
# Dependencies: bash, date (standard utilities)
################################################################################

# Global state for operation tracking
declare -g _OPERATION_START_TIME
declare -g _OPERATION_NAME
declare -g _CURRENT_OP_CONTEXT

# Enable structured logging (default: disabled, set STRUCTURED_LOGS=1 to enable)
LOG_FORMAT="${LOG_FORMAT:-human}"  # Options: human, json

################################################################################
# log_operation_start: Mark the start of a named operation
################################################################################
# Usage: log_operation_start "my-operation"
# Sets up timing and context for a tracked operation
################################################################################
log_operation_start() {
    local op_name="$1"
    _OPERATION_NAME="$op_name"
    _OPERATION_START_TIME=$(date +%s%N)  # Nanoseconds precision
    
    if [ "$LOG_FORMAT" = "json" ]; then
        # JSON format omits start event; we log only completion
        :
    else
        # Human-readable format: optional startup message
        :
    fi
}

################################################################################
# log_operation_result: Log operation completion with structured fields
################################################################################
# Usage: log_operation_result "success" "All tests passed"
# Fields: op, status, elapsed_ms, message
# Outputs to stdout (structured log) and stderr for errors
################################################################################
log_operation_result() {
    local status="$1"
    local message="$2"
    local details="${3:-}"
    
    if [ -z "$_OPERATION_START_TIME" ]; then
        # Timing not available; use current time
        local elapsed_ms=0
    else
        local end_time=$(date +%s%N)
        local elapsed_ns=$((end_time - _OPERATION_START_TIME))
        local elapsed_ms=$((elapsed_ns / 1000000))
    fi
    
    if [ "$LOG_FORMAT" = "json" ]; then
        # Structured JSON output
        local log_entry=$(cat <<EOF
{
  "op": "$_OPERATION_NAME",
  "status": "$status",
  "elapsed_ms": $elapsed_ms,
  "message": "$(echo "$message" | sed 's/"/\\"/g')",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
        )
        
        if [ "$status" = "success" ]; then
            echo "$log_entry"
        else
            echo "$log_entry" >&2
        fi
    else
        # Human-readable format (default)
        # Already handled by calling script's echo statements
        :
    fi
    
    # Clear operation context
    unset _OPERATION_START_TIME
    unset _OPERATION_NAME
}

################################################################################
# log_check: Log a single validation check result
################################################################################
# Usage: log_check "check-name" "passed|failed" "reason"
# For JSON format: collects checks for batch output
################################################################################
declare -ga _CHECK_RESULTS=()

log_check() {
    local check_name="$1"
    local check_status="$2"  # passed, failed, skipped
    local reason="$3"
    
    if [ "$LOG_FORMAT" = "json" ]; then
        local check_log=$(cat <<EOF
  {
    "check": "$check_name",
    "status": "$check_status",
    "reason": "$(echo "$reason" | sed 's/"/\\"/g')"
  }
EOF
        )
        _CHECK_RESULTS+=("$check_log")
    fi
}

################################################################################
# log_checks_summary: Output all accumulated checks in structured format
################################################################################
log_checks_summary() {
    local checks_passed="$1"
    local checks_failed="$2"
    local checks_total="$3"
    
    if [ "$LOG_FORMAT" = "json" ]; then
        local checks_json=""
        for check in "${_CHECK_RESULTS[@]}"; do
            checks_json+="$check"$'\n,'
        done
        checks_json="${checks_json%,}"  # Remove trailing comma
        
        cat <<EOF
{
  "op": "diagram-validation",
  "status": "complete",
  "elapsed_ms": $(($(date +%s%N) - _OPERATION_START_TIME) / 1000000),
  "summary": {
    "passed": $checks_passed,
    "failed": $checks_failed,
    "total": $checks_total
  },
  "checks": [
$checks_json
  ],
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
    fi
}

export -f log_operation_start
export -f log_operation_result
export -f log_check
export -f log_checks_summary
