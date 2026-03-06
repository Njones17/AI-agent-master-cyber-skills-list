# CVSS v4.0 Quick Reference

**Load this reference when:** scoring a vulnerability, justifying a severity rating, or when you need to calculate CVSS for a confirmed finding. This document covers CVSS v4.0 — do NOT use CVSS v3.1 vectors or metrics.

## Overview

CVSS (Common Vulnerability Scoring System) v4.0 produces a score from 0.0 to 10.0 based on **11 base metrics** (up from 8 in v3.1). Every finding in a pentest report MUST include a CVSS score with the full vector string and justification.

Key changes from v3.1:
- **Scope is removed.** Replaced by Subsequent System impact metrics (SC/SI/SA).
- **User Interaction** now has three values: None/Passive/Active (not None/Required).
- **Attack Requirements (AT)** is a new metric for deployment-specific conditions.
- **Impact is split** into Vulnerable System (VC/VI/VA) and Subsequent System (SC/SI/SA).

Use the Python `cvss` library (`pip install cvss`) for accurate programmatic scoring. All scores in this document have been verified against it.

**Core principle:** Score based on what you DEMONSTRATED, not what is theoretically possible. Over-scoring destroys credibility. Under-scoring leaves clients exposed.

## Severity Ranges

| Score | Severity | Typical SLA | Color |
|-------|----------|-------------|-------|
| 9.0-10.0 | Critical | 24-48 hours | Red |
| 7.0-8.9 | High | 7 days | Orange |
| 4.0-6.9 | Medium | 30 days | Yellow |
| 0.1-3.9 | Low | 90 days | Blue |
| 0.0 | Informational | Best effort | White |

## Base Metrics -- Decision Guide

### Attack Vector (AV) -- How does the attacker reach the target?

```
Network (N)  -> Exploitable remotely via internet/network
               Examples: web vuln, remote service, API endpoint

Adjacent (A) -> Requires same network segment (LAN, WiFi, Bluetooth)
               Examples: ARP spoofing, Bluetooth attack, same-subnet exploit

Local (L)    -> Requires local system access (shell, physical login)
               Examples: local privilege escalation, file permission issue

Physical (P) -> Requires physical access to the device
               Examples: USB attack, JTAG, cold boot, evil maid
```

**Decision flow:**
```
Can it be exploited over the internet? -> Network (N)
Requires same LAN/WiFi? -> Adjacent (A)
Requires shell access or local login? -> Local (L)
Requires touching the hardware? -> Physical (P)
```

### Attack Complexity (AC) -- Does exploitation require special conditions?

```
Low (L)   -> No special conditions. Exploit works reliably every time.
             Examples: Simple SQLi, unauthenticated RCE, direct IDOR

High (H)  -> Requires conditions beyond attacker's control:
             - Race condition with specific timing window
             - Man-in-the-middle position required
             - Exploit depends on unpredictable runtime state
```

**Decision flow:**
```
Can a script kiddie exploit this with a single request? -> Low (L)
Does it require specific timing, network position, or luck? -> High (H)
```

**Common mistake:** Do not confuse "requires multiple steps" with High complexity. A multi-step exploit that works reliably = Low complexity. Complexity is about CONDITIONS, not STEPS.

### Attack Requirements (AT) -- Does exploitation depend on deployment conditions?

This is a NEW metric in CVSS v4.0. It captures whether exploitation depends on specific deployment or configuration conditions of the target.

```
None (N)     -> No special deployment conditions needed.
                Exploit works against any standard deployment.
                Examples: SQLi in application code, XSS in core feature,
                default-config RCE

Present (P)  -> Requires specific deployment or configuration conditions.
                NOT about security features -- about how the system is deployed.
                Examples: Exploit only works when app runs behind specific
                reverse proxy, requires specific OS version, depends on
                non-default storage backend, needs a feature flag enabled
```

**Decision flow:**
```
Does exploitation depend on deployment-specific conditions? -> No: AT:N / Yes: AT:P
Is the condition a security feature (WAF, CSP)? -> That is AC:H, not AT:P
Is it about HOW the target is deployed/configured? -> AT:P
```

**Common mistake:** AT is not about security mechanisms (those affect AC). AT is about deployment topology, runtime environment, or configuration choices that are not security controls.

