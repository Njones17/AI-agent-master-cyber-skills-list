---
name: recon-and-enumeration
description: "Use when starting a new engagement, scoping a target, gathering intelligence before exploitation, discovering attack surface, enumerating services and technologies, performing subdomain discovery, identifying entry points, or when the user asks to scan, enumerate, fingerprint, or map a target network or application."
---

## Required Tools

> **STEALTH CONFIGURATION:** To avoid WAF/blocking, source stealth profile before testing:
> `bash $SUPERHACKERS_ROOT/scripts/stealth-profile.sh && eval "$(stealth_curl_headers)"`
> See `skills/stealth-techniques/SKILL.md` for comprehensive stealth methodology.
> **Run `bash $SUPERHACKERS_ROOT/scripts/detect-tools.sh` for tool availability, or read `$SUPERHACKERS_ROOT/TOOLCHAIN.md` for the full resolution protocol.** If a tool is missing, check the fallback chain.

| Tool | Required | Fallback | Install |
|------|----------|----------|---------|
| rustscan | ✅ Yes | nmap → masscan → nc -zv | `cargo install rustscan` / `brew install rustscan` |
| nmap | ✅ Yes | masscan → nc -zv | `brew install nmap` / `apt install nmap` |
| ffuf | ✅ Yes | gobuster → dirb → curl loop | `go install github.com/ffuf/ffuf/v2@latest` |
| nuclei | ✅ Yes | nikto → manual curl | `go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest` |
| httpx | ✅ Yes | curl -s -o /dev/null -w "%{http_code}" | `go install github.com/projectdiscovery/httpx/cmd/httpx@latest` |
| curl | ✅ Yes | wget → python3 requests | Usually pre-installed |
| dig | ✅ Yes | nslookup → host → python dnspython | `brew install bind` / `apt install dnsutils` |
| whois | ✅ Yes | curl whois API | `brew install whois` / `apt install whois` |
| jq | ✅ Yes | python3 -m json.tool | `brew install jq` / `apt install jq` |
| smbclient | ⚡ Optional | nmap smb-enum scripts | `apt install smbclient` |
| ldapsearch | ⚡ Optional | nmap ldap scripts | `apt install ldap-utils` |
| snmpwalk | ⚡ Optional | nmap snmp scripts | `apt install snmp` |

> **Before running any commands in this skill:**
> 1. Run `bash $SUPERHACKERS_ROOT/scripts/detect-tools.sh` if not already run this session
> 2. For any ❌ missing tool, use the fallback from the chain above

## Tool Execution Protocol

> **CRITICAL: If SUPERHACKERS_ROOT is not set, auto-detect it first**

```bash
# Auto-detect SUPERHACKERS_ROOT if not set
if [ -z "${SUPERHACKERS_ROOT:-}" ]; then
  # Try common plugin cache paths
  for path in \
    "$HOME/.claude/plugins/cache/superhackers/superhackers/1.2.* \
    "$HOME/.claude/plugins/cache/superhackers/superhackers/"* \
    "$HOME/superhackers" \
    "$(pwd)/superhackers"; do
    if [ -d "$path" ] && [ -f "$path/scripts/detect-tools.sh" ]; then
      export SUPERHACKERS_ROOT="$path"
      echo "Auto-detected SUPERHACKERS_ROOT=$SUPERHACKERS_ROOT"
      break
    fi
  done
fi

# Verify detection worked
if [ -z "${SUPERHACKERS_ROOT:-}" ] || [ ! -f "$SUPERHACKERS_ROOT/scripts/detect-tools.sh" ]; then
  echo "ERROR: SUPERHACKERS_ROOT not set and auto-detection failed"
  echo "Please set: export SUPERHACKERS_ROOT=/path/to/superhackers"
  return 1
fi
```

**MANDATORY**: All reconnaissance commands MUST follow this protocol:

1. **Timeout on network operations**: DNS queries and HTTP requests can hang
   ```bash
   # DNS enumeration with timeout (30 seconds)
   bash $SUPERHACKERS_ROOT/scripts/timeout-helper.sh 30 dig +short target.com ANY

   # Port discovery with rustscan (60 seconds total)
   bash $SUPERHACKERS_ROOT/scripts/timeout-helper.sh 60 rustscan -a target --ulimit 5000

   # HTTP probing with timeout (15 seconds per request)
   bash $SUPERHACKERS_ROOT/scripts/timeout-helper.sh 15 curl -s -I https://target.com
   ```

2. **Validate tool output before proceeding**
   ```bash
   OUTPUT=$(bash $SUPERHACKERS_ROOT/scripts/timeout-helper.sh 30 rustscan -a target 2>&1)
   EXIT_CODE=$?

   if [ $EXIT_CODE -eq 124 ]; then
     echo "TOOL_FAILURE: rustscan timeout after 30 seconds"
     echo "FALLBACK: Using nmap with reduced port range"
     bash $SUPERHACKERS_ROOT/scripts/timeout-helper.sh 60 nmap -sS --top-ports 1000 target
   elif [ $EXIT_CODE -ne 0 ]; then
     echo "TOOL_FAILURE: rustscan failed with exit code $EXIT_CODE"
     echo "FALLBACK: Using nmap directly"
     bash $SUPERHACKERS_ROOT/scripts/timeout-helper.sh 90 nmap -sS -p- target
   fi

   # Parse open ports
   OPEN_PORTS=$(echo "$OUTPUT" | rg -o "\d{1,5}/open" | rg -o "^\d+" | tr '\n' ',' | sed 's/,$//')
   if [ -n "$OPEN_PORTS" ]; then
     echo "Open ports: $OPEN_PORTS"
   else
     echo "INFO: No open ports found or scan failed"
   fi
   ```

