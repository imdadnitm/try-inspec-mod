# Test Suite

This directory contains deterministic validation tests that don't require Docker, InSpec, or external dependencies.

## Available Tests

### `validate-mermaid.sh` (Production Validator)
Validates the Mermaid diagram syntax in `ai-track-docs/architecture.mmd`.

**Purpose**: Ensure architecture diagram maintains valid syntax for rendering and documentation consistency.

**Documentation**: Each test includes a docstring header explaining:
- What it validates
- Why it matters (catches what type of errors)
- What it prevents

**Tests**: 10 deterministic checks
1-8: Original syntax validation (structure, labels, connections)
9-10: **NEW Input Validation at Safe Boundary** (format, references)

**Run (Human-Readable)**:
```bash
chmod +x validate-mermaid.sh
./validate-mermaid.sh
```

**Run with Structured Logging** (JSON format):
```bash
LOG_FORMAT=json ./validate-mermaid.sh
```

**Structured Log Example**:
```json
{
  "op": "diagram-validation",
  "status": "success",
  "elapsed_ms": 37,
  "message": "All validation tests passed",
  "details": {
    "file": "ai-track-docs/architecture.mmd",
    "checks_total": 10,
    "checks_passed": 10,
    "checks_failed": 0,
    "performance_rating": "optimal"
  },
  "timestamp": "2026-08-24T18:31:02Z"
}
```

**Structured Logging**: See [STRUCTURED-LOGGING.md](../ai-track-docs/STRUCTURED-LOGGING.md) for complete guide on viewing, parsing, and using JSON logs in CI/CD pipelines.

---

### `validate-mermaid-negative-tests.sh` (Negative Test Suite)
**NEW** — Demonstrates input validation catches common errors at the validator boundary.

**Purpose**: Verify validator rejects invalid diagrams before processing; ensures robustness against user mistakes.

**Tests**: 6 negative scenarios
- Invalid Node ID (lowercase letters)
- Undefined Node Reference (arrow to non-existent node)
- Empty Node Label
- Unbalanced Brackets
- Missing Graph Declaration
- Invalid Node ID with Underscore

**Run**:
```bash
bash validate-mermaid-negative-tests.sh
```

**Expected Output**:
```
📋 Negative Input Validation Tests
Testing error detection at validator boundary

Test 1: Invalid Node ID - lowercase letters
❌ FAIL: [validator correctly rejects]
Test 2: Arrow references undefined node
❌ FAIL: [validator correctly rejects]
... (4 more tests)

════════════════════════════════════════════════════════════
✅ Input Validation: 6/6 errors correctly detected
════════════════════════════════════════════════════════════

✅ Input validation at boundary is working!
```

**Key Insight**: Output shows "FAIL" from the perspective of the bad diagrams (they fail to validate), but the summary confirms all errors were **correctly detected** by the validator.

---

### `benchmark-validator.sh` (Performance Benchmark)
**NEW** — Micro-benchmark for validator performance and regression detection.

**Purpose**: Establish baseline performance, measure variance, detect regression.

**Metrics**: 
- Average execution time
- Min/max variance
- Performance rating (Optimal/Acceptable/Slow)

**Baseline**: 37ms average, 4ms variance (36-40ms range)

**Run**:
```bash
bash benchmark-validator.sh
```

**Output** (first run):
```
📊 Mermaid Validator Micro-Benchmark
Running 10 iterations...
  Run 1: 38ms
  Run 2: 38ms
  ... (8 more runs)

════════════════════════════════════════════════════════════
Performance Summary (10 runs)
════════════════════════════════════════════════════════════
Average:  37ms
Min:      36ms
Max:      40ms
Variance: 4ms (range: 36-40ms)

Rating: ⚡ OPTIMAL

Recording baseline...
✅ Baseline saved to: tests/.validate-baseline.txt
```

**Output** (subsequent runs, with regression detection):
```
Baseline Comparison:
  Previous: 37ms
  Current:  39ms
  Change:   +2ms (+5%) ✅ acceptable
```

**See Also**: [PERFORMANCE.md](../ai-track-docs/PERFORMANCE.md) for detailed timing analysis and variance notes.

**What it tests** (8 deterministic checks):
1. ✓ File exists and is readable
2. ✓ File is not empty
3. ✓ Contains Mermaid `graph` declaration
4. ✓ Brackets are balanced (correct `[` and `]` count)
5. ✓ Diagram has sufficient content (minimum 3 lines)
6. ✓ All nodes have labels (no empty brackets)
7. ✓ Contains valid arrow connections (`-->`)
8. ✓ Organizational comments present (readability indicator)

**Exit codes**:
- `0` = All tests passed
- `1` = One or more tests failed

**Sample output**:
```
🔍 Validating Mermaid diagram: ai-track-docs/architecture.mmd
✓ File exists
✓ File is not empty
✓ Contains Mermaid graph declaration
✓ Brackets are balanced (12 pairs)
✓ Diagram has sufficient content (21 lines)
✓ All nodes have labels
✓ Contains 12 node connections
✓ Contains 4 organizational comments (good readability)

✅ All validation tests passed!
```

---

## Why This Module?

The Mermaid diagram validator is a **deterministic unit test** for `ai-track-docs/architecture.mmd`:

| Criterion | Why Safe |
|-----------|----------|
| **No Docker required** | Pure file validation with bash |
| **No InSpec required** | Syntax-only checks, no execution |
| **Deterministic** | Same input → same output, every time |
| **Zero dependencies** | Uses only bash built-ins (`grep`, `wc`, `wc`) |
| **Fast** | Completes in milliseconds |
| **Reversible** | Changes to diagram don't break other systems |
| **Clear pass/fail** | 7 objective criteria, binary result |

---

## Running All Tests

```bash
# From repository root
./tests/validate-mermaid.sh && echo "✅ All tests passed"
```

Integrate into CI/CD:
```yaml
- name: Run documentation tests
  run: ./tests/validate-mermaid.sh
```

---

## Future Tests

As the project grows, add more deterministic validation:
- JSON schema validation for `inspec.yml`
- Markdown linting for documentation
- Control naming convention checks
- Dependency version constraint validation

---

## Extending the Architecture Diagram

For detailed guidance on modifying and extending `ai-track-docs/architecture.mmd`, see:

**[ARCHITECTURE-EXTENDING.md](../ai-track-docs/ARCHITECTURE-EXTENDING.md)**

Topics covered:
- Adding new nodes and connections
- Safely refactoring sections
- Common extensions (CI/CD, error handling, etc.)
- Testing your changes
- Validator rules reference
- Troubleshooting

Quick reference: All changes must pass `./tests/validate-mermaid.sh` (8 automated checks)
