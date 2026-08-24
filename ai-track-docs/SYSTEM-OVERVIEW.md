# InSpec Docker Profile System Overview

## Quick Summary

| Aspect | Details |
|--------|---------|
| **Project Type** | InSpec Compliance Testing Profile (Docker-focused) |
| **Tech Stack** | Ruby (InSpec DSL), YAML, Markdown |
| **Maturity** | Early-stage (v0.1.0) |
| **Primary Purpose** | Validate Docker infrastructure compliance against security/configuration controls |

---

## Project Structure
This workspace contains a Docker compliance testing profile built with InSpec. The profile validates Docker container configurations against compliance controls.

### Components
- **Profile Root**: `docker-profile-1/`
- **Metadata**: `docker-profile-1/inspec.yml` — Defines profile name, version, maintainer, and dependencies
- **Controls**: `docker-profile-1/controls/` — Compliance control definitions
- **Lock File**: `docker-profile-1/inspec.lock` — Dependency resolution snapshot

## Profile Details
- **Name**: docker-profile-1
- **Version**: 0.1.0
- **Title**: Test Docker InSpec Profile
- **License**: Apache-2.0

## Dependencies
- **inspec-docker-resources**: https://github.com/inspec/inspec-docker-resources.git
  - Provides Docker resource types for querying container state
  - Enables control authors to test Docker daemon, containers, images, networks, volumes

## Compliance Controls
Controls are located in `docker-profile-1/controls/` and define testable assertions about Docker environments.

Example control topics (extend as profile grows):
- Docker daemon configuration
- Container security settings
- Image scanning and validation
- Network isolation
- Volume mount compliance

## Supported Platforms
- OS-level testing (Linux, Windows with Docker daemon)
- Docker daemon must be accessible from InSpec runner

## Testing Scope
This profile validates **Docker infrastructure** compliance, not application-level functionality.

---

## Languages & Tech Stack

| Language/Format | Purpose | Examples |
|---|---|---|
| **Ruby** | InSpec compliance DSL for controls | `docker-profile-1/controls/example.rb` |
| **YAML** | Profile metadata & configuration | `docker-profile-1/inspec.yml`, `docker-profile-1/inspec.lock` |
| **Markdown** | Documentation | `*.md` files, this file |
| **Mermaid** | Architecture diagrams | `ai-track-docs/architecture.mmd` |

---

## Entry Points & Execution

### Primary Entry Points

| File/Command | Path | Purpose |
|---|---|---|
| Profile Config | `docker-profile-1/inspec.yml` | Defines profile identity, version (0.1.0), maintainer, license, and dependencies |
| Profile Lock | `docker-profile-1/inspec.lock` | Locks dependency versions for deterministic builds |
| Controls | `docker-profile-1/controls/example.rb` | Main executable compliance controls |
| Profile README | `docker-profile-1/README.md` | User-facing profile documentation |

### Execution Commands

```bash
# Run all compliance controls against Docker daemon
inspec exec docker-profile-1/

# Validate control syntax without execution
inspec check docker-profile-1/

# Fetch and lock dependencies
inspec vendor

# Run specific control by name
inspec exec docker-profile-1/ -c control_name

# Generate HTML report
inspec exec docker-profile-1/ --reporter html:report.html
```

---

## Test Approach

| Aspect | Details |
|--------|---------|
| **Framework** | InSpec (Chef compliance testing framework) |
| **Test Location** | `docker-profile-1/controls/example.rb` |
| **Test Type** | Infrastructure compliance (queries live Docker state) |
| **Execution Model** | Real-time Docker daemon validation via Unix socket |
| **Control Structure** | Each control = one compliance requirement with test assertions |
| **Test Scope** | Docker images, containers, networks, volumes, daemon config |
| **No Mocking** | Tests run against actual Docker daemon state (not unit tests) |
| **Output Formats** | CLI, HTML, JSON reports via `--reporter` flag |
| **CI/CD Ready** | Yes; can integrate into pipelines for continuous compliance |

---

## Low-Risk Modules for Safe Modification

### Recommended: `ai-track-docs/build-test.md`

**Path**: `ai-track-docs/build-test.md`

