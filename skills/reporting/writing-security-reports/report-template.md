# Penetration Test Report Template

**Load this reference when:** compiling final pentest deliverables, structuring a vulnerability assessment, or drafting any formal security assessment document.

## Usage

Copy this template and fill in each section. Write the Executive Summary LAST (after all findings are documented). Sections marked `[REQUIRED]` must be present. Sections marked `[IF APPLICABLE]` are included when relevant.

---

```markdown
# Penetration Test Report

**Client:** [Company Name]
**Assessment Type:** [External | Internal | Web Application | Mobile | API | Cloud] Penetration Test
**Version:** [1.0 Draft | 1.1 Final | 2.0 Retest]
**Date:** [YYYY-MM-DD]
**Assessor(s):** [Names / Team]
**Classification:** CONFIDENTIAL — Authorized Recipients Only

---

## Document Control [REQUIRED]

| Version | Date       | Author    | Changes           |
|---------|------------|-----------|-------------------|
| 0.1     | YYYY-MM-DD | [Name]    | Initial draft     |
| 1.0     | YYYY-MM-DD | [Name]    | Draft for review  |
| 1.1     | YYYY-MM-DD | [Name]    | Final after feedback |

**Distribution:**
| Name | Role | Organization |
|------|------|-------------|

---

## 1. Executive Summary [REQUIRED]

> **Write this section LAST.** Summarize findings in BUSINESS terms.
> No technical jargon. 1-2 pages maximum.

### Overall Risk Rating: [CRITICAL | HIGH | MEDIUM | LOW]

[Company Name]'s [application/infrastructure] was assessed during [date range].
The assessment identified [X] vulnerabilities, including [N] critical and [N] high
severity findings that pose immediate risk to [business impact: customer data,
financial operations, regulatory compliance].

### Finding Summary

| Severity | Count | Remediated | Open |
|----------|-------|------------|------|
| Critical | X     | X          | X    |
| High     | X     | X          | X    |
| Medium   | X     | X          | X    |
| Low      | X     | X          | X    |
| Info     | X     | X          | X    |
| **Total**| **X** | **X**      | **X**|

### Key Findings

1. **[Most critical — one sentence with business impact]**
   Example: "An unauthenticated attacker can access all 50,000 customer records
   including PII, posing GDPR risk (fines up to 4% annual revenue)."

2. **[Second most critical — one sentence with business impact]**

3. **[Third — one sentence with business impact]**

### Positive Observations

- [What's done well — builds rapport and shows thoroughness]
- [Example: "TLS 1.3 enforced across all endpoints with strong cipher suites"]
- [Example: "Database credentials properly managed via secrets manager"]

### Immediate Actions Required

1. [Action tied to Critical finding — specific, not generic]
2. [Action tied to Critical/High finding — specific, not generic]

### Strategic Recommendations

1. [Long-term security improvement]
2. [Process/architecture improvement]

---

## 2. Scope [REQUIRED]

### 2.1 In-Scope Assets

| Asset           | Type        | IP/URL                    | Notes          |
|-----------------|-------------|---------------------------|----------------|
| Web Application | HTTPS       | https://app.example.com   | Production     |
| API             | REST        | https://api.example.com   | v2 endpoints   |
| Internal Host   | Windows     | 192.168.1.100             | Domain joined  |

### 2.2 Out-of-Scope

- [Assets explicitly excluded]
- [Techniques not authorized (DoS, social engineering, physical)]
- [Third-party services (CDN, SaaS providers)]

### 2.3 Testing Credentials [IF APPLICABLE]

| Role         | Username     | Access Level    |
|-------------|-------------|-----------------|
| Regular User | testuser01  | Standard user   |
| Admin       | testadmin01 | Full admin      |

### 2.4 Rules of Engagement

- Testing window: [dates and times]
- Emergency contact: [name, phone, email]
- Notification protocol: [when to notify client — e.g., critical findings]
- Data handling: [sample extraction limits, PII handling]

---

## 3. Methodology [REQUIRED]

### Standards and Frameworks

- OWASP Testing Guide v4.2
- PTES (Penetration Testing Execution Standard)
- NIST SP 800-115 (Technical Guide to Information Security Testing)

### Phases

| Phase              | Activities                              | Duration    |
|--------------------|-----------------------------------------|-------------|
| Reconnaissance     | OSINT, passive enumeration              | [X] days    |
| Enumeration        | Service discovery, version detection    | [X] days    |
| Vulnerability Analysis | Automated scanning, manual testing  | [X] days    |
| Exploitation       | Controlled exploitation, PoC development| [X] days    |
| Post-Exploitation  | Privilege escalation, lateral movement  | [X] days    |
| Reporting          | Documentation, evidence compilation     | [X] days    |

### Tools Used

| Category          | Tools                                     |
|-------------------|-------------------------------------------|
| Reconnaissance    | [nmap, amass, subfinder, etc.]            |
| Scanning          | [nuclei, nikto, burpsuite, etc.]          |
| Exploitation      | [metasploit, sqlmap, custom scripts, etc.] |
| Post-Exploitation | [mimikatz, linpeas, etc.]                 |

---

## 4. Findings [REQUIRED]

### 4.1 Finding Summary

| ID   | Title                          | Severity | CVSS | Status |
|------|--------------------------------|----------|------|--------|
| F01  | [Finding title]               | Critical | 9.8  | Open   |
| F02  | [Finding title]               | High     | 8.1  | Open   |
| F03  | [Finding title]               | Medium   | 6.5  | Open   |

### 4.2 Detailed Findings

> Use the finding-template.md format for each finding.
> Include: Title, Severity, CVSS, Description, Impact, Steps to Reproduce,
> Evidence (request/response/screenshots), Remediation, References.

[Insert individual findings here — see superhackers:writing-security-reports/finding-template.md]

---

## 5. Remediation Roadmap [REQUIRED]

### Immediate (0-48 hours)
- [ ] [Critical finding remediation — specific action]
- [ ] [Critical finding remediation — specific action]

### Short-term (1-2 weeks)
- [ ] [High finding remediation — specific action]
- [ ] [High finding remediation — specific action]

### Medium-term (1-3 months)
- [ ] [Medium finding remediation — specific action]
- [ ] [Architecture improvement]

### Long-term (3-6 months)
- [ ] [Strategic security improvement]
- [ ] [Security program maturity]
- [ ] [Training/process improvements]

---

## 6. Risk Matrix [IF APPLICABLE]

### Likelihood × Impact Grid

|              | Low Impact | Medium Impact | High Impact | Critical Impact |
|--------------|-----------|---------------|-------------|-----------------|
| **Very Likely**  | Medium | High      | Critical    | Critical        |
| **Likely**       | Low    | Medium    | High        | Critical        |
| **Possible**     | Low    | Medium    | Medium      | High            |
| **Unlikely**     | Info   | Low       | Medium      | Medium          |

### Finding Risk Mapping

| Finding | Likelihood | Impact   | Risk Rating |
|---------|-----------|----------|-------------|
| F01     | Very Likely | Critical | Critical   |
| F02     | Likely    | High     | High        |
| F03     | Possible  | Medium   | Medium      |

---

## 7. Timeline [REQUIRED]

| Date       | Phase    | Activity                          | Notes         |
|------------|----------|-----------------------------------|---------------|
| YYYY-MM-DD | Kickoff  | Scoping call, ROE signed          |               |
| YYYY-MM-DD | Recon    | Passive reconnaissance            |               |
| YYYY-MM-DD | Testing  | Active testing began               |               |
| YYYY-MM-DD | Advisory | Critical finding — advisory sent   | F01           |
| YYYY-MM-DD | Report   | Draft report delivered              |               |
| YYYY-MM-DD | Review   | Client feedback incorporated       |               |
| YYYY-MM-DD | Final    | Final report delivered              |               |
| YYYY-MM-DD | Retest   | Remediation verification           |               |

---

## 8. Appendices [IF APPLICABLE]

### A: Raw Scan Output
[Summarized scan results, not full dumps — reference available upon request]

### B: Additional Evidence
[Extra screenshots, HTTP captures, tool output referenced in findings]

### C: Retest Results [IF APPLICABLE]

| Finding ID | Original Severity | Action Taken        | Retest Date | Result       |
|------------|------------------|---------------------|-------------|-------------|
| F01        | Critical         | Parameterized queries| YYYY-MM-DD | ✅ Remediated |
| F02        | High             | Added auth check    | YYYY-MM-DD  | ⚠️ Partial   |

### D: Glossary
[Define technical terms used in the report for non-technical readers]
```

---

## Report Quality Checklist

Before delivering, verify:

```
□ All findings verified and reproducible
□ CVSS scores calculated with vector strings and justifications
□ Screenshots annotated and readable at print resolution
□ Remediation is SPECIFIC (code/config, not "sanitize input")
□ No unredacted sensitive data (credentials, PII)
□ Executive summary uses business language only
□ Client name and dates correct throughout document
□ Classification marking present
□ Finding IDs consistent (summary table matches detailed findings)
□ Spell check and grammar check complete
□ Version number and document control updated
□ All cross-references verified (Appendix references match)
□ Positive observations included (not adversarial tone)
```

Cross-reference: Use `superhackers:writing-security-reports/finding-template.md` for individual finding format. Use `superhackers:writing-security-reports/cvss-reference.md` for scoring guidance.
