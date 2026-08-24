# AI-Assisted Development Tracking

This directory documents AI-generated and AI-assisted code changes, evidence chains, and Copilot prompt patterns used in this InSpec profile project.

## Chain-PR Methodology

**Goal**: Track sequential, AI-assisted changes with evidence and traceability.

### PR Naming Convention
```
[chain-N] {Feature/Component}: {Brief description}
```

Example: `[chain-01] controls: Add Docker daemon security checks`

### What Each PR Contains
- **AI Prompt**: The Copilot/LLM prompt used to generate or assist the code
- **Generated Code**: The actual code, control, or documentation produced
- **Evidence**: Test results, validation output, manual review notes
- **Prompt Patterns Used**: Reference to patterns in this README that worked well

## Evidence in PRs

Include in PR description:
1. **Prompt Used** — Exact prompt text sent to Copilot
2. **Output Validation** — `inspec check` and `inspec exec` results
3. **Manual Review** — Notes on what was verified manually vs. automated
4. **Modifications** — Any post-generation edits made for correctness/style

### Evidence Checklist
- [ ] Prompt documented in PR description
- [ ] Controls pass `inspec check` syntax validation
- [ ] Test execution results included (report or console output)
- [ ] No hardcoded secrets or sensitive data
- [ ] Code follows project style conventions

## Prompt Usage Patterns

### Pattern 1: Writing Compliance Controls
**Use Case**: Generate new Docker security controls

**Effective Prompt Structure**:
```
Write an InSpec control for validating [SPECIFIC DOCKER CONFIGURATION].
The control should:
- Check [specific condition]
- Use inspec-docker-resources [resource type]
- Include descriptive title and description
```

### Pattern 2: Documenting System Architecture
**Use Case**: Create system overview or architecture diagrams

**Effective Prompt**:
```
Create a Mermaid diagram showing the flow: [Component A] → [Component B] → [Result].
Include [specific details]. Use graph TD for top-down layout.
```

### Pattern 3: Build & Test Procedures
**Use Case**: Writing documentation for running tests

**Effective Prompt**:
```
Write markdown documentation for users to:
1. Install prerequisites
2. Run InSpec profile against Docker
3. Troubleshoot common issues
Include code blocks with example commands.
```

## Prompt Catalog

Store effective prompts here as they're discovered:
- _Placeholder for future prompt patterns_

## Future Enhancement
- Link to detailed PR reviews
- Archive successful prompt patterns
- Document lessons learned from AI-assisted development
