# InSpec Docker Profile System Overview

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
