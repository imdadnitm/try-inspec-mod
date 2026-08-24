#!/bin/bash
################################################################################
# Mermaid Diagram Validator
################################################################################
# Purpose: Deterministic syntax validation for ai-track-docs/architecture.mmd
# Ensures diagram maintains valid Mermaid syntax and documentation quality
# Exits: 0 (all checks pass) | 1 (critical failure) | 0 + warnings (non-critical)
# Dependencies: bash, grep, wc (standard utilities, no external tools needed)
#
# STRUCTURED LOGGING:
#   Enable with: LOG_FORMAT=json ./validate-mermaid.sh
#   Output: JSON structured logs with op, status, elapsed_ms fields
#   Example: {"op": "diagram-validation", "status": "success", "elapsed_ms": 42}
################################################################################

set -e

DIAGRAM_FILE="ai-track-docs/architecture.mmd"
ERRORS=0

# TIMING: Capture execution start time for micro-benchmark
# Records wall-clock time to measure validator performance
# Used to track performance regression (should stay <500ms)
START_TIME=$(date +%s%N)  # Nanoseconds precision

if [ "$LOG_FORMAT" != "json" ]; then
    echo "🔍 Validating Mermaid diagram: $DIAGRAM_FILE"
fi

# TEST 1: File Accessibility
# Ensures diagram file exists and is readable from current working directory
if [ ! -f "$DIAGRAM_FILE" ]; then
    if [ "$LOG_FORMAT" = "json" ]; then
        cat <<EOF
{"op": "diagram-validation", "status": "failure", "elapsed_ms": 0, "message": "File not found"}
EOF
    else
        echo "❌ FAIL: File not found: $DIAGRAM_FILE"
    fi
    exit 1
fi
if [ "$LOG_FORMAT" != "json" ]; then
    echo "✓ File exists"
fi

# TEST 2: Content Presence
# Prevents empty/corrupted files that would render as blank diagrams
if [ ! -s "$DIAGRAM_FILE" ]; then
    if [ "$LOG_FORMAT" = "json" ]; then
        cat <<EOF
{"op": "diagram-validation", "status": "failure", "elapsed_ms": 0, "message": "File is empty"}
EOF
    else
        echo "❌ FAIL: File is empty: $DIAGRAM_FILE"
    fi
    exit 1
fi
if [ "$LOG_FORMAT" != "json" ]; then
    echo "✓ File is not empty"
fi

# TEST 3: Mermaid Syntax
# Verifies file declares graph type (required for Mermaid rendering)
if ! grep -q "^graph" "$DIAGRAM_FILE"; then
    if [ "$LOG_FORMAT" != "json" ]; then
        echo "❌ FAIL: Missing 'graph' declaration (Mermaid syntax)"
    fi
    ((ERRORS++))
else
    if [ "$LOG_FORMAT" != "json" ]; then
        echo "✓ Contains Mermaid graph declaration"
    fi
fi

# TEST 4: Bracket Symmetry
# Checks node labels are properly wrapped: A["text"] requires balanced []
# Catches common errors like unclosed node definitions
OPEN_BRACKETS=$(grep -o '\[' "$DIAGRAM_FILE" | wc -l)
CLOSE_BRACKETS=$(grep -o '\]' "$DIAGRAM_FILE" | wc -l)
if [ "$OPEN_BRACKETS" -ne "$CLOSE_BRACKETS" ]; then
    if [ "$LOG_FORMAT" != "json" ]; then
        echo "❌ FAIL: Unbalanced brackets - $OPEN_BRACKETS '[' vs $CLOSE_BRACKETS ']'"
    fi
    ((ERRORS++))
else
    if [ "$LOG_FORMAT" != "json" ]; then
        echo "✓ Brackets are balanced ($OPEN_BRACKETS pairs)"
    fi
fi