3. **Fallback for subdomain enumeration**
   ```bash
   # Primary: httpx for HTTP probing
   bash $SUPERHACKERS_ROOT/scripts/timeout-helper.sh 15 httpx -u target.com -silent 2>/dev/null
   if [ $? -ne 0 ]; then
     echo "FALLBACK: httpx failed, using curl"
     bash $SUPERHACKERS_ROOT/scripts/timeout-helper.sh 10 curl -s -o /dev/null -w "%{http_code}" https://target.com
     if [ $? -ne 0 ]; then
       echo "FALLBACK: Target unreachable or blocking probes"
     fi
   fi
   ```

4. **DNS resolution fallback**
   ```bash
   # Primary: dig
   if ! command -v dig >/dev/null 2>&1; then
     echo "FALLBACK: dig not found, using nslookup"
     bash $SUPERHACKERS_ROOT/scripts/timeout-helper.sh 10 nslookup target.com
     if [ $? -ne 0 ]; then
       echo "FALLBACK: nslookup failed, using host"
       bash $SUPERHACKERS_ROOT/scripts/timeout-helper.sh 10 host target.com
     fi
   fi
   ```

5. **Subdomain discovery with validation**
   ```bash
   # When running subdomain enumeration, validate results
   bash $SUPERHACKERS_ROOT/scripts/timeout-helper.sh 60 ffuf -u https://target.com -w wordlist.txt 2>/dev/null
   if [ $? -ne 0 ]; then
     echo "FALLBACK: ffuf failed, trying gobuster"
     bash $SUPERHACKERS_ROOT/scripts/timeout-helper.sh 60 gobuster dns -d target.com -w wordlist.txt
   fi
   ```

## Overview

**Role: Attack Surface Cartographer** — Your job is to map every reachable endpoint, technology, and entry point. Stay in your lane: you enumerate and discover, you do NOT test for vulnerabilities or attempt exploitation.

Reconnaissance and enumeration is the foundation of every penetration test. This skill covers the full pipeline from passive intelligence gathering through active scanning to service enumeration. Every subsequent phase depends on the quality of recon — missed services mean missed vulnerabilities.

The methodology flows: **Passive OSINT → DNS & Subdomain Enum → Active Port Scanning → Service Fingerprinting → Web Enumeration → Network Service Enumeration**.

## Pipeline Position

> **Position:** Phase 2 (Reconnaissance) — after `security-assessment` planning, before all testing skills
> **Expected Input:** Scope definition and target URLs/IPs from the user or `security-assessment`
> **Your Output:** Endpoint inventory, technology stack, authentication mechanisms, attack surface map
> **Consumed By:** All testing skills (`webapp-pentesting`, `api-pentesting`, `infra-pentesting`, `android-pentesting`, `secure-code-review`)
> **Critical:** Every endpoint you miss is an endpoint that will NEVER be tested. Every technology you fail to identify is a technology-specific skill that will NEVER be loaded.

## Downstream Impact Warning

> Your output is the SOLE input for all testing phases that follow.
> Every endpoint you miss is an endpoint that will NEVER be tested.
> Every technology you fail to identify is a technology-specific skill that will NEVER be loaded.
> Incomplete recon creates blind spots that persist through the entire engagement.
> You are the foundation — if you are lazy, every subsequent skill suffers.

Never skip passive recon. Never jump straight to exploitation.

## When to Use

- Starting a new penetration test or red team engagement
- User provides a target domain, IP, or IP range
- Need to discover all subdomains for a given domain
- Need to identify running services and their versions
- Need to map web application attack surface
- Need to enumerate network services (SMB, SNMP, LDAP, NFS)
- Need to find exposed sensitive files, directories, or admin panels
- User asks to "scan", "enumerate", "discover", "fingerprint", or "map" a target

## Core Pattern

```
1. PASSIVE RECON
   ├── OSINT & Google Dorking
   ├── WHOIS & DNS Records
   ├── Certificate Transparency Logs
   ├── Wayback Machine & Cached Content
   ├── Shodan/Censys Queries
   ├── Social Media & Leaked Credentials
   └── Collect all domains, IPs, emails, tech stack hints

2. DNS & SUBDOMAIN ENUMERATION
   ├── DNS Record Extraction (A, AAAA, MX, TXT, NS, SOA, SRV, CNAME)
   ├── Zone Transfer Attempts
   ├── Subdomain Brute-forcing (ffuf vhost mode)
   ├── Certificate Transparency Mining
   └── Consolidate unique hostnames → resolve to IPs

3. ACTIVE SCANNING
   ├── Host Discovery (nmap -sn / rustscan ping sweep)
   ├── Fast Port Discovery (rustscan — all 65535 ports in seconds)
   ├── Service Version Detection (nmap -sV on confirmed open ports only)
   ├── OS Detection (nmap -O on confirmed open ports only)
   ├── NSE Script Scanning (nmap -sC on confirmed open ports only)
   └── httpx probing for web services

4. WEB ENUMERATION
   ├── Technology Fingerprinting (httpx, nuclei tech-detect)
   ├── Directory/File Discovery (ffuf)
   ├── Sensitive File Checks (robots.txt, sitemap.xml, .git, backups)
   ├── API Endpoint Discovery
   ├── Parameter Fuzzing
   └── Admin Panel Discovery

5. NETWORK SERVICE ENUMERATION
   ├── SMB Share Enumeration
   ├── SNMP Community String Brute-force
   ├── LDAP Anonymous Bind Queries
   ├── NFS Export Listing
   └── Service-specific NSE scripts

6. TECHNOLOGY STACK DETECTION
   ├── Framework Detection (Next.js, FastAPI, Django, Rails)
   ├── Technology Detection (Supabase, Firebase, AWS)
   ├── Protocol Detection (GraphQL, gRPC, WebSocket)
   └── Map detected stack → supplementary security skills

7. CONSOLIDATE → Feed into vulnerability-verification
```

