# Individual Finding Document Template

**Load this reference when:** documenting a confirmed vulnerability for inclusion in a security report. Every finding must follow this exact structure.

## Usage

Copy the template below for each confirmed finding. Fill in every field. Fields marked `[REQUIRED]` must be present — a finding without any required field is incomplete.

---

## Template

```markdown
---
id: F[XX]
title: [Specific, descriptive title including affected component]
severity: [Critical | High | Medium | Low | Info]
cvss_score: [X.X]
cvss_vector: [CVSS:4.0/AV:X/AC:X/AT:X/PR:X/UI:X/VC:X/VI:X/VA:X/SC:X/SI:X/SA:X]
cwe: [CWE-XXX — Name]
owasp: [Category — e.g., A03:2021 — Injection]
cve: [CVE-XXXX-XXXXX or N/A]
status: [Open | Remediated | Accepted Risk | Partial Fix]
found_date: [YYYY-MM-DD]
asset: [hostname, IP, URL, or code file]
---

### [SEVERITY] [Title] — [Affected Component] [REQUIRED]

**Finding ID:** F[XX]
**Severity:** [Critical | High | Medium | Low | Info] [REQUIRED]
**CVSS v4.0:** [X.X] ([vector string]) [REQUIRED]
**CWE:** [CWE-XXX — Vulnerability Class Name] [REQUIRED]
**OWASP:** [Category — e.g., A03:2021 — Injection]
**CVE:** [CVE-XXXX-XXXXX] (if applicable)
**Status:** [Open | Remediated | Accepted Risk]
**Found:** [YYYY-MM-DD]
**Affected Asset:** [Specific endpoint, IP:port, or file path] [REQUIRED]

---

#### Description [REQUIRED]

[2-4 sentences. What the vulnerability IS, where it exists, and why the code/config
is vulnerable. Technical facts only — no impact assessment here.]

Example:
"The login endpoint at `/api/v1/auth/login` constructs SQL queries using string
concatenation with user-supplied username and password parameters. The application
does not use parameterized queries or input validation, allowing an attacker to
inject arbitrary SQL commands into the authentication query."

---

#### Impact [REQUIRED]

[What an attacker achieves by exploiting this. BUSINESS impact.
"An unauthenticated attacker could..." framing.
Quantify where possible: number of records, users affected, systems accessible.]

Example:
"An unauthenticated attacker can bypass authentication and gain admin access to
the application, exposing all 47,000 customer records including names, email
addresses, and billing information. This poses GDPR/CCPA compliance risk and
could result in regulatory fines and reputational damage."

**DO NOT write:** "SQL injection allows database access."
**DO write:** "An unauthenticated attacker can extract all customer records including PII."

---

#### Steps to Reproduce [REQUIRED]

> Every step must be EXACT and independently REPRODUCIBLE.
> A junior tester must be able to reproduce using ONLY these steps.

1. Navigate to `https://target.example.com/login`
2. Open browser developer tools → Network tab
3. Enter username: `admin' OR '1'='1' --`
4. Enter password: `anything`
5. Click "Login"
6. Observe: HTTP 200 response with admin session token
7. Navigate to `https://target.example.com/admin/dashboard`
8. Observe: Full admin dashboard loads with access to user management

**Tool-based reproduction (alternative):**
```bash
curl -X POST https://target.example.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin'\'' OR '\''1'\''='\''1'\'' --", "password": "anything"}'
```

---

#### Evidence [REQUIRED]

**Request:**
```http
POST /api/v1/auth/login HTTP/1.1
Host: target.example.com
Content-Type: application/json
Content-Length: 72

{"username": "admin' OR '1'='1' --", "password": "anything"}
```

**Response:**
```http
HTTP/1.1 200 OK
Content-Type: application/json
Set-Cookie: session=eyJhbGciOiJIUzI1NiIs...; Path=/; HttpOnly

{"status": "success", "role": "admin", "user_id": 1, "name": "Administrator"}
```

**Screenshots:**
- `F[XX]-[description]-01.png` — [What the screenshot shows]
- `F[XX]-[description]-02.png` — [What the screenshot shows]

> Screenshot naming: `F01-sqli-auth-bypass-01.png`
> Screenshots must show browser URL bar for target verification.
> Annotate with red boxes/arrows highlighting relevant areas.
> Redact any real PII, passwords, or sensitive data.

**Additional Evidence:** [IF APPLICABLE]
- Database extraction sample (3-5 records, PII redacted)
- Command output for RCE findings
- Internal page content for SSRF findings

---

#### CVSS Justification [REQUIRED]