### Privileges Required (PR) -- What access level does the attacker need?

```
None (N)  -> No authentication needed
             Examples: Unauthenticated SQLi, public endpoint XSS

Low (L)   -> Regular user account needed
             Examples: IDOR between users, authenticated XSS, file upload

High (H)  -> Admin/privileged account needed
             Examples: Admin panel RCE, privileged API abuse
```

**Decision flow:**
```
Can an anonymous internet user exploit this? -> None (N)
Requires a regular user account? -> Low (L)
Requires an admin or privileged account? -> High (H)
```

**Note:** If self-registration is available, PR is effectively None for "Low" scenarios (attacker creates own account). Adjust scoring context accordingly.

### User Interaction (UI) -- Must a victim do something?

CHANGED from v3.1. Now has three values instead of two (None/Required).

```
None (N)    -> No victim action needed. Attacker exploits directly.
               Examples: SQLi, SSRF, direct RCE, IDOR

Passive (P) -> Victim performs an ordinary, involuntary, or uninvolved action.
               Examples: clicking a link, visiting a page, viewing an email,
               browsing to a page with stored XSS

Active (A)  -> Victim must perform specific, conscious actions.
               Examples: installing an application, changing security settings,
               dismissing or accepting a security warning, importing a file
```

**Decision flow:**
```
Does the exploit fire without any victim involvement? -> None (N)
Victim just clicks a link or views a page? -> Passive (P)
Victim must actively install/configure/accept something? -> Active (A)
```

**Common mistake:** Do NOT use UI:R (v3.1 syntax). Use UI:P or UI:A in v4.0. Most former UI:R scenarios map to UI:P.

### Vulnerable System Impact (VC/VI/VA) -- Impact on the vulnerable component itself

These metrics measure CIA impact on the system that contains the vulnerability.

```
Confidentiality (VC):
  None (N) -> No data accessed from the vulnerable system
  Low (L)  -> Limited data accessed (non-sensitive, partial)
  High (H) -> All data accessible, or sensitive data (PII, creds, secrets)

Integrity (VI):
  None (N) -> No data modified on the vulnerable system
  Low (L)  -> Limited data modification (some records, non-critical)
  High (H) -> Arbitrary data modification, or critical data altered

Availability (VA):
  None (N) -> No service disruption to the vulnerable system
  Low (L)  -> Partial/intermittent disruption
  High (H) -> Complete service outage, persistent DoS
```

### Subsequent System Impact (SC/SI/SA) -- Impact on OTHER systems

This REPLACES the Scope metric from v3.1. Instead of a binary Unchanged/Changed flag, you now directly score CIA impact on systems beyond the vulnerable component.

```
Confidentiality (SC):
  None (N) -> No data accessed on other systems
  Low (L)  -> Limited data accessed on other systems
  High (H) -> Full data access on downstream/connected systems

Integrity (SI):
  None (N) -> No data modified on other systems
  Low (L)  -> Limited modification on other systems
  High (H) -> Arbitrary modification on downstream/connected systems

Availability (SA):
  None (N) -> No disruption to other systems
  Low (L)  -> Partial disruption to other systems
  High (H) -> Complete outage of downstream/connected systems
```

**Decision flow:**
```
Does exploitation impact systems BEYOND the vulnerable component?
  No  -> SC:N/SI:N/SA:N
  Yes -> Score CIA impact on those other systems (L or H per metric)

Examples of subsequent system impact:
  SSRF from web app -> reads cloud metadata service -> SC:H
  XSS steals session -> accesses different-origin resources -> SC:L/SI:L
  Web app compromise -> attacker pivots to internal network -> SC:H/SI:H/SA:H
```

## Common Vulnerability Scoring Examples

### Critical (9.0-10.0)

```
Unauthenticated Remote Code Execution:
  CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:H/VI:H/VA:H/SC:N/SI:N/SA:N = 9.3 Critical
  Justification: Network-accessible, no auth, no special conditions. Full
  system compromise on the vulnerable host.

SSRF -> Cloud Credentials -> Full Infrastructure Access:
  CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:H/VI:H/VA:H/SC:H/SI:H/SA:H = 10.0 Critical
  Justification: Web app SSRF leads to cloud metadata theft, then full
  infrastructure compromise. Maximum impact on both vulnerable and
  subsequent systems.

Authentication Bypass -> Admin Access:
  CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:H/VI:H/VA:N/SC:N/SI:N/SA:N = 9.3 Critical
  Justification: No auth needed, full read/write as admin. No availability
  impact (system still runs).

SQL Injection -- DBA Privileges (xp_cmdshell):
  CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:H/VI:H/VA:H/SC:N/SI:N/SA:N = 9.3 Critical
  Justification: Unauth SQLi, DBA allows xp_cmdshell -> RCE equivalent.
  Full CIA impact on the database server.
```