### Execution Discipline

- **Persist**: Continue working through ALL steps of the Core Pattern until completion criteria are met. Do NOT stop after a single tool run or partial result.
- **Scope**: Work ONLY within this skill's methodology. Do NOT jump to another phase (e.g., don't start writing the report while still testing).
- **Negative Results**: If thorough testing reveals no vulnerabilities, that IS a valid result. Document what was tested and report "no findings" — do NOT invent issues.
- **Retry Limit**: Max 3 attempts per test. If blocked, classify the failure and proceed.

## Quick Reference

### Passive Recon Commands

```bash
# WHOIS lookup
whois target.com

# DNS record extraction — all types
dig target.com ANY +noall +answer
dig target.com A +short
dig target.com AAAA +short
dig target.com MX +short
dig target.com TXT +short
dig target.com NS +short
dig target.com SOA +short
dig target.com SRV +short
dig target.com CNAME +short

# Reverse DNS
dig -x 192.168.1.1 +short

# Certificate Transparency Logs (passive subdomain discovery)
curl -s "https://crt.sh/?q=%.target.com&output=json" | jq -r '.[].name_value' | sort -u

# Wayback Machine — discover historical URLs and endpoints
curl -s "https://web.archive.org/cdx/search/cdx?url=*.target.com/*&output=json&fl=original&collapse=urlkey" | jq -r '.[][]' | sort -u

# Shodan CLI queries (if API key configured)
shodan search "hostname:target.com"
shodan host 1.2.3.4

# Censys search
censys search "services.tls.certificates.leaf.names: target.com"
```

### Google Dorking Examples

```
# Find exposed sensitive files
site:target.com filetype:pdf | filetype:xlsx | filetype:docx
site:target.com filetype:sql | filetype:bak | filetype:log
site:target.com filetype:env | filetype:cfg | filetype:conf

# Find login pages and admin panels
site:target.com inurl:admin | inurl:login | inurl:dashboard
site:target.com intitle:"admin" | intitle:"login" | intitle:"dashboard"

# Find exposed directories and listings
site:target.com intitle:"index of" | intitle:"directory listing"

# Find error messages leaking info
site:target.com "mysql error" | "sql syntax" | "warning: mysql"
site:target.com "Fatal error" | "Stack trace" | "Exception"

# Find exposed API docs
site:target.com inurl:swagger | inurl:api-docs | inurl:graphql

# Find exposed config files
site:target.com ext:xml | ext:json inurl:config
site:target.com "DB_PASSWORD" | "API_KEY" | "SECRET_KEY"

# Find subdomains indexed by Google
site:*.target.com -www

# Find exposed git repos
site:target.com inurl:.git
```

### Leaked Credentials / Breach Data

```bash
# Check Have I Been Pwned (API)
curl -s -H "hibp-api-key: YOUR_KEY" \
  "https://haveibeenpwned.com/api/v3/breachedaccount/user@target.com"

# Check dehashed (API)
curl -s -u email:api_key \
  "https://api.dehashed.com/search?query=domain:target.com"

# Search for credentials in public paste sites
# Manual: check pastebin, ghostbin, rentry for target.com references
```

### Active Scanning — rustscan + nmap (Two-Phase Pattern)

> **REQUIRED TWO-PHASE PATTERN**: Always use rustscan for fast port discovery, then feed confirmed open ports to nmap for service/version/script detection. Never run nmap full-range scans directly — rustscan completes in seconds what nmap takes minutes to do, eliminating scan timeout failures.

