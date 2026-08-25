# Extending the Architecture Diagram

This guide explains how to modify and extend `ai-track-docs/architecture.mmd` while maintaining validator compliance and readability.

---

## Overview: The Architecture Diagram

**File**: `ai-track-docs/architecture.mmd`  
**Format**: Mermaid graph (top-down flow)  
**Purpose**: Visualize InSpec profile execution, dependency resolution, and Docker testing flow  
**Validator**: `tests/validate-mermaid.sh` (8 automated checks)

The diagram has 4 logical sections:
1. **Profile Execution Flow** — How InSpec loads controls
2. **Dependency Resolution** — How Docker resources are loaded
3. **Assertions Bridge** — How assertions use Docker resources
4. **Execution & Reporting** — How tests run and generate reports

---

## Adding a New Node

### Pattern
```mermaid
NodeID["Display Label<br/>with optional<br/>line breaks"]
```

### Example: Add a new node for "Control Metadata"
```mermaid
%% Add inside INSPEC PROFILE EXECUTION FLOW section
    C --> C1["Control Metadata<br/>impact, tags"]
    C1 --> D["Compliance Assertions"]
```

### Steps
1. Choose a unique node ID (e.g., `C1`, `D1`, `X`)
2. Write descriptive label with `<br/>` for line breaks (matches existing style)
3. Add arrow connection (e.g., `C --> C1`) showing data flow
4. Update the section comment if you're adding a new flow
5. **Test**: `./tests/validate-mermaid.sh` must pass
   - Verifies: brackets balanced, nodes have labels, arrows valid

### Validator Checks After Adding
✓ Bracket count increases by 2 (one `[` and `]` pair)  
✓ Arrow count increases by 1 (one `-->`)  
✓ All other tests remain unchanged

---

## Adding a New Connection

### Pattern
```mermaid
SourceID --> DestID
```

### Example: Connect test results to a new reporting flow
```mermaid
L --> L1["CI/CD Pipeline"]
```

### Steps
1. Identify source and destination node IDs (must already exist)
2. Add line: `SourceID --> DestID`
3. Add descriptive comment above if starting new flow
4. **Test**: `./tests/validate-mermaid.sh`
   - Arrow count should increase by 1
   - All other metrics unchanged

### When to Add Section Comments
Add a comment when creating a new logical flow:
```mermaid
%% ===== NEW SECTION NAME =====
%% Explanation of what this section represents
NewNode --> OtherNode
```

---

## Refactoring: Moving/Reorganizing Flows

### Pattern
Reorganize nodes within a section without changing arrows or labels.

### Example: Move "Dependency Resolution" before "Profile Execution"
```bash
# BEFORE:
# Profile → Controls → ... (lines 1-5)
# Dependencies → Resources (lines 8-11)

# AFTER:
# Dependencies → Resources (lines 1-4)
# Profile → Controls → ... (lines 7-12)
```

**CRITICAL**: Don't change node IDs, arrows, or labels — only reorder sections.

### Test Validation
✓ Same number of nodes (12)  
✓ Same number of arrows (12)  
✓ Same bracket count (12 pairs)  
✓ Tests pass identically

---

## Editing Labels: Before & After

### SAFE Changes ✓
These preserve validator checks:
```bash
# Adding context to a label
A["InSpec"] → A["InSpec<br/>v1.3+"]

# Clarifying purpose
F["GitHub"] → F["inspec-docker-resources<br/>GitHub"]

# Breaking long labels
A["Docker Daemon Unix Socket"] → A["Docker Daemon<br/>Unix Socket"]
```

### UNSAFE Changes ✗
These will fail validation:
```bash
# Empty label (fails Test 6: Node Label Quality)
A["Profile"] → A[""]

# Missing brackets (fails Test 4: Bracket Symmetry)
A["Profile"] → A["Profile"  # Missing closing ]

# Corrupted connection (fails Test 7: Arrow Syntax)
A ["Profile"] --> B  # Space before bracket
```