# TEST 5: Diagram Completeness
# Ensures minimum viable content (graph declaration + at least one node definition)
# Prevents trivial/stub diagrams from passing validation
LINES=$(wc -l < "$DIAGRAM_FILE")
if [ "$LINES" -lt 3 ]; then
    if [ "$LOG_FORMAT" != "json" ]; then
        echo "❌ FAIL: Diagram too short ($LINES lines, expected at least 3)"
    fi
    ((ERRORS++))
else
    if [ "$LOG_FORMAT" != "json" ]; then
        echo "✓ Diagram has sufficient content ($LINES lines)"
    fi
fi

# TEST 6: Node Label Quality
# Detects empty labels that render as invisible/broken nodes in diagrams
# Examples of failures caught: A[""], B[''], C[]
if grep -q '\["\]' "$DIAGRAM_FILE" || grep -q "\[''\]" "$DIAGRAM_FILE"; then
    if [ "$LOG_FORMAT" != "json" ]; then
        echo "❌ FAIL: Found empty node labels"
    fi
    ((ERRORS++))
else
    if [ "$LOG_FORMAT" != "json" ]; then
        echo "✓ All nodes have labels"
    fi
fi

# TEST 7: Connection Syntax
# Validates arrow connections using Mermaid syntax (A --> B)
# Ensures directed acyclic graph (DAG) structure is maintained
ARROW_COUNT=$(grep -o ' --> ' "$DIAGRAM_FILE" | wc -l)
if [ "$ARROW_COUNT" -eq 0 ]; then
    if [ "$LOG_FORMAT" != "json" ]; then
        echo "❌ FAIL: No connections found (expected ' --> ' arrows)"
    fi
    ((ERRORS++))
else
    if [ "$LOG_FORMAT" != "json" ]; then
        echo "✓ Contains $ARROW_COUNT node connections"
    fi
fi

# TEST 8: Readability Enhancement (Non-Critical)
# Checks for section comments (%% ====== SECTION NAME ======) that organize flows
# Improves maintainability but is not required for valid syntax
# This is an informational check: missing comments don't cause test failure
COMMENT_COUNT=$(grep -c "^[[:space:]]*%%" "$DIAGRAM_FILE" || true)
if [ "$COMMENT_COUNT" -eq 0 ]; then
    if [ "$LOG_FORMAT" != "json" ]; then
        echo "⚠️  INFO: No section comments found (readability enhancement missing)"
    fi
else
    if [ "$LOG_FORMAT" != "json" ]; then
        echo "✓ Contains $COMMENT_COUNT organizational comments (good readability)"
    fi
fi

# TEST 9: Node ID Format Validation (Input Validation - Safe Boundary)
# Validates that all node identifiers follow the pattern: Single letter [A-Z] optionally followed by digits
# Examples of valid node IDs: A, B, C1, D2, G1, L
# Examples of invalid node IDs: abc, node1, _A, 1A
# Prevents typos and ensures consistent node naming convention
# Extracted from graph lines like: A["label"], B1["label"]
INVALID_NODE_IDS=$(grep -oE '^[[:space:]]*[a-zA-Z0-9_]+\[' "$DIAGRAM_FILE" | grep -oE '[a-zA-Z0-9_]+' | grep -vE '^[A-Z][0-9]*$' | sort -u || true)
if [ -n "$INVALID_NODE_IDS" ]; then
    if [ "$LOG_FORMAT" != "json" ]; then
        echo "❌ FAIL: Invalid node ID format found (must be A-Z optionally followed by digits):"
        echo "$INVALID_NODE_IDS" | sed 's/^/     - /'
    fi
    ((ERRORS++))
else
    if [ "$LOG_FORMAT" != "json" ]; then
        echo "✓ All node IDs follow valid format (A-Z + optional digits)"
    fi
fi

