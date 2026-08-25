# Logging Guide

## Overview

Logging provides visibility into system behavior, performance, and errors. This guide covers logging principles, best practices, and implementation patterns used across this project.

---

## Logging Levels

Logs serve different purposes depending on what information they contain:

### 1. **Operational Logs**
Track what the system is doing in normal operation.

**Example**: Validator completing successfully
```
✅ All validation tests passed!
```

**When to use**: 
- Normal operations completing
- Milestones reached
- State transitions

---

### 2. **Performance Logs**
Track how fast operations execute.

**Example**: Execution time
```
⚡ Performance: 43ms (optimal)
```

**When to use**:
- Measuring operation duration
- Detecting regression
- Tracking performance trends

---

### 3. **Error Logs**
Track what went wrong and why.

**Example**: Validation failure
```
❌ Validation failed: Node ID contains invalid character
```

**When to use**:
- Operation failed
- Unexpected state
- User input invalid

---

### 4. **Debug Logs**
Detailed information for troubleshooting.

**Example**: Check results in order
```
Test 1: File exists ✓
Test 2: Valid graph structure ✓
Test 3: Valid node IDs ✓
```

**When to use**:
- Diagnosing issues
- Understanding operation flow
- Development & testing

---

## Structured vs Unstructured Logging

### Unstructured Logging (Human-Readable)

Best for: Interactive use, terminal output, quick visual inspection

```
🔍 Validating Mermaid diagram: ai-track-docs/architecture.mmd
✓ File exists
✓ Contains valid Mermaid graph declaration
✓ Graph has valid structure
✓ All nodes are properly labeled
✓ Node connections are valid
✓ No duplicate node definitions
✓ Graph is acyclic (no circular references)
✓ All node IDs follow valid format (A-Z + optional digits)
✓ All arrow references point to defined nodes

✅ All validation tests passed!
⚡ Performance: 43ms (optimal)
```

**Pros**:
- Easy to read on terminal
- Good for human operators
- Emoji/colors improve clarity

**Cons**:
- Hard to parse programmatically
- Format varies (inconsistent structure)
- Difficult for CI/CD automation

---

### Structured Logging (JSON)

Best for: CI/CD pipelines, automation, log aggregation, machine parsing

```json
{
  "op": "diagram-validation",
  "status": "success",
  "elapsed_ms": 43,
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

**Pros**:
- Machine-parseable (JSON standard)
- Consistent structure (all logs same format)
- Easy filtering (jq, grep, etc.)
- CI/CD friendly (automation)

**Cons**:
- Less readable at terminal
- Requires JSON tools to parse
- More verbose (more bytes)

---

## When to Use Each

### Use Unstructured Logging When:
- Developer running locally: `./tests/validate-mermaid.sh`
- Quick visual feedback needed
- Human reading output in terminal
- Testing/debugging interactively

### Use Structured Logging When:
- CI/CD pipeline running checks
- Aggregating logs from multiple runs
- Detecting performance regression
- Automating based on results
- Storing logs for analysis

---

## Enabling Structured Logs

### Per-Operation Control

Use environment variable to enable JSON output:

```bash
# Default: human-readable
./tests/validate-mermaid.sh

# JSON structured logs
LOG_FORMAT=json ./tests/validate-mermaid.sh
```

### In CI/CD Pipeline

```yaml
# GitHub Actions example
- name: Validate diagram
  run: LOG_FORMAT=json ./tests/validate-mermaid.sh | tee validation.log
```

---

## Structured Logging Fields

### Standard Fields (All Logs)

Every structured log includes these fields:

| Field | Type | Purpose | Example |
|-------|------|---------|---------|
| `op` | string | Operation identifier | "diagram-validation" |
| `status` | string | Result: "success" or "failure" | "success" |
| `elapsed_ms` | number | Execution time (milliseconds) | 43 |
| `timestamp` | string | When log was created (ISO 8601 UTC) | "2026-08-24T18:31:02Z" |

### Message & Details

| Field | Type | Purpose | Example |
|-------|------|---------|---------|
| `message` | string | Human summary | "All validation tests passed" |
| `details` | object | Operation-specific data | `{checks_total: 10, ...}` |

### Details Structure (Operation-Specific)

For diagram validation, `details` contains:

```json
{
  "file": "ai-track-docs/architecture.mmd",
  "checks_total": 10,
  "checks_passed": 10,
  "checks_failed": 0,
  "performance_rating": "optimal"
}
```

---

## Parsing Structured Logs

### With jq (JSON Query Tool)

Pretty-print:
```bash
LOG_FORMAT=json ./tests/validate-mermaid.sh | jq .
```

Extract field:
```bash
LOG_FORMAT=json ./tests/validate-mermaid.sh | jq '.status'
# → "success"
```

Filter results:
```bash
LOG_FORMAT=json ./tests/validate-mermaid.sh | jq 'select(.status == "failure")'
```

### In Shell Scripts

```bash
#!/bin/bash

# Run validator and capture output
OUTPUT=$(LOG_FORMAT=json ./tests/validate-mermaid.sh)

# Extract status
STATUS=$(echo "$OUTPUT" | jq -r '.status')

# Conditional logic
if [ "$STATUS" = "success" ]; then
    echo "✅ Validation passed, proceeding..."
else
    echo "❌ Validation failed"
    exit 1