---

## Common Extensions

### Extension 1: Add CI/CD Integration Section
```mermaid
%% ===== CI/CD INTEGRATION =====
%% Shows how reports feed into automated pipelines
L --> M["GitHub Actions"]
M --> N["Report Review"]
N --> O["Compliance Enforcement"]
```

**What to verify**:
1. Test 7: 3 new arrow connections
2. Test 4: 6 new brackets (3 nodes × 2)
3. Test 6: 3 new nodes with non-empty labels

### Extension 2: Add Control Execution Details
```mermaid
%% Inside ASSERTIONS section
    D --> D1["Control Execution<br/>iterate & evaluate"]
    D1 --> D2["Individual Results<br/>Pass/Fail/Skip"]
    D2 --> G  # Connect to Docker Resources
```

### Extension 3: Add Error Handling Path
```mermaid
%% Inside DOCKER INTERACTION section
    H -.->|error| P["Error Log<br/>Debug info"]
    P --> L  # Feed to results
```
(Note: Mermaid uses `-.->` for dotted error flows)

---

## Testing Your Changes

### Quick Validation
```bash
./tests/validate-mermaid.sh
```

Expected output:
```
✓ File exists
✓ File is not empty
✓ Contains Mermaid graph declaration
✓ Brackets are balanced (N pairs)
✓ Diagram has sufficient content (M lines)
✓ All nodes have labels
✓ Contains X node connections
✓ Contains Y organizational comments (good readability)

✅ All validation tests passed!
```

### Visual Verification
1. Copy refactored diagram to https://mermaid.live
2. Verify rendering is readable and arrows flow correctly
3. Check that new nodes/connections appear as intended

### Before Committing
```bash
# 1. Run validator
./tests/validate-mermaid.sh

# 2. Verify diagram renders
# (copy to mermaid.live or use VSCode Mermaid preview)

# 3. Review section comments
grep "^%%" ai-track-docs/architecture.mmd

# 4. Check for readability
wc -l ai-track-docs/architecture.mmd
```

---

## Validator Rules Reference

| Test # | Check | Criteria | Why It Matters |
|--------|-------|----------|---|
| 1 | File Accessibility | File exists & readable | Catches missing/deleted files |
| 2 | Content Presence | File not empty | Prevents corrupted diagrams |
| 3 | Mermaid Syntax | Has `graph` declaration | Ensures valid Mermaid syntax |
| 4 | Bracket Symmetry | Brackets balanced | Catches incomplete node definitions |
| 5 | Diagram Completeness | ≥3 lines content | Prevents trivial/stub diagrams |
| 6 | Node Label Quality | No empty labels | Prevents invisible/broken nodes |
| 7 | Connection Syntax | Valid arrow syntax | Ensures DAG connections valid |
| 8 | Readability | Organizational comments | Encourages maintainability |
| **9** | **Node ID Format (Input Validation)** | **IDs match [A-Z][0-9]*** | **Prevents invalid identifiers** |
| **10** | **Node Reference Validity (Input Validation)** | **All arrow refs defined** | **Catches undefined node errors** |

**Key Insight**: Tests 1-8 validate structure. Tests 9-10 validate input at the safe boundary before processing.

---

## Input Validation at Safe Boundary

### Tests 9-10: Preventing Invalid Input

The validator includes **input validation at the safe boundary** (where diagram files are read) to catch common user errors early:

#### Test 9: Node ID Format Validation
**Rule**: Node IDs must match pattern `[A-Z][0-9]*` (single uppercase letter, optionally followed by digits)

**Valid**: `A`, `B1`, `C2`, `Z9`  
**Invalid**: `a` (lowercase), `node1`, `_A`, `A_1` (underscore)

**Catches**: Typos in node naming that would create silent failures

#### Test 10: Node Reference Validity
**Rule**: All nodes referenced in arrows must be defined somewhere in the diagram