| Metric | Value | Justification |
|--------|-------|---------------|
| Attack Vector | Network (N) | Exploitable via internet through web application |
| Attack Complexity | Low (L) | No special conditions; single request exploits |
| Attack Requirements | None (N) | No deployment-specific conditions required |
| Privileges Required | None (N) | No authentication needed |
| User Interaction | None (N) | No victim action required |
| Vuln. Confidentiality | High (H) | Full access to all database records |
| Vuln. Integrity | High (H) | Can modify/delete any database record |
| Vuln. Availability | None (N) | No service disruption demonstrated |
| Sub. Confidentiality | None (N) | Impact limited to the application |
| Sub. Integrity | None (N) | No impact on other systems |
| Sub. Availability | None (N) | No impact on other systems |

**Score:** 9.3 Critical (CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:H/VI:H/VA:N/SC:N/SI:N/SA:N)

---

#### Remediation [REQUIRED]

**Priority:** [Immediate | Short-term | Medium-term | Long-term]
**Estimated Effort:** [Hours | Days]
**Breaking Change Risk:** [None | Low | Medium | High]

**Vulnerable Code:** (`[file:line]`)
```python
# src/auth/login.py:42
query = f"SELECT * FROM users WHERE username = '{username}' AND password = '{password}'"
result = db.execute(query)
```

**Fixed Code:**
```python
# src/auth/login.py:42
query = "SELECT * FROM users WHERE username = :username AND password = :password"
result = db.execute(query, {"username": username, "password": password})
```

**Additional Hardening:**
- Implement input validation (alphanumeric + limited special characters)
- Add rate limiting to login endpoint (5 attempts per minute)
- Implement account lockout after 10 failed attempts
- Use bcrypt for password hashing (current implementation appears to store plain text)
- Enable SQL query logging for audit trail

**Verification Steps:**
1. Deploy the fix
2. Attempt the original exploit payload
3. Verify HTTP 401 response (not 200)
4. Test SQL injection bypass variations (double quotes, UNION-based, time-based)
5. Confirm legitimate login still functions

---

#### References

- CWE-89: Improper Neutralization of Special Elements used in an SQL Command
  https://cwe.mitre.org/data/definitions/89.html
- OWASP A03:2021 — Injection
  https://owasp.org/Top10/A03_2021-Injection/
- OWASP SQL Injection Prevention Cheat Sheet
  https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html

---

#### Chain Potential [IF APPLICABLE]

This finding chains with:
- **F[XX]:** [How it connects] → Combined severity: [X.X]
- See chain documentation in Finding F[XX] for full attack path.
```

---

## Finding Quality Checklist

Before including a finding in the report:

```
□ Title is specific (includes component name, not just "XSS found")
□ Severity matches CVSS score (not inflated or deflated)
□ CVSS vector string present with per-metric justification
□ Description explains WHAT, not IMPACT (that's the Impact section)
□ Impact uses business language and quantifies where possible
□ Steps to Reproduce are numbered, exact, and independently testable
□ Evidence includes BOTH request AND response
□ Screenshots are annotated with URL bar visible
□ Sensitive data is redacted (passwords, PII, tokens)
□ Remediation includes vulnerable AND fixed code
□ Remediation is specific (not "sanitize input")
□ CWE and OWASP references included
□ Finding ID is unique and matches summary table
```

## Finding Title Guidelines

**Bad titles:**
- "XSS Vulnerability"
- "SQL Injection Found"
- "Security Issue"

**Good titles:**
- "SQL Injection in Login Endpoint Allows Authentication Bypass"
- "Stored XSS in User Profile Bio Enables Session Hijacking"
- "IDOR in /api/users/{id}/documents Exposes All User Documents"
- "Hardcoded AWS Credentials in config/deploy.py"
- "Missing Authorization Check on Admin API Endpoints"

## Evidence Formatting Rules

### HTTP Request/Response
- Include ALL relevant headers (Authorization, Content-Type, Cookie)
- Highlight malicious payload with inline comment if needed
- Truncate large response bodies: `[...truncated X bytes...]`
- Redact tokens: `Authorization: Bearer [REDACTED]`
- Show BOTH legitimate AND attack request for comparison

### Screenshots
- Format: PNG, minimum 1280×720
- Naming: `F[ID]-[description]-[sequence].png`
- Browser URL bar MUST be visible
- Annotate with red boxes/arrows
- Never include unredacted PII

### Code Snippets
- Include file path and line numbers
- Add inline comments for vulnerable line: `← VULNERABLE: no parameterization`
- Show enough context (5-10 lines around vulnerable code)
- Include finding ID for cross-reference

Cross-reference: Use `superhackers:writing-security-reports/cvss-reference.md` for CVSS scoring. Use `superhackers:writing-security-reports/report-template.md` for the full report structure.
