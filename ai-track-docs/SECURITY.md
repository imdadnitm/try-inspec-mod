# Security Guidelines & Secret Hygiene

## Overview

This document outlines security best practices for the InSpec Docker compliance profile project. Focus areas: preventing secret leaks, managing credentials, securing dependencies, and responding to security incidents.

---

## 🔐 Secret Hygiene

### What Counts as a Secret?

Any value that grants access to systems, APIs, or data:

| Category | Examples | Risk Level |
|----------|----------|-----------|
| **API Keys** | AWS keys, Docker Hub tokens, GitHub tokens | 🔴 CRITICAL |
| **Passwords** | Database passwords, service credentials | 🔴 CRITICAL |
| **Private Keys** | SSH, GPG, TLS certificates, .pem files | 🔴 CRITICAL |
| **Tokens** | OAuth tokens, JWT secrets, bearer tokens | 🔴 CRITICAL |
| **Credentials** | Connection strings, usernames with passwords | 🔴 CRITICAL |
| **Config Files** | .env files, docker config.json | 🟡 HIGH |
| **URLs with Secrets** | URLs containing API keys or auth | 🟡 HIGH |

### Prevention: Never Commit Secrets

**Protected by .gitignore**:
- `*.pem`, `*.key`, `*.pkcs8` — Private keys
- `.env`, `.env.*` — Environment variable files
- `*credentials*`, `*secret*`, `*token*` — Credential files
- `.aws/`, `.ssh/`, `.docker/config.json` — System credential stores
- `*.p12`, `*.pfx` — Certificate files

**Manually verify**:
```bash
# Before committing, check for secrets
git diff --cached | grep -iE "password|secret|key|token|api_key"

# Safer: use pre-commit hooks (recommended for CI/CD)
# See: Setting Up Pre-Commit Hooks (below)
```

### Best Practices

✅ **DO**:
- Store secrets in environment variables or secure vaults (not in code)
- Use `.env` files locally (in .gitignore, never commit)
- Rotate secrets regularly (quarterly recommended)
- Use strong secrets (minimum 32 characters for keys)
- Document where each secret lives (without exposing the value)
- Grant minimum necessary permissions (principle of least privilege)

❌ **DON'T**:
- Commit .env files, credentials, or private keys
- Share secrets in Slack, email, or comments
- Use hardcoded credentials in controls or scripts
- Store secrets in documentation
- Reuse secrets across environments
- Log secrets to stdout/stderr
- Leave secrets in IDE/editor config files

### Common Mistakes to Avoid

| Mistake | Example | Prevention |
|---------|---------|-----------|
| Committing .env file | `.env` with API_KEY=secret123 | Always in .gitignore ✓ |
| Secrets in code comments | `# TODO: API_KEY=abc123` | Use env vars, docs never have values |
| Secrets in test data | `test_password: "admin123"` | Use env var fixtures, test secrets |
| Secrets in error messages | `Connection failed: user:pass@host` | Sanitize error logs |
| Secrets in debug output | `printf "key: $API_KEY\n"` | Redact in logs, never print secrets |
| Secrets in git commit messages | `"Fixed API key: xyz789"` | Use git hooks to prevent |

---

## 🛡️ Dependency Security

### Dependency Threat Model

| Threat | Source | Mitigation |
|--------|--------|-----------|
| Compromised upstream package | inspec-docker-resources updated | Lock to commit hash (inspec.lock) ✓ |
| Malicious version | Auto-update to bad version | Manual vendor + test workflow ✓ |
| Vulnerable dependency | Old version with CVE | Monitor releases, update with testing |
| Supply chain attack | Compromised maintainer | Verify commits, review diffs before updating |
| Transitive dependency leak | Dep of inspec-docker-resources | InSpec manages (same security model) |

### Dependency Security Workflow

```bash
# 1. Current state: locked to commit hash (deterministic, safe)
cat docker-profile-1/inspec.lock
# Shows: commit hash 15e068090bf9ec066a1111e13d41c42138b50f1a

# 2. To update (never auto-update):
cd docker-profile-1
rm inspec.lock vendor/
inspec vendor

# 3. Review changes
git diff inspec.lock

# 4. Test thoroughly
inspec exec .

# 5. If safe, commit
git commit inspec.lock

# 6. If unsafe, rollback
git checkout inspec.lock
inspec vendor
```

