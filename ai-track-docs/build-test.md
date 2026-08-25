# Build & Test Guide

## Prerequisites
1. **InSpec CLI**: Install from https://docs.chef.io/inspec/install/
   ```bash
   # Verify installation
   inspec --version
   ```

2. **Docker**: Running Docker daemon required
   ```bash
   docker --version
   docker ps  # Verify connectivity
   ```

3. **Dependencies**: Fetch InSpec dependency
   ```bash
   cd docker-profile-1
   inspec vendor
   ```

---

## Security Best Practices

**Before Building or Testing**:

✅ **Pre-Commit Checklist** (prevent accidental secret commits):
```bash
# 1. Check for hardcoded secrets
git diff --cached | grep -iE "password|secret|key|token|api_key|credential"
# Should return NOTHING ✓

# 2. Verify .env files are NOT staged
git diff --cached | grep ".env"
# Should return NOTHING ✓

# 3. Verify no private keys
git diff --cached | grep -E "\.(pem|key|pkcs8|p8|p12|pfx)$"
# Should return NOTHING ✓
```

**When Running Tests**:
- Never commit `.env` files (always in .gitignore)
- Store Docker credentials in environment (not inspec.yml)
- Use .env.local for local development (ignored by .gitignore)

**Docker Credentials** (example, never commit):
```bash
# .env.local (NOT version controlled, never commit!)
DOCKER_USERNAME=myuser
DOCKER_TOKEN=mytoken

# Load before running tests
source .env.local
inspec exec docker-profile-1/
```

**For Complete Security Guide**: See [SECURITY.md](SECURITY.md)

## Dependency Management

### How Dependencies Are Resolved

**Profile declares** (loose, no version constraint):
```yaml
# docker-profile-1/inspec.yml
depends:
  - name: inspec-docker-resources
    url: https://github.com/inspec/inspec-docker-resources.git
```

**Lock file pins** (deterministic, commit hash locked):
```yaml
# docker-profile-1/inspec.lock
depends:
- name: inspec-docker-resources
  resolved_source:
    url: https://github.com/inspec/inspec-docker-resources/archive/15e068090bf9ec066a1111e13d41c42138b50f1a.tar.gz
    sha256: 5f24bab1f34839a20f9cf43153375d3a26515537fd72319fa5d141e09e5ae030
```

**Workflow**:
1. User runs `inspec vendor` (step 3 above)
2. InSpec reads `inspec.lock` if it exists (uses pinned version)
3. Dependencies extracted to `docker-profile-1/vendor/` directory
4. All users get **same dependency versions** → deterministic builds ✅

### Dependency Constraints Strategy

**Current**: Minimal pinning — no version constraints in inspec.yml
- `inspec-docker-resources` is pinned via commit hash in lock file (deterministic)
- No version constraints (allows flexibility, fewer constraints to maintain)
- Early-stage profile (v0.1.0) unlikely to have breaking changes

**Why This Approach**:
- ✅ Simplicity — fewer constraints = easier maintenance
- ✅ Flexibility — users can test newer versions if desired
- ✅ Determinism — lock file ensures consistent builds
- ✅ Low risk — single external dependency, well-maintained upstream

**For detailed constraints strategy, update procedures, and monitoring**: See [DEPENDENCIES.md](DEPENDENCIES.md)

### Manual Dependency Update

To test or update to a newer version of inspec-docker-resources:

```bash
cd docker-profile-1

# 1. Remove current lock and vendor
rm -rf inspec.lock vendor/

# 2. Re-vendor (fetches latest)
inspec vendor

# 3. Run tests to verify compatibility
inspec exec .

# 4. If all tests pass, commit new lock file
git add inspec.lock
git commit -m "deps: update inspec-docker-resources"

# 5. If tests fail, rollback
git checkout inspec.lock
inspec vendor
```

---

## Exact Build Commands

### 1. Build (Fetch Dependencies)
```bash
cd docker-profile-1
inspec vendor
```
**Expected output**: "Dependencies downloaded to /...vendor/"
**What it does**: Reads `inspec.lock`, fetches pinned inspec-docker-resources, extracts to `vendor/` directory

### 2. Validate Syntax
```bash
cd docker-profile-1
inspec check .
```
**Expected output**: `Profile validation of . succeeded.`

### 3. List Available Controls
```bash
cd docker-profile-1
inspec exec . --controls
```
**Expected output**: Lists all control IDs (e.g., `docker-image-1.0`, `docker-container-1.0`)

---

## Exact Test Commands

### Run All Compliance Controls
```bash
cd docker-profile-1
inspec exec .
```
**Output**: Pass/Fail/Skip results for each control against live Docker daemon

### Run Single Control
```bash
cd docker-profile-1
inspec exec . -c "docker-image-1.0"
```
**Output**: Results for only the specified control

