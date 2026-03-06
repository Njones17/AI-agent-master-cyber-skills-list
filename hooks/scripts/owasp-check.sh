#!/usr/bin/env bash
# owasp-check.sh — Runs Semgrep OWASP rules on web code files Claude writes
# Fires: PostToolUse on Write|Edit
# Behavior: Non-blocking — reports findings to Claude via stderr

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)

[ -z "$FILE_PATH" ] && exit 0
[ ! -f "$FILE_PATH" ] && exit 0

# Only scan code files — skip configs, markdowns, binaries, etc.
FILENAME=$(basename "$FILE_PATH")
EXT="${FILENAME##*.}"

WEB_EXTS="php|py|js|ts|jsx|tsx|rb|go|java|cs|cpp|c|rs|swift|kt"
if ! echo "$EXT" | grep -qiE "^($WEB_EXTS)$"; then
  exit 0
fi

# Skip test files (reduce noise)
if echo "$FILE_PATH" | grep -qiE "test|spec|mock|fixture|__tests__"; then
  exit 0
fi

FINDINGS=""

# ─── Semgrep (preferred) ─────────────────────────────────────────────────────
if command -v semgrep &>/dev/null; then
  SEMGREP_OUT=$(semgrep scan \
    --config "p/owasp-top-ten" \
    --config "p/security-audit" \
    --json \
    --quiet \
    "$FILE_PATH" 2>/dev/null || true)

  RESULT_COUNT=$(echo "$SEMGREP_OUT" | jq '.results | length' 2>/dev/null || echo "0")

  if [ "$RESULT_COUNT" -gt 0 ]; then
    echo "" >&2
    echo "🔍 OWASP SECURITY CHECK: ${RESULT_COUNT} finding(s) in ${FILENAME}" >&2
    echo "" >&2

    echo "$SEMGREP_OUT" | jq -r '
      .results[] |
      "  [\(.extra.severity // "WARN")] \(.check_id | split(".") | last)
       Line \(.start.line): \(.extra.message | gsub("\n";" ") | .[0:120])
       Fix: \(.extra.metadata.fix // "See semgrep docs")"
    ' 2>/dev/null | head -40 >&2

    ERRORS=$(echo "$SEMGREP_OUT" | jq -r '[.results[] | select(.extra.severity == "ERROR")] | length' 2>/dev/null || echo "0")
    WARNINGS=$(echo "$SEMGREP_OUT" | jq -r '[.results[] | select(.extra.severity == "WARNING")] | length' 2>/dev/null || echo "0")

    echo "" >&2
    echo "  Summary: ${ERRORS} errors, ${WARNINGS} warnings" >&2
    echo "  Run: semgrep scan --config p/owasp-top-ten ${FILE_PATH}" >&2
    FINDINGS="semgrep found ${RESULT_COUNT} issue(s)"
  fi
fi

# ─── Fallback: grep-based OWASP checks ───────────────────────────────────────
if [ -z "$FINDINGS" ]; then
  check_owasp() {
    local desc="$1"
    local pattern="$2"
    if grep -qiE "$pattern" "$FILE_PATH" 2>/dev/null; then
      FINDINGS="${FINDINGS}\n  [WARN] ${desc}"
    fi
  }

  case "$EXT" in
    php)
      check_owasp "A03: Possible SQL injection (string concat in query)"  "\\\$[a-z_]+\s*\.\s*\\\$_(GET|POST|REQUEST|COOKIE)"
      check_owasp "A03: eval() with user input"                           "eval\s*\(\s*\\\$_(GET|POST|REQUEST)"
      check_owasp "A03: system/exec with user input"                      "(system|exec|passthru|shell_exec)\s*\(\s*\\\$_(GET|POST|REQUEST)"
      check_owasp "A02: MD5/SHA1 used for passwords"                      "md5\s*\(|sha1\s*\("
      check_owasp "A05: extract() — variable injection"                   "\bextract\s*\("
      check_owasp "A01: No input sanitization on output"                  "echo\s+\\\$_(GET|POST|REQUEST|COOKIE)"
      ;;
    py)
      check_owasp "A03: String formatting in SQL query"                   "execute\s*\(\s*['\"].*%[s|d].*['\"]"
      check_owasp "A03: os.system/subprocess with user input"             "(os\.system|subprocess\.call|subprocess\.run)\s*\(.*request\."
      check_owasp "A03: eval() usage"                                     "\beval\s*\("
      check_owasp "A02: hashlib MD5/SHA1 (weak for passwords)"           "hashlib\.(md5|sha1)\s*\("
      check_owasp "A05: pickle.loads (deserialization)"                   "pickle\.loads\s*\("
      check_owasp "A05: yaml.load without Loader"                        "yaml\.load\s*\([^,)]*\)"
      ;;
    js|ts|jsx|tsx)
      check_owasp "A03: innerHTML assignment (XSS risk)"                  "\.innerHTML\s*="
      check_owasp "A03: dangerouslySetInnerHTML (XSS risk)"              "dangerouslySetInnerHTML"
      check_owasp "A03: document.write() (XSS risk)"                     "document\.write\s*\("
      check_owasp "A03: eval() usage"                                     "\beval\s*\("
      check_owasp "A02: Math.random() for security (use crypto)"         "Math\.random\s*\("
      check_owasp "A07: JWT without expiry check"                        "jwt\.sign\s*\([^)]*\)\s*(?!.*exp)"
      ;;
    rb)
      check_owasp "A03: Raw SQL with string interpolation"               "where\s*\(\s*['\"].*#{"
      check_owasp "A03: system() call"                                    "\bsystem\s*\("
      check_owasp "A05: YAML.load (deserialization)"                     "YAML\.load\s*\("
      check_owasp "A05: Marshal.load (deserialization)"                  "Marshal\.load\s*\("
      ;;
  esac

  if [ -n "$FINDINGS" ]; then
    echo "" >&2
    echo "🔍 OWASP CODE CHECK: Potential issues in ${FILENAME}" >&2
    echo -e "$FINDINGS" >&2
    echo "" >&2
    echo "  Install semgrep for more comprehensive scanning: pip install semgrep" >&2
  fi
fi

exit 0