### High (7.0-8.9)

```
SQL Injection -- Data Extraction (non-DBA):
  CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:H/VI:N/VA:N/SC:N/SI:N/SA:N = 8.7 High
  Justification: Full read access to database, no write/exec capability.

SSRF -- Internal Network Access (no cloud creds):
  CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:N/VI:N/VA:N/SC:H/SI:N/SA:N = 7.7 High
  Justification: Web app SSRF reads internal services (subsequent system),
  but no direct impact on the vulnerable web app itself.

Stored XSS -> Admin Session Hijack:
  CVSS:4.0/AV:N/AC:L/AT:N/PR:L/UI:P/VC:H/VI:H/VA:N/SC:N/SI:N/SA:N = 8.5 High
  Justification: Low-priv user injects XSS, admin passively views content
  (UI:P), attacker hijacks admin session. Full read/write on vulnerable app.

IDOR -- Read + Write Other Users' Data:
  CVSS:4.0/AV:N/AC:L/AT:N/PR:L/UI:N/VC:H/VI:H/VA:N/SC:N/SI:N/SA:N = 8.6 High
  Justification: Authenticated user can access and modify any other user's
  data. No availability impact.

Path Traversal -- Arbitrary File Read:
  CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:H/VI:N/VA:N/SC:N/SI:N/SA:N = 8.7 High
  Justification: Read /etc/passwd, source code, config files with secrets.
  No authentication required.

IDOR -- Read-Only:
  CVSS:4.0/AV:N/AC:L/AT:N/PR:L/UI:N/VC:H/VI:N/VA:N/SC:N/SI:N/SA:N = 7.1 High
  Justification: Authenticated user reads any other user's data. No
  modification capability.
```

### Medium (4.0-6.9)

```
Reflected XSS -- Standard:
  CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:P/VC:N/VI:N/VA:N/SC:L/SI:L/SA:N = 5.3 Medium
  Justification: User must click link (UI:P). Limited impact on the
  user's browser session (subsequent system, low C+I).

Stored XSS -- Standard (no admin context):
  CVSS:4.0/AV:N/AC:L/AT:N/PR:L/UI:P/VC:N/VI:N/VA:N/SC:L/SI:L/SA:N = 5.1 Medium
  Justification: Requires account to inject (PR:L), user must view content
  (UI:P). Limited impact on victim's session.

CSRF -- State-Changing Operation:
  CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:P/VC:N/VI:L/VA:N/SC:N/SI:N/SA:N = 5.3 Medium
  Justification: Victim must visit attacker page (UI:P). Limited integrity
  impact on the vulnerable application.

Open Redirect:
  CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:P/VC:N/VI:N/VA:N/SC:L/SI:L/SA:N = 5.3 Medium
  Justification: Phishing amplification, OAuth token theft potential.
  Impact on subsequent system (user's trust, downstream auth).

Verbose Error Messages:
  CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:L/VI:N/VA:N/SC:N/SI:N/SA:N = 6.9 Medium
  Justification: No auth needed, reveals internal paths, framework versions,
  SQL queries. Low confidentiality impact on the vulnerable system.
```

### Low (0.1-3.9)

```
Missing Security Headers:
  CVSS:4.0/AV:N/AC:L/AT:P/PR:N/UI:P/VC:N/VI:L/VA:N/SC:N/SI:N/SA:N = 2.3 Low
  Justification: Requires specific deployment conditions (AT:P) and user
  interaction (UI:P). Indirect risk, needs additional vulnerability to
  exploit meaningfully.

Cookie Without Secure Flag:
  CVSS:4.0/AV:N/AC:L/AT:P/PR:N/UI:P/VC:L/VI:N/VA:N/SC:N/SI:N/SA:N = 2.3 Low
  Justification: Requires MITM position on non-HTTPS path (AT:P) and
  user interaction (UI:P). Low confidentiality impact.
```