```bash
# ─── PHASE A: Fast port discovery with rustscan ───────────────────────────────

# Full TCP port discovery — all 65535 ports, seconds not minutes
rustscan -a TARGET --ulimit 5000 -b 1000 -- --open -oG recon/rustscan_ports.gnmap

# Multiple targets
rustscan -a 192.168.1.0/24 --ulimit 5000 -b 500 -- --open -oG recon/rustscan_subnet.gnmap

# Extract open port list for nmap phase
OPEN_PORTS=$(rg -o '[0-9]+/open' recon/rustscan_ports.gnmap | cut -d/ -f1 | sort -n | paste -sd',')
echo "Open ports: $OPEN_PORTS"

# ─── PHASE B: nmap service/version/script scan on confirmed open ports only ───

# Service version detection — targeted to confirmed open ports
nmap -sV -sC -p "$OPEN_PORTS" TARGET -oA recon/service_scan

# OS detection on confirmed open ports
nmap -O -p "$OPEN_PORTS" TARGET -oA recon/os_detect

# Aggressive scan (combines -sV -sC -O -traceroute) — confirmed ports only
nmap -A -p "$OPEN_PORTS" TARGET -oA recon/aggressive_scan

# ─── SUPPLEMENTAL: nmap for UDP and service-specific scripts ──────────────────

# Top UDP ports (nmap only — rustscan does not support UDP)
nmap -sU --top-ports 50 TARGET -oA recon/udp_scan

# Specific service NSE scripts (run only when port confirmed open by rustscan)
nmap --script=http-enum,http-title,http-headers -p 80,443 TARGET
nmap --script=smb-enum-shares,smb-enum-users -p 445 TARGET
nmap --script=snmp-brute,snmp-info -p 161 TARGET -sU
nmap --script=ldap-rootdse,ldap-search -p 389 TARGET
nmap --script=nfs-showmount,nfs-ls -p 2049 TARGET
nmap --script=dns-zone-transfer -p 53 TARGET --script-args dns-zone-transfer.domain=target.com

# Vulnerability NSE scan — confirmed ports only
nmap --script=vuln -p "$OPEN_PORTS" TARGET -oA recon/vuln_nse_scan

# ─── FALLBACK: If rustscan unavailable, use nmap with timeout ─────────────────
# nmap -p- -T4 --min-rate=2000 TARGET -oA recon/full_tcp
# (rustscan preferred — less likely to timeout on engagements)
```

### Web Probing — httpx

```bash
# Probe list of hosts for web services
cat hosts.txt | httpx -silent -status-code -title -tech-detect -o web_hosts.txt

# Full web probe with all metadata
cat subdomains.txt | httpx -ports 80,443,8080,8443,8000,3000,9090 \
  -status-code -title -tech-detect -content-length -web-server \
  -cdn -follow-redirects -o httpx_full.txt

# Screenshot all web services
cat hosts.txt | httpx -screenshot -screenshot-timeout 10 -o screenshots/

# Extract specific response data
cat hosts.txt | httpx -silent -json | jq '{url: .url, status: .status_code, title: .title, tech: .tech}'

# Filter by status code
cat hosts.txt | httpx -silent -mc 200,301,302,403 -o live_hosts.txt

# Content-type and content-length filtering
cat hosts.txt | httpx -silent -ct -cl -o content_info.txt
```

### Directory & File Discovery — ffuf

```bash
# Basic directory brute-force
ffuf -u https://target.com/FUZZ -w /usr/share/wordlists/dirb/common.txt \
  -mc 200,204,301,302,307,401,403 -o dirs.json

# Recursive directory discovery
ffuf -u https://target.com/FUZZ -w /usr/share/wordlists/dirb/common.txt \
  -recursion -recursion-depth 3 -mc 200,301,302 -o recursive.json

# File extension fuzzing
ffuf -u https://target.com/FUZZ -w /usr/share/wordlists/dirb/common.txt \
  -e .php,.asp,.aspx,.jsp,.html,.js,.json,.xml,.txt,.bak,.old,.sql,.zip,.tar.gz,.config \
  -mc 200,204,301,302,403 -o files.json

# Virtual host discovery
ffuf -u https://target.com -H "Host: FUZZ.target.com" \
  -w /usr/share/wordlists/subdomains.txt \
  -fs 0 -mc 200,301,302 -o vhosts.json

# Parameter fuzzing — GET
ffuf -u "https://target.com/page?FUZZ=test" \
  -w /usr/share/wordlists/params.txt \
  -mc 200 -fw 100 -o params_get.json

# Parameter fuzzing — POST
ffuf -u "https://target.com/api/endpoint" \
  -X POST -d '{"FUZZ":"test"}' -H "Content-Type: application/json" \
  -w /usr/share/wordlists/params.txt \
  -mc 200 -o params_post.json

# Content-type fuzzing
ffuf -u https://target.com/api/upload \
  -X POST -H "Content-Type: FUZZ" \
  -w /usr/share/wordlists/content-types.txt \
  -d 'test' -mc 200 -o content_types.json

# Filter by response size (remove false positives)
ffuf -u https://target.com/FUZZ -w wordlist.txt \
  -mc all -fs 4242 -o filtered.json

# Rate-limited fuzzing
ffuf -u https://target.com/FUZZ -w wordlist.txt \
  -rate 50 -mc 200,301,302 -o rate_limited.json
```

### Nuclei — Technology & Vulnerability Scanning

```bash
# Technology detection
nuclei -u https://target.com -tags tech -o tech_detect.txt

# Full vulnerability scan with severity filter
nuclei -u https://target.com -severity critical,high -o critical_vulns.txt

# Scan multiple targets
nuclei -l urls.txt -severity critical,high,medium -o vulns.txt

# Tag-based scanning
nuclei -u https://target.com -tags cve,misconfig,exposure -o tagged.txt

# Specific template categories
nuclei -u https://target.com -t exposures/ -o exposures.txt
nuclei -u https://target.com -t misconfiguration/ -o misconfigs.txt
nuclei -u https://target.com -t vulnerabilities/ -o vulns.txt

# Rate-limited scanning
nuclei -u https://target.com -rl 50 -bulk-size 10 -c 5 -o rate_limited.txt

# Custom template
nuclei -u https://target.com -t /path/to/custom-template.yaml -o custom.txt

# JSON output for parsing
nuclei -u https://target.com -severity critical,high -json -o vulns.json

# Scan with proxy (BurpSuite)
nuclei -u https://target.com -proxy http://127.0.0.1:8080 -o proxied.txt
```

