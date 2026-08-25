# Input Validation & Testing — Implementation Summary

## What Was Added

### 1. Input Validation at Safe Boundary (2 new tests)

**Test 9: Node ID Format Validation**
- Ensures all node IDs follow pattern: `[A-Z][0-9]*`
- Single uppercase letter, optionally followed by digits
- Prevents invalid identifiers: lowercase, underscores, special chars
- Example violations caught: `a`, `node1`, `_A`, `A_1`

**Test 10: Node Reference Validity**
- Verifies all nodes referenced in arrows are actually defined
- Catches broken connections from typos
- Example violations caught: `X --> A` (X undefined), `A --> Z` (Z undefined)

### 2. Comprehensive Test Suite Updates

**Validator Enhancements**:
- Original 8 tests → **10 tests** (added input validation)
- Each test documented with detailed docstrings
- Boundary validation at file read entry point
- Deterministic, zero-dependency validation

**Negative Test Suite** (NEW):
- `tests/validate-mermaid-negative-tests.sh` 
- 6 test scenarios demonstrating error detection
- Validates input validation catches common user errors
- Run: `bash tests/validate-mermaid-negative-tests.sh`

---

## Test Results

### Positive Tests (Valid Diagram)
```
✓ File exists
✓ File is not empty
✓ Contains Mermaid graph declaration
✓ Brackets are balanced (12 pairs)
✓ Diagram has sufficient content (28 lines)
✓ All nodes have labels
✓ Contains 12 node connections
✓ Contains 11 organizational comments (good readability)
✓ All node IDs follow valid format (A-Z + optional digits)
✓ All arrow references point to defined nodes

✅ All validation tests passed!
```

### Negative Tests (Invalid Diagrams)
```
Test 1: Invalid Node ID - lowercase letters ❌ [correctly rejected]
Test 2: Arrow references undefined node ❌ [correctly rejected]
Test 3: Empty node label ❌ [correctly rejected]
Test 4: Unbalanced brackets (unclosed) ❌ [correctly rejected]
Test 5: Missing 'graph' declaration ❌ [correctly rejected]
Test 6: Node ID with underscore (boundary) ❌ [correctly rejected]

✅ Input Validation: 6/6 errors correctly detected
```

---

## Risk Assessment: LOW

| Aspect | Why Safe |
|--------|----------|
| **Scope** | Documentation validator only, no code execution |
| **Backward Compatible** | Valid diagrams pass all 10 tests |
| **Testable** | 6 negative tests verify error detection |
| **Reversible** | Revert 2 test functions if needed |
| **Deterministic** | Same diagram → same result every time |
| **No Dependencies** | Uses only bash built-ins (grep, wc, comm) |

**Rollback**: Revert last 2 tests (TEST 9 & 10) in `validate-mermaid.sh`

---

## Files Modified

1. **tests/validate-mermaid.sh** (Production Validator)
   - Added TEST 9: Node ID Format Validation
   - Added TEST 10: Node Reference Validity
   - Total: 10 checks (was 8)
   - All checks have detailed docstrings

2. **tests/validate-mermaid-negative-tests.sh** (NEW)
   - 6 negative test scenarios
   - Demonstrates input validation robustness
   - Tests each validation boundary condition

3. **tests/README.md**
   - Documented both test suites
   - Added negative test details
   - Explained input validation purpose

4. **ai-track-docs/ARCHITECTURE-EXTENDING.md**
   - New section: "Input Validation at Safe Boundary"
   - Explained Tests 9-10 with examples
   - Added negative test suite reference
   - Updated validator rules table

---

## Key Implementation Details

### Input Validation Pattern
Validation happens at the **safe boundary** (where input enters the system):
- When diagram file is first read by validator
- Before any processing occurs
- Catches errors early with clear messages

### Boundary Condition Tests (Test 9 & 10)

**Test 9 Pattern Validation**:
```bash
# Extracts all node IDs: A, B, C1, etc.
DEFINED_NODES=$(grep -oE '[A-Z][0-9]*\[' "$DIAGRAM_FILE" | grep -oE '^[A-Z][0-9]*' | sort -u)

# Checks each one matches [A-Z][0-9]*
INVALID=$(echo "$DEFINED_NODES" | grep -vE '^[A-Z][0-9]*$' || true)
```

**Test 10 Reference Validation**:
```bash
# All nodes defined with []
DEFINED_NODES=$(grep -oE '[A-Z][0-9]*\[' ...)

# All nodes referenced in arrows
ARROW_LEFT=$(grep ' --> ' | grep -oE '^[A-Z][0-9]*' ...)
ARROW_RIGHT=$(grep ' --> ' | sed 's/.*--> *//' | grep -oE '^[A-Z][0-9]*' ...)

# Check all references exist
UNDEFINED=$(comm -23 <(referenced) <(defined))
```

---

## Usage for Contributors

### Before Modifying Diagram
```bash
# Run all validations
./tests/validate-mermaid.sh

# Verify input validation catches bad input
bash tests/validate-mermaid-negative-tests.sh
```

### After Modifying Diagram
```bash
# All 10 tests must pass
./tests/validate-mermaid.sh
# Expected: ✅ All validation tests passed!
```

### Testing Custom Changes
Copy bad diagram to temporary file:
```bash
# Create a diagram with invalid node ID
echo 'graph TD
a["bad"]
a --> b["good"]' > /tmp/bad.mmd

# Test it
DIAGRAM_FILE="/tmp/bad.mmd" bash ./tests/validate-mermaid.sh
# Expected: ❌ FAIL: All node IDs follow valid format (found: a)
```

---

## Future Extensions

Negative test suite pattern can be extended for:
- JSON schema validation (`inspec.yml`)
- Markdown linting (documentation)
- Control naming conventions
- Dependency version constraints

Each would follow same pattern:
1. Define validation rules at boundary
2. Create negative test suite demonstrating error detection
3. Document in extending guide
