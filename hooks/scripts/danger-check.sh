#!/usr/bin/env bash
# danger-check.sh — Blocks or warns on destructive/irreversible Bash commands
# Fires: PreToolUse on Bash
# Behavior: Blocking (exit 2) for truly dangerous patterns
#           Ask-for-confirmation for moderately risky patterns

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

[ -z "$COMMAND" ] && exit 0

# ─── Hard blocks — irreversible data destruction ─────────────────────────────
HARD_BLOCK_PATTERNS=(
  "rm\s+-rf\s+/"                  # rm -rf /
  "rm\s+-rf\s+\*"                 # rm -rf *
  "dd\s+.*of=/dev/sd"             # dd to disk device
  "mkfs\."                         # format filesystem
  "> /dev/sd"                      # write directly to disk
  "shred\s+.*-u"                   # shred and unlink files
  ":(){:|:&};:"                    # fork bomb
  "chmod\s+-R\s+777\s+/"          # chmod 777 on root
  "wget.*\|\s*(bash|sh)"           # pipe wget to shell (common malware delivery)
  "curl.*\|\s*(bash|sh)"           # pipe curl to shell
)

for pattern in "${HARD_BLOCK_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qiE "$pattern"; then
    cat >&2 << EOF
🚫 DANGER CHECK: Potentially destructive command blocked.

  Command: $COMMAND
  Reason:  Matches dangerous pattern: ${pattern}

  This command could cause irreversible data loss.
  If you're certain this is needed, run it manually in your terminal.
EOF
    jq -n '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: "danger-check: Potentially irreversible destructive command. Run manually if certain."
      }
    }'
    exit 0
  fi
done

# ─── Soft warnings — risky but sometimes legitimate ──────────────────────────
WARN_PATTERNS=(
  "DROP\s+(TABLE|DATABASE|SCHEMA)"  # SQL DROP
  "TRUNCATE\s+TABLE"                 # SQL TRUNCATE
  "DELETE\s+FROM\s+\w+\s*;"         # DELETE without WHERE
  "UPDATE\s+\w+\s+SET.*;"           # UPDATE without WHERE
  "rm\s+-rf"                         # rm -rf (non-root)
  "git\s+push\s+.*--force"          # force push
  "git\s+reset\s+--hard"            # hard reset
  "> /etc/"                           # redirect to /etc/
  "passwd\s+root"                    # change root password
  "userdel\s+"                       # delete user
  "iptables\s+-F"                    # flush firewall rules
  "systemctl\s+disable\s+firewall"  # disable firewall
)

for pattern in "${WARN_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qiE "$pattern"; then
    echo "⚠️  DANGER CHECK: Risky command detected — proceeding with caution." >&2
    echo "   Command: $COMMAND" >&2
    echo "   Pattern: $pattern" >&2
    echo "   Verify this is intentional before relying on its output." >&2
    break
  fi
done

# ─── Security tool aggression warnings ───────────────────────────────────────
# Warn when aggressive sqlmap, nmap, or nuclei flags are used
if echo "$COMMAND" | grep -qiE "sqlmap.*(--level\s+[4-5]|--risk\s+[2-3])"; then
  echo "⚠️  SCOPE GUARD: High-aggression sqlmap flags detected." >&2
  echo "   --level 4-5 or --risk 2-3 can cause significant server load." >&2
  echo "   Confirm this is authorized on the target." >&2
fi

if echo "$COMMAND" | grep -qiE "nmap.*(--script\s+(vuln|exploit)|--script\s+all|-T5)"; then
  echo "⚠️  SCOPE GUARD: Aggressive nmap scan detected." >&2
  echo "   Vuln scripts or -T5 can trigger IDS/IPS and cause disruption." >&2
fi

exit 0
