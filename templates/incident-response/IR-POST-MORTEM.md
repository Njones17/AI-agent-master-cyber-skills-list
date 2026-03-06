# Incident Response Post-Mortem

> This document is blameless. The goal is to understand what happened and prevent recurrence.
> Focus on systems and processes, not individual mistakes.

---

**Incident ID:** IR-YYYY-NNN
**Classification:** [Confirmed Breach / Suspected Breach / False Positive / Near Miss]
**Severity:** P1-Critical / P2-High / P3-Medium / P4-Low
**Status:** [Open / Contained / Remediated / Closed]
**Incident Commander:** [Name]
**Report Author:** [Name]
**Report Date:** YYYY-MM-DD

---

## 1. Incident Summary

### What Happened (5 sentences or less)

[Plain-language summary. Assume the reader is a senior leader who was not involved. Answer: what happened, when, what was affected, and what was done about it.]

**Example:** *On [date] at approximately [time], the security team detected unusual outbound traffic from a production web server. Investigation revealed an attacker had exploited an unpatched vulnerability (CVE-XXXX-XXXXX) to gain remote code execution, then exfiltrated approximately 4.2 GB of data over a 6-hour period before detection. Affected systems were isolated at [time], and the attacker's access was fully revoked by [time]. Customer data from the [product] database was included in the exfiltrated data.*

### Timeline (Quick Reference)

| Time (UTC) | Event |
|---|---|
| YYYY-MM-DD HH:MM | First attacker activity observed (post-hoc) |
| YYYY-MM-DD HH:MM | Initial detection / alert |
| YYYY-MM-DD HH:MM | Incident declared / team assembled |
| YYYY-MM-DD HH:MM | Containment actions initiated |
| YYYY-MM-DD HH:MM | Systems isolated |
| YYYY-MM-DD HH:MM | Attacker access revoked |
| YYYY-MM-DD HH:MM | Eradication confirmed |
| YYYY-MM-DD HH:MM | Recovery completed |
| YYYY-MM-DD HH:MM | Incident closed |

**Total time to detect:** [X hours/days from first attacker activity to detection]
**Total time to contain:** [X hours from detection to containment]
**Total duration (detection to close):** [X hours/days]

---

## 2. Impact Assessment

### Systems Affected

| System | Impact Type | Data Classification | Restored |
|---|---|---|---|
| [System/Service] | [Compromised / Accessed / Disrupted] | [Public / Internal / Confidential / Regulated] | [Yes / No / Partial] |

### Data Impact

| Data Type | Volume | Affected Records | Regulatory Scope |
|---|---|---|---|
| [Customer PII] | [X GB / X records] | [Count or "Unknown"] | [GDPR / HIPAA / PCI / None] |

**Was data exfiltrated?** [Confirmed Yes / Suspected Yes / No / Unknown]
**Was data modified or destroyed?** [Yes / No / Unknown]
**Was a ransom demanded?** [Yes / No]

### Business Impact

- **Revenue impact:** [Dollar amount or "Under assessment"]
- **Downtime:** [X hours of service disruption]
- **Customers affected:** [Count or "Unknown"]
- **Regulatory notification required:** [Yes — [regulation] / No / Under assessment]
- **Notification deadline:** [YYYY-MM-DD if applicable]

### Reputational Impact

[Was this publicly disclosed? Any media coverage? Customer communications sent?]

---

## 3. Detailed Timeline

[Comprehensive, chronological account of the incident. Include both attacker actions (from logs/forensics) and responder actions. Be specific about times and evidence sources.]

### Pre-Incident (Attacker Activity)

| Time (UTC) | Source | Event | Evidence |
|---|---|---|---|
| YYYY-MM-DD HH:MM | [Firewall log / Auth log / etc.] | [What happened] | [Log file, screenshot, etc.] |

### Detection & Initial Response

| Time (UTC) | Actor | Action | Outcome |
|---|---|---|---|
| YYYY-MM-DD HH:MM | [SIEM / Person] | [Alert fired / Ticket created / etc.] | [Result] |

### Containment

| Time (UTC) | Actor | Action | Outcome |
|---|---|---|---|
| YYYY-MM-DD HH:MM | [Name / System] | [Action taken] | [Result] |

### Eradication & Recovery

| Time (UTC) | Actor | Action | Outcome |
|---|---|---|---|
| YYYY-MM-DD HH:MM | [Name / System] | [Action taken] | [Result] |

---

## 4. Root Cause Analysis

### Initial Access Vector

**How did the attacker gain initial access?**

[Specific technical description. CVE exploited? Phishing email? Credential stuffing? Insider?]

- **Vulnerability/Technique:** [CVE / ATT&CK Technique ID]
- **Entry point:** [URL / System / Account]
- **Why it was possible:** [Unpatched system / Weak credentials / Missing control]

### Attacker Techniques (MITRE ATT&CK)

