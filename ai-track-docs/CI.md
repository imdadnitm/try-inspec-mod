# CI/CD Testing Guide

## Overview

This project uses **automated testing** to ensure code quality and reliability:

- **Local Testing**: Run tests locally with `bash tests/run-tests.sh`
- **CI/CD Pipeline**: GitHub Actions automatically runs tests on every push and PR
- **Exit Codes**: Tests return 0 (pass) or 1 (fail) for easy CI integration

---

## Quick Start

### Local Testing

Run all tests locally:

```bash
bash tests/run-tests.sh
```

Output:
```
╔════════════════════════════════════════════════════════════════════════════╗
║ PROJECT TEST SUITE
╚════════════════════════════════════════════════════════════════════════════╝

Test Configuration
  ℹ️  Working directory: /path/to/project
  ℹ️  Test directory: /path/to/tests
  ℹ️  Timestamp: 2026-08-24T18:39:00Z

Running Tests
  Running: Diagram Validation (Human-Readable)
  ✅ Diagram Validation (Human-Readable)
  ...
  
Test Summary
  Passed:  4 / 4
  Failed:  0 / 4
  Pass Rate: 100%

✅ All tests passed! ✨
```

---

## Test Suite

### 1. Diagram Validation (Human-Readable)

**File**: [tests/validate-mermaid.sh](../tests/validate-mermaid.sh)

**Purpose**: Validate Mermaid diagram syntax with human-friendly output

**Checks**:
- ✓ File exists
- ✓ Contains valid Mermaid graph declaration
- ✓ Graph structure is valid (curly braces)
- ✓ All nodes properly labeled
- ✓ Node connections valid
- ✓ No duplicate node definitions
- ✓ Graph is acyclic (no circular references)
- ✓ Node IDs follow valid format (A-Z + optional digits)
- ✓ Arrow references point to defined nodes

**Duration**: ~40-50ms

**Run**: 
```bash
bash tests/validate-mermaid.sh
```

---

### 2. Diagram Validation (JSON Format)

**Purpose**: Same validation but with structured JSON output for CI/CD automation

**Output Format**: 
```json
{
  "op": "diagram-validation",
  "status": "success",
  "elapsed_ms": 42,
  "message": "All validation tests passed",
  "details": {
    "file": "ai-track-docs/architecture.mmd",
    "checks_total": 10,
    "checks_passed": 10,
    "checks_failed": 0,
    "performance_rating": "optimal"
  },
  "timestamp": "2026-08-24T18:39:00Z"
}
```

**Run**:
```bash
LOG_FORMAT=json bash tests/validate-mermaid.sh
```

**Parse in CI/CD**:
```bash
# Extract status
LOG_FORMAT=json bash tests/validate-mermaid.sh | jq '.status'

# Extract performance
LOG_FORMAT=json bash tests/validate-mermaid.sh | jq '.elapsed_ms'

# Save for analysis
LOG_FORMAT=json bash tests/validate-mermaid.sh >> logs/validation.log
```

---

### 3. Negative Input Validation Tests

**File**: [tests/validate-mermaid-negative-tests.sh](../tests/validate-mermaid-negative-tests.sh)

**Purpose**: Verify validator correctly rejects invalid diagrams

**Test Cases** (should all fail validation):
1. Invalid Node ID with lowercase letters
2. Arrow references undefined node
3. Empty node label
4. Unbalanced brackets
5. Missing graph declaration
6. Invalid Node ID with underscore

**Duration**: ~50-60ms

**Run**:
```bash
bash tests/validate-mermaid-negative-tests.sh
```

**Expected**: 6/6 errors correctly detected

---

### 4. Performance Benchmark

**File**: [tests/benchmark-validator.sh](../tests/benchmark-validator.sh)

**Purpose**: Measure performance and detect regression

**Metrics**:
- Average execution time
- Min/max values
- Variance
- Performance rating (Optimal/Acceptable/Slow)

**Duration**: ~200-300ms (5 runs)

**Run**:
```bash
bash tests/benchmark-validator.sh --runs 5
```

**Baseline Performance**:
- Average: 37ms
- Range: 36-40ms
- Variance: 4ms
- Rating: ⚡ OPTIMAL

---

## GitHub Actions CI/CD

### Workflow Configuration

**File**: [.github/workflows/test.yml](.github/workflows/test.yml)

**Triggers**:
- On every push to `main` or `learn/**` branches
- On every pull request to `main`

**Jobs**:
1. **Setup**: Checkout code and make scripts executable
2. **Test**: Run complete test suite
3. **Report**: Upload test results on failure

### Workflow File

```yaml
name: Test Suite

on:
  push:
    branches: [main, "learn/**"]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Make test scripts executable
        run: |
          chmod +x tests/*.sh

      - name: Run test suite
        run: bash tests/run-tests.sh
        
      - name: Upload test results (on failure)
        if: failure()
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: test-results.json
          retention-days: 30
```

### Workflow Behavior

**On Success** (all tests pass):
- ✅ Green checkmark in PR
- Workflow completes with exit code 0
- Next steps (merge, deploy) can proceed

**On Failure** (any test fails):
- ❌ Red X in PR
- Workflow stops with exit code 1
- Test results artifact uploaded for analysis
- PR blocks merge until tests pass

---

## Test Results

### Local Results File

After running `bash tests/run-tests.sh`, results are saved to:

**File**: `test-results.json`

