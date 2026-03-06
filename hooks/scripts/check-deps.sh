#!/usr/bin/env bash
# check-deps.sh — Runs dependency vulnerability checks when manifest files change
# Fires: PostToolUse on Write|Edit
# Behavior: Non-blocking warning when vulnerable deps are found

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)

[ -z "$FILE_PATH" ] && exit 0
[ ! -f "$FILE_PATH" ] && exit 0

FILENAME=$(basename "$FILE_PATH")
DIR=$(dirname "$FILE_PATH")
FINDINGS=""

# ─── npm / Node.js ───────────────────────────────────────────────────────────
if [[ "$FILENAME" == "package.json" || "$FILENAME" == "package-lock.json" ]]; then
  if command -v npm &>/dev/null; then
    echo "📦 Dependency check: Running npm audit on ${FILE_PATH}..." >&2
    AUDIT=$(cd "$DIR" && npm audit --json 2>/dev/null || true)
    CRITICAL=$(echo "$AUDIT" | jq -r '.metadata.vulnerabilities.critical // 0' 2>/dev/null || echo "0")
    HIGH=$(echo "$AUDIT" | jq -r '.metadata.vulnerabilities.high // 0' 2>/dev/null || echo "0")
    if [ "$CRITICAL" -gt 0 ] || [ "$HIGH" -gt 0 ]; then
      FINDINGS="npm: ${CRITICAL} critical, ${HIGH} high vulnerabilities found"
      echo "  Run: cd ${DIR} && npm audit fix" >&2
    fi
  fi
fi

# ─── Python / pip ────────────────────────────────────────────────────────────
if [[ "$FILENAME" == "requirements.txt" || "$FILENAME" == "requirements-dev.txt" || "$FILENAME" == "Pipfile.lock" ]]; then
  if command -v pip-audit &>/dev/null; then
    echo "🐍 Dependency check: Running pip-audit on ${FILE_PATH}..." >&2
    PIP_OUT=$(pip-audit -r "$FILE_PATH" --format=json 2>/dev/null || true)
    VULN_COUNT=$(echo "$PIP_OUT" | jq '[.[] | select(.vulns | length > 0)] | length' 2>/dev/null || echo "0")
    if [ "$VULN_COUNT" -gt 0 ]; then
      FINDINGS="pip-audit: ${VULN_COUNT} packages with vulnerabilities"
    fi
  elif command -v safety &>/dev/null; then
    SAFETY_OUT=$(safety check -r "$FILE_PATH" --json 2>/dev/null || true)
    VULN_COUNT=$(echo "$SAFETY_OUT" | jq 'length' 2>/dev/null || echo "0")
    if [ "$VULN_COUNT" -gt 0 ]; then
      FINDINGS="safety: ${VULN_COUNT} vulnerabilities found"
    fi
  fi
fi

# ─── Ruby / Bundler ──────────────────────────────────────────────────────────
if [[ "$FILENAME" == "Gemfile" || "$FILENAME" == "Gemfile.lock" ]]; then
  if command -v bundle &>/dev/null && bundle exec bundler-audit --version &>/dev/null 2>&1; then
    BUNDLE_OUT=$(cd "$DIR" && bundle exec bundler-audit check 2>&1 || true)
    if echo "$BUNDLE_OUT" | grep -q "Vulnerabilities found"; then
      FINDINGS="bundler-audit: vulnerabilities found"
      echo "$BUNDLE_OUT" | grep -E "Name:|CVE:|Criticality:" >&2 | head -20
    fi
  fi
fi

# ─── Go ──────────────────────────────────────────────────────────────────────
if [[ "$FILENAME" == "go.mod" || "$FILENAME" == "go.sum" ]]; then
  if command -v govulncheck &>/dev/null; then
    echo "🐹 Dependency check: Running govulncheck..." >&2
    GOVULN=$(cd "$DIR" && govulncheck ./... 2>&1 || true)
    if echo "$GOVULN" | grep -qiE "vulnerability|vuln"; then
      FINDINGS="govulncheck: vulnerabilities found"
      echo "$GOVULN" | grep -i "vulnerability" | head -5 >&2
    fi
  fi
fi

# ─── trivy (universal fallback) ──────────────────────────────────────────────
if [[ "$FILENAME" =~ ^(package\.json|requirements\.txt|Gemfile|go\.mod|pom\.xml|build\.gradle|composer\.json|Cargo\.toml)$ ]]; then
  if command -v trivy &>/dev/null && [ -z "$FINDINGS" ]; then
    TRIVY_OUT=$(trivy fs "$FILE_PATH" --format json --quiet 2>/dev/null || true)
    CRITICAL=$(echo "$TRIVY_OUT" | jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "CRITICAL")] | length' 2>/dev/null || echo "0")
    HIGH=$(echo "$TRIVY_OUT" | jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH")] | length' 2>/dev/null || echo "0")
    if [ "$CRITICAL" -gt 0 ] || [ "$HIGH" -gt 0 ]; then
      FINDINGS="trivy: ${CRITICAL} critical, ${HIGH} high vulnerabilities"
    fi
  fi
fi

# ─── Output ──────────────────────────────────────────────────────────────────
if [ -n "$FINDINGS" ]; then
  echo "" >&2
  echo "⚠️  DEPENDENCY VULNERABILITY WARNING" >&2
  echo "   File: ${FILE_PATH}" >&2
  echo "   ${FINDINGS}" >&2
  echo "   Review and update vulnerable packages before deployment." >&2
fi

exit 0
