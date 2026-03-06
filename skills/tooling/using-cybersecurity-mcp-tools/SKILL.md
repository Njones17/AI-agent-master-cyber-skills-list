---
name: using-cybersecurity-mcp-tools
description: Guides Claude on how to discover, select, and effectively use cybersecurity MCP tools (nmap, nuclei, shodan, virustotal, radare2, bloodhound, trivy, sqlmap, ffuf, MITRE ATT&CK, and more) alongside the skills in this package. Use when performing security assessments, threat intelligence, or any task that benefits from live tool access.
---

# Using Cybersecurity MCP Tools

This skill helps you effectively combine MCP tools with the methodology skills in this package.

## Discovering Available Tools

Before starting any security task, check which MCP tools you have access to. You can list them or attempt to call them. The key tools and what they unlock:

| If you have... | You can... |
|---|---|
| `nmap` | Real port scans, service detection, OS fingerprinting |
| `nuclei` | Automated vuln scanning against 8000+ templates |
| `sqlmap` | Actual SQLi testing and exploitation |
| `ffuf` | Real directory/parameter fuzzing |
| `shodan` | IP recon, internet device search, CVE lookups by product |
| `virustotal` | Hash/URL/IP/domain reputation, malware analysis |
| `mitre-attack` | TTP queries, threat actor profiles, Navigator layers |
| `radare2` | Binary disassembly, decompilation, analysis |
| `yara` | Malware pattern matching on samples |
| `capa` | Capability detection in executables |
| `binwalk` | Firmware extraction and analysis |
| `trivy` | Container and IaC vulnerability scanning |
| `prowler` | AWS/Azure/GCP compliance auditing |
| `gitleaks` | Secret scanning in repos |
| `semgrep` | Static code analysis |
| `bloodhound` | Active Directory attack path analysis |
| `searchsploit` | Exploit-DB queries |
| `maigret` | OSINT username searches across 2500+ sites |

## Tool Selection by Task

### Recon Phase
1. `shodan` → passive IP intel before touching the target
2. `nmap` → active port/service enumeration
3. `masscan` → fast scan for large IP ranges
4. `whatweb` → web tech fingerprinting
5. `waybackurls` → historical URL discovery

### Vuln Identification Phase
1. `nuclei` → broad template-based scanning (run first for quick wins)
2. `ffuf` → directory/endpoint discovery
3. `nikto` → web server misconfiguration checks
4. `semgrep` or `gitleaks` → if source code is in scope

### Exploitation Phase
1. `sqlmap` → after manually confirming injection point exists
2. `searchsploit` → find public exploits for identified versions
3. `ffuf` → parameter fuzzing for logic/auth flaws

### Post-Exploitation / AD
1. `bloodhound` → map AD attack paths after getting initial access
2. `roadrecon` → Azure AD enumeration

### Threat Intelligence
1. `virustotal` → IOC lookup (hashes, IPs, domains, URLs)
2. `shodan` → CVE lookups by product (`cves_by_product`)
3. `mitre-attack` → map findings to ATT&CK techniques
4. `otx` → AlienVault OTX for threat feeds

### Malware Analysis
1. `yara` → pattern matching against known signatures
2. `capa` → identify capabilities (network comms, persistence, evasion)
3. `radare2` → deep binary analysis, disassembly
4. `ghidra` → decompilation for complex samples
5. `binwalk` → firmware or packed files

### Cloud Security
1. `trivy` → scan container images and IaC templates
2. `prowler` → AWS/Azure/GCP compliance checks

### Code Security
1. `semgrep` → SAST with 5000+ security rules
2. `gitleaks` → credentials and secrets in repos

## Combining Tools with Skills

Skills provide methodology; MCP tools provide execution. Always load the relevant skill first, then use MCP tools to execute the workflow:

**Example: Web Application Pentest**
1. Load skill: `webapp-pentesting` (or `api-pentesting` for APIs)
2. Recon: `shodan` → passive intel on target
3. Enum: `nmap` → port/service scan
4. Discovery: `ffuf` → directory fuzzing
5. Vuln scan: `nuclei` → template scan
6. Manual testing: per skill methodology
7. Map findings: `mitre-attack` → tag with ATT&CK techniques

**Example: Threat Intel Investigation**
1. Load skill: `performing-threat-intelligence-analysis` (or similar)
2. IOC enrichment: `virustotal` → hash/domain/IP reputation
3. Attribution: `mitre-attack` → technique → actor mapping
4. Context: `shodan` → infrastructure intel on attacker IPs

**Example: Malware Sample Analysis**
1. Load skill: `analyzing-malware-with-dynamic-analysis` or `reverse-engineering-*`
2. Initial triage: `yara` → known family match
3. Capability check: `capa` → what does it do?
4. Deep analysis: `radare2` or `ghidra` → disassemble/decompile
5. Network IOCs: `virustotal` → check C2 domains/IPs

## Tool Usage Guidelines

**Always verify authorization before active scanning.** Tools like `nmap`, `nuclei`, and `sqlmap` actively probe targets and may trigger alerts or cause disruption.

**Start passive, go active:**
- Passive first: `shodan`, `waybackurls`, `virustotal`, `mitre-attack`
- Active second: `nmap`, `nuclei`, `ffuf`, `sqlmap`

**Confirm before exploiting:**
- Never run `sqlmap` with `--level 5` or `--risk 3` without understanding the target
- Never use `hashcat` on hashes you didn't capture in the engagement

**Tool output is raw data — analyze it:**
- A nuclei scan returning 50 findings is not a report. Triage each one.
- A bloodhound graph is not an attack path. Analyze what's actually exploitable.
- A shodan result is not confirmed vulnerable. Verify with targeted testing.

## When MCP Tools Are Unavailable

If an MCP tool isn't available, Claude should:
1. Provide the exact CLI command the human can run manually
2. Explain what to do with the output
3. Ask for the output to be pasted back for analysis

Example: "I don't have nmap access, but run this: `nmap -sV -sC -p- --min-rate 5000 <target>` and paste the output."

## MITRE ATT&CK Mapping

Always map significant findings to ATT&CK. Use `mitre-attack` tools to:
- `get_technique` → look up technique details by ID (e.g., T1059.001)
- `get_techniques_by_tactic` → find all techniques for a tactic
- `get_group` → threat actor profile
- `get_software` → malware/tool profiles
- `generate_navigator_layer` → visual heat map for reports

Include ATT&CK IDs in all findings: `T1190 - Exploit Public-Facing Application`, `T1078 - Valid Accounts`, etc.
