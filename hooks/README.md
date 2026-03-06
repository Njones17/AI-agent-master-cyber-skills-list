# Security Hooks

Six automated security hooks that run in the background as Claude works. No configuration needed — they activate automatically when this plugin is enabled.

---

## Hooks Overview

| Hook | Trigger | Type | What it Does |
|---|---|---|---|
| `scan-secrets` | After any file write/edit | Async warning | Scans for API keys, tokens, private keys, connection strings |
| `check-deps` | After manifest file change | Async warning | Runs npm audit / pip-audit / trivy on dependency files |
| `owasp-check` | After web code file write/edit | Async warning | Runs Semgrep OWASP rules or grep-based fallback checks |
| `scope-guard` | Before any Bash command | Blocking/warning | Detects security tool commands, warns if no scope loaded, blocks obvious out-of-scope targets |
| `danger-check` | Before any Bash command | Blocking/warning | Blocks destructive commands (rm -rf /, dd to disk, fork bombs), warns on risky operations |
| `capture-evidence` | After any Bash command | Async silent | Auto-logs security tool output to `evidence/` with timestamp and index |

---

## Hook Details

### 🔑 scan-secrets (PostToolUse: Write|Edit)
Runs on every file Claude creates or modifies. Detects:
- AWS access/secret keys, GCP API keys, GitHub tokens, Slack tokens, Stripe keys
- JWT tokens, generic API key/secret/token assignments
- Private key headers (RSA, EC, PGP)
- Hardcoded connection strings with credentials
- Uses gitleaks and trufflehog if installed, regex fallback otherwise

**Behavior:** Non-blocking. Reports findings via stderr so Claude is warned.

### 📦 check-deps (PostToolUse: Write|Edit)
Triggers when Claude modifies a dependency manifest:
- `package.json` / `package-lock.json` → `npm audit`
- `requirements.txt` / `Pipfile.lock` → `pip-audit` or `safety`
- `Gemfile` / `Gemfile.lock` → `bundler-audit`
- `go.mod` / `go.sum` → `govulncheck`
- Any manifest → `trivy` fallback

**Behavior:** Non-blocking. Reports critical/high counts via stderr.

### 🔍 owasp-check (PostToolUse: Write|Edit)
Runs on web code files (.php, .py, .js, .ts, .jsx, .tsx, .rb, .go, .java, .cs). Checks for OWASP Top 10 patterns:
- A01: Broken Access Control
- A02: Cryptographic failures (weak hashing, Math.random for security)
- A03: Injection (SQL, eval, innerHTML, system calls with user input)
- A05: Security Misconfiguration (insecure deserialization, yaml.load)
- A07: Auth failures (JWT without expiry)

Uses Semgrep with `p/owasp-top-ten` + `p/security-audit` if installed, grep-based fallback otherwise.

**Behavior:** Non-blocking. Reports findings via stderr.

### 🛡️ scope-guard (PreToolUse: Bash)
Fires before any Bash command that contains a known security tool (nmap, nuclei, sqlmap, ffuf, etc.):
- **Hard block (ask):** Command targets well-known external services (google.com, github.com, cloudflare.com, etc.)
- **Soft warning:** No `scope.md` file found — reminds to run `/pentest-start` first

**Behavior:** Prompts for confirmation when targeting well-known services. Non-blocking warning when no scope file.

### ⚠️ danger-check (PreToolUse: Bash)
**Hard blocks** (deny, run manually):
- `rm -rf /` or `rm -rf *`
- `dd` writing to disk devices
- `mkfs.*` (format filesystem)
- Fork bombs
- `chmod -R 777 /`
- Piping curl/wget directly to bash

**Soft warnings** (allow with caution message):
- SQL DROP/TRUNCATE/DELETE without WHERE
- `git push --force`, `git reset --hard`
- High-aggression sqlmap flags (`--level 4-5`, `--risk 2-3`)
- Aggressive nmap (`--script vuln`, `-T5`)

### 📸 capture-evidence (PostToolUse: Bash)
After every successful security tool command, silently:
1. Saves full output to `evidence/TIMESTAMP-TOOLNAME.txt`
2. Updates `evidence/INDEX.md` with timestamp, tool, file link, command

Works with: nmap, masscan, nuclei, sqlmap, ffuf, nikto, gobuster, hydra, semgrep, gitleaks, trivy, bloodhound, searchsploit, yara, binwalk, radare2, and more.

**Behavior:** Async, silent. Never blocks. Creates `evidence/` if it doesn't exist.

---

## Requirements

Hooks work without any dependencies using regex fallbacks. For best results install:

```bash
# Secret scanning
brew install gitleaks
pip install trufflehog

# Dependency scanning  
npm install -g npm        # npm audit (built-in)
pip install pip-audit
gem install bundler-audit
go install golang.org/x/vuln/cmd/govulncheck@latest
brew install trivy

# OWASP code scanning
pip install semgrep
```

---

## Disabling Individual Hooks

To disable a specific hook without removing it, comment it out in `hooks/hooks.json` or use `/hooks` in Claude Code to manage hooks interactively.

To disable all hooks temporarily: add `"disableAllHooks": true` to `.claude/settings.json`.
