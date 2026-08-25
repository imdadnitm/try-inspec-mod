# Docker Compliance Profile

This InSpec compliance profile validates Docker infrastructure configuration and security.

## Quick Start

```bash
# 1. Install InSpec
brew install inspec  # or see https://docs.chef.io/inspec/install/

# 2. Fetch dependencies
cd docker-profile-1
inspec vendor

# 3. Run compliance checks
inspec exec .
```

## Dependencies

This profile depends on:
- **inspec-docker-resources** — Provides Docker resource types for compliance controls

**Dependency Strategy**: Minimal pinning with commit-hash locking for deterministic builds.

For detailed information about:
- Current dependency versions
- Version constraint strategy  
- How to safely update dependencies
- Dependency monitoring and rollback

See: [../ai-track-docs/DEPENDENCIES.md](../ai-track-docs/DEPENDENCIES.md)

## Documentation

- [../ai-track-docs/SYSTEM-OVERVIEW.md](../ai-track-docs/SYSTEM-OVERVIEW.md) — Project structure and entry points
- [../ai-track-docs/build-test.md](../ai-track-docs/build-test.md) — Exact build and test commands
- [../ai-track-docs/DEPENDENCIES.md](../ai-track-docs/DEPENDENCIES.md) — Dependency management strategy
