---
name: severity-rate
description: Rates the severity of a security finding by walking through CVSS v3.1 scoring, EPSS context, and real-world risk factors. Produces a justified severity rating with full CVSS vector. Use when you need to assign or challenge a severity for a finding.
argument-hint: "[describe the vulnerability and its context]"
disable-model-invocation: true
---

# Severity Rating: $ARGUMENTS

Walk through CVSS v3.1 scoring systematically, then adjust for real-world context.

## Step 1: Understand the Vulnerability

Clarify the following before scoring. If not provided in the arguments, ask:

1. **What is the vulnerability?** (SQLi, XSS, SSRF, RCE, IDOR, auth bypass, etc.)
2. **Where is it?** (public-facing web app, internal API, local service, VPN endpoint)
3. **What does the vulnerable component have access to?** (DB with PII, admin console, file system)
4. **What level of access does an attacker need to exploit it?** (none, low-priv account, admin)
5. **Does exploiting it require another person to take action?** (click a link, visit a page)

## Step 2: CVSS v3.1 Base Score

Walk through each metric interactively if not obvious from the description:

### Attack Vector (AV)
*How does the attacker reach the vulnerable component?*

| Value | Meaning | Example |
|---|---|---|
| **Network (N)** | Exploitable remotely, no local access needed | Internet-facing web app vuln |
| **Adjacent (A)** | Same network/segment required | WiFi attack, LAN-only service |
| **Local (L)** | Requires local shell access | Local privilege escalation |
| **Physical (P)** | Requires physical hardware access | USB-based attack |

**Selected:** [AV:?]

### Attack Complexity (AC)
*Beyond the attacker's control — are special conditions required?*

| Value | Meaning |
|---|---|
| **Low (L)** | No special conditions — attack works reliably every time |
| **High (H)** | Requires specific config, race condition, or prior info gathering |

**Selected:** [AC:?]

### Privileges Required (PR)
*What level of authentication does the attacker need?*

| Value | Meaning |
|---|---|
| **None (N)** | No authentication needed — unauthenticated |
| **Low (L)** | Requires a standard user account |
| **High (H)** | Requires admin or elevated privileges |

**Selected:** [PR:?]

### User Interaction (UI)
*Does exploitation require a victim to do something?*

| Value | Meaning |
|---|---|
| **None (N)** | No victim interaction needed |
| **Required (R)** | Victim must click, visit, or take some action |

**Selected:** [UI:?]

### Scope (S)
*Does impact extend beyond the vulnerable component?*

| Value | Meaning | Example |
|---|---|---|
| **Unchanged (U)** | Impact stays within the vulnerable component | SQLi → database only |
| **Changed (C)** | Impact affects other components | XSS → attacker's browser → victim's session |

**Selected:** [S:?]

### Impact Metrics (C/I/A)
*For each: None (N) = no impact, Low (L) = limited, High (H) = complete loss*

**Confidentiality (C):** Can the attacker read data they shouldn't? [N/L/H]
- None: No data exposed
- Low: Some data exposed, not all
- High: Full data disclosure possible

**Integrity (I):** Can the attacker modify data or system state? [N/L/H]
- None: No modification possible
- Low: Limited modification
- High: Full modification/takeover possible

**Availability (A):** Can the attacker disrupt the service? [N/L/H]
- None: No disruption possible
- Low: Reduced performance or partial unavailability
- High: Full denial of service

**Selected:** [C:? I:? A:?]

## Step 3: Calculate CVSS Score

Using the selected values, calculate or look up the CVSS v3.1 base score:

**CVSS Vector:** `CVSS:3.1/AV:[?]/AC:[?]/PR:[?]/UI:[?]/S:[?]/C:[?]/I:[?]/A:[?]`

**Base Score:** [X.X]
**Severity:** [None (0.0) / Low (0.1-3.9) / Medium (4.0-6.9) / High (7.0-8.9) / Critical (9.0-10.0)]

## Step 4: Real-World Context Adjustments

CVSS scores vulnerability in isolation. Adjust your reported severity based on context:

### Factors that INCREASE effective risk
- ✅ Public exploit or Metasploit module available → upgrade consideration
- ✅ In CISA KEV (actively exploited in wild) → treat as at least one severity higher
- ✅ Externally accessible without authentication → amplifies base score
- ✅ Leads to access to crown jewel systems (AD, payment DB, customer PII)
- ✅ Part of an exploit chain that achieves critical impact

### Factors that DECREASE effective risk
- ✅ Compensating control exists (WAF partially mitigates, network segmentation limits blast radius)
- ✅ Internal-only access required (reduces AV from Network to Local effectively)
- ✅ No public exploit and vulnerability is complex to reproduce
- ✅ Minimal data or system access from the vulnerable component
- ✅ Patch is already deployed or imminent

### Adjusted Severity
Based on context: [Same as CVSS / Upgrade to X / Downgrade to X]
**Reason for adjustment:** [Explain if different from raw CVSS]

## Step 5: Final Verdict

```
FINDING: $ARGUMENTS

CVSS Score:    [X.X] ([Severity])
CVSS Vector:   CVSS:3.1/AV:[?]/AC:[?]/PR:[?]/UI:[?]/S:[?]/C:[?]/I:[?]/A:[?]

Reported Severity: [Critical / High / Medium / Low / Informational]
Adjusted from CVSS: [Yes — explain / No]

Justification:
[2-3 sentence explanation of why this severity is appropriate,
referencing specific factors: exposure, impact, exploitability,
compensating controls, or context]

Comparable findings for calibration:
- This is similar in severity to: [known CVE or vulnerability type]
- This is more/less severe than: [comparison]

Remediation Priority:
- P1 (24-72h): [If Critical + externally exposed + public exploit]
- P2 (30 days): [If High]
- P3 (90 days): [If Medium]
- P4 (180 days): [If Low/Info]
```
