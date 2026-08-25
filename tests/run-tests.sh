#!/bin/bash

#╔════════════════════════════════════════════════════════════════════════════╗
#║                         TEST SUITE RUNNER                                  ║
#║                                                                            ║
#║ Runs all project tests with comprehensive reporting                       ║
#╚════════════════════════════════════════════════════════════════════════════╝

set -o pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test tracking
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0
FAILED_TESTS=()
TEST_RESULTS=()

# Exit codes
SUCCESS=0
FAILURE=1

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

#───────────────────────────────────────────────────────────────────────────────
# Logging Functions
#───────────────────────────────────────────────────────────────────────────────

log_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} $1"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
}

log_section() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

log_pass() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_fail() {
    echo -e "${RED}❌ $1${NC}"
}

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

#───────────────────────────────────────────────────────────────────────────────
# Test Execution
#───────────────────────────────────────────────────────────────────────────────

run_test() {
    local test_name="$1"
    local test_cmd="$2"
    local test_file="$3"
    
    echo -e "\n${YELLOW}Running:${NC} $test_name"
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    # Run test and capture output
    local output
    local exit_code
    
    output=$(eval "$test_cmd" 2>&1)
    exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        log_pass "$test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        TEST_RESULTS+=("{\"test\": \"$test_name\", \"status\": \"pass\", \"exit_code\": 0, \"file\": \"$test_file\"}")
        return 0
    else
        log_fail "$test_name (exit code: $exit_code)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$test_name")
        TEST_RESULTS+=("{\"test\": \"$test_name\", \"status\": \"fail\", \"exit_code\": $exit_code, \"file\": \"$test_file\"}")
        
        # Show last few lines of output for debugging
        echo -e "${RED}Error output:${NC}"
        echo "$output" | tail -10 | sed 's/^/  /'
        return 1
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# Main Test Suite
#───────────────────────────────────────────────────────────────────────────────

main() {
    cd "$PROJECT_ROOT" || exit 1
    
    log_header "PROJECT TEST SUITE"
    
    log_section "Test Configuration"
    log_info "Working directory: $PROJECT_ROOT"
    log_info "Test directory: $SCRIPT_DIR"
    log_info "Timestamp: $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
    
    # Run tests
    log_section "Running Tests"
    
    # Test 1: Diagram Validation (Human-Readable)
    run_test "Diagram Validation (Human-Readable)" \
        "bash $SCRIPT_DIR/validate-mermaid.sh" \
        "validate-mermaid.sh"
    
    # Test 2: Diagram Validation (JSON Format)
    run_test "Diagram Validation (JSON Format)" \
        "LOG_FORMAT=json bash $SCRIPT_DIR/validate-mermaid.sh" \
        "validate-mermaid.sh"
    
    # Test 3: Negative Tests (Error Detection)
    run_test "Negative Input Validation Tests" \
        "bash $SCRIPT_DIR/validate-mermaid-negative-tests.sh" \
        "validate-mermaid-negative-tests.sh"
    
    # Test 4: Performance Benchmark
    run_test "Performance Benchmark (5 runs)" \
        "bash $SCRIPT_DIR/benchmark-validator.sh --runs 5" \
        "benchmark-validator.sh"
    
    # Summary
    log_section "Test Summary"
    
    local pass_rate=0
    if [ $TESTS_TOTAL -gt 0 ]; then
        pass_rate=$((TESTS_PASSED * 100 / TESTS_TOTAL))
    fi
    
    echo ""
    echo "Results:"
    echo "  ${GREEN}Passed:${NC}  $TESTS_PASSED / $TESTS_TOTAL"
    echo "  ${RED}Failed:${NC}  $TESTS_FAILED / $TESTS_TOTAL"
    echo "  Pass Rate: ${pass_rate}%"
    
    if [ $TESTS_FAILED -gt 0 ]; then
        echo ""
        echo "Failed Tests:"
        for test in "${FAILED_TESTS[@]}"; do
            echo "  ${RED}•${NC} $test"
        done
    fi
    
    # Save results to JSON file
    save_test_results
    
    echo ""
    if [ $TESTS_FAILED -eq 0 ]; then
        log_pass "All tests passed! ✨"
        return $SUCCESS
    else
        log_fail "Some tests failed. See above for details."
        return $FAILURE
    fi
}

#───────────────────────────────────────────────────────────────────────────────
# Results Export
#───────────────────────────────────────────────────────────────────────────────

save_test_results() {
    local results_file="$PROJECT_ROOT/test-results.json"
    
    # Build JSON array
    local json_results="["
    for result in "${TEST_RESULTS[@]}"; do
        json_results="${json_results}${result},"
    done
    # Remove trailing comma
    json_results="${json_results%,}]"
    
    # Create full JSON object
    local json_output=$(cat <<EOF
{
  "timestamp": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')",
  "summary": {
    "total": $TESTS_TOTAL,
    "passed": $TESTS_PASSED,
    "failed": $TESTS_FAILED,
    "pass_rate": $((TESTS_PASSED * 100 / TESTS_TOTAL))
  },
  "results": $json_results
}
EOF
)
    
    echo "$json_output" > "$results_file"
    log_info "Results saved to: $results_file"
}

#───────────────────────────────────────────────────────────────────────────────
# Entry Point
#───────────────────────────────────────────────────────────────────────────────

main
exit $?