**Format**:
```json
{
  "timestamp": "2026-08-24T18:39:00Z",
  "summary": {
    "total": 4,
    "passed": 4,
    "failed": 0,
    "pass_rate": 100
  },
  "results": [
    {
      "test": "Diagram Validation (Human-Readable)",
      "status": "pass",
      "exit_code": 0,
      "file": "validate-mermaid.sh"
    },
    ...
  ]
}
```

### Parsing Results

Extract specific information:

```bash
# Total tests
jq '.summary.total' test-results.json

# Pass rate
jq '.summary.pass_rate' test-results.json

# Failed tests only
jq '.results[] | select(.status == "fail")' test-results.json

# Extract exit codes
jq '.results[] | {test: .test, exit_code: .exit_code}' test-results.json
```

---

## Running Tests in Different Contexts

### Before Committing

```bash
# Run all tests locally
bash tests/run-tests.sh

# Check exit code
echo $?  # Should be 0
```

### In Pull Request

Tests run automatically when you:
1. Push commits to your branch
2. Open/update a PR to main
3. Push more commits to PR branch

Check the PR status for test results (green checkmark = pass, red X = fail).

### In CI/CD Pipeline

Tests run on:
- **Ubuntu Linux** (GitHub Actions runner)
- **Bash shell** with standard Unix tools (grep, wc, etc.)
- **No external dependencies** (deterministic, fast)

---

## Performance Targets

| Scenario | Target | Actual | Status |
|----------|--------|--------|--------|
| Single validation | <50ms | 37ms | ✅ OPTIMAL |
| Negative tests | <100ms | 57ms | ✅ OPTIMAL |
| Benchmark (5 runs) | <500ms | 185ms | ✅ OPTIMAL |
| Full suite | <1000ms | ~280ms | ✅ OPTIMAL |

---

## Troubleshooting

### Tests Fail Locally but Pass in CI

**Problem**: Tests work on your machine but fail in GitHub Actions

**Solutions**:
1. Check line endings: `dos2unix tests/*.sh`
2. Verify bash version: `bash --version`
3. Check file permissions: `chmod +x tests/*.sh`
4. Run on same OS: Tests run on Ubuntu in CI

### JSON Output Not Valid

**Problem**: `LOG_FORMAT=json` produces invalid JSON

**Diagnosis**:
```bash
LOG_FORMAT=json bash tests/validate-mermaid.sh | jq .
# If this shows an error, JSON is invalid
```

**Fix**:
- Ensure all quotes are escaped properly
- Check for unescaped newlines in variables
- Verify date command format is correct

### Performance Regression Detected

**Problem**: Tests pass but performance degrades over time

**Investigation**:
```bash
# Compare baseline vs current
cat tests/.validate-baseline.txt
bash tests/benchmark-validator.sh --runs 10

# Look for differences in hardware, shell, etc.
uname -a
bash --version
```

### Tests Timeout in CI

**Problem**: GitHub Actions workflow times out

**Solutions**:
1. **Increase timeout**: Edit `.github/workflows/test.yml`
   ```yaml
   jobs:
     test:
       timeout-minutes: 30  # Increase if needed
   ```

2. **Optimize tests**: 
   - Reduce benchmark iterations
   - Skip heavy tests on every push
   - Use matrix strategy for parallel runs

---

## Best Practices

### For Developers

✅ **DO**:
- Run tests locally before pushing: `bash tests/run-tests.sh`
- Check test results in PR before merging
- Update tests when changing validation logic
- Use `LOG_FORMAT=json` for debugging failed tests

❌ **DON'T**:
- Push without running tests locally
- Ignore failing tests in CI
- Modify test scripts without understanding them
- Run tests with `sudo` or special privileges

### For CI/CD

✅ **DO**:
- Run tests on every push (catch issues early)
- Block merge on failing tests (prevent broken code)
- Archive test results (track trends)
- Report clear pass/fail status

❌ **DON'T**:
- Skip tests to speed up pipeline
- Ignore flaky tests (fix them instead)
- Store test results forever (set retention)
- Run tests in parallel without isolation

---

## Adding New Tests

To add a new test to the suite:

1. **Create test script**: `tests/my-test.sh`
   ```bash
   #!/bin/bash
   # My test description
   
   # Test logic here
   if [ /* test passes */ ]; then
       exit 0
   else
       exit 1
   fi
   ```

2. **Make executable**: `chmod +x tests/my-test.sh`

3. **Update run-tests.sh**: Add call to your test
   ```bash
   run_test "My Test Description" \
       "bash $SCRIPT_DIR/my-test.sh" \
       "my-test.sh"
   ```

4. **Test locally**: `bash tests/run-tests.sh`

5. **Commit**: Add new test file to git

---

## Related Documentation

- [build-test.md](build-test.md) — Build and test procedures
- [STRUCTURED-LOGGING.md](STRUCTURED-LOGGING.md) — Structured logging in tests
- [tests/README.md](../tests/README.md) — Test suite details
- [tests/run-tests.sh](../tests/run-tests.sh) — Test runner implementation

---

## Key Takeaways

1. **Local testing**: Run `bash tests/run-tests.sh` before pushing
2. **CI/CD automatic**: GitHub Actions runs tests on every push/PR
3. **Exit codes matter**: 0 = pass, 1 = fail (used by CI)
4. **Structured logs**: Use `LOG_FORMAT=json` for automation
5. **Fast & reliable**: Tests complete in <500ms, deterministic
6. **No dependencies**: Tests need only bash and standard Unix tools
