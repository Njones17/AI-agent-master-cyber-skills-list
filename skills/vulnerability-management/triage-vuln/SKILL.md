---
name: triage-vuln
description: Triages a vulnerability or CVE. Pulls CVSS score, EPSS exploitation probability, KEV status, affected versions, patch availability, and produces a prioritized remediation recommendation. Use when evaluating scanner findings or CVE notifications.
argument-hint: "[CVE-ID or vulnerability description]"
disable-model-invocation: true
---

# Vulnerability Triage: $ARGUMENTS

Perform a complete triage of this vulnerability. Work through each section systematically.

## Step 1: Identify the Vulnerability

If a CVE ID was provided, gather the following. If only a description was given, first identify the most likely CVE(s):

- **CVE ID:** [CVE-YYYY-NNNNN]
- **Vulnerability type:** [SQLi / RCE / XSS / SSRF / Auth bypass / etc.]
- **CWE:** [CWE-XXX: Name]
- **Affected software/component:** [Name + versions]
- **Published date:** [Date]

If MCP tools are available, use `shodan cve_lookup` to pull live data.

## Step 2: Severity Scoring

### CVSS v3.1 Score
Break down the CVSS vector:

| Metric | Value | Reasoning |
|---|---|---|
| Attack Vector (AV) | Network/Adjacent/Local/Physical | |
| Attack Complexity (AC) | Low/High | |
| Privileges Required (PR) | None/Low/High | |
| User Interaction (UI) | None/Required | |
| Scope (S) | Unchanged/Changed | |
| Confidentiality (C) | None/Low/High | |
| Integrity (I) | None/Low/High | |
| Availability (A) | None/Low/High | |

**CVSS Score:** X.X ([Critical/High/Medium/Low])
**Vector:** CVSS:3.1/AV:_/AC:_/PR:_/UI:_/S:_/C:_/I:_/A:_

### EPSS Score
EPSS (Exploit Prediction Scoring System) estimates the probability of exploitation in the next 30 days based on real-world data — far more useful than CVSS alone for prioritization.

- **EPSS Score:** [0.0–1.0] ([X]% probability of exploitation in next 30 days)
- **EPSS Percentile:** Top [X]% of all CVEs

If Shodan MCP is available: `cve_lookup CVE-YYYY-NNNNN` returns EPSS data.
Otherwise, check https://api.first.org/data/v1/epss?cve=CVE-YYYY-NNNNN

### KEV Status
CISA's Known Exploited Vulnerabilities catalog tracks CVEs with confirmed active exploitation.

- **In CISA KEV:** [Yes — added YYYY-MM-DD / No]
- **KEV due date (if applicable):** [YYYY-MM-DD]

If in KEV: this must be treated as P1 regardless of CVSS score.

## Step 3: Exploitability Assessment

### Public Exploit Availability
- [ ] Public PoC exists (Exploit-DB, GitHub, PacketStorm)
- [ ] Metasploit module available
- [ ] Active exploitation reported in the wild
- [ ] Ransomware groups have weaponized this
- [ ] Wormable / self-propagating

If MCP available: `searchsploit $ARGUMENTS` to check Exploit-DB.

### Exploitation Complexity (Real-World)
Beyond CVSS AC: how hard is this actually to exploit?

- [ ] Trivially exploitable (copy-paste PoC works)
- [ ] Requires some configuration or conditions
- [ ] Requires significant skill or specific environment
- [ ] Complex chain required (multiple vulnerabilities)

## Step 4: Contextual Risk Assessment

CVSS scores vulnerabilities in isolation. Real risk depends on context. Answer:

1. **Is the affected component exposed externally?** [Yes/No/Unknown]
2. **Is the vulnerable version actually deployed?** [Confirmed/Likely/Unknown]
3. **What data/systems does this component have access to?** [High value / Low value]
4. **Is there compensating controls?** [WAF, network segmentation, monitoring, etc.]
5. **What's the blast radius if exploited?** [Single system / Lateral movement possible / Full domain]

## Step 5: Patch & Remediation Status

- **Patch available:** [Yes — version X.X.X / No — vendor advisory only / No fix]
- **Workaround available:** [Yes — describe / No]
- **Vendor advisory:** [URL]
- **Estimated patch effort:** [Drop-in upgrade / Config change / Major refactor]

## Step 6: Priority Decision

Combine all factors into a remediation priority:

| Factor | Status | Weight |
|---|---|---|
| CVSS Score | [X.X] | Base risk |
| EPSS Score | [X%] | Exploitation likelihood |
| KEV | [Yes/No] | Active exploitation confirmed |
| External exposure | [Yes/No] | Amplifier |
| Patch available | [Yes/No] | Ease of remediation |

**Recommended Priority:**

- **P1 — Patch Now (24-72h):** KEV listed, OR (CVSS ≥ 9.0 AND externally exposed AND EPSS > 0.5)
- **P2 — Patch Soon (30 days):** CVSS ≥ 7.0 AND public exploit AND externally exposed
- **P3 — Patch Next Cycle (90 days):** CVSS ≥ 4.0 AND no public exploit, OR internal-only exposure
- **P4 — Track (180 days):** CVSS < 4.0 OR informational, low exposure

**Final Priority: [P1/P2/P3/P4]**

**Reasoning:** [One sentence explaining the priority decision]

## Step 7: Output Summary

Produce a concise triage card:

```
CVE: [ID]
Component: [Name + version]
CVSS: [Score] ([Severity])
EPSS: [Score] ([X]% exploitation probability)
KEV: [Yes/No]
Public Exploit: [Yes/No]
Externally Exposed: [Yes/No]
Patch Available: [Yes — version X / No]
Priority: [P1/P2/P3/P4]
Action: [Specific recommended action]
```