## Implementation

### Enumeration Economy

Reconnaissance has diminishing returns. Apply these constraints:

1. **Sufficiency Check**: After each enumeration phase, ask: "Do I have enough targets to begin testing?"
   - If you have 5+ unique endpoints/services — sufficient for initial testing
   - If you have valid credentials or auth tokens — move to auth testing

2. **Tool Limits Per Phase**:
   - Subdomain enumeration: Max 2 tools (e.g., subfinder + amass), cross-reference
   - Port scanning: 1 quick scan (top 1000) + 1 full scan (background)
   - Directory bruteforcing: 1 tool, 1 wordlist, then targeted based on findings
   - Technology detection: 1 tool (httpx/wappalyzer) is usually sufficient

3. **Stop Conditions**:
   - Same results from 2+ tools — move on
   - Phase taking more than 30% of total engagement time — move on
   - No new findings after 2 consecutive tool runs — move on

4. **Priority Order**: Focus on scope-critical targets first, expand breadth only if time permits

### Phase 1: Passive Reconnaissance

Collect intelligence without touching the target directly. This generates zero logs on the target.

```bash
# Step 1: WHOIS and registration data
whois target.com | tee recon/whois.txt

# Step 2: DNS records — comprehensive extraction
for type in A AAAA MX TXT NS SOA SRV CNAME; do
  echo "=== $type ===" >> recon/dns_records.txt
  dig target.com $type +noall +answer >> recon/dns_records.txt
done

# Step 3: Certificate Transparency — subdomain discovery
mkdir -p recon
curl -s "https://crt.sh/?q=%.target.com&output=json" | \
  jq -r '.[].name_value' 2>/dev/null | sed 's/\*\.//g' | sort -u > recon/ct_subdomains.txt || touch recon/ct_subdomains.txt

# Step 4: Wayback Machine — historical URL discovery
curl -s "https://web.archive.org/cdx/search/cdx?url=*.target.com/*&output=json&fl=original&collapse=urlkey" | \
  jq -r '.[][]' | sort -u > recon/wayback_urls.txt

# Step 5: Extract interesting paths from Wayback data
cat recon/wayback_urls.txt | rg -i '\.(php|asp|aspx|jsp|json|xml|conf|env|bak|sql|zip|tar|gz|log)' | \
  sort -u > recon/interesting_urls.txt

# Step 6: Google dorking — run these manually in browser or via API
# Record findings in recon/google_dorks_results.txt
```

**Key passive OSINT data to collect:**
- Organization name, address, phone, email from WHOIS
- Nameservers — may reveal hosting provider, shared infrastructure
- MX records — email provider (Google Workspace, O365, self-hosted)
- TXT records — SPF, DKIM, DMARC (email security posture), verification tokens
- ASN and IP ranges owned by the target
- Employee names, roles, emails from LinkedIn
- Technology stack hints from job postings

### Phase 2: DNS & Subdomain Enumeration

```bash
# Zone transfer attempt (rarely works, always try)
dig axfr target.com @ns1.target.com

# Build master subdomain list from passive sources
cat recon/ct_subdomains.txt > recon/all_subdomains.txt

# Brute-force subdomains via DNS
ffuf -u "http://FUZZ.target.com" -w /usr/share/wordlists/subdomains-top1million-5000.txt \
  -mc 200,301,302,403 -o recon/ffuf_subdomains.json

# Resolve all discovered subdomains
cat recon/all_subdomains.txt | while read sub; do
  ip=$(dig +short "$sub" 2>/dev/null | head -1)
  [ -n "$ip" ] && echo "$sub,$ip"
done | tee recon/resolved_subdomains.csv

# Identify unique IPs for port scanning
cat recon/resolved_subdomains.csv | cut -d',' -f2 | sort -u > recon/target_ips.txt

# Virtual host discovery (find subdomains on same IP)
ffuf -u http://TARGET_IP -H "Host: FUZZ.target.com" \
  -w /usr/share/wordlists/subdomains-top1million-5000.txt \
  -fs 0 -mc 200,301,302 -o recon/vhosts.json
```

### Phase 3: Active Port Scanning

**REQUIRED: Use the two-phase rustscan → nmap pattern. Never skip rustscan in favor of direct nmap full-range scans — rustscan eliminates the scan timeout failures that produce empty output and "not confirmed" results.**

