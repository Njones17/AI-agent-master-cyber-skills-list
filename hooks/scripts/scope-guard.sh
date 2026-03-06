#!/usr/bin/env bash
# scope-guard.sh — Warns before running security tool commands against targets
# Fires: PreToolUse on Bash
# Behavior: Blocking (exit 2) if obvious out-of-scope tool usage detected
#           Warning (exit 0 + stderr) for targets without a loaded scope file

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)

[ -z "$COMMAND" ] && exit 0

# ─── Detect security tool commands ───────────────────────────────────────────
SECURITY_TOOLS="nmap|masscan|nuclei|sqlmap|ffuf|gobuster|dirbuster|nikto|wfuzz|hydra|medusa|metasploit|msfconsole|burpsuite|nessus|openvas|zap|whatweb|wafw00f|amass|subfinder|httpx|katana"

if ! echo "$COMMAND" | grep -qiE "\b($SECURITY_TOOLS)\b"; then
  exit 0  # Not a security tool — skip
fi

# ─── Look for scope file ──────────────────────────────────────────────────────
SCOPE_FILE=""
if [ -n "$CWD" ]; then
  # Check common scope file locations
  for scope_path in "$CWD/scope.md" "$CWD/.claude/scope.md"; do
    if [ -f "$scope_path" ]; then
      SCOPE_FILE="$scope_path"
      break
    fi
  done
  # Check engagement directories
  if [ -z "$SCOPE_FILE" ]; then
    SCOPE_FILE=$(find "$CWD" -maxdepth 2 -name "scope.md" 2>/dev/null | head -1)
  fi
fi

# ─── Extract target from command ─────────────────────────────────────────────
# Common ways targets appear in these tools
TARGET=$(echo "$COMMAND" | grep -oiE '([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]{1,2})?|([a-zA-Z0-9][a-zA-Z0-9\-]{0,61}[a-zA-Z0-9]?\.[a-zA-Z]{2,})+' | head -1 || true)

# Block obviously dangerous targets
DANGEROUS_TARGETS="8.8.8.8|1.1.1.1|google\.com|facebook\.com|microsoft\.com|amazon\.com|cloudflare\.com|github\.com"
if [ -n "$TARGET" ] && echo "$TARGET" | grep -qiE "$DANGEROUS_TARGETS"; then
  cat >&2 << EOF
🚫 SCOPE GUARD: Command targets a well-known external service.

  Command: $COMMAND
  Target:  $TARGET

  This looks like it may be testing an unauthorized target.
  If this is intentional, confirm explicit authorization before proceeding.
EOF
  # Output blocking JSON
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "ask",
      permissionDecisionReason: "scope-guard: Command appears to target an unauthorized external service. Confirm authorization."
    }
  }'
  exit 0
fi

# ─── Warn if no scope file loaded ────────────────────────────────────────────
if [ -z "$SCOPE_FILE" ]; then
  cat >&2 << EOF
⚠️  SCOPE GUARD: No scope.md found for this session.

  Command: $COMMAND
  Target:  ${TARGET:-unknown}

  Before running security tools, run /pentest-start to define scope.
  This ensures you test only authorized targets.
EOF
  # Non-blocking warning — allow the command but Claude sees the warning
fi

exit 0
