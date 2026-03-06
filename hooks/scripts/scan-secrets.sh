#!/usr/bin/env bash
# scan-secrets.sh — Scans any file Claude writes for secrets/credentials
# Fires: PostToolUse on Write|Edit
# Behavior: Non-blocking warning — reports findings to Claude via stderr

set -euo pipefail

# Read JSON input from stdin
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)

# Skip if no file path or file doesn't exist
[ -z "$FILE_PATH" ] && exit 0
[ ! -f "$FILE_PATH" ] && exit 0

# Skip binary files
if file "$FILE_PATH" | grep -q 'binary\|executable\|image\|audio\|video'; then
  exit 0
fi

FINDINGS=""

# ─── Pattern-based secret detection ──────────────────────────────────────────

check_pattern() {
  local desc="$1"
  local pattern="$2"
  if grep -qiE "$pattern" "$FILE_PATH" 2>/dev/null; then
    FINDINGS="${FINDINGS}\n  ⚠  ${desc}"
  fi
}

# API keys and tokens
check_pattern "Potential AWS Access Key"        "AKIA[0-9A-Z]{16}"
check_pattern "Potential AWS Secret Key"        "aws_secret_access_key\s*[=:]\s*['\"][A-Za-z0-9/+=]{40}"
check_pattern "Potential GCP API Key"           "AIza[0-9A-Za-z\\-_]{35}"
check_pattern "Potential GitHub Token"          "gh[pousr]_[A-Za-z0-9]{36,}"
check_pattern "Potential Slack Token"           "xox[baprs]-[0-9A-Za-z]{10,48}"
check_pattern "Potential Stripe Key"            "sk_live_[0-9a-zA-Z]{24,}"
check_pattern "Potential Twilio Account SID"    "AC[a-z0-9]{32}"
check_pattern "Potential SendGrid API Key"      "SG\.[a-zA-Z0-9\-_]{22}\.[a-zA-Z0-9\-_]{43}"
check_pattern "Potential JWT Token"             "eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}"
check_pattern "Generic API Key assignment"      "(api_key|apikey|api-key)\s*[=:]\s*['\"][A-Za-z0-9_\-]{16,}"
check_pattern "Generic Secret assignment"       "(secret|password|passwd|pwd)\s*[=:]\s*['\"][^'\"]{8,}"
check_pattern "Generic Token assignment"        "(token|access_token|auth_token)\s*[=:]\s*['\"][A-Za-z0-9_\-]{16,}"
check_pattern "Private key header"             "-----BEGIN (RSA |EC |DSA |OPENSSH |PGP )?PRIVATE KEY"
check_pattern "Hardcoded connection string"    "(mongodb|postgresql|mysql|redis):\/\/[^:]+:[^@]+@"
check_pattern "Basic auth in URL"              "https?:\/\/[^:]+:[^@]+@"

# ─── gitleaks (if available) ──────────────────────────────────────────────────
if command -v gitleaks &>/dev/null; then
  GITLEAKS_OUT=$(gitleaks detect --source "$FILE_PATH" --no-git --quiet 2>&1 || true)
  if [ -n "$GITLEAKS_OUT" ]; then
    FINDINGS="${FINDINGS}\n  ⚠  gitleaks: $(echo "$GITLEAKS_OUT" | head -5)"
  fi
fi

# ─── trufflehog (if available) ───────────────────────────────────────────────
if command -v trufflehog &>/dev/null; then
  TRUFFLE_OUT=$(trufflehog filesystem "$FILE_PATH" --only-verified --json 2>/dev/null | jq -r '.DetectorName // empty' 2>/dev/null | head -5 || true)
  if [ -n "$TRUFFLE_OUT" ]; then
    FINDINGS="${FINDINGS}\n  ⚠  trufflehog: ${TRUFFLE_OUT}"
  fi
fi

# ─── Output ──────────────────────────────────────────────────────────────────
if [ -n "$FINDINGS" ]; then
  echo "🔑 SECRET SCAN WARNING: Potential secrets detected in ${FILE_PATH}:" >&2
  echo -e "$FINDINGS" >&2
  echo "" >&2
  echo "  Review before committing. Add to .gitignore or use environment variables." >&2
  # Non-blocking (exit 0) — Claude is warned via stderr but can proceed
fi

exit 0
