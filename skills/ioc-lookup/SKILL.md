---
name: ioc-lookup
description: Enriches an indicator of compromise (IP, domain, URL, file hash, or email). Pulls reputation data, threat intelligence, WHOIS, passive DNS, malware associations, and ATT&CK context. Use during incident response, threat hunting, or alert triage.
argument-hint: "[IP address | domain | URL | MD5/SHA1/SHA256 | email]"
disable-model-invocation: true
---

# IOC Lookup: $ARGUMENTS

Automatically detect the IOC type and run the appropriate enrichment chain.

## Step 1: Identify IOC Type

Determine what type of indicator was provided:
- **IPv4/IPv6 address** → run IP enrichment
- **Domain name** → run domain enrichment
- **URL** → run URL enrichment
- **MD5 (32 hex) / SHA1 (40 hex) / SHA256 (64 hex)** → run file hash enrichment
- **Email address** → run email enrichment

If the type is ambiguous, ask for clarification.

---

## IP Address Enrichment

Run all applicable checks:

### Geolocation & ASN
- Country, city, ASN, ISP, organization
- Is it a datacenter/hosting/VPN/Tor exit node?

### Reputation
- VirusTotal: `get_ip_report` — detection count, community score
- Shodan: `ip_lookup` — open ports, running services, banners, SSL certs, hostnames
- AbuseIPDB category if available

### Threat Intelligence
- AlienVault OTX: pulse hits, threat actor associations
- Is this IP in any known C2 infrastructure databases?
- Recent malicious activity reported?

### Passive DNS
- What domains has this IP hosted? (Shodan reverse DNS)
- How long has it been active?
- Any suspicious hosting patterns?

### ATT&CK Context
If associated with known threat activity, map to ATT&CK:
- Infrastructure technique: T1583 (Acquire Infrastructure), T1584 (Compromise Infrastructure)
- C2 technique if applicable

**Verdict:** [Malicious / Suspicious / Unknown / Benign]
**Confidence:** [High / Medium / Low]
**Recommended action:** [Block / Monitor / No action]

---

## Domain Enrichment

### WHOIS
- Registrar, registration date, expiry, registrant (if not privacy-protected)
- Newly registered? (< 30 days = higher risk)
- Privacy-protected registration?

### DNS Records
- A/AAAA: what IPs does it resolve to?
- MX: mail servers (useful for phishing assessment)
- NS: nameservers
- TXT: SPF, DKIM, DMARC (phishing infrastructure assessment)

### Reputation
- VirusTotal: `get_domain_report` — detection count, categories, SSL cert history
- Shodan: `dns_lookup` — resolution and hosting info

### Threat Intelligence
- OTX: threat actor associations, pulse hits
- Is this a typosquat/lookalike of a legitimate domain?
- DGA (Domain Generation Algorithm) characteristics?
- Sinkholed?

### Certificate Transparency
- Historical SSL certs (org name, SANs, issuer)
- Does the cert cover unexpected domains? (shared hosting / malicious infra)

### ATT&CK Context
- T1566.002 (Spearphishing Link) if phishing
- T1583.001 (Acquire Domains) for C2 infrastructure
- T1071.001 (Web Protocols) for C2 comms

**Verdict:** [Malicious / Suspicious / Unknown / Benign]
**Confidence:** [High / Medium / Low]
**Recommended action:** [Block / Monitor / No action]

---

## URL Enrichment

### Reputation
- VirusTotal: `get_url_report` — scan results from 70+ engines, downloaded files, contacted domains
- Check URL shortener expansion if applicable

### Content Analysis (if safe to access)
- What does the page serve? Phishing kit? Malware dropper? Legitimate?
- Does it redirect? To where?

### Infrastructure
- What IP does the hostname resolve to? (run IP enrichment on result)
- Hosting provider?

### Threat Intelligence
- Known phishing campaign?
- Exploit kit delivery URL?
- Malware C2 endpoint?

**Verdict:** [Malicious / Suspicious / Unknown / Benign]
**Confidence:** [High / Medium / Low]
**Recommended action:** [Block URL / Block domain / Monitor / No action]

---

## File Hash Enrichment

### Basic Info
- Hash format: MD5 / SHA1 / SHA256
- File type (magic bytes if known)
- File size

### Reputation
- VirusTotal: `get_file_report` — detection ratio (X/72 engines), community score, first/last seen
- Family name if detected
- Tags: trojan, ransomware, backdoor, dropper, etc.

### Behavioral Analysis (from VT sandbox)
- Network connections: C2 IPs/domains
- Dropped files
- Registry modifications
- Process injection techniques
- Persistence mechanisms

### Threat Intelligence
- Known malware family?
- APT group attribution?
- Campaign associations?

### ATT&CK Mapping
Map behaviors to ATT&CK techniques. Common patterns:
- T1055 (Process Injection)
- T1059 (Command and Scripting Interpreter)
- T1071 (Application Layer Protocol — C2)
- T1082 (System Information Discovery)
- T1543 (Create or Modify System Process — Persistence)

If MCP YARA tool available: run against known signatures.

**Verdict:** [Malicious — Family name / Suspicious / Unknown / Benign]
**Confidence:** [High / Medium / Low]
**Recommended action:** [Quarantine / Investigate / No action]

---

## Email Address Enrichment

### Breach Data
- Has this email appeared in known breach data? (via public APIs)
- What services were breached?

### Domain Assessment
- Run domain enrichment on the email domain
- Is this a free provider (gmail, proton) or corporate?
- Is the domain newly registered or suspicious?

### Threat Intelligence
- Used in phishing campaigns?
- Social engineering activity?
- Spamhaus / reputation lists?

**Verdict:** [Malicious / Suspicious / Unknown / Benign]
**Confidence:** [High / Medium / Low]

---

## Step 2: Consolidated Report

After all enrichment is complete, output a structured summary:

```
IOC: $ARGUMENTS
Type: [IP / Domain / URL / Hash / Email]
Verdict: [Malicious / Suspicious / Unknown / Benign]
Confidence: [High / Medium / Low]

Key Findings:
- [Most important finding]
- [Second finding]
- [Third finding]

Threat Context:
- Malware family / Actor: [If known]
- ATT&CK techniques: [T-IDs]
- Campaign: [If known]

Sources:
- VirusTotal: [X/Y detections]
- Shodan: [Key finding]
- OTX: [Pulse hits]
- Other: [Any additional sources]

Recommended Actions:
1. [Immediate action]
2. [Follow-up action]
3. [Detection/hunting recommendation]

Related IOCs to investigate:
- [Connected IPs, domains, hashes from the analysis]
```

## Step 3: Detection Recommendations

Based on the findings, suggest at least one hunting/detection rule:

- SIEM query to find other systems that communicated with this IOC
- EDR query for process/network patterns
- DNS query pattern to detect similar domains (DGA, typosquats)
- YARA rule structure if this is a file hash