**Why it's low-risk:**
- ✅ **Pure documentation** — No executable code or logic
- ✅ **Zero dependencies** — Doesn't import, call, or reference any modules
- ✅ **Self-contained** — Changes won't propagate to controls or config
- ✅ **No CI/CD impact** — Updating procedures doesn't trigger test execution
- ✅ **Reversible** — Easy to rollback if content is wrong
- ✅ **High value** — First resource new contributors check; improving it aids onboarding

**Safe modification examples:**
- Add troubleshooting steps
- Expand setup prerequisites
- Document additional InSpec commands or report formats
- Add Docker test scenario examples
- Include CI/CD integration patterns

### Additional Low-Risk Modules

| Module | Type | Risk Level | Safe To Modify | Reason |
|--------|------|------------|---|---------|
| `ai-track-docs/SYSTEM-OVERVIEW.md` | Documentation | Very Low | ✅ Yes | Pure documentation; no code impact |
| `ai-track-docs/architecture.mmd` | Diagram | Very Low | ✅ Yes | Visual reference only; no execution |
| `docker-profile-1/README.md` | Documentation | Very Low | ✅ Yes | Profile documentation; no functional code |
| `.copilot-track/crawl/README.md` | Development Metadata | Very Low | ✅ Yes | Process documentation; no functional code |

### High-Risk Modules (Caution)

| Module | Type | Risk Level | Why Risky |
|--------|------|----------|----------|
| `docker-profile-1/controls/example.rb` | Executable | **High** | Core compliance logic; changes break test execution; requires validation |
| `docker-profile-1/inspec.yml` | Configuration | **High** | Affects profile identity, versioning, dependency resolution |
| `docker-profile-1/inspec.lock` | Lock File | **Medium** | Regenerated by `inspec vendor`; manual edits not recommended |

---

## Assumptions & Verification

### Key Assumptions

| Assumption | Rationale | How to Verify |
|-----------|-----------|---------------|
| Docker daemon is running during profile execution | InSpec requires live Docker access via Unix socket | `docker ps` should return container list |
| `inspec-docker-resources` dependency is available | Without it, Docker resource types won't load | `inspec exec docker-profile-1/ --controls` lists all controls |
| Controls in `example.rb` are the only test suite | No other control directories observed | `find docker-profile-1/controls/ -name "*.rb"` returns only example.rb |
| Profile is designed for Linux/Unix Docker | Metadata says platform: os | Check `inspec vendor` succeeds on target OS |
| No git submodules or vendor dependencies | User requirement specified | `ls -la docker-profile-1/` shows no submodules |

### How to Verify Entry Points

1. **Profile Config Valid**:
   ```bash
   inspec check docker-profile-1/
   ```
   Expected: "Profile validation of docker-profile-1 succeeded"

2. **Dependency Lock Exists**:
   ```bash
   ls -l docker-profile-1/inspec.lock
   ```
   Expected: File exists and has recent modification timestamp

3. **Controls Exist and Parse**:
   ```bash
   inspec exec docker-profile-1/ --controls
   ```
   Expected: Lists all available control names from example.rb

4. **Docker Daemon Accessible**:
   ```bash
   docker ps
   ```
   Expected: Returns list of running containers (or empty list if none running)

5. **Dry-run Execution** (validates structure without full test):
   ```bash
   inspec exec docker-profile-1/ --runner-ui progress
   ```
   Expected: Runs controls and outputs pass/fail results

---

## Directory Tree

```
try-inspec-mod/
├── .git/                                    # Git repository
├── docker-profile-1/                       # Core InSpec Profile [MAIN EXECUTION PATH]
│   ├── inspec.yml                          # Profile config [ENTRY POINT]
│   ├── inspec.lock                         # Dependency lock [GENERATED]
│   ├── README.md                           # Profile docs [LOW-RISK]
│   └── controls/
│       └── example.rb                      # Compliance controls [HIGH-RISK]
├── ai-track-docs/                          # Documentation & architecture [ALL LOW-RISK]
│   ├── SYSTEM-OVERVIEW.md                  # This file
│   ├── build-test.md                       # Build procedures
│   └── architecture.mmd                    # System diagram
└── .copilot-track/                         # AI development tracking [LOW-RISK]
    └── crawl/
        └── README.md                       # Chain-PR methodology
```