### Security Monitoring

**Check for known vulnerabilities**:
```bash
# Option 1: GitHub security advisories (automatic)
# Enabled on GitHub; shows in "Security" tab

# Option 2: Manual check
cd docker-profile-1
inspec exec . --audit-only

# Option 3: Third-party scanner (optional)
# Snyk, Dependabot, etc. (not set up, but recommended for production)
```

**For detailed dependency strategy**: See [DEPENDENCIES.md](DEPENDENCIES.md)

---

## 🔑 Environment Variables & Configuration

### Local Development Setup

**Never commit .env files**. Create `.env.local` (always in .gitignore):

```bash
# 1. Create local file (not version controlled)
cat > .env.local << EOF
# Local development only
# Never commit this file!

# Docker credentials (example)
DOCKER_HUB_USERNAME=your_username
DOCKER_HUB_TOKEN=your_token

# InSpec credentials (if needed)
INSPEC_REPORTER=html
INSPEC_REPORTER_PATH=./report.html
EOF

# 2. Use in scripts with source
source .env.local
inspec exec docker-profile-1/
```

### Environment-Specific Configuration

Never mix secrets and non-secrets:

```
✅ GOOD:
  config/
    - general.yml (version controlled)
    - docker-repo: inspec  # Public info
    - docker-tags: v5.0,latest

  .env.local (NOT version controlled)
    - DOCKER_HUB_TOKEN=xyz789  # Secret

❌ BAD:
  config/secrets.yml (version controlled)
    - docker-repo-username: user123
    - docker-repo-token: secret789  # LEAKED!
```

---

## 🚨 Incident Response: Secret Leaked!

### If You Accidentally Commit a Secret:

**IMMEDIATE (< 1 minute)**:
1. DO NOT PUSH to GitHub yet (if local only)
2. Remove the secret from the file
3. Create a new commit: `git commit --amend` (rewrites last commit)
4. If already pushed → see Damage Control (below)

**Example: Remove secret from file**:
```bash
# 1. Find the file with secret
grep -r "password" .

# 2. Edit file, remove secret
vim <file>

# 3. Stage change
git add <file>

# 4. Amend previous commit (rewrites history)
git commit --amend

# 5. If not yet pushed, you're safe
```

### If Secret Was Pushed to GitHub:

**DAMAGE CONTROL (now critical)**:
1. **Revoke the secret immediately** (most important!)
   ```bash
   # Example: If API key exposed
   # → Contact service provider, regenerate API key
   # → Update all services using old key
   ```

2. **Remove from git history** (permanent removal):
   ```bash
   # Option A: Rewrite single commit (if most recent)
   git rebase -i HEAD~1
   # Edit to remove secret, save

   # Option B: Remove from entire history (nuclear option)
   # Using git-filter-repo (recommended over BFG)
   git filter-repo --path <file> --invert-paths
   
   # Force push (only if not shared branch)
   # ⚠️ WARNING: destructive, coordinate with team
   git push origin --force-with-lease
   ```

3. **Notify team** (if shared repo):
   - Explain what was leaked
   - Confirm secret was revoked
   - Explain what was done to remove it

4. **GitHub: check exposed credentials**:
   - Go to: Settings → Security → Secret scanning
   - GitHub shows if secrets were detected
   - Confirm revocation

5. **Assume compromise**: If secret was user's GitHub token or AWS key:
   - Assume attacker accessed your account
   - Review recent activity/API calls
   - Check for additional exposure (other repos, services)

### Prevention: Git Pre-Commit Hooks

**Recommended setup** (prevents secrets before commit):

```bash
# 1. Install git-secrets (or similar)
brew install git-secrets

# 2. Configure for this repo
git secrets --install
git secrets --register-aws

# 3. Add custom patterns
git secrets --add 'secret\s*=\s*['\''][^'\'']*['\''']'
git secrets --add 'password\s*=\s*['\''][^'\'']*['\''']'

# 4. Test
echo "LEAKED_KEY=secret123" > test.txt
git add test.txt
git commit -m "test"
# Should FAIL with: "Potential secret detected"

# 5. Clean up
rm test.txt
```