### Generate JSON Report
```bash
cd docker-profile-1
inspec exec . --reporter json:report.json
```
**Output**: `report.json` with detailed test results

### Generate HTML Report
```bash
cd docker-profile-1
inspec exec . --reporter html:report.html
```
**Output**: `report.html` (view in browser)

### Run with Verbose Output
```bash
cd docker-profile-1
inspec exec . -v
```
**Output**: Detailed execution log including resource queries

---

## Deterministic Unit Tests

### Test: Mermaid Diagram Validation
Validates `ai-track-docs/architecture.mmd` syntax without requiring Docker or InSpec.

**Run test**:
```bash
chmod +x tests/validate-mermaid.sh
./tests/validate-mermaid.sh
```

**Expected output**:
```
🔍 Validating Mermaid diagram: ai-track-docs/architecture.mmd
✓ File exists
✓ File is not empty
✓ Contains Mermaid graph declaration
✓ Brackets are balanced (12 pairs)
✓ Diagram has sufficient content (22 lines)
✓ All nodes have labels
✓ Contains 10 node connections

✅ All validation tests passed!
```

**Tests performed** (deterministic, no dependencies):
1. File exists and readable
2. File is not empty
3. Contains Mermaid `graph` declaration
4. Bracket pairs are balanced (`[` count == `]` count)
5. Diagram has minimum content (≥3 lines)
6. All nodes have labels (no empty `[]`)
7. Arrow connections are present and valid

---

## Full Test Suite (All at Once)

```bash
# 1. Build & validate syntax
cd docker-profile-1
inspec vendor && inspec check .

# 2. Run deterministic tests (no Docker required)
cd ..
./tests/validate-mermaid.sh

# 3. Run compliance tests (requires Docker daemon)
cd docker-profile-1
inspec exec . --reporter cli

# 4. Generate reports
inspec exec . --reporter json:report.json
inspec exec . --reporter html:report.html

echo "✅ All tests complete"
```

---

## Test Structure
- Each control in `controls/*.rb` contains one or more tests
- Tests query Docker resources via inspec-docker-resources library
- Results indicate Pass/Fail/Skip for each control

## Local Test Runner

Run all validation tests with a single command:

```bash
bash tests/run-tests.sh
```

**What it runs**:
1. Diagram validation (human-readable)
2. Diagram validation (JSON format)
3. Negative input tests (error detection)
4. Performance benchmark (5 iterations)

**Output**: Summary with pass/fail status, performance metrics, and detailed results

**Results file**: `test-results.json` (contains structured results for CI/CD parsing)

For complete testing documentation: See [CI.md](CI.md)

## Validation Procedures
1. **Dependency Check**: `inspec vendor` should complete without errors
2. **Syntax Check**: `inspec check .` validates control syntax
3. **Control Listing**: `inspec exec . --controls` shows runnable controls
4. **Test Execution**: `inspec exec .` runs all controls against live Docker daemon
5. **Diagram Validation**: `bash tests/run-tests.sh` validates all documentation tests

## Common Issues
- **Docker Daemon Not Accessible**: Verify Docker socket permissions and InSpec runner environment
- **Dependency Resolution Failed**: Check internet connectivity and GitHub URL access
- **Missing Dependencies**: Run `inspec vendor` to download and lock dependencies
- **Mermaid Validator Fails**: Check `ai-track-docs/architecture.mmd` for syntax errors (unbalanced brackets, missing labels)
- **Tests fail locally**: Run with `bash tests/run-tests.sh` for comprehensive diagnostics

## CI/CD Integration

### Automated Testing with GitHub Actions

GitHub Actions workflow automatically:
- Runs on every push to `main` or `learn/**` branches
- Runs on every pull request to `main`
- Blocks merge if tests fail (red X in PR)
- Archives test results for analysis

**Workflow file**: [.github/workflows/test.yml](.github/workflows/test.yml)

### Local Testing Before Push

```bash
# Run full test suite locally
bash tests/run-tests.sh

# Verify exit code (0 = pass, 1 = fail)
echo $?
```

### CI/CD Benefits

✅ **Deterministic tests** — No external dependencies, fast execution (<1s)
✅ **Structured output** — JSON format for easy parsing and automation
✅ **Performance tracking** — Detect regression automatically
✅ **Error detection** — Validate negative cases (bad input rejection)

### Example: GitHub Actions Integration

```yaml
- name: Validate syntax
  run: cd docker-profile-1 && inspec check .
  
- name: Run deterministic tests
  run: bash tests/run-tests.sh

- name: Parse JSON results
  run: |
    PASS_RATE=$(jq '.summary.pass_rate' test-results.json)
    echo "Pass Rate: ${PASS_RATE}%"
  
- name: Run compliance controls (requires Docker)
  run: cd docker-profile-1 && inspec exec .
```

For complete CI/CD documentation: See [CI.md](CI.md)
