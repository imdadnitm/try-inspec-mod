#!/bin/bash
################################################################################
# Mermaid Validator Performance Benchmark
################################################################################
# Purpose: Measure validator performance and track baseline
# Records execution time across multiple runs
# Detects performance regression and variance
# Baseline Target: <50ms (optimal), <200ms (acceptable)
################################################################################

RUNS=10
DIAGRAM_FILE="ai-track-docs/architecture.mmd"
BASELINE_FILE="tests/.validate-baseline.txt"

if [ ! -f "$DIAGRAM_FILE" ]; then
    echo "❌ Diagram file not found: $DIAGRAM_FILE"
    exit 1
fi

echo "📊 Mermaid Validator Micro-Benchmark"
echo "Running $RUNS iterations..."
echo ""

TIMES=()
TOTAL_TIME=0

# Run validator multiple times, extract timing
for i in $(seq 1 $RUNS); do
    # Capture full output
    output=$(bash tests/validate-mermaid.sh 2>&1)
    
    # Extract timing from output (format: "Performance: XXms")
    time_ms=$(echo "$output" | grep -oE 'Performance: [0-9]+ms' | grep -oE '[0-9]+' || echo "0")
    
    if [ -z "$time_ms" ] || [ "$time_ms" -eq 0 ]; then
        # Fallback: use time command
        time_output=$( { time bash tests/validate-mermaid.sh > /dev/null 2>&1; } 2>&1)
        time_ms=$(echo "$time_output" | grep real | awk '{print $2}' | cut -d'm' -f1)
        time_ms=$((time_ms * 1000))  # Convert seconds to ms
    fi
    
    TIMES+=($time_ms)
    TOTAL_TIME=$((TOTAL_TIME + time_ms))
    
    printf "  Run $i: ${time_ms}ms\n"
done

# Calculate statistics
AVG_TIME=$((TOTAL_TIME / RUNS))
MIN_TIME=${TIMES[0]}
MAX_TIME=${TIMES[0]}

for t in "${TIMES[@]}"; do
    if [ $t -lt $MIN_TIME ]; then
        MIN_TIME=$t
    fi
    if [ $t -gt $MAX_TIME ]; then
        MAX_TIME=$t
    fi
done

VARIANCE=$((MAX_TIME - MIN_TIME))

echo ""
echo "════════════════════════════════════════════════════════════"
echo "Performance Summary ($RUNS runs)"
echo "════════════════════════════════════════════════════════════"
echo "Average:  ${AVG_TIME}ms"
echo "Min:      ${MIN_TIME}ms"
echo "Max:      ${MAX_TIME}ms"
echo "Variance: ${VARIANCE}ms (range: ${MIN_TIME}-${MAX_TIME}ms)"
echo ""

# Baseline check
if [ $AVG_TIME -lt 50 ]; then
    RATING="⚡ OPTIMAL"
elif [ $AVG_TIME -lt 200 ]; then
    RATING="✓ ACCEPTABLE"
else
    RATING="⚠️  SLOW"
fi

echo "Rating: $RATING"
echo ""

# Record baseline
if [ ! -f "$BASELINE_FILE" ]; then
    echo "Recording baseline..."
    cat > "$BASELINE_FILE" << EOF
# Mermaid Validator Performance Baseline
# Date: $(date)
# Runs: $RUNS

Baseline Average: ${AVG_TIME}ms
Baseline Min:     ${MIN_TIME}ms
Baseline Max:     ${MAX_TIME}ms
Baseline Variance: ${VARIANCE}ms

Notes:
- Validator uses deterministic bash utilities (grep, wc, comm)
- Performance is I/O bound (file read) not computation bound
- Variance reflects system load, not algorithmic variance
- Expected performance: <200ms on typical systems
- Current implementation runs 10 grep/pattern checks (O(n) per check)
EOF
    echo "✅ Baseline saved to: $BASELINE_FILE"
else
    # Compare to baseline
    BASELINE_AVG=$(grep "Baseline Average:" "$BASELINE_FILE" | grep -oE '[0-9]+' | head -1)
    
    if [ -n "$BASELINE_AVG" ]; then
        DIFF=$((AVG_TIME - BASELINE_AVG))
        DIFF_PERCENT=$(( (DIFF * 100) / BASELINE_AVG ))
        
        echo "Baseline Comparison:"
        echo "  Previous: ${BASELINE_AVG}ms"
        echo "  Current:  ${AVG_TIME}ms"
        
        if [ $DIFF -gt 0 ]; then
            echo "  Change:   +${DIFF}ms (+${DIFF_PERCENT}%) ⚠️  slower"
        else
            echo "  Change:   ${DIFF}ms (${DIFF_PERCENT}%) ✅ faster"
        fi
    fi
fi

echo ""
echo "Benchmark complete. For details, see:"
echo "  - Test output: ./tests/validate-mermaid.sh"
echo "  - Baseline: $BASELINE_FILE"
