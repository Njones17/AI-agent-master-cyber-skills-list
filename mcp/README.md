# MCP Integrations — Master Cybersecurity Skills

MCP (Model Context Protocol) servers give Claude **live tool access** — not just instructions, but actual running tools. Combined with the 741 skills in this package, Claude can perform real security operations end-to-end.

---

## Quick Decision: What to Install First

| Priority | Server | Cost | Use Case |
|---|---|---|---|
| 🔴 Must-have | FuzzingLabs Security Hub | Free | 36 servers, 175+ tools: nmap, nuclei, sqlmap, ffuf, radare2, trivy, gitleaks, bloodhound... |
| 🔴 Must-have | MITRE ATT&CK MCP | Free, no key | TTP queries, threat actor profiles, Navigator layers |
| 🟡 High value | Shodan MCP | Free tier / Paid | IP recon, CVE lookups, internet device search |
| 🟡 High value | VirusTotal MCP | Free API key | Malware/IOC analysis, URL/file/hash/domain reports |
| 🟢 Nice to have | Maigret MCP | Free | OSINT — username search across 2500+ sites |
| 🟢 Nice to have | AlienVault OTX MCP | Free API key | Threat intelligence feeds, IOC enrichment |

---

## Tier 1: FuzzingLabs Security Hub (Install This First)

**36 MCP servers, 175+ security tools, Docker-based, production-hardened.**

This is the foundation. One repo gives you:

### Reconnaissance
| Server | Tools | What it does |
|---|---|---|
| `nmap-mcp` | 8 | Port scanning, service detection, OS fingerprinting, NSE scripts |
| `masscan-mcp` | 6 | High-speed scanning for large networks |
| `whatweb-mcp` | 5 | Web tech fingerprinting, CMS detection |
| `shodan-mcp` | — | Wrapper → BurtTheCoder/mcp-shodan |
| `pd-tools-mcp` | — | ProjectDiscovery: subfinder, httpx, katana |
| `networksdb-mcp` | 4 | IP/ASN/DNS lookups |
| `externalattacker-mcp` | 6 | Attack surface mapping |

### Web Security
| Server | Tools | What it does |
|---|---|---|
| `nuclei-mcp` | 7 | Template-based vuln scanning (8000+ templates) |
| `sqlmap-mcp` | 8 | SQL injection detection and exploitation |
| `ffuf-mcp` | 9 | Web fuzzing: directories, files, params, vhosts |
| `nikto-mcp` | — | Web server scanning |
| `burp-mcp` | — | Wrapper → PortSwigger official Burp MCP |
| `waybackurls-mcp` | 3 | Historical URL recon via Wayback Machine |

### Binary Analysis / Reverse Engineering
| Server | Tools | What it does |
|---|---|---|
| `radare2-mcp` | 32 | Disassembly, decompilation, binary analysis |
| `ghidra-mcp` | — | Headless Ghidra AI-powered RE |
| `ida-mcp` | — | IDA Pro integration |
| `binwalk-mcp` | 6 | Firmware analysis, extraction |
| `yara-mcp` | 7 | Malware pattern matching |
| `capa-mcp` | 5 | Capability detection in executables |

### Cloud Security
| Server | Tools | What it does |
|---|---|---|
| `trivy-mcp` | 7 | Container, filesystem, IaC vuln scanning |
| `prowler-mcp` | 6 | AWS/Azure/GCP security auditing and compliance |
| `roadrecon-mcp` | 6 | Azure AD enumeration |

### Threat Intelligence
| Server | Tools | What it does |
|---|---|---|
| `virustotal-mcp` | — | Wrapper → BurtTheCoder/mcp-virustotal |
| `otx-mcp` | — | AlienVault Open Threat Exchange |

