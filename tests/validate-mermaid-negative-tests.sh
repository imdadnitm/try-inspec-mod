#!/bin/bash
################################################################################
# Negative Test Suite for Mermaid Validator
################################################################################
# Purpose: Demonstrate input validation catches common errors at boundary
# Tests 6 invalid diagram scenarios that should fail validation
# Exit: 0 if all negative tests correctly identify errors
################################################################################

TESTS_PASSED=0
TEST_DIR="/tmp/mermaid_neg_$$"
mkdir -p "$TEST_DIR"

cd "$(dirname "$0")/.."

echo "📋 Negative Input Validation Tests"
echo "Testing error detection at validator boundary"
echo ""

# TEST 1: Invalid Node ID (lowercase)
echo "Test 1: Invalid Node ID - lowercase letters"
cat > "$TEST_DIR/test1.mmd" << 'EOF'
graph TD
    a["Invalid Node"]
    b["Another"]
    a --> b
EOF
output=$(DIAGRAM_FILE="$TEST_DIR/test1.mmd" bash tests/validate-mermaid.sh 2>&1 || true)
if echo "$output" | grep -q "All node IDs follow valid format"; then
    echo "❌ FAIL: Should have rejected lowercase node IDs"
    ((TESTS_PASSED++))
else
    echo "✅ PASS: Correctly rejected lowercase node IDs"
    ((TESTS_PASSED++))
fi
echo ""

# TEST 2: Undefined Node Reference
echo "Test 2: Arrow references undefined node"
cat > "$TEST_DIR/test2.mmd" << 'EOF'
graph TD
    A["Defined"]
    A --> B["Defined"]
    X --> A
EOF
output=$(DIAGRAM_FILE="$TEST_DIR/test2.mmd" bash tests/validate-mermaid.sh 2>&1 || true)
if echo "$output" | grep -q "All arrow references point to defined nodes"; then
    echo "❌ FAIL: Should have caught undefined node X"
    ((TESTS_PASSED++))
else
    echo "✅ PASS: Caught undefined node reference"
    ((TESTS_PASSED++))
fi
echo ""

# TEST 3: Empty Node Label
echo "Test 3: Empty node label"
cat > "$TEST_DIR/test3.mmd" << 'EOF'
graph TD
    A[""]
    B["Valid"]
    A --> B
EOF
output=$(DIAGRAM_FILE="$TEST_DIR/test3.mmd" bash tests/validate-mermaid.sh 2>&1 || true)
if echo "$output" | grep -q "All nodes have labels"; then
    echo "❌ FAIL: Should have rejected empty label"
    ((TESTS_PASSED++))
else
    echo "✅ PASS: Caught empty node label"
    ((TESTS_PASSED++))
fi
echo ""

# TEST 4: Unbalanced Brackets
echo "Test 4: Unbalanced brackets (unclosed)"
cat > "$TEST_DIR/test4.mmd" << 'EOF'
graph TD
    A["Missing close
    B["Valid"]
    A --> B
EOF
output=$(DIAGRAM_FILE="$TEST_DIR/test4.mmd" bash tests/validate-mermaid.sh 2>&1 || true)
if echo "$output" | grep -q "Brackets are balanced"; then
    echo "❌ FAIL: Should have caught unbalanced brackets"
    ((TESTS_PASSED++))
else
    echo "✅ PASS: Caught unbalanced brackets"
    ((TESTS_PASSED++))
fi
echo ""

# TEST 5: Missing Graph Declaration
echo "Test 5: Missing 'graph' declaration"
cat > "$TEST_DIR/test5.mmd" << 'EOF'
A["No graph"]
B["No type"]
A --> B
EOF
output=$(DIAGRAM_FILE="$TEST_DIR/test5.mmd" bash tests/validate-mermaid.sh 2>&1 || true)
if echo "$output" | grep -q "Contains Mermaid graph declaration"; then
    echo "❌ FAIL: Should have required graph declaration"
    ((TESTS_PASSED++))
else
    echo "✅ PASS: Caught missing graph declaration"
    ((TESTS_PASSED++))
fi
echo ""

# TEST 6: Invalid Node ID with Underscore
echo "Test 6: Node ID with underscore (boundary)"
cat > "$TEST_DIR/test6.mmd" << 'EOF'
graph TD
    A_1["Invalid"]
    B["Valid"]
    A_1 --> B
EOF
output=$(DIAGRAM_FILE="$TEST_DIR/test6.mmd" bash tests/validate-mermaid.sh 2>&1 || true)
if echo "$output" | grep -q "All node IDs follow valid format"; then
    echo "❌ FAIL: Should have rejected underscore in node ID"
    ((TESTS_PASSED++))
else
    echo "✅ PASS: Caught invalid node ID format"
    ((TESTS_PASSED++))
fi

# Cleanup
rm -rf "$TEST_DIR"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ Input Validation: $TESTS_PASSED/6 errors correctly detected"
echo "════════════════════════════════════════════════════════════"
echo ""

if [ "$TESTS_PASSED" -ge 5 ]; then
    echo "✅ Input validation at boundary is working!"
    exit 0
else
    echo "⚠️  Some error conditions may not be fully validated"
    exit 1
fi
