---
name: writing-security-reports
description: "Use when documenting security findings, writing pentest reports, creating vulnerability advisories, drafting executive summaries for security assessments, formatting evidence for security deliverables, scoring vulnerabilities with CVSS, writing remediation guidance, or producing any security assessment documentation deliverable."
---

## Required Tools

> This skill requires no external security tools. It is a documentation and reporting skill that works with any text editor or markdown renderer.

| Tool | Required | Purpose |
|------|----------|---------|
| Any text editor | ✅ Yes | Writing reports in Markdown format |
| CVSS Calculator | ⚡ Optional | Use https://www.first.org/cvss/calculator/4.0 for scoring |

## Tool Execution Protocol

**MANDATORY**: All report file operations MUST follow this protocol:

1. **File write validation**: Always confirm files were written successfully
   ```bash
   # Write report and validate
   cat > findings/critical-sqli.md << 'EOF'
   # SQL Injection in Login Form

   ## Severity: Critical (CVSS 9.8)
   ...
   EOF

   # Validate file was created
   if [ -f findings/critical-sqli.md ]; then
     FILE_SIZE=$(stat -f%z findings/critical-sqli.md 2>/dev/null || stat -c%s findings/critical-sqli.md)
     if [ "$FILE_SIZE" -gt 0 ]; then
       echo "SUCCESS: Report file created (${FILE_SIZE} bytes)"
     else
       echo "ERROR: Report file is empty"
     fi
   else
     echo "ERROR: Failed to create report file"
   fi
   ```

2. **Directory validation before writing**
   ```bash
   # Ensure output directory exists
   if [ ! -d findings ]; then
     mkdir -p findings
     if [ $? -ne 0 ]; then
       echo "ERROR: Cannot create findings directory"
       echo "FALLBACK: Writing to current directory"
       REPORT_PATH="./critical-sqli.md"
     else
       REPORT_PATH="findings/critical-sqli.md"
     fi
   fi
   ```

## Overview

**Role: Security Report Compiler** — Your job is to compile verified findings into a clear, actionable report for the intended audience. Stay in your lane: you document and present, you do NOT discover new vulnerabilities, verify findings, or perform testing.

Professional security report writing methodology for penetration tests, vulnerability assessments, code reviews, and compliance audits. Covers the complete documentation lifecycle from individual finding documentation through final deliverable production.

## Pipeline Position

> **Position:** Phase 6 (Reporting) — final phase, after all testing and verification
> **Expected Input:** Verified findings from `vulnerability-verification`, exploitation evidence from `exploit-development`, recon data from `recon-and-enumeration`
> **Your Output:** Final security assessment report — executive summary, technical findings, remediation guidance
> **Consumed By:** The human reader (client, development team, security team, management)
> **Critical:** You compile and present — you do NOT discover, test, or verify. All findings should already be confirmed before reaching you.

Reports are the ONLY tangible output of a security engagement. A brilliant exploit that's poorly documented delivers zero value. Write findings as if the reader has never seen the application.

**REQUIRED SUB-SKILL:** Use superhackers:vulnerability-verification before documenting any finding — never report unverified vulnerabilities.

## When to Use

