---
name: mitre-map
description: Maps a security finding, attack technique, threat actor, or malware family to the MITRE ATT&CK framework. Returns tactic, technique ID, sub-technique, detection opportunities, and data sources. Use when writing reports, building detection rules, or attributing activity.
argument-hint: "[finding description | technique name | actor name | malware name]"
disable-model-invocation: true
---

# MITRE ATT&CK Mapping: $ARGUMENTS

Map the provided input to ATT&CK and provide enrichment for reporting and detection.

## Step 1: Determine What Was Provided

Identify whether the input is:
- A **vulnerability or finding** (e.g., "SQL injection on login form", "RDP exposed to internet")
- A **technique description** (e.g., "attackers used Mimikatz for credential dumping")
- A **threat actor name** (e.g., "APT29", "Lazarus Group", "Scattered Spider")
- A **malware/tool name** (e.g., "Cobalt Strike", "Emotet", "Mimikatz")
- An **ATT&CK ID** (e.g., "T1059", "T1078.003") to look up

If MITRE ATT&CK MCP is available, use it for live queries. Otherwise, use training knowledge.

## Step 2: ATT&CK Mapping

### Tactic
Which of the 14 ATT&CK Enterprise tactics applies?

| Tactic | ID | Description |
|---|---|---|
| Reconnaissance | TA0043 | Gathering info before attack |
| Resource Development | TA0042 | Establishing resources to support operations |
| Initial Access | TA0001 | Getting into the network |
| Execution | TA0002 | Running malicious code |
| Persistence | TA0003 | Maintaining foothold |
| Privilege Escalation | TA0004 | Gaining higher permissions |
| Defense Evasion | TA0005 | Avoiding detection |
| Credential Access | TA0006 | Stealing credentials |
| Discovery | TA0007 | Learning about the environment |
| Lateral Movement | TA0008 | Moving through the network |
| Collection | TA0009 | Gathering data of interest |
| Command and Control | TA0011 | Communicating with compromised systems |
| Exfiltration | TA0010 | Stealing data |
| Impact | TA0040 | Manipulate, interrupt, or destroy systems/data |

### Technique & Sub-technique

**Primary technique:**
- **ID:** T[XXXX]
- **Name:** [Technique name]
- **Tactic:** [Parent tactic]
- **Description:** [What this technique involves]

**Sub-technique (if applicable):**
- **ID:** T[XXXX].[XXX]
- **Name:** [Sub-technique name]
- **Specifics:** [How this specific variant works]

### Procedure (How it was used in this case)
[Describe the specific implementation — what tool, what command, what target, what outcome]

## Step 3: Detection Opportunities

For each mapped technique, provide detection guidance:

### Data Sources Required
What log sources and sensors are needed to detect this?

| Data Source | Component | What to look for |
|---|---|---|
| [Process monitoring] | [Process creation] | [Specific behavior] |
| [Network traffic] | [DNS queries] | [Suspicious patterns] |
| [Windows Event Logs] | [Event ID 4624] | [Anomalous logon] |

### Detection Rule Concepts
Describe what a detection rule should look for — not necessarily in a specific SIEM syntax, but the logic:

**Alert when:**
- [Condition 1]
- [Condition 2]
- AND/OR [Condition 3]

**Filter out (reduce false positives):**
- [Common benign pattern to exclude]

### Visibility Gaps
What would an attacker need to do to evade detection?
- [Evasion method 1]
- [Detection gap]

## Step 4: Mitigation

ATT&CK mitigations for this technique:

| Mitigation ID | Name | How it applies here |
|---|---|---|
| M[XXXX] | [Name] | [Specific application] |

## Step 5: Threat Actor Context (if applicable)

If a threat actor or malware was provided, or if the technique is strongly associated with known actors:

### Known Actors Using This Technique
| Actor | Also known as | Motivation | Notable campaigns |
|---|---|---|---|
| [APT group] | [Aliases] | [Nation-state / Criminal / Hacktivist] | [Campaign name] |

### Malware/Tools Associated
| Tool | Type | How it implements this technique |
|---|---|---|
| [Tool name] | [RAT / Loader / C2] | [Description] |

## Step 6: Report Output

Produce a formatted mapping block ready to paste into a report:

```
ATT&CK Mapping
==============
Tactic:      [Tactic Name] ([TA-ID])
Technique:   [Technique Name] ([T-ID])
Sub-tech:    [Sub-technique Name] ([T-ID.XXX]) ← if applicable
Procedure:   [How it was used in this engagement]

Detection:
  - Data source: [Primary log source]
  - Key indicator: [What to alert on]

Mitigation:
  - [Primary mitigation recommendation]

Reference: https://attack.mitre.org/techniques/T[XXXX]/
```

If multiple techniques apply (e.g., a finding maps to both Initial Access and Execution), produce a block for each.
