---
name: generating-security-reports
description: Guides Claude in generating professional security reports (penetration test, vulnerability assessment, bug bounty, code review, incident response post-mortem) using the templates in this package. Use when writing up findings, drafting client deliverables, or documenting incidents.
---

# Generating Security Reports

## When to Use Which Template

| Situation | Template |
|---|---|
| Full pentest engagement with exploitation | `pentest-report/PENTEST-REPORT.md` |
| Scan-only, no exploitation | `vulnerability-assessment/VULN-ASSESSMENT.md` |
| Bug bounty submission | `bug-bounty/BUG-BOUNTY-REPORT.md` |
| Source code review | `code-security-review/CODE-SECURITY-REVIEW.md` |
| Incident post-mortem | `incident-response/IR-POST-MORTEM.md` |

## Report Generation Workflow

1. **Identify template** — ask what type of report is needed if not clear
2. **Load template** — read the appropriate file from `templates/`
3. **Gather inputs** — ask for any missing details (scope, dates, target names, findings list)
4. **Populate** — fill in all sections with actual content, remove placeholder text
5. **Review** — check that all findings have evidence, every severity is justified, and remediation is specific
6. **Output** — deliver as markdown; client can convert to PDF/Word as needed

## Finding Quality Checklist

Before including any finding in a report, verify:

- [ ] **Confirmed** — personally verified, not just scanner output
- [ ] **Evidence** — screenshot, request/response, or tool output attached
- [ ] **Reproducible** — step-by-step PoC that another person can follow
- [ ] **Severity justified** — CVSS vector attached, reasoning explained
- [ ] **Impact specific** — "attacker can read /etc/passwd" not "sensitive data exposed"
- [ ] **Remediation actionable** — specific fix, not vague advice
- [ ] **Referenced** — CVE, CWE, OWASP, or ATT&CK ID where applicable

## Severity Calibration

Apply these consistently. See `CLAUDE.md` for full definitions.

| Severity | Threshold |
|---|---|
| Critical | Unauthenticated RCE, unauthenticated data breach, SQLi → full DB dump, auth bypass |
| High | Authenticated RCE, SSRF to internal, IDOR with significant data, stored XSS → ATO |
| Medium | Self-XSS, reflected XSS (requires user interaction), info disclosure (non-sensitive), CSRF |
| Low | Missing headers, verbose errors, rate limiting absent but no direct impact |
| Informational | Best practice deviation, no direct exploitability |

Never inflate severity to appear more impactful. Never deflate to avoid difficult conversations.

## Executive Summary Rules

- Max 1 page
- Zero jargon — if your non-technical manager couldn't read it, rewrite it
- Answer these questions: What was tested? What's the worst thing we found? What does it mean for the business? What should we do first?
- Lead with the most important finding, not with methodology
- Include a severity count table

## Bug Bounty-Specific Rules

- Get to impact in the first 3 sentences — triagers are busy
- Include a working PoC — reports without reproduction steps are deprioritized
- Be conservative with severity self-assessment — over-rating damages credibility
- Document what you tested that was NOT vulnerable (shows thoroughness)
- Confirm you didn't access real user data beyond your own test accounts

## IR Post-Mortem Rules

- Blameless — no individual fault assignment, ever
- Timeline precision matters — "around 3pm" is not acceptable, use exact timestamps from logs
- Root cause must be systemic — "the developer made a mistake" is not a root cause
- Every action item must have an owner and deadline — no orphans
- ATT&CK map the incident — it enables better detection rules and future correlation