```bash
# Step 1: Live host discovery (for subnets/IP ranges — skip for single targets)
nmap -sn -T4 192.168.1.0/24 -oG recon/live_hosts.gnmap
rg "Up" recon/live_hosts.gnmap | awk '{print $2}' > recon/live_ips.txt

# Step 2: Fast full-range port discovery with rustscan
rustscan -a TARGET_IP --ulimit 5000 -b 1000 -- --open -oG recon/rustscan_ports.gnmap

# Step 3: Extract confirmed open port list
OPEN_PORTS=$(rg -o '[0-9]+/open' recon/rustscan_ports.gnmap | cut -d/ -f1 | sort -n | paste -sd',')
echo "Confirmed open ports: $OPEN_PORTS" | tee recon/open_ports_summary.txt

# Step 4: Service version + script scan on confirmed open ports ONLY
nmap -sV -sC -p "$OPEN_PORTS" TARGET_IP -oA recon/service_scan

# Step 5: OS detection on confirmed open ports
nmap -O -p "$OPEN_PORTS" TARGET_IP -oA recon/os_detect

# Step 6: Targeted UDP scan (rustscan does not support UDP — nmap only)
nmap -sU --top-ports 50 TARGET_IP -oA recon/udp_scan

# Step 7: Parse results for quick reference
rg "open" recon/service_scan.nmap | tee -a recon/open_ports_summary.txt
```

### Output Validation (MANDATORY)

After every recon tool execution (rustscan, nmap, httpx, ffuf, dig, whois), validate output:

```bash
bash $SUPERHACKERS_ROOT/scripts/validate-output.sh <tool_name> <output_file> <exit_code>
```

Or use the auto-validating wrapper (preferred):

```bash
bash $SUPERHACKERS_ROOT/scripts/run-tool.sh <tool> <timeout_secs> <output_file> -- <command...>
```

**CRITICAL: If a tool produces no output, that is a TOOL FAILURE — NOT a clean result.** A rustscan or nmap run that produces no output means the scan failed silently, not that all ports are closed. A legitimate clean result contains structural markers (e.g., rustscan reports "Closed Port(s): 65535", nmap reports "all ports filtered"). Never proceed past a failed scan output.

**If validation fails:**
1. Read the `REASON` and `ACTION` fields
2. Apply the suggested fix (check connectivity, permissions, rate limits)
3. Re-run the tool with corrected configuration
4. If validation fails 3 consecutive times — report tool failure to user and switch to fallback chain

Recon is the foundation — all subsequent phases depend on accurate recon data. Validate early, validate always.

### Phase 4: Web Enumeration

> **SPA (Single Page Application) Note:** Modern JavaScript applications (React, Vue, Angular) have different reconnaissance needs. Client-side routing means traditional directory brute forcing often fails. See SPA Discovery below for specialized techniques.

```bash
# Step 1: Probe all hosts for HTTP/HTTPS services
cat recon/all_subdomains.txt | httpx -ports 80,443,8080,8443,8000,3000,5000,9090 \
  -status-code -title -tech-detect -web-server -cdn \
  -follow-redirects -json -o recon/httpx_results.json

# Step 2: Check for sensitive files on every web host
for url in $(cat recon/httpx_results.json | jq -r '.url'); do
  echo "--- $url ---" >> recon/sensitive_files.txt
  for path in robots.txt sitemap.xml .git/HEAD .env .htaccess \
    wp-config.php.bak web.config crossdomain.xml \
    /.well-known/security.txt /server-status /server-info; do
    code=$(curl -s -o /dev/null -w "%{http_code}" "$url/$path" --max-time 5)
    [ "$code" != "404" ] && echo "  [${code}] $url/$path" >> recon/sensitive_files.txt
  done
done

# Step 3: Directory discovery on primary targets
ffuf -u https://target.com/FUZZ -w /usr/share/wordlists/dirb/common.txt \
  -e .php,.html,.js,.json,.xml,.txt,.bak,.asp,.aspx,.jsp \
  -mc 200,204,301,302,307,401,403,405 \
  -fc 404 -o recon/dirs_main.json

# Step 4: API endpoint discovery
ffuf -u https://target.com/api/FUZZ -w /usr/share/wordlists/api_endpoints.txt \
  -mc 200,204,301,302,401,403,405 -o recon/api_endpoints.json

# Also try common API prefixes
for prefix in api v1 v2 v3 api/v1 api/v2 api/v3 graphql rest; do
  code=$(curl -s -o /dev/null -w "%{http_code}" "https://target.com/$prefix" --max-time 5)
  [ "$code" != "404" ] && echo "[${code}] /$prefix"
done | tee recon/api_prefixes.txt

# Step 5: Technology-focused nuclei scan
nuclei -l recon/web_urls.txt -tags tech -json -o recon/tech_nuclei.json

# Step 6: Check for exposed .git
curl -s https://target.com/.git/HEAD
# If returns "ref: refs/heads/main" → .git is exposed
# Use git-dumper to download full repo if exposed

# Step 7: Admin panel discovery
ffuf -u https://target.com/FUZZ -w /usr/share/wordlists/admin_panels.txt \
  -mc 200,301,302,401,403 -o recon/admin_panels.json
```


#### 4.6 SPA and JavaScript Application Discovery

> **Modern SPA Context:** Single Page Applications (React, Vue, Angular, Svelte) hide their API surface in JavaScript bundles. Traditional directory brute forcing will miss most endpoints.

**SPA Detection:**
```bash
# Detect if target is an SPA
curl -s https://TARGET | rg -i "react|vue|angular|svelte|ember"

# Check for client-side routing indicators
curl -s https://TARGET | rg -o 'href="#/[^"]*"'

# Find JavaScript bundle files
curl -s https://TARGET | rg -o 'src="[^"]*\.js"' | cut -d'"' -f2

# Check for service workers (PWA)
curl -s https://TARGET/service-worker.js 2>/dev/null | head -20
```

