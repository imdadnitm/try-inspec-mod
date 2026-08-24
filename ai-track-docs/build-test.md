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

## Running Tests Locally

### Execute Profile Against Local Docker
```bash
cd docker-profile-1
inspec exec . --reporter cli:results.txt
```

### Run Specific Control
```bash
inspec exec . -c "control_name"
```

### Generate HTML Report
```bash
inspec exec . --reporter html:report.html
```

## Test Structure
- Each control in `controls/*.rb` contains one or more tests
- Tests query Docker resources via inspec-docker-resources library
- Results indicate Pass/Fail/Skip for each control

## Validation Procedures
1. **Dependency Check**: `inspec vendor` should complete without errors
2. **Syntax Check**: `inspec check .` validates control syntax
3. **Control Listing**: `inspec exec . --controls` shows runnable controls
4. **Test Execution**: `inspec exec .` runs all controls against live Docker daemon

## Common Issues
- **Docker Daemon Not Accessible**: Verify Docker socket permissions and InSpec runner environment
- **Dependency Resolution Failed**: Check internet connectivity and GitHub URL access
- **Missing Dependencies**: Run `inspec vendor` to download and lock dependencies

## CI/CD Integration
Profile can be integrated into CI/CD pipelines to validate Docker infrastructure on every commit or deployment.
