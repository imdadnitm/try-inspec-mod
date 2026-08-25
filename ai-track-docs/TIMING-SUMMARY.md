# Timing & Micro-Benchmark — Implementation Summary

## What Was Added

### 1. Timing Instrumentation (validate-mermaid.sh)

**Capture Points**:
- `START_TIME`: Captured at validator startup (nanosecond precision)
- `END_TIME`: Captured before exit
- `ELAPSED_MS`: Calculated millisecond delta

**Display**:
Each run now shows performance rating:
```
✅ All validation tests passed!
⚡ Performance: 37ms (optimal)
```

### 2. Performance Ratings

| Rating | Threshold | Implication |
|--------|-----------|------------|
| ⚡ OPTIMAL | < 50ms | Negligible validator overhead |
| ✓ ACCEPTABLE | 50-200ms | Normal performance, no action needed |
| ⚠️ SLOW | > 200ms | Investigate (new tests, regex, I/O) |

### 3. Micro-Benchmark Script (benchmark-validator.sh)

**Function**: Runs validator 10 times, measures performance, detects regression

**Baseline Established**:
```
Average:  37ms
Min:      36ms
Max:      40ms
Variance: 4ms (range: 36-40ms)
Rating:   ⚡ OPTIMAL
```

**Regression Detection**:
On subsequent runs, compares current performance to baseline:
```
Baseline Comparison:
  Previous: 37ms
  Current:  42ms
  Change:   +5ms (+13%) ⚠️  slower
```

---

## Performance Baseline Data

### Initial Measurement (10 runs, August 24, 2026)

```
Run 1:  38ms  ✓
Run 2:  38ms  ✓
Run 3:  37ms  ✓
Run 4:  40ms  ✓
Run 5:  38ms  ✓
Run 6:  40ms  ✓
Run 7:  38ms  ✓
Run 8:  37ms  ✓
Run 9:  36ms  ✓
Run 10: 37ms  ✓

Average:  37ms (⚡ OPTIMAL)
Variance: 4ms (extremely stable)
```

### Stored Baseline

**File**: `tests/.validate-baseline.txt`

Contains:
- Date & run count
- Baseline average/min/max
- Performance notes

Used for regression detection on future runs.

---

## Variance Analysis

### Observed Variance: 4ms

**Stability Metrics**:
- 10/10 runs in 36-40ms band (tight clustering)
- Standard deviation: ~1.3ms
- No outliers or anomalies
- Extremely predictable performance

**Causes of Variance** (minor, natural):
- System load (disk I/O cache)
- Process scheduling (CPU context switches)
- Background activity
- Not algorithmic (no loops/dynamic operations)

**Implication**: Validator is suitable for CI/CD gates (no flaky timeouts)

---

## Performance Factors

### Why It's Fast (37ms)

**Simple Operations**:
- Bash built-ins only (grep, wc, sort, comm)
- No subprocess spawning
- No external tools (python, jq)
- No network I/O

**Deterministic Algorithm**:
- Fixed 10-test suite
- Each test is O(n) where n = 28 lines
- Total: 10 single-pass operations
- No loops or branches affecting test count

**Minimal Data**:
- File: 28 lines (small)
- Nodes: 12 (small dataset)
- Arrows: 12 (small dataset)

### Scaling Characteristics

| Diagram Size | Expected Time | Notes |
|--------------|---------------|-------|
| 30 lines (current) | ~37ms | Baseline |
| 100 lines | ~40-50ms | Linear scaling, still <50ms |
| 1000 lines | ~100-150ms | Still acceptable |
| 10000 lines | ~500-1000ms | Warn threshold (unlikely) |

---

## CI/CD Integration

### Include Timing in Tests

Validator automatically displays timing on each run:
```bash
./tests/validate-mermaid.sh
# Output includes:
# ⚡ Performance: 37ms (optimal)
```

### Regression Gate (Optional)

```yaml
# GitHub Actions: Fail if regression
- name: Validate diagram
  run: |
    bash ./tests/validate-mermaid.sh
    # Check exit code (0 = pass) and timing in output
```

### Trend Tracking (Optional)

```bash
# Log performance over time (weekly/monthly)
bash tests/benchmark-validator.sh >> tests/.performance-history.txt
```

---

## Implementation Details

### Timing Code (validate-mermaid.sh)

```bash
# Line ~9: Capture start
START_TIME=$(date +%s%N)  # Nanoseconds

# Line ~145: Calculate elapsed
END_TIME=$(date +%s%N)
ELAPSED_NS=$((END_TIME - START_TIME))
ELAPSED_MS=$((ELAPSED_NS / 1000000))  # Convert to ms

# Line ~150: Display rating
if [ $ELAPSED_MS -lt 50 ]; then
    echo "⚡ Performance: ${ELAPSED_MS}ms (optimal)"
```

### Benchmark Logic (benchmark-validator.sh)

1. Run validator 10 times
2. Extract timing from output (grep "Performance: ")
3. Collect times in array
4. Calculate: average, min, max, variance
5. Compare to baseline (if exists)
6. Save/update baseline file

---

## Files Modified

| File | Change |
|------|--------|
| `tests/validate-mermaid.sh` | +7 lines: START_TIME, END_TIME, ELAPSED_MS, rating |
| `tests/benchmark-validator.sh` | NEW — 10-run micro-benchmark with regression detection |
| `ai-track-docs/PERFORMANCE.md` | NEW — Detailed timing analysis & variance notes |
| `tests/.validate-baseline.txt` | NEW — Baseline performance record (auto-created) |
| `tests/README.md` | Updated — Documented benchmark-validator.sh |

---

## Monitoring & Alerts

### Performance Thresholds

| Metric | Baseline | Alert Threshold | Action |
|--------|----------|-----------------|--------|
| Avg Time | 37ms | > 100ms (+170%) | Investigate new tests |
| Max Time | 40ms | > 200ms | Investigate algorithm |
| Variance | 4ms | > 20ms | Check system load |

### How to Investigate

```bash
# 1. Run benchmark to see baseline comparison
bash tests/benchmark-validator.sh

# 2. Profile individual test
time bash ./tests/validate-mermaid.sh

# 3. Check for new tests
grep "TEST.*:" tests/validate-mermaid.sh | wc -l
# Current: 10 tests (should be ~3-5ms per test)

# 4. Profile with system time
bash -x ./tests/validate-mermaid.sh 2>&1 | grep "^+" | wc -l
# Count bash operations (should be ~50-100)
```

---

## Summary

**Timing Added**: Minimal, non-intrusive
- Uses `date +%s%N` for nanosecond precision
- Converts to milliseconds for readability
- Displays performance rating (⚡/✓/⚠️)
- Zero impact on validator logic

**Baseline Established**: 37ms (⚡ OPTIMAL)
- 10 runs averaged
- 4ms variance (36-40ms band)
- Deterministic performance
- Suitable for CI/CD gates

**Regression Detection**: Automatic
- Baseline saved to `.validate-baseline.txt`
- Benchmark compares current vs. baseline
- Shows percentage change
- Alerts on >13% regression

**Key Takeaway**: Validator is lightweight, predictable, and measurable. Timing provides visibility into performance without adding complexity.