- After discovering and verifying vulnerabilities during any security assessment
- When producing final deliverables for a pentest, code review, or vulnerability assessment
- When documenting individual findings during testing (don't wait until the end)
- When writing executive summaries for management stakeholders
- When scoring vulnerabilities using CVSS v4.0
- When formatting evidence: screenshots, HTTP request/response pairs, code snippets
- When writing specific remediation guidance with code fixes
- When creating quick security advisories for critical findings
- When tracking finding timelines and SLA compliance

## Core Pattern

```
1. DOCUMENT findings AS YOU FIND THEM (not at the end)
2. VERIFY each finding before writing it up
3. SCORE using CVSS v4.0 with justification
4. WRITE finding with full evidence chain
5. DRAFT remediation with specific code/config fixes
6. COMPILE into appropriate report type
7. WRITE executive summary LAST (after all findings)
8. REVIEW draft for accuracy, completeness, tone
9. PRODUCE stakeholder-appropriate versions
10. DELIVER with timeline and retest expectations
```

### Execution Discipline

- **Persist**: Continue working through ALL steps of the Core Pattern until completion criteria are met. Do NOT stop after a single tool run or partial result.
- **Scope**: Work ONLY within this skill's methodology. Do NOT jump to another phase.
- **Negative Results**: If thorough testing reveals no vulnerabilities, that IS a valid result. Document what was tested and report "no findings" — do NOT invent issues.

## Quick Reference

### Severity Mapping

| Severity | CVSS Score | SLA (typical) | Example |
|----------|-----------|---------------|---------|
| Critical | 9.0-10.0  | 24-48 hours   | RCE, Auth Bypass, SQLi with data exfil |
| High     | 7.0-8.9   | 7 days        | Stored XSS, IDOR with sensitive data, Privilege Escalation |
| Medium   | 4.0-6.9   | 30 days       | CSRF, Reflected XSS, Info Disclosure (internal paths) |
| Low      | 0.1-3.9   | 90 days       | Missing headers, Verbose errors, Cookie flags |
| Info     | 0.0       | Best effort   | Version disclosure, Interesting endpoints |

### Report Type Selection

| Engagement Type | Report Template | Typical Length |
|----------------|----------------|----------------|
| Full Pentest | Full Pentest Report | 30-80 pages |
| Vulnerability Assessment | Vuln Assessment Report | 15-40 pages |
| Code Review | Code Review Report | 20-50 pages |
| Compliance Audit | Compliance Audit Report | 25-60 pages |
| Critical Finding | Quick Advisory/Alert | 1-3 pages |

### Finding Documentation Checklist

```
[ ] Title — clear, specific, includes affected component
[ ] Severity — with CVSS score and justification
[ ] Description — what the vulnerability IS
[ ] Impact — what an attacker CAN DO (business terms)
[ ] Steps to Reproduce — exact, numbered, reproducible
[ ] Evidence — screenshots, requests/responses, code
[ ] Remediation — specific fix with code/config
[ ] References — CWE, CVE, OWASP mapping
```

## Implementation

### 1. Individual Finding Documentation Format

Every finding MUST follow this structure:

```markdown
### [SEVERITY] Finding Title — Affected Component

**Severity:** Critical | High | Medium | Low | Info
**CVSS v4.0 Score:** X.X (CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:H/VI:H/VA:H/SC:N/SI:N/SA:N)
**CWE:** CWE-XXX — Name
**OWASP:** Category (e.g., A03:2021 — Injection)
**CVE:** CVE-XXXX-XXXXX (if applicable)
 **Status:** Open | Mitigated | Remediated | Accepted Risk
> ⚠️ **FORBIDDEN statuses in a final report:** "Unverified", "Not confirmed", "Possible", "TBD", "Needs investigation". If a finding cannot be classified definitively, it must be EXCLUDED from the report and flagged as a scope gap.
**Found:** YYYY-MM-DD
**Affected Asset:** hostname/IP, endpoint, code file

#### Description
[2-4 sentences. What the vulnerability is, where it exists, why it's vulnerable.
No impact here — just the technical facts.]

#### Impact
[What an attacker achieves by exploiting this. Business terms.
"An unauthenticated attacker could extract all customer records including PII"
NOT "SQL injection allows database access."]

#### Steps to Reproduce
1. Navigate to `https://target.example.com/login`
2. Enter username: `admin' OR '1'='1' --`
3. Enter password: `anything`
4. Click "Login"
5. Observe: Authentication bypassed, admin dashboard loads

> All steps must be EXACT and REPRODUCIBLE. Include full URLs, exact payloads,
> specific parameter names. A junior tester must reproduce using ONLY these steps.

#### Evidence

**Tool Command (REQUIRED):**
> Every evidence section MUST include the exact command used to discover or verify the finding. This is mandatory — a finding without a reproducible tool command is a finding without evidence.

```bash
# Example: the exact command that produced this finding
sqlmap -u "https://target.example.com/api/v1/login" --data="username=admin&password=test" \
  --batch --level 3 --risk 2 --output-dir=./sqlmap_output --timeout=30
# Output: sqlmap identified 3 injection points (error-based, time-based blind, UNION-based)
```

**Request:**
```http
POST /api/v1/login HTTP/1.1
Host: target.example.com
Content-Type: application/json

{"username": "admin' OR '1'='1' --", "password": "anything"}
```

**Response:**
```http
HTTP/1.1 200 OK
Content-Type: application/json

{"token": "eyJhbGciOiJIUzI1NiIs...", "role": "admin", "user_id": 1}
```

**Screenshot:** [F01-sqli-auth-bypass-01.png] — Annotated showing admin dashboard.

#### Remediation

Vulnerable code (`auth/login.py:42`):
```python
query = f"SELECT * FROM users WHERE username='{username}' AND password='{password}'"
```

Fixed code:
```python
query = "SELECT * FROM users WHERE username = :username AND password = :password"
result = db.execute(query, {"username": username, "password": password})
```

#### References
- CWE-89: SQL Injection
- OWASP A03:2021 — Injection
```

### 2. CVSS v4.0 Scoring Reference

#### Base Metrics

| Metric | Values | Description |
|--------|--------|-------------|
| **Attack Vector (AV)** | Network (N), Adjacent (A), Local (L), Physical (P) | How attacker reaches component |
| **Attack Complexity (AC)** | Low (L), High (H) | Conditions beyond attacker control |
| **Attack Requirements (AT)** | None (N), Present (P) | Deployment/config prerequisites |
| **Privileges Required (PR)** | None (N), Low (L), High (H) | Auth level needed |
| **User Interaction (UI)** | None (N), Passive (P), Active (A) | Does a user need to act? |
| **Confidentiality - Vulnerable System (VC)** | None (N), Low (L), High (H) | Confidentiality impact on vulnerable system |
| **Integrity - Vulnerable System (VI)** | None (N), Low (L), High (H) | Integrity impact on vulnerable system |
| **Availability - Vulnerable System (VA)** | None (N), Low (L), High (H) | Availability impact on vulnerable system |
| **Confidentiality - Subsequent Systems (SC)** | None (N), Low (L), High (H) | Confidentiality impact on subsequent systems |
| **Integrity - Subsequent Systems (SI)** | None (N), Low (L), High (H) | Integrity impact on subsequent systems |
| **Availability - Subsequent Systems (SA)** | None (N), Low (L), High (H) | Availability impact on subsequent systems |

#### Common Scoring Examples

```
SQLi (unauth, data exfil):
  CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:H/VI:H/VA:N/SC:N/SI:N/SA:N = 9.3 Critical
  Network-accessible, no auth, full read/write to database.

Stored XSS (auth user → admin session hijack):
  CVSS:4.0/AV:N/AC:L/AT:N/PR:L/UI:P/VC:H/VI:H/VA:N/SC:N/SI:N/SA:N = 8.5 High
  Attacker needs low-priv account, victim passively visits page.

IDOR (auth, read other users' data):
  CVSS:4.0/AV:N/AC:L/AT:N/PR:L/UI:N/VC:H/VI:N/VA:N/SC:N/SI:N/SA:N = 7.1 High
  With write: CVSS:4.0/AV:N/AC:L/AT:N/PR:L/UI:N/VC:H/VI:H/VA:N/SC:N/SI:N/SA:N = 8.6 High

RCE (unauthenticated, subsequent system impact):
  CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:H/VI:H/VA:H/SC:H/SI:H/SA:H = 10.0 Critical
  Full system compromise, no conditions required.

SSRF (internal network → cloud metadata → AWS keys):
  CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:H/VI:N/VA:N/SC:H/SI:H/SA:H = 9.3 Critical

Missing Security Headers:
  CVSS:4.0/AV:N/AC:L/AT:P/PR:N/UI:P/VC:N/VI:L/VA:N/SC:N/SI:N/SA:N = 2.3 Low
```

#### Severity Justification Rules

- **Critical vs High:** Critical requires unauthenticated access with high impact OR any RCE/full auth bypass. Exploitation chains achieving full compromise = Critical even if individual links are Medium.
- **High vs Medium:** High requires direct sensitive data access or privilege escalation. Medium is exploitable but limited blast radius or requires specific conditions.
- **Chain Exploitation:** Document the CHAIN severity. Info + IDOR + privesc → admin = Critical, even if components are Info + Medium + High individually.
- **Always justify:** Every severity MUST include 1-2 sentences explaining WHY. Clients will challenge ratings.

### 3. Report Templates

#### Template: Full Pentest Report

```markdown
# Penetration Test Report
**Client:** [Company] | **Type:** [External/Internal/WebApp] Pentest
**Version:** [1.0 Draft | 1.1 Final] | **Date:** [YYYY-MM-DD]
**Assessor(s):** [Names] | **Classification:** CONFIDENTIAL

## Document Control
| Version | Date | Author | Changes |
|---------|------|--------|---------|

## 1. Executive Summary
[Write LAST. 1-2 pages. Business language only. See Section 5.]

**Overall Risk Rating:** [Critical | High | Medium | Low]

| Severity | Count | Remediated | Open |
|----------|-------|------------|------|
| Critical | X | X | X |
| High     | X | X | X |
| Medium   | X | X | X |
| Low      | X | X | X |
| **Total**| **X** | **X** | **X** |

**Key Findings:**
1. [Most critical — 1 sentence, business impact]
2. [Second — 1 sentence, business impact]
3. [Third — 1 sentence, business impact]

**Immediate Actions Required:**
- [Action tied to Critical finding]
- [Action tied to Critical/High finding]

## 2. Scope
### 2.1 In-Scope Assets
| Asset | Type | IP/URL | Notes |
|-------|------|--------|-------|
### 2.2 Out-of-Scope
- [Excluded assets, tests, techniques]
### 2.3 Testing Credentials
| Role | Username | Access Level |
|------|----------|-------------|

## 3. Methodology
[Reference: OWASP Testing Guide v4.2, PTES, NIST SP 800-115]
Phases: Recon → Enumeration → Vuln Analysis → Exploitation → Post-Exploitation → Reporting
Tools Used: [List tools actually used]

## 4. Findings
### 4.1 Summary
| # | Title | Severity | CVSS | Status |
|---|-------|----------|------|--------|
### 4.2 Detailed Findings
[Use Individual Finding Documentation Format from Section 1]

## 5. Remediation Roadmap
- **Immediate (0-48h):** [Critical finding actions]
- **Short-term (1-2 weeks):** [High finding actions]
- **Medium-term (1-3 months):** [Medium finding actions]
- **Long-term (3-6 months):** [Strategic improvements]

## 6. Appendices
A: Raw Scan Output | B: Additional Evidence | C: Retest Results
```

#### Template: Vulnerability Assessment Report

```markdown
# Vulnerability Assessment Report
**Client:** [Company] | **Date:** [YYYY-MM-DD] | **Classification:** CONFIDENTIAL

## Executive Summary
**Assets Scanned:** [X] | **Vulnerabilities:** [X] (C:X H:X M:X L:X)
**Patch Compliance:** [X]%

## Scope & Methodology
[Scan tools, config, authenticated vs unauthenticated, coverage]

## Vulnerability Summary
| Severity | Count | % of Total |
|----------|-------|-----------|

## Findings by Host
### [Hostname/IP]
| Vulnerability | Severity | Port | CVE | Fix Available |
|--------------|----------|------|-----|--------------|

## Remediation Priority List
[Ordered by risk, grouped by remediation effort]

## Appendices
[Scan config, full output, false positive analysis]
```

#### Template: Code Review Report

```markdown
# Security Code Review Report
**Project:** [Repo Name] | **Date:** [YYYY-MM-DD] | **Reviewer:** [Name]
**Scope:** [Files/modules, commit range] | **Classification:** CONFIDENTIAL

## Executive Summary
[Languages, frameworks, LOC reviewed, security posture overview]

## Files Reviewed
| Path | Language | LOC | Risk Area |
|------|----------|-----|-----------|

## Review Criteria
OWASP ASVS v4.0, language-specific secure coding standards

## Findings
[Use finding format, replacing "Steps to Reproduce" with:]

**File:** `src/auth/login.py` | **Lines:** 42-58 | **CWE:** CWE-XXX

**Vulnerable Code:**
```python
# src/auth/login.py:42-58
[exact code with line numbers]
```

**Fixed Code:**
```python
[exact remediated code]
```

## Positive Observations
[What's done well — builds trust and shows thoroughness]

## Recommendations
Architecture-Level | Code-Level | Process-Level (SAST, hooks, training)
```

#### Template: Quick Advisory/Alert

```markdown
# SECURITY ADVISORY — [SEVERITY]
**Date:** [YYYY-MM-DD] | **Advisory ID:** [SA-YYYY-NNN]
**Affected System:** [Name] | **Status:** [Active | Remediated]

## Summary
[2-3 sentences: what was found, risk, action needed]

## Technical Details
[Brief description with key evidence]

## Immediate Actions Required
1. [Specific action with exact steps]
2. [Specific action with exact steps]

## Remediation
[Exact fix — code/config change, patch to apply]

## Timeline
| Date | Event |
|------|-------|
```

#### Template: Compliance Audit Report

```markdown
# Security Compliance Audit Report
**Client:** [Company] | **Standard:** [PCI DSS v4.0 | SOC 2 | ISO 27001 | HIPAA]
**Audit Period:** [Start] to [End] | **Classification:** CONFIDENTIAL

## Executive Summary
**Overall Compliance Rate:** [X]%

| Control Domain | Total | Compliant | Partial | Non-Compliant |
|---------------|-------|-----------|---------|---------------|

## Detailed Findings
### [Control ID] — [Control Name]
**Requirement:** [What the standard requires]
**Status:** Compliant | Partially Compliant | Non-Compliant
**Evidence Reviewed:** [What was examined]
**Gap:** [What's missing]
**Remediation:** [Steps to compliance]
**Priority:** [Based on risk and audit timeline]

## Remediation Plan
| Finding | Priority | Owner | Target Date | Status |
|---------|----------|-------|-------------|--------|

## Appendices
[Evidence inventory, interview notes, configuration samples]
```

### 4. Evidence Formatting Standards

#### Screenshots
- Annotate with red boxes/arrows pointing to relevant area
- Browser URL bar visible (proves target)
- Naming: `[finding-number]-[description]-[sequence].png` (e.g., `F01-sqli-bypass-01.png`)
- Min resolution: 1280x720, readable when printed
- NEVER include unredacted sensitive data (real creds, PII)

#### HTTP Request/Response

```http
POST /api/v1/users/profile HTTP/1.1
Host: target.example.com
Authorization: Bearer [REDACTED]
Content-Type: application/json

{"user_id": 1337, "role": "admin"}
```

Rules:
- Include ALL relevant headers (Auth, Content-Type)
- Highlight malicious payload with inline comments
- Truncate large bodies: `[...truncated...]`
- Redact tokens/credentials: `Authorization: Bearer [REDACTED]`
- Show both legitimate AND attack request for comparison

#### Code Snippets

```python
# File: src/controllers/user_controller.py
# Lines: 127-132 | Finding: F03 — IDOR
127 | @app.route('/api/user/<int:user_id>')
128 | @login_required
129 | def get_user(user_id):
130 |     # VULNERABLE: No authorization check
131 |     user = User.query.get(user_id)  # ← No ownership verification
132 |     return jsonify(user.to_dict())
```

Rules:
- Always include file path and line numbers
- Add comments explaining the vulnerability inline
- Use arrows (←) to highlight the exact vulnerable line
- Include finding ID for cross-reference

### 5. Executive Summary Writing

#### Structure

1. What was tested, when, by whom
2. Overall risk rating with justification
3. Key metrics — vuln counts by severity
4. Top 3 critical findings — one sentence each, BUSINESS impact
5. Positive observations (builds rapport)
6. Immediate actions — urgent items
7. Strategic recommendations — 2-3 long-term improvements

#### Language Rules

- NO technical jargon — write "customer data could be stolen" NOT "SQL injection in login"
- Quantify risk: "affects 50,000 user records" NOT "database is vulnerable"
- Business impact framing: revenue loss, regulatory fines, reputation damage
- Include positives: "encryption at rest is properly implemented"
- 1-2 pages maximum

**BAD:** "We found a SQL injection in /api/login through string concatenation."
**GOOD:** "A critical vulnerability allows any unauthenticated attacker to gain full admin access, exposing all 50,000 customer records including PII. This poses GDPR risk (fines up to 4% annual revenue) and immediate reputational risk."

### 6. Remediation Writing Standards

#### Rules

1. **NEVER generic advice.** "Sanitize input" is NOT a remediation. Specific code IS.
2. **BEFORE and AFTER code.** Show vulnerable and fixed versions.
3. **Exact config values.** "Enable HSTS" → `Strict-Transport-Security: max-age=31536000; includeSubDomains; preload`
4. **Vendor-specific.** Not "update config" — specify the exact file and directive.
5. **Verification steps.** How to confirm the fix works.
6. **Breaking change warnings.** Note if the fix may break functionality.

#### Remediation Template

```markdown
**Priority:** [Immediate | Short-term | Medium-term]
**Estimated Effort:** [Hours/Days]
**Breaking Change Risk:** [None | Low | Medium | High]

**Fix:** [Specific code/config change]
**Verification:** [Steps to confirm fix]
**Additional Hardening:** [Defense-in-depth measures]
```

#### Vendor-Specific Examples

**Nginx — Security Headers:**
```nginx
# /etc/nginx/conf.d/security-headers.conf
add_header X-Frame-Options "DENY" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
add_header Content-Security-Policy "default-src 'self';" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Permissions-Policy "camera=(), microphone=(), geolocation=()" always;
```

**Apache — Disable Directory Listing:**
```apache
# /etc/apache2/apache2.conf or .htaccess
<Directory /var/www/html>
    Options -Indexes
</Directory>
```

**Express.js — Helmet:**
```javascript
const helmet = require('helmet');
app.use(helmet({
  contentSecurityPolicy: { directives: { defaultSrc: ["'self'"] } },
  hsts: { maxAge: 31536000, includeSubDomains: true, preload: true },
  frameguard: { action: 'deny' },
}));
```

**Django — Session Security:**
```python
# settings.py
CSRF_COOKIE_SECURE = True
CSRF_COOKIE_HTTPONLY = True
SESSION_COOKIE_SECURE = True
SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_SAMESITE = 'Strict'
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = 'DENY'
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
```

### 7. Timeline Tracking

#### Engagement Timeline

```markdown
| Date | Phase | Activity | Notes |
|------|-------|----------|-------|
| YYYY-MM-DD | Kickoff | Scoping, ROE signed | |
| YYYY-MM-DD | Recon | Passive recon, OSINT | |
| YYYY-MM-DD | Testing | Active testing | |
| YYYY-MM-DD | Finding | Critical finding — advisory sent | |
| YYYY-MM-DD | Report | Draft delivered | |
| YYYY-MM-DD | Review | Client feedback | |
| YYYY-MM-DD | Final | Final report | |
| YYYY-MM-DD | Retest | Remediation verification | |
```

#### SLA Tracking

```markdown
| Finding | Severity | Found | SLA Deadline | Remediated | Status |
|---------|----------|-------|-------------|------------|--------|
| F01 | Critical | MM-DD | MM-DD | MM-DD | ✅ Met |
| F02 | High | MM-DD | MM-DD | — | ⚠️ Overdue |
| F03 | Medium | MM-DD | MM-DD | — | 🔵 On Track |
```

#### Finding Discovery Log (use DURING testing — NEVER copy directly into the final report)

> **This log is a working document only.** Any row with "No" in the Verified column or "TBD" / "Needs investigation" in Notes MUST be resolved before the engagement is complete. These rows must NEVER appear in any report section — they represent work in progress, not findings.

```markdown
| Time | ID | Title | Severity | Verified | Notes |
|------|-----|-------|----------|----------|-------|
| 09:15 | F01 | SQLi in login | Critical | Yes | Confirmed — request/response saved |
| 11:30 | F02 | IDOR /api/users | High | Yes | Confirmed — full user data dump |
| 14:00 | F03 | Reflected XSS | Medium | Yes | Confirmed — search param, POC link |
| 15:45 | — | Possible SSRF | TBD | No | ⚠️ WORKING ONLY — must resolve before report |
```

### 8. Report Delivery

#### Draft Review Checklist

```
BLOCKING GATES — report CANNOT be delivered if any of these fail:
[ ] FORBIDDEN LANGUAGE CHECK: Search report for "not confirmed", "inconclusive",
    "possible", "TBD", "needs investigation", "unverified". Zero matches required.
[ ] TOOL OUTPUT CHECK: Every finding has exact tool command + output snippet in Evidence.
[ ] All findings verified and reproducible (run through vulnerability-verification skill)
[ ] No finding has Status = "Unverified", "Not confirmed", or any ambiguous state
[ ] No finding with blank version field (must be version number or "version undetermined via [methods]")
[ ] No unverified or false-positive findings anywhere in the report

QUALITY CHECKS:
[ ] CVSS scores calculated and justified
[ ] Screenshots annotated and readable
[ ] Remediation is specific (code/config, not generic)
[ ] No unredacted sensitive data
[ ] Executive summary in business language
[ ] Client name and dates correct throughout
[ ] Classification marking on every page
[ ] Finding IDs consistent (summary matches details)
[ ] Spell check and grammar check complete
[ ] Version number and document control updated
[ ] Cross-references verified
```

#### Stakeholder Versions

**Technical (dev/security teams):** Full details, request/response evidence, code-level remediation, tool output appendices.

**Management (executives/board):** Expanded executive summary, risk ratings with business context, remediation roadmap with timelines and cost estimates, compliance impact, cost-of-breach comparison. No technical exploit details.

#### Delivery Communication Template

```
Subject: [CONFIDENTIAL] Security Assessment Report — [Company] — [Date]

Please find attached the [draft/final] [assessment type] report.
Assessment period: [start] to [end].

Key highlights:
- [X] findings ([N] Critical, [N] High)
- [Most critical finding — one sentence]
- Immediate action recommended for [N] critical items

[If draft]: Please review by [date]. Available for questions via secure call.
[If final]: Retest scheduled for [date]. Please confirm remediated items.

Next steps:
1. Review findings and remediation guidance
2. Prioritize Critical/High for immediate action
3. Schedule retest for [date]
```

### Context Window Awareness

During long engagements, prior conversation context may be summarized or compressed. When you detect summarized content (shorter-than-expected prior messages, loss of technical detail):

1. **Never trust summarized values** for: IP addresses, port numbers, URLs, credentials, CVSS scores, CWE IDs
2. **Re-verify** critical data by re-running the discovery command rather than quoting from summary
3. **Maintain a running findings log** in a file (not just in conversation) — this survives context compression
4. **Flag uncertainty**: If a prior finding's details are unclear from summary, state "details from prior context, re-verification recommended" in the report

## Common Mistakes

### 1. Writing Findings After Testing Completes
**Problem:** Memory fades, evidence lost, details fuzzy.
**Fix:** Document IMMEDIATELY when discovered. Use the Finding Discovery Log. Full write-up within 24 hours.

### 2. Generic Remediation
**Problem:** "Implement input validation" tells developers nothing.
**Fix:** Show exact vulnerable code, exact fixed code, exact config change. File path, line number, language-specific fix.

### 3. Technical Language in Executive Summaries
**Problem:** Executives don't know what "SQL injection" means.
**Fix:** Business impact only: data exposure, financial risk, regulatory consequences.

### 4. Incorrect CVSS Scoring
**Problem:** Inflating to look impressive or deflating to avoid hard conversations.
**Fix:** Score honestly using CVSS v4.0. Document the vector string. Justify every rating. Account for chain exploitation.

### 5. Missing Steps to Reproduce
**Problem:** Steps requiring tribal knowledge or specific setup.
**Fix:** Write for a junior tester who's never seen the app. Exact URLs, exact payloads, exact params. Test your own steps.

### 6. Unverified Findings in the Report
**Problem:** Reporting findings that were not definitively verified leads to false positives, incorrect severity, and destroyed client trust. Labeling them "Unverified — Requires Manual Confirmation" and including them anyway is NOT an acceptable workaround — it is the same problem with a label on it.
**Fix:**
- REQUIRED SUB-SKILL: Use `superhackers:vulnerability-verification` for every finding before writing the report
- **NEVER include a finding in the report without a definitive classification: Confirmed, Mitigated, False Positive, Out of Scope, or Inconclusive (with specific network-layer evidence)**
- "Not confirmed", "Possible", "TBD", "Needs investigation", "Unverified", and "Inconclusive — likely [something]" are FORBIDDEN in any final report section
- If a finding cannot be verified before the report deadline, it must be excluded from the report and flagged to the client as a scope gap requiring follow-up — do not include it with an ambiguous label
- The engagement is not complete while any finding is in an ambiguous state

### 7. No Positive Observations
**Problem:** All-negative reports feel adversarial, not collaborative.
**Fix:** Note what's done well: proper encryption, good session management, effective WAF rules. Builds trust and shows thoroughness.

### 8. Inconsistent Finding IDs
**Problem:** Summary IDs don't match detail section.
**Fix:** Format: `F01`, `F02`. Multi-phase: `P1-F01`, `P2-F01`. Verify all cross-references before delivery.

### 9. Missing Retest Documentation
**Problem:** No proof that remediation was verified.
**Fix:** For each fix: original finding ID, action taken, retest date, result (Pass/Fail), evidence of remediation.

### 10. No Draft Review
**Problem:** Typos, wrong client names, factual errors destroy credibility.
**Fix:** ALWAYS draft first. Use the checklist. Second pair of eyes. 2-3 days for client questions before finalizing.

## Completion Criteria

This skill's work is DONE when ALL of the following are true:
- [ ] Executive summary has been written with audience-appropriate language
- [ ] All verified findings are included with severity, evidence, and remediation
- [ ] Findings are organized by severity (Critical → High → Medium → Low → Informational)
- [ ] Each finding has actionable remediation guidance (not just "fix it")
- [ ] Report type matches the engagement scope (Full Pentest, Vuln Assessment, Code Review, etc.)
- [ ] No unverified or false-positive findings are included in the report
- [ ] All todo items created during this phase are marked complete

When all conditions are met, state "Phase complete: writing-security-reports" and stop.
Do NOT discover new vulnerabilities, re-test findings, or extend the engagement scope.