---

## 📋 Security Checklist

### Before Every Commit

- [ ] No `.env*` files staged
- [ ] No `*.pem`, `*.key` files staged  
- [ ] No `*credentials*` or `*secret*` files
- [ ] No hardcoded API keys in code/comments
- [ ] Verified with: `git diff --cached | grep -iE "password|secret|key|token"`
- [ ] Pre-commit hook configured (recommended)

### Weekly

- [ ] Review recent commits for accidental secrets
- [ ] Check dependency updates for security issues
- [ ] Verify .gitignore is up-to-date with patterns

### Quarterly

- [ ] Rotate any secrets that are in use
- [ ] Audit environment variables used in controls
- [ ] Review GitHub security alerts (Settings → Security)

### When Adding Dependencies

- [ ] Check upstream project's security policy
- [ ] Review recent commits/issues for security concerns
- [ ] Test thoroughly before committing lock file
- [ ] Document why dependency is needed

---

## 📖 Secret Patterns to Watch For

### In Code/Commits (will catch at commit time)

```bash
# Search current files
grep -ri "password\|secret\|token\|api_key\|credentials" . --include="*.yml" --include="*.yaml" --include="*.rb" --include="*.json" | grep -v "^\s*#" | grep -v "documentation\|docs\|guide"

# Search git history (DO NOT DO THIS ON PUBLIC REPOS)
git log -p --all -S 'password' --source --remotes

# Check for commit messages mentioning secrets
git log --all | grep -iE "password|secret|key|token|api_key|credentials|fix.*key"
```

### In Environment

```bash
# Check what's exposed to processes
env | grep -iE "PASSWORD|SECRET|TOKEN|API_KEY|KEY|CREDENTIALS"

# Check file permissions (should not be readable by others)
ls -la ~/.aws/
ls -la ~/.ssh/
```

---

## 🔍 Verification: Current Project Status

### Project Status Check

```bash
# 1. Verify .gitignore is in place
ls -la .gitignore
cat .gitignore | head -20

# 2. Verify no secrets tracked
git ls-files | grep -iE "secret|password|token|credentials|\.env|\.pem|\.key"
# Should return NOTHING (safe)

# 3. Verify inspec.lock IS tracked (intentional)
git ls-files | grep inspec.lock
# Should show: docker-profile-1/inspec.lock (✓ correct)

# 4. Verify vendor/ is NOT tracked (gitignored)
git ls-files | grep vendor/
# Should return NOTHING (✓ correct)

# 5. Check for obvious secrets in code
grep -r "password\|secret\|token\|api" docker-profile-1/controls/*.rb 2>/dev/null
# Should only show comments/docs, not values
```

### Current Project Status

**✅ Safe**:
- No obvious secret files found
- No .env files committed
- No private keys exposed
- inspec.lock correctly tracked (deterministic)
- vendor/ correctly ignored

**⚠️ Action Items**:
- Add pre-commit hooks for local development (optional but recommended)
- Set up GitHub secret scanning (free on GitHub, auto-enabled)
- Document any environment variables needed for running profile

---

## 📚 Related Documentation

- [DEPENDENCIES.md](DEPENDENCIES.md) — Dependency security strategy & monitoring
- [build-test.md](build-test.md) — Build procedures (doesn't expose secrets)
- [SYSTEM-OVERVIEW.md](SYSTEM-OVERVIEW.md) — Architecture & entry points
- [.gitignore](../.gitignore) — Secret files and artifacts to ignore

---

## ⚠️ Key Takeaways

1. **Never commit secrets** — .gitignore blocks common patterns ✓
2. **Use environment variables** — Store sensitive config separately
3. **Lock dependencies** — inspec.lock ensures reproducible builds
4. **Rotate secrets** — Quarterly minimum
5. **If leaked, revoke immediately** — Most important step
6. **Use pre-commit hooks** — Catch mistakes before pushing
7. **Monitor dependencies** — GitHub security tab shows advisories

---

## Questions?

- **Secret accidentally committed?** → Follow "Incident Response" section
- **How to safely update dependencies?** → See DEPENDENCIES.md
- **Where to store API keys?** → Environment variables (never in code)
- **Is inspec.lock safe to commit?** → YES (determinism, not a secret)
