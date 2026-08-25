# Structured Logging Guide

## Overview

This document explains how to enable and use structured logging in validator operations. Structured logs provide consistent, machine-readable output with standard fields: `op` (operation), `status` (result), and `elapsed_ms` (execution time).

---

## Quick Start

### Enable JSON Structured Logs

```bash
# Set LOG_FORMAT environment variable before running validator
LOG_FORMAT=json ./tests/validate-mermaid.sh
```

### View Human-Readable Output (Default)

```bash
# Default format (no environment variable needed)
./tests/validate-mermaid.sh
```

---

## Structured Log Format

### JSON Output Fields

**Standard fields** (all logs):
- `op` — Operation name (e.g., "diagram-validation")
- `status` — Result status: "success" or "failure"
- `elapsed_ms` — Total execution time in milliseconds
- `timestamp` — UTC timestamp of log entry

**Message & details**:
- `message` — Human-readable result summary
- `details` — Operation-specific data (file, checks, ratings)

### Example: Success Log

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

### Example: Failure Log

```json
{
  "op": "diagram-validation",
  "status": "failure",
  "elapsed_ms": 12,
  "message": "1 validation test(s) failed",
  "details": {
    "file": "ai-track-docs/architecture.mmd",
    "checks_total": 10,
    "checks_passed": 9,
    "checks_failed": 1
  },
  "timestamp": "2026-08-24T18:31:05Z"
}
```

---

## Viewing Structured Logs

### 1. Direct Output

```bash
LOG_FORMAT=json ./tests/validate-mermaid.sh
# Output: Single JSON object to stdout
```

### 2. Pretty-Print with `jq`

```bash
# Install jq (JSON query tool)
brew install jq  # macOS
apt-get install jq  # Linux

# Pretty-print log output
LOG_FORMAT=json ./tests/validate-mermaid.sh | jq .

# Extract specific fields
LOG_FORMAT=json ./tests/validate-mermaid.sh | jq '.status'  # → "success"
LOG_FORMAT=json ./tests/validate-mermaid.sh | jq '.elapsed_ms'  # → 37
```

### 3. Save to Log File

```bash
# Append to log file
LOG_FORMAT=json ./tests/validate-mermaid.sh >> validation.log

# View log file
cat validation.log

# Parse specific logs (one per line)
jq '.op, .status, .elapsed_ms' validation.log
```

### 4. Filter & Analyze Logs

```bash
# Extract failures only
cat validation.log | jq 'select(.status == "failure")'

# Show execution times for all runs
cat validation.log | jq '.elapsed_ms'

# Count passes vs failures
cat validation.log | jq '.status' | sort | uniq -c
```

### 5. Monitor Performance Regression

```bash
# Run multiple times, capture times
for i in {1..10}; do
  LOG_FORMAT=json ./tests/validate-mermaid.sh >> perf.log
done

# Analyze performance
cat perf.log | jq '.elapsed_ms' | \
  awk '{sum+=$0; sumsq+=$0*$0; n++}
       END {
         print "Runs:", n
         print "Mean:", sum/n "ms"
         print "Min:", min "ms"
         print "Max:", max "ms"
       }'
```

---

## Use Cases

### 1. CI/CD Integration

```yaml
# GitHub Actions: Capture structured logs
- name: Validate diagram
  run: LOG_FORMAT=json ./tests/validate-mermaid.sh | tee diagram-validation.log

- name: Upload logs
  uses: actions/upload-artifact@v3
  with:
    name: validation-logs
    path: diagram-validation.log
```

### 2. Local Development

```bash
# Run with human-readable output (default)
./tests/validate-mermaid.sh

# If validation fails, re-run with detailed logging
LOG_FORMAT=json ./tests/validate-mermaid.sh | jq .
```

### 3. Performance Tracking

```bash
# Baseline performance (initial run)
LOG_FORMAT=json ./tests/validate-mermaid.sh > .validate-baseline.json

# Compare current run to baseline
BASELINE=$(cat .validate-baseline.json | jq '.elapsed_ms')
CURRENT=$(LOG_FORMAT=json ./tests/validate-mermaid.sh | jq '.elapsed_ms')

if [ $CURRENT -gt $((BASELINE * 2)) ]; then
  echo "⚠️  Performance regression detected!"
  echo "Baseline: ${BASELINE}ms → Current: ${CURRENT}ms"
fi
```