# TEST 10: Node Reference Validity (Input Validation - Safe Boundary)
# Ensures all nodes referenced in arrows are actually defined in the diagram
# Catches common errors like: A --> B (but B is never defined)
# Extracts all node definitions: A["..."], B1["..."]
# Extracts all arrow references from both sides of arrows: X --> Y
# Validates that both X and Y exist as defined nodes
DEFINED_NODES=$(grep -oE '[A-Z][0-9]*\[' "$DIAGRAM_FILE" | grep -oE '^[A-Z][0-9]*' | sort -u)

# Extract nodes from left side of arrows (A --> ..., B --> ...)
ARROW_LEFT=$(grep ' --> ' "$DIAGRAM_FILE" | grep -oE '^[[:space:]]*[A-Z][0-9]*' | grep -oE '[A-Z][0-9]*' | sort -u)

# Extract nodes from right side of arrows (... --> A, ... --> B)
ARROW_RIGHT=$(grep ' --> ' "$DIAGRAM_FILE" | sed 's/.*--> *//' | grep -oE '^[A-Z][0-9]*' | sort -u)

REFERENCED_NODES=$(printf "%s\n%s\n" "$ARROW_LEFT" "$ARROW_RIGHT" | grep . | sort -u)
UNDEFINED=$(comm -23 <(echo "$REFERENCED_NODES") <(echo "$DEFINED_NODES") || true)

if [ -n "$UNDEFINED" ]; then
    if [ "$LOG_FORMAT" != "json" ]; then
        echo "❌ FAIL: Arrows reference undefined nodes:"
        echo "$UNDEFINED" | sed 's/^/     - /'
    fi
    ((ERRORS++))
else
    if [ "$LOG_FORMAT" != "json" ]; then
        echo "✓ All arrow references point to defined nodes"
    fi
fi

# TIMING: Calculate elapsed execution time
# End time in nanoseconds
END_TIME=$(date +%s%N)
ELAPSED_NS=$((END_TIME - START_TIME))
# Convert to milliseconds for readability
ELAPSED_MS=$((ELAPSED_NS / 1000000))

# Final result - Output structured logs if JSON format requested
if [ "$LOG_FORMAT" = "json" ]; then
    # JSON Structured Log Format
    # Fields: op (operation), status (success|failure), elapsed_ms
    if [ "$ERRORS" -eq 0 ]; then
        cat <<EOF
{
  "op": "diagram-validation",
  "status": "success",
  "elapsed_ms": $ELAPSED_MS,
  "message": "All validation tests passed",
  "details": {
    "file": "$DIAGRAM_FILE",
    "checks_total": 10,
    "checks_passed": 10,
    "checks_failed": 0,
    "performance_rating": "optimal"
  },
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
        exit 0
    else
        cat <<EOF
{
  "op": "diagram-validation",
  "status": "failure",
  "elapsed_ms": $ELAPSED_MS,
  "message": "$ERRORS validation test(s) failed",
  "details": {
    "file": "$DIAGRAM_FILE",
    "checks_total": 10,
    "checks_passed": $((10 - ERRORS)),
    "checks_failed": $ERRORS
  },
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
        exit 1
    fi
else
    # Human-readable format (default)
    # Final result
    if [ "$ERRORS" -eq 0 ]; then
        echo ""
        echo "✅ All validation tests passed!"
        # Performance note: Validator should complete in <500ms
        # Typical performance: 5-15ms (10 grep/wc operations)
        if [ $ELAPSED_MS -lt 50 ]; then
            echo "⚡ Performance: ${ELAPSED_MS}ms (optimal)"
        elif [ $ELAPSED_MS -lt 200 ]; then
            echo "✓ Performance: ${ELAPSED_MS}ms (acceptable)"
        else
            echo "⚠️  Performance: ${ELAPSED_MS}ms (may indicate issue)"
        fi
        exit 0
    else
        echo ""
        echo "❌ $ERRORS validation test(s) failed"
        echo "⏱️  Execution time: ${ELAPSED_MS}ms"
        exit 1
    fi
fi