### Other
| Server | Tools | What it does |
|---|---|---|
| `gitleaks-mcp` | 5 | Secrets/credentials in git repos |
| `semgrep-mcp` | 7 | Static code analysis (5000+ rules) |
| `searchsploit-mcp` | 5 | ExploitDB search and retrieval |
| `bloodhound-mcp` | 75+ | Active Directory attack path analysis |
| `hashcat-mcp` | — | Natural language hash cracking |
| `maigret-mcp` | — | OSINT username search |
| `dnstwist-mcp` | — | Typosquatting/phishing detection |
| `boofuzz-mcp` | 4 | Network protocol fuzzing |

### Install

```bash
git clone https://github.com/FuzzingLabs/mcp-security-hub
cd mcp-security-hub
docker-compose build        # builds all images (takes a while first time)
docker-compose up nmap-mcp nuclei-mcp gitleaks-mcp -d   # start the ones you want
```

**Requirements:** Docker Desktop (Mac/Windows) or Docker Engine (Linux)

Use the ready-made config: [`configs/claude-code-fuzzinglabs.json`](configs/claude-code-fuzzinglabs.json)

---

## Tier 2: MITRE ATT&CK MCP

**50+ tools. No API key. Works offline after initial data download.**

Lets Claude query:
- Techniques, tactics, sub-techniques
- Threat actor → technique mappings
- Malware → technique mappings
- Generate ATT&CK Navigator layers
- Find technique overlaps between groups

### Install

```bash
pipx install git+https://github.com/stoyky/mitre-attack-mcp
```

Claude Code one-liner:
```bash
claude mcp add mitre-attack -- mitre-attack-mcp
```

---

## Tier 3: BurtTheCoder Suite (API Keys Required)

Three standalone servers, easy to install via npm.

### Shodan MCP

Needs a [Shodan API key](https://account.shodan.io/) (free tier available, paid for full features).

Tools: `ip_lookup`, `shodan_search`, `cve_lookup`, `dns_lookup`, `reverse_dns_lookup`, `cpe_lookup`, `cves_by_product`

```bash
claude mcp add --transport stdio --env SHODAN_API_KEY=your-key shodan -- npx -y @burtthecoder/mcp-shodan
```

### VirusTotal MCP

Needs a [VirusTotal API key](https://www.virustotal.com/gui/my-apikey) (free).

Tools: `get_url_report`, `get_file_report`, `get_ip_report`, `get_domain_report` + relationship queries for each

```bash
claude mcp add --transport stdio --env VIRUSTOTAL_API_KEY=your-key virustotal -- npx -y @burtthecoder/mcp-virustotal
```

### Maigret MCP (OSINT)

Requires Docker. No API key needed.

```bash
npm install -g mcp-maigret
mkdir -p ~/maigret-reports
claude mcp add --env MAIGRET_REPORTS_DIR=~/maigret-reports maigret -- mcp-maigret
```

---

## All-in-One Config Files

Pre-built configs are in [`configs/`](configs/):

| File | What it configures |
|---|---|
| `claude-code-minimal.json` | MITRE ATT&CK only (no Docker, no API keys) |
| `claude-code-fuzzinglabs.json` | Full FuzzingLabs hub (requires Docker) |
| `claude-code-full.json` | Everything: FuzzingLabs + BurtTheCoder + MITRE |
| `claude-desktop-full.json` | Same as full, Desktop format |

---

## Using MCP Tools with the Skills in This Package

When an MCP server is active, Claude can use it **alongside** a skill. Example:

> "Perform a web application pentest on target.example.com"

Claude will:
1. Load `webapp-pentesting` skill (methodology guide)
2. Use `nmap-mcp` to enumerate services
3. Use `nuclei-mcp` to scan for known vulns
4. Use `ffuf-mcp` to fuzz directories
5. Use `sqlmap-mcp` to test injection points
6. Report findings using the template in `CLAUDE.md`

The skill provides the *methodology*. The MCP gives the *tools*. Together they're more powerful than either alone.

---

## Security Notes

- All FuzzingLabs containers run as non-root with dropped capabilities
- Never point scanning tools at targets you don't own/have written authorization for
- Some tools (sqlmap, hashcat, searchsploit) should only be used in authorized engagements
- API keys: store in env vars, never hardcode in config files committed to git