### 4. Debugging

```bash
# Capture full output on failure
LOG_FORMAT=json ./tests/validate-mermaid.sh > current-run.log

# Compare to known-good run
diff known-good.log current-run.log

# Extract details for inspection
jq '.details' current-run.log
```

---

## Environment Variables

### LOG_FORMAT

Control output format for validators:

```bash
# Default (human-readable)
LOG_FORMAT=human ./tests/validate-mermaid.sh

# Structured JSON (machine-parseable)
LOG_FORMAT=json ./tests/validate-mermaid.sh

# Omitted/empty: defaults to human
./tests/validate-mermaid.sh
```

### Future Options

Potential formats for extension (not yet implemented):

- `LOG_FORMAT=csv` — Comma-separated values
- `LOG_FORMAT=jsonl` — JSON Lines (one JSON object per line)
- `LOG_FORMAT=xml` — XML structured format
- `LOG_FORMAT=yaml` — YAML format

---

## Structured Logging Fields Reference

### Operation Fields

| Field | Type | Example | Always Present |
|-------|------|---------|---|
| `op` | string | "diagram-validation" | ✅ Yes |
| `status` | string | "success" / "failure" | ✅ Yes |
| `elapsed_ms` | number | 37 | ✅ Yes |
| `timestamp` | string (ISO 8601) | "2026-08-24T18:31:02Z" | ✅ Yes |

### Message & Details

| Field | Type | Example | When Present |
|-------|------|---------|---|
| `message` | string | "All validation tests passed" | ✅ Always |
| `details` | object | {checks_total: 10, ...} | ✅ Always |

### Details Subfields (validation-specific)

| Field | Type | Example | Description |
|-------|------|---------|---|
| `file` | string | "ai-track-docs/architecture.mmd" | Target file |
| `checks_total` | number | 10 | Total checks run |
| `checks_passed` | number | 10 | Passed checks |
| `checks_failed` | number | 0 | Failed checks |
| `performance_rating` | string | "optimal" | Performance assessment |

---

## Logging Across Operations

### Benchmark Validator

**Not yet structured** (planned for future enhancement):
```bash
# Current: human-readable output only
bash tests/benchmark-validator.sh

# Future: will support LOG_FORMAT=json
```

### Negative Tests

**Not yet structured** (planned for future enhancement):
```bash
# Current: human-readable output only
bash tests/validate-mermaid-negative-tests.sh

# Future: will support LOG_FORMAT=json
```

### Profile Validation

**Not managed by this project** (InSpec handles):
```bash
# InSpec's native logging (not JSON structured)
cd docker-profile-1
inspec check .
inspec exec .

# To capture as structured logs, wrap with JSON output:
LOG_FORMAT=json inspec exec . --reporter json:report.json
```

---

## Troubleshooting

### JSON Output Not Pretty

If output appears on a single line:

```bash
# Use jq to pretty-print
LOG_FORMAT=json ./tests/validate-mermaid.sh | jq .
```

### jq Not Available

Install JSON query tool:
```bash
brew install jq  # macOS
apt-get install jq  # Linux
yum install jq  # RHEL/CentOS
```

### Parsing JSON in Scripts

```bash
# Extract field in shell script
STATUS=$(LOG_FORMAT=json ./tests/validate-mermaid.sh | jq -r '.status')
if [ "$STATUS" = "success" ]; then
    echo "✅ Validation passed"
else
    echo "❌ Validation failed"
fi
```

### Combining with Other Commands

```bash
# Chain validation with next steps based on result
LOG_FORMAT=json ./tests/validate-mermaid.sh | \
  jq -e '.status == "success"' > /dev/null && \
  echo "Proceeding with next steps" || \
  echo "Validation failed, stopping"
```

---

## Related Documentation

- [build-test.md](build-test.md) — Build and test procedures
- [PERFORMANCE.md](PERFORMANCE.md) — Performance benchmarking guide
- [tests/README.md](../tests/README.md) — Test suite documentation

---

## Key Takeaways

1. **Enable structured logs**: Set `LOG_FORMAT=json` before running validators
2. **Standard fields**: All logs include op, status, elapsed_ms, timestamp
3. **Parse with jq**: Use JSON query tool for filtering and analysis
4. **CI/CD ready**: Capture logs to files for tracking and automation
5. **Performance monitoring**: Track elapsed_ms to detect regressions
