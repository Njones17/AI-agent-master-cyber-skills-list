#!/usr/bin/env bash
# capture-evidence.sh — Auto-logs security tool output to engagement evidence folder
# Fires: PostToolUse on Bash (async, non-blocking)
# Behavior: Silently captures output of security tools to evidence/

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
OUTPUT=$(echo "$INPUT" | jq -r '.tool_response // .output // empty' 2>/dev/null)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)

[ -z "$COMMAND" ] && exit 0
[ -z "$OUTPUT" ] && exit 0
[ -z "$CWD" ] && exit 0

# ─── Only capture security tool output ───────────────────────────────────────
SECURITY_TOOLS="nmap|masscan|nuclei|sqlmap|ffuf|gobuster|nikto|wfuzz|hydra|metasploit|nessus|whatweb|amass|subfinder|httpx|semgrep|gitleaks|trufflehog|trivy|prowler|bloodhound|hashcat|searchsploit|yara|binwalk|radare2|capa"

if ! echo "$COMMAND" | grep -qiE "\b($SECURITY_TOOLS)\b"; then
  exit 0
fi

# ─── Find or create evidence directory ───────────────────────────────────────
EVIDENCE_DIR=""

# Look for existing engagement directory
for dir in "$CWD"/engagement-*; do
  if [ -d "$dir/evidence" ]; then
    EVIDENCE_DIR="$dir/evidence"
    break
  fi
done

# If not found, use CWD/evidence
if [ -z "$EVIDENCE_DIR" ]; then
  EVIDENCE_DIR="$CWD/evidence"
fi

mkdir -p "$EVIDENCE_DIR"

# ─── Determine tool name and create filename ──────────────────────────────────
TOOL=$(echo "$COMMAND" | grep -oiE "\b($SECURITY_TOOLS)\b" | head -1 | tr '[:upper:]' '[:lower:]')
TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")
OUTFILE="${EVIDENCE_DIR}/${TIMESTAMP}-${TOOL}.txt"

# ─── Write evidence file ──────────────────────────────────────────────────────
cat > "$OUTFILE" << EOF
# Evidence: ${TOOL}
# Timestamp: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
# Command: ${COMMAND}
# CWD: ${CWD}
# ─────────────────────────────────────────

${OUTPUT}
EOF

# ─── Maintain evidence index ──────────────────────────────────────────────────
INDEX="${EVIDENCE_DIR}/INDEX.md"
if [ ! -f "$INDEX" ]; then
  echo "# Evidence Index" > "$INDEX"
  echo "" >> "$INDEX"
  echo "| Timestamp | Tool | File | Command |" >> "$INDEX"
  echo "|---|---|---|---|" >> "$INDEX"
fi

SHORT_CMD="${COMMAND:0:80}"
echo "| ${TIMESTAMP} | ${TOOL} | [${OUTFILE##*/}](./${OUTFILE##*/}) | \`${SHORT_CMD}\` |" >> "$INDEX"

exit 0