fi
```

---

## Logging Best Practices

### 1. **Log at Natural Boundaries**

Log when:
- Operation starts
- Operation completes (success)
- Operation fails with reason
- Major milestones reached

**Don't**: Log every single check/step (too verbose)

### 2. **Include Context**

Good:
```json
{
  "op": "diagram-validation",
  "file": "ai-track-docs/architecture.mmd",
  "status": "failure",
  "message": "Node ID contains invalid character"
}
```

Bad:
```json
{
  "status": "failure",
  "message": "Error"
}
```

### 3. **Use Consistent Fields**

Every log should have: `op`, `status`, `elapsed_ms`, `timestamp`

This allows:
- Filtering across different operations
- Performance tracking
- Aggregation tools

### 4. **Include Timing Data**

Always measure and report `elapsed_ms`:
- Detects performance regression
- Identifies slow operations
- Tracks optimization benefits

### 5. **Keep Logs Concise**

**Good**: `"message": "All validation tests passed"`

**Bad**: `"message": "The diagram validation process has completed successfully with all 10 tests passing without any errors detected"`

---

## Use Cases

### 1. Local Development

**How**: Run with default (human-readable) format
```bash
./tests/validate-mermaid.sh
```

**Why**: Emoji and colors make output easy to scan

---

### 2. CI/CD Pipeline

**How**: Capture JSON logs to file
```yaml
- run: LOG_FORMAT=json ./tests/validate-mermaid.sh >> validation.log
- uses: actions/upload-artifact@v3
  with:
    name: validation-logs
    path: validation.log
```

**Why**: JSON is machine-parseable, can be processed by next steps

---

### 3. Performance Monitoring

**How**: Extract elapsed_ms and track over time
```bash
for i in {1..10}; do
  LOG_FORMAT=json ./tests/validate-mermaid.sh | jq '.elapsed_ms'
done
```

**Why**: Detect regression, ensure performance remains optimal

---

### 4. Failure Analysis

**How**: Filter for failures and examine details
```bash
cat validation.log | jq 'select(.status == "failure")' | jq '.details'
```

**Why**: Understand what went wrong and why

---

### 5. Audit Trail

**How**: Keep all logs with timestamps for compliance
```bash
LOG_FORMAT=json ./tests/validate-mermaid.sh >> logs/audit-trail.log
```

**Why**: Demonstrate system behavior over time, troubleshoot issues later

---

## Common Patterns

### Pattern 1: Success/Failure Branching

```bash
if LOG_FORMAT=json ./tests/validate-mermaid.sh | jq -e '.status == "success"' > /dev/null; then
    echo "✅ Validation passed"
    # next steps
else
    echo "❌ Validation failed"
    exit 1
fi
```

### Pattern 2: Log Aggregation

```bash
# Run multiple checks, collect results
(
  LOG_FORMAT=json ./tests/validate-mermaid.sh
  LOG_FORMAT=json ./tests/benchmark-validator.sh
) | tee combined-logs.json
```

### Pattern 3: Performance Tracking

```bash
# Save baseline
LOG_FORMAT=json ./tests/validate-mermaid.sh | jq '.elapsed_ms' > baseline.txt

# Compare current run
CURRENT=$(LOG_FORMAT=json ./tests/validate-mermaid.sh | jq '.elapsed_ms')
BASELINE=$(cat baseline.txt)

if [ $CURRENT -gt $((BASELINE * 2)) ]; then
    echo "⚠️  Performance degraded: $BASELINE ms → $CURRENT ms"
fi
```

---

## Troubleshooting

### JSON Output Not Pretty

**Problem**: Output appears on one line
```
{"op":"diagram-validation",...}
```

**Solution**: Use jq to pretty-print
```bash
LOG_FORMAT=json ./tests/validate-mermaid.sh | jq .
```

---

### Can't Parse JSON

**Problem**: `jq: command not found`

**Solution**: Install jq
```bash
brew install jq  # macOS
apt-get install jq  # Linux
```

---

### Extract Field Returns null

**Problem**: 
```bash
LOG_FORMAT=json ./tests/validate-mermaid.sh | jq '.missing_field'
# → null
```

**Solution**: Check available fields
```bash
LOG_FORMAT=json ./tests/validate-mermaid.sh | jq 'keys'
# → ["op", "status", "elapsed_ms", "message", "details", "timestamp"]
```

---

## Related Documentation

- [STRUCTURED-LOGGING.md](STRUCTURED-LOGGING.md) — Complete structured logging guide with advanced examples
- [PERFORMANCE.md](PERFORMANCE.md) — Performance tracking and benchmarking
- [build-test.md](build-test.md) — Build and test procedures
- [tests/README.md](../tests/README.md) — Test suite documentation

---

## Key Takeaways

1. **Use unstructured logs for interactive development** — Human-readable, emoji/colors help
2. **Use structured logs for CI/CD & automation** — JSON is machine-parseable
3. **Standard fields ensure consistency** — op, status, elapsed_ms, timestamp in every log
4. **Include timing data** — Track performance regression
5. **Keep logs concise** — Focus on what matters
6. **Log at boundaries** — When operations start/complete/fail
7. **Parse with jq** — Standard JSON tool for filtering & analysis

---

## Quick Reference

| Task | Command |
|------|---------|
| Human-readable output | `./tests/validate-mermaid.sh` |
| JSON output | `LOG_FORMAT=json ./tests/validate-mermaid.sh` |
| Pretty-print JSON | `LOG_FORMAT=json ./tests/validate-mermaid.sh \| jq .` |
| Extract status | `LOG_FORMAT=json ./tests/validate-mermaid.sh \| jq '.status'` |
| Save to file | `LOG_FORMAT=json ./tests/validate-mermaid.sh >> logs.json` |
| Filter failures | `cat logs.json \| jq 'select(.status == "failure")'` |
| Extract timing | `cat logs.json \| jq '.elapsed_ms'` |