| Phase | Technique | ID | How it was used |
|---|---|---|---|
| Initial Access | [Technique] | T1XXX | [Description] |
| Execution | [Technique] | T1XXX | [Description] |
| Persistence | [Technique] | T1XXX | [Description] |
| Privilege Escalation | [Technique] | T1XXX | [Description] |
| Defense Evasion | [Technique] | T1XXX | [Description] |
| Credential Access | [Technique] | T1XXX | [Description] |
| Discovery | [Technique] | T1XXX | [Description] |
| Lateral Movement | [Technique] | T1XXX | [Description] |
| Collection | [Technique] | T1XXX | [Description] |
| Exfiltration | [Technique] | T1XXX | [Description] |

### Contributing Factors (5 Whys)

**Problem:** [State the problem in one sentence]

1. **Why?** [First level cause]
   - **Why?** [Second level cause]
     - **Why?** [Third level cause]
       - **Why?** [Fourth level cause]
         - **Why?** [Root cause — systemic/process issue]

**Root cause:** [One sentence summarizing the systemic root cause — usually a process, not a person]

### Detection Gap

**Why wasn't this detected sooner?**

[Was the attacker in the environment before detection? Why? Missing logging? Alert threshold too high? Understaffed SOC? Explain the detection gap.]

- Time attacker was undetected: [X days/hours]
- Missing control that would have detected earlier: [Specific control]
- Closest thing that fired but was ignored or missed: [If applicable]

---

## 5. Response Assessment

### What Worked Well

[Blameless. Give credit where it's due. What response capabilities performed as expected or better?]

- [e.g., "Runbook for credential compromise was followed accurately, reducing response time"]
- [e.g., "Log retention was sufficient (90 days) to reconstruct the full attack timeline"]
- [e.g., "IR team assembled within 15 minutes of detection"]

### What Didn't Work

[Blameless. What gaps were exposed? What slowed the response? Focus on processes and systems.]

- [e.g., "No runbook existed for ransomware — team improvised, adding 2+ hours to response"]
- [e.g., "Network segmentation was insufficient — lateral movement was trivial once inside"]
- [e.g., "EDR was not deployed on the affected server, significantly limiting forensic data"]

### Near Misses

[What almost made this much worse? What prevented it from escalating?]

- [e.g., "Attacker was 3 commands away from reaching the payment card database before isolation"]

---

## 6. Action Items

All items must have an owner and a deadline. No orphan action items.

### Immediate (Within 7 days)

| # | Action | Owner | Deadline | Status |
|---|---|---|---|---|
| 1 | [Specific action] | [Name] | YYYY-MM-DD | Open |

### Short Term (Within 30 days)

| # | Action | Owner | Deadline | Status |
|---|---|---|---|---|
| 1 | [Specific action] | [Name] | YYYY-MM-DD | Open |

### Long Term (Within 90 days)

| # | Action | Owner | Deadline | Status |
|---|---|---|---|---|
| 1 | [Specific action] | [Name] | YYYY-MM-DD | Open |

### Detection Improvements

[Specific new alerts, rules, or monitoring to implement]

- [ ] New SIEM rule: [What should trigger an alert?]
- [ ] EDR coverage: [Systems that need coverage added]
- [ ] Log source: [What logging was missing?]

---

## 7. Lessons Learned

### Technical Lessons

[What technical gaps did this expose?]

### Process Lessons

[What process failures contributed? What process improvements would help?]

### People / Communication Lessons

[Were the right people notified at the right time? Was communication clear?]

### What We'd Do Differently

[If this happened again tomorrow, what would the team do differently from the start?]

---

## 8. Appendix

### A. Indicators of Compromise (IOCs)

| Type | Value | Context | First Seen | Last Seen |
|---|---|---|---|---|
| IP Address | [x.x.x.x] | [C2 / Scanner / Exfil destination] | YYYY-MM-DD | YYYY-MM-DD |
| Domain | [attacker.com] | [C2] | YYYY-MM-DD | YYYY-MM-DD |
| File Hash (SHA256) | [hash] | [Malware dropper] | YYYY-MM-DD | YYYY-MM-DD |
| URL | [https://...] | [Exploit delivery] | YYYY-MM-DD | YYYY-MM-DD |
| User-Agent | [...] | [Attacker tooling] | YYYY-MM-DD | YYYY-MM-DD |

### B. Forensic Artifacts

[Evidence preserved and where it's stored]

| Artifact | Location | Preserved By | Chain of Custody |
|---|---|---|---|
| [Memory dump] | [Path/S3 bucket] | [Name] | [Notes] |

### C. Communications Log

[Record of all external communications: customers, regulators, press]

| Date | Recipient | Channel | Summary |
|---|---|---|---|
| YYYY-MM-DD | [Customer / Regulator / Press] | [Email / Phone / Public] | [What was communicated] |

### D. Evidence References

[Log sources, forensic tool output, screenshots — indexed with findings]

---

*This document is confidential. Handle per data classification policy.*
*Post-mortem findings are protected under attorney-client privilege where applicable — consult legal before sharing externally.*