**JavaScript Bundle Analysis:**
```bash
# Extract API endpoints from bundles
curl -s https://TARGET/main.js | rg -o '"/api/[^"]*"'
curl -s https://TARGET/app.js | rg -o '"/v[0-9]+/[^"]*"'

# Find secrets in bundles
curl -s https://TARGET/main.js | rg -i 'apikey|api_key|secret|token|password'

# Extract routes for React/Vue/Angular
curl -s https://TARGET/main.js | rg -o 'path:"[^"]*"'
curl -s https://TARGET/app.js | rg -o 'path: ?`[^`]*`'
```

**Client-Side Route Enumeration:**
```bash
# Test discovered SPA routes
for route in admin dashboard profile settings; do
  code=$(curl -s -o /dev/null -w "%{http_code}" "https://TARGET/#/$route")
  echo "Route /$route: HTTP $code"
done
```

> **Critical:** For SPAs, JavaScript bundle analysis reveals the true attack surface. Always analyze bundles before concluding reconnaissance is complete.

### Phase 5: Network Service Enumeration

> **Run service enumeration ONLY on ports confirmed open by rustscan/nmap. Never run service-specific NSE scripts on the full host — target confirmed ports only.**

```bash
# ─── Cross-platform timeout helper (macOS + Linux, no coreutils needed) ────────
# Define this function inline in bash commands before using:
# _to() { local s=$1; shift; if command -v timeout &>/dev/null; then timeout "$s" "$@"; elif command -v gtimeout &>/dev/null; then gtimeout "$s" "$@"; else perl -e 'use POSIX qw(SIGALRM); alarm shift; exec @ARGV' "$s" "$@"; fi; }
# ────────────────────────────────────────────────────────────────────────────────

# SMB Enumeration (port 445) — run only if port 445 confirmed open
# Define timeout function then use it:
# bash -c 'f() { local s=$1; shift; if command -v timeout &>/dev/null; then timeout "$s" "$@"; elif command -v gtimeout &>/dev/null; then gtimeout "$s" "$@"; else perl -e "use POSIX qw(SIGALRM); alarm shift; exec @ARGV" "$s" "$@"; fi; }; f 120 nmap --script=smb-enum-shares,smb-enum-users,smb-os-discovery,smb-security-mode -p 445 TARGET -oN recon/smb_enum.txt'
nmap --script=smb-enum-shares,smb-enum-users,smb-os-discovery,smb-security-mode \
  -p 445 TARGET -oN recon/smb_enum.txt

# SMB — list shares with smbclient
smbclient -L //TARGET -N 2>/dev/null | tee recon/smb_shares.txt

# SMB — attempt null session
smbclient //TARGET/share -N

# SNMP Enumeration (port 161/udp) — run only if UDP 161 confirmed open
# Use the timeout wrapper script instead for long-running commands:
# bash $SUPERHACKERS_ROOT/scripts/run-tool.sh nmap 120 recon/snmp_enum.txt -- nmap --script=snmp-brute,snmp-info,snmp-interfaces,snmp-processes,snmp-sysdescr -sU -p 161 TARGET
nmap --script=snmp-brute,snmp-info,snmp-interfaces,snmp-processes,snmp-sysdescr \
  -sU -p 161 TARGET -oN recon/snmp_enum.txt

# SNMP walk with default community string
snmpwalk -v2c -c public TARGET | tee recon/snmpwalk.txt

# LDAP Enumeration (port 389) — run only if port 389 confirmed open
nmap --script=ldap-rootdse,ldap-search -p 389 TARGET -oN recon/ldap_enum.txt

# LDAP — anonymous bind query
ldapsearch -x -H ldap://TARGET -b "dc=target,dc=com" | tee recon/ldap_search.txt

# NFS Enumeration (port 2049) — run only if port 2049 confirmed open
nmap --script=nfs-showmount,nfs-ls,nfs-statfs -p 2049 TARGET -oN recon/nfs_enum.txt

# NFS — show exports
showmount -e TARGET | tee recon/nfs_exports.txt

# RPC Enumeration
rpcinfo -p TARGET | tee recon/rpcinfo.txt

# FTP Enumeration (port 21) — run only if port 21 confirmed open
nmap --script=ftp-anon,ftp-bounce,ftp-syst -p 21 TARGET -oN recon/ftp_enum.txt

# SMTP Enumeration (port 25) — run only if port 25 confirmed open
nmap --script=smtp-commands,smtp-enum-users,smtp-open-relay -p 25 TARGET -oN recon/smtp_enum.txt
```

### Phase 6: Technology Stack Detection & Skill Routing

After web enumeration, identify specific technologies to load supplementary security skills.

```bash
# Step 1: Identify framework from response headers and body
# Next.js detection
curl -s -I https://target.com | rg -i "x-powered-by: Next.js"
curl -s https://target.com | rg -o "__NEXT_DATA__|_next/static|_buildManifest.js"
# If detected → Load superhackers:nextjs-security

# FastAPI detection
curl -s -I https://target.com/docs | rg -i "swagger|fastapi"
curl -s https://target.com/openapi.json 2>/dev/null | rg -o "FastAPI|Starlette"
# If detected → Load superhackers:fastapi-security

# Supabase detection
curl -s -I https://target.com | rg -i "x-supabase|supabase"
curl -s https://target.com | rg -o "supabase\.co|supabase\.in|\.supabase\."
# Check for PostgREST API pattern
curl -s https://api.target.com/ -H "apikey: test" 2>/dev/null | rg -i "postgrest|pgrst"
# If detected → Load superhackers:supabase-security

# Firebase detection
curl -s https://target.com | rg -o "firebase|firebaseapp\.com|firestore|firebaseio\.com"
curl -s https://target.com/__/firebase/init.json 2>/dev/null
# If detected → Load superhackers:firebase-security

# GraphQL detection
for path in graphql graphiql playground api/graphql v1/graphql gql query; do
  code=$(curl -s -o /dev/null -w "%{http_code}" "https://target.com/$path" -X POST \
    -H "Content-Type: application/json" \
    -d '{"query":"{__typename}"}' --max-time 5)
  [ "$code" != "404" ] && echo "[${code}] /$path may be GraphQL"
done
# If detected → Load superhackers:graphql-security

# Step 2: Summarize detected technologies
echo "=== TECHNOLOGY SKILLS TO LOAD ===" >> recon/summary.txt
# List each detected technology and its corresponding skill
```

**Technology skill loading rules:**
- Technology skills are loaded AS SUPPLEMENTS to the primary testing skill (webapp-pentesting, api-pentesting, etc.)
- Multiple technology skills can be loaded simultaneously (e.g., Next.js + Supabase + GraphQL)
- Load technology skills BEFORE starting the testing phase — they inform what to test
- If no specific framework/technology is detected, proceed with generic testing skills only

### Phase 7: Consolidation

```bash
# Create engagement summary
echo "=== RECON SUMMARY ===" > recon/summary.txt
echo "" >> recon/summary.txt
echo "Subdomains found: $(wc -l < recon/all_subdomains.txt)" >> recon/summary.txt
echo "Live IPs: $(wc -l < recon/live_ips.txt)" >> recon/summary.txt
echo "Web services: $(wc -l < recon/httpx_results.json)" >> recon/summary.txt
echo "" >> recon/summary.txt
echo "=== OPEN PORTS ===" >> recon/summary.txt
cat recon/open_ports_summary.txt >> recon/summary.txt
echo "" >> recon/summary.txt
echo "=== TECHNOLOGIES ===" >> recon/summary.txt
cat recon/httpx_results.json | jq -r '.tech[]?' | sort | uniq -c | sort -rn >> recon/summary.txt
echo "" >> recon/summary.txt
echo "=== SENSITIVE FILES ===" >> recon/summary.txt
cat recon/sensitive_files.txt >> recon/summary.txt
```

After consolidation:
- **REQUIRED SUB-SKILL: Use superhackers:vulnerability-verification** to validate any findings
- **REQUIRED SUB-SKILL: Use superhackers:exploit-development** when ready to exploit discovered services

## Common Mistakes

1. **Skipping passive recon** — Jumping to nmap before OSINT means missing subdomains, historical endpoints, and technology context. Always do passive first.

2. **Incomplete port scanning** — Only scanning top 1000 ports. Services frequently run on high ports (8080, 8443, 9090, custom). Always do full TCP (`-p-`) on priority targets.

3. **Ignoring UDP** — UDP services like SNMP (161), DNS (53), TFTP (69), NTP (123) are often overlooked but can be critical entry points.

4. **Not resolving all subdomains** — Subdomains may point to different infrastructure. Each unique IP is a separate attack surface.

5. **Missing vhosts** — Multiple applications can share one IP. Virtual host discovery catches what DNS enumeration misses.

6. **Not checking for .git exposure** — Exposed `.git` directories can leak source code, credentials, and full commit history. Always check `/.git/HEAD`.

7. **Ignoring backup and old files** — Files like `.bak`, `.old`, `.swp`, `~`, `.save` often contain credentials or previous versions with vulnerabilities.

8. **Scanning too aggressively** — Flooding the target with nmap `-T5` or unthrottled ffuf can trigger WAFs, get IP banned, or crash fragile services. Use rate limiting.

9. **Not saving output** — Every scan must be saved with `-o` or `-oA`. If you don't save it, you have to run it again. Always output to files.

10. **Tunnel vision on web** — Don't ignore non-HTTP services. SMB shares, SNMP communities, NFS exports, and database ports are often low-hanging fruit.

11. **Not feeding results forward** — Recon data should flow into the next phase. Discovered URLs go into nuclei, open ports inform exploit selection, technology stack guides attack vectors.

   12. **Using tools not in the toolkit** — Stick to installed tools: rustscan, nmap, ffuf, nuclei, httpx. Don't try to use gobuster, amass, subfinder, or other tools not available in the environment. Check `detect-tools.sh` output first.

## Completion Criteria

This skill's work is DONE when ALL of the following are true:
- [ ] All target hosts/domains have been enumerated (subdomains, virtual hosts)
- [ ] Port scanning and service detection is complete for all in-scope targets
- [ ] Technology stack has been identified (frameworks, languages, servers, databases)
- [ ] Authentication mechanisms have been documented
- [ ] Attack surface map has been written with all discovered endpoints
- [ ] All todo items created during this phase are marked complete

When all conditions are met, state "Phase complete: recon-and-enumeration" and stop.
Do NOT test for vulnerabilities, attempt exploitation, or provide remediation recommendations — those are other skills' jobs.