**Valid**: 
```mermaid
A --> B
B --> C
```

**Invalid**:
```mermaid
A --> B
X --> A  % X is never defined!
```

**Catches**: Broken connections from typos in node IDs

---

## Negative Test Suite

### `tests/validate-mermaid-negative-tests.sh`

Demonstrates that input validation catches common errors:

```bash
bash tests/validate-mermaid-negative-tests.sh
```

**Tests 6 invalid scenarios**:
1. Lowercase node IDs → ✅ Rejected
2. Undefined node references → ✅ Rejected
3. Empty node labels → ✅ Rejected
4. Unbalanced brackets → ✅ Rejected
5. Missing graph declaration → ✅ Rejected
6. Node IDs with underscores → ✅ Rejected

**Output shows**: 6/6 errors correctly detected at validator boundary

---

## Troubleshooting

### "Brackets are balanced (X pairs)" doesn't match `grep`
This can happen if you use special quotes in labels:
```bash
# ❌ BAD
A["Label with "quotes""]  # Inner quotes break bracket counting

# ✅ GOOD  
A["Label with &quot;quotes&quot;"]  # HTML entities
A["Label with 'single quotes'"]     # Single quotes inside double
```

### "No connections found" but I added arrows
Check spacing:
```bash
# ❌ BAD - no spaces
A-->B

# ✅ GOOD - spaces required
A --> B
```

### Visual rendering breaks but validator passes
Check Mermaid syntax (not just structure):
```bash
# ❌ BAD - invalid label syntax
A["Line 1\nLine 2"]  # \n not supported

# ✅ GOOD - use <br/>
A["Line 1<br/>Line 2"]
```

---

## Maintenance Checklist

After modifying the diagram:

- [ ] Run `./tests/validate-mermaid.sh` → all 8 checks pass
- [ ] Verify visual rendering at https://mermaid.live
- [ ] Confirm section comments match actual flows
- [ ] Check label line breaks are readable (not overcrowded)
- [ ] Ensure arrows point in logical direction (A → B → C, not loops)
- [ ] Update related documentation (SYSTEM-OVERVIEW.md) if sections change
- [ ] Git commit with clear message: `docs: add [feature] to architecture diagram`

---

## Example PR: Adding Docker Security Section

**Goal**: Add new flow showing Docker security checks

```mermaid
%% Insert before Docker Interaction section:

%% ===== DOCKER SECURITY VALIDATION =====
%% Shows how Docker security controls are tested
G --> G1["Security Checks<br/>socket, policies"]
G1 --> H
```

**Validation results**:
- Arrow count: 12 → 13 ✓
- Node count: 12 → 13 ✓
- Bracket count: 12 pairs → 13 pairs ✓
- Test 8: Comments preserved ✓

**PR description** (chain-PR format):
```
[chain-02] architecture: Add Docker security validation flow

Prompt used:
> Add a new section to the architecture diagram showing Docker 
> security checks between Docker Resource Types and Docker Daemon.

Evidence:
- ./tests/validate-mermaid.sh passes all 8 checks
- Diagram renders correctly at mermaid.live
- New flow: Security Checks (G1) connects Types (G) to Daemon (H)

Changes:
- Added 1 new node (G1: Security Checks)
- Added 1 new arrow (G → G1 → H replaces G → H)
- Added section comment explaining security validation
```

---

## Quick Reference

| Task | Command | Expected |
|------|---------|----------|
| Validate syntax | `./tests/validate-mermaid.sh` | Exit 0, 10 checks pass |
| Test input validation | `bash ./tests/validate-mermaid-negative-tests.sh` | 6/6 errors detected |
| Preview diagram | Copy to https://mermaid.live | Visual rendering |
| Count connections | `grep -c ' --> '` | Current arrow count |
| List node IDs | `grep -oE '[A-Z][0-9]*\['` | All defined nodes |
| Find section | `grep '%% =====' ` | All sections |