## Scoring Chains

When vulnerabilities chain together:

1. **Score the CHAIN as a single finding** with its combined impact
2. **Document individual components** with their standalone CVSS
3. **Chain CVSS reflects FINAL impact** -- not the weakest link

When a chain crosses system boundaries, reflect this in SC/SI/SA metrics (High values) rather than the old Scope:Changed approach.

```
Example: IDOR + Password Reset Token Leak -> Account Takeover

Individual:
  IDOR:              CVSS:4.0/AV:N/AC:L/AT:N/PR:L/UI:N/VC:L/VI:N/VA:N/SC:N/SI:N/SA:N = 5.3
  Token leak:        CVSS:4.0/AV:N/AC:L/AT:N/PR:L/UI:N/VC:H/VI:N/VA:N/SC:N/SI:N/SA:N = 7.1

Chain:
  Account Takeover:  CVSS:4.0/AV:N/AC:L/AT:N/PR:L/UI:N/VC:H/VI:H/VA:N/SC:N/SI:N/SA:N = 8.6
  Justification: IDOR exposes reset tokens -> attacker resets any password.
  Full read/write access to victim accounts.
```

## Programmatic Score Verification

Use the Python `cvss` library to verify all scores programmatically. Never trust manual calculations alone.

```
pip install cvss
```

```python
from cvss import CVSS4

# Score a single vector
c = CVSS4("CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:H/VI:H/VA:H/SC:N/SI:N/SA:N")
print(f"Score: {c.scores()[0]}")       # 9.3
print(f"Severity: {c.severities()[0]}")  # Critical

# Batch verification
vectors = [
    "CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:H/VI:H/VA:H/SC:N/SI:N/SA:N",
    "CVSS:4.0/AV:N/AC:L/AT:N/PR:L/UI:P/VC:N/VI:N/VA:N/SC:L/SI:L/SA:N",
]
for v in vectors:
    c = CVSS4(v)
    print(f"{c.scores()[0]:.1f} {c.severities()[0]} -- {v}")
```

## Justification Requirements

Every CVSS score in a report MUST include:

```
1. The full vector string:   CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:H/VI:H/VA:H/SC:N/SI:N/SA:N
2. The numeric score:        9.3
3. The severity label:       Critical
4. 1-2 sentence justification explaining WHY each metric was chosen
```

**Bad justification:** "CVSS 9.3 -- very severe vulnerability."
**Good justification:** "CVSS 9.3 Critical (CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:H/VI:H/VA:H/SC:N/SI:N/SA:N) -- Exploitable remotely without authentication. No special conditions or deployment requirements. Attacker gains full read/write access to database and OS command execution via xp_cmdshell, resulting in complete system compromise."

## Common Scoring Mistakes

| Mistake | Correct Approach |
|---------|-----------------|
| Everything is 9.3 | Score reflects DEMONSTRATED impact |
| Reflected XSS = Critical | Requires user interaction (UI:P) and impacts subsequent system only -> 5.3 |
| IDOR = Critical | Usually 5.3-8.6 depending on read-only vs read/write and data sensitivity |
| "Theoretical RCE" scored as RCE | Score what you PROVED, note theoretical in narrative |
| Chain scored as weakest link | Chain scored by FINAL impact |
| Missing headers = Medium | Usually Low (2.3) unless directly exploitable |
| Self-XSS = Medium | Self-XSS is typically not reportable or Info |
| Using old Scope metric (S:U/S:C) | Use SC/SI/SA to capture cross-boundary impact |
| Using AT:N when deployment config matters | Use AT:P when exploit depends on specific deployment conditions |
| Using UI:R (v3.1 syntax) | Use UI:P (passive) or UI:A (active) in v4.0 |

## Calculator

For exact calculations, use: https://www.first.org/cvss/calculator/4.0

For programmatic verification, use the Python `cvss` library as shown above. For common vulnerability types, the examples in this document cover 90% of findings. Keep scores consistent across your reports.

Cross-reference: Use `superhackers:vulnerability-verification` for confirming impact before scoring. Use `superhackers:writing-security-reports/finding-template.md` for including CVSS in finding documentation.
