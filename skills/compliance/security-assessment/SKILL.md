---
name: security-assessment
description: "Use when planning, scoping, or executing a comprehensive security assessment, penetration test, red team engagement, or security audit. Use when the user needs to coordinate multiple security testing activities, define assessment scope and rules of engagement, perform threat modeling, rate risk using CVSS, map findings to compliance frameworks (OWASP Top 10, PCI DSS, SOC 2, ISO 27001), manage assessment lifecycle from planning through reporting, or orchestrate multiple security skills together. Use as the master coordinator when no single specialized skill covers the full task."
---

## Required Tools

> This is an orchestrator skill that delegates to sub-skills. Tool requirements depend on which sub-skills are invoked during the assessment.

| Sub-Skill | Tools Required | Reference |
|-----------|---------------|-----------|
| recon-and-enumeration | rustscan, nmap, ffuf, nuclei, httpx, dig | See [recon skill](../recon-and-enumeration/SKILL.md) |
| webapp-pentesting | rustscan, nmap, ffuf, nuclei, nikto, sqlmap, curl | See [webapp skill](../webapp-pentesting/SKILL.md) |
| api-pentesting | curl, ffuf, httpx, nuclei, sqlmap | See [api skill](../api-pentesting/SKILL.md) |
| infra-pentesting | rustscan, nmap, Metasploit, john, hashcat | See [infra skill](../infra-pentesting/SKILL.md) |
| android-pentesting | adb, jadx, apktool, Frida, mitmproxy | See [android skill](../android-pentesting/SKILL.md) |
| secure-code-review | ripgrep, find, ast-grep | See [code-review skill](../secure-code-review/SKILL.md) |

## Tool Execution Protocol

**Before starting any assessment**, verify tool availability and establish fallback chains:

### 1. Pre-Assessment Tool Check

> **CRITICAL: If SUPERHACKERS_ROOT is not set, auto-detect it first**

```bash
# Auto-detect SUPERHACKERS_ROOT if not set
if [ -z "${SUPERHACKERS_ROOT:-}" ]; then
  # Try common plugin cache paths
  for path in \
    "$HOME/.claude/plugins/cache/superhackers/superhackers/1.2.* \
    "$HOME/.claude/plugins/cache/superhackers/superhackers/"* \
    "$HOME/superhackers" \
    "$(pwd)/superhackers" \
    "$(dirname "$(dirname "${BASH_SOURCE[0]:-$0}")")"; do
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

```bash
# Run automated tool detection
bash $SUPERHACKERS_ROOT/scripts/detect-tools.sh > tool_check.log 2>&1

# Analyze results
if rg -q "TOOLS_BROKEN" tool_check.log; then
  echo "WARNING: Some tools are broken and need reinstallation"
  rg "TOOLS_BROKEN" tool_check.log
fi

if rg -q "REQUIRED_MISSING" tool_check.log; then
  echo "CRITICAL: Required tools are missing"
  rg "REQUIRED_MISSING" tool_check.log
  echo ""
  echo "Options:"
  echo "1. Install missing tools (see SETUP.md)"
  echo "2. Proceed with available tools (reduced coverage)"
  echo "3. Cancel assessment"
fi

# Cache tool availability for sub-skills
export TOOL_AVAILABILITY=$(cat tool_check.log)
```

### 2. Sub-Skill Tool Validation

Before delegating to any sub-skill, verify its required tools are available:

```bash
# Check if recon tools are available before loading recon skill
RECON_TOOLS="rustscan nmap ffuf nuclei httpx dig"
MISSING_TOOLS=()

for tool in $RECON_TOOLS; do
  if ! command -v $tool >/dev/null 2>&1; then
    MISSING_TOOLS+=($tool)
  fi
done

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
  echo "WARNING: Recon phase missing tools: ${MISSING_TOOLS[*]}"
  echo "Fallback tools will be used by recon skill"
  echo "See TOOLCHAIN.md for fallback chains"
fi
```

### 3. Tool Failure During Assessment

If a tool fails during assessment execution:

1. **Don't skip the phase** - Use fallback tools
2. **Document the failure** - Note which tools failed and what was used instead
3. **Don't downgrade severity** - Finding severity based on what was tested, not what failed

```bash
# Example: Port scanning phase
echo "=== Phase 2: Port Scanning ==="

if command -v rustscan >/dev/null 2>&1; then
  echo "Using rustscan for port discovery..."
  bash $SUPERHACKERS_ROOT/scripts/run-tool.sh rustscan 60 scan_results.txt -- rustscan -a $TARGET --ulimit 5000
else
  echo "PRIMARY_TOOL_FAILURE: rustscan not available"
  echo "FALLBACK: Using nmap for port scanning"
  bash $SUPERHACKERS_ROOT/scripts/run-tool.sh nmap 300 scan_results.txt -- nmap -sS -T4 $TARGET
fi

# Validate output before proceeding
bash $SUPERHACKERS_ROOT/scripts/validate-output.sh rustscan scan_results.txt $?
```

### 4. Assessment-Level Decision Tree

When multiple tools fail, decide whether to:

- **Continue with reduced coverage** - Document limitations, test what you can
- **Re-plan the assessment** - Adjust methodology to available tools
- **Report to stakeholder** - If critical tools are missing

```bash
# Decision framework
PRIMARY_TOOLS_AVAILABLE=$(rg -c "local" tool_check.log)
TOTAL_REQUIRED_TOOLS=$(rg -c "Yes" TOOLCHAIN.md | head -1)

AVAILABILITY_RATIO=$((PRIMARY_TOOLS_AVAILABLE * 100 / TOTAL_REQUIRED_TOOLS))

if [ $AVAILABILITY_RATIO -lt 50 ]; then
  echo "WARNING: Less than 50% of required tools available"
  echo "Recommendation: Re-plan assessment or install tools"
  echo "Current tool availability: $PRIMARY_TOOLS_AVAILABLE/$TOTAL_REQUIRED_TOOLS"
fi
```

> **Run `bash $SUPERHACKERS_ROOT/scripts/detect-tools.sh` for tool availability, or read `$SUPERHACKERS_ROOT/TOOLCHAIN.md` for the full resolution protocol before starting any assessment to identify available tools and plan accordingly.**

## Overview

**Role: Engagement Planner** — Your job is to define scope, select methodology, and sequence the engagement phases. Stay in your lane: you plan and coordinate, you do NOT perform testing, verification, or reporting.

Master orchestrator skill for comprehensive security assessments. This skill coordinates the full assessment lifecycle — from scoping and planning through testing, analysis, and reporting. It ties together all specialized security skills (recon, pentesting, code review, exploit development, reporting) into a cohesive engagement.

## Pipeline Position

> **Position:** Phase 1 (Planning) — the FIRST skill loaded in a full engagement
> **Expected Input:** User's scope definition, target URLs/IPs, rules of engagement, engagement depth preference
> **Your Output:** Engagement plan — scope boundaries, skill sequence, depth selection, rules of engagement
> **Consumed By:** All subsequent skills (defines their operating boundaries and sequence)
> **Critical:** Your plan determines which skills are loaded, in what order, and at what depth. An incomplete plan = an incomplete engagement.

This is NOT a replacement for specialized skills. It is the conductor that determines WHICH skills to invoke, in WHAT order, and HOW to synthesize their outputs into actionable security intelligence.

### Sub-Skill Registry

| Skill | Purpose | When to Invoke |
|-------|---------|----------------|
| superhackers:recon-and-enumeration | Attack surface discovery | Always first in external assessments |
| superhackers:webapp-pentesting | Web application testing | Web apps in scope |
| superhackers:api-pentesting | API security testing | REST/GraphQL/gRPC APIs in scope |
| superhackers:secure-code-review | Source code analysis | Source code access granted |
| superhackers:vulnerability-verification | Confirm exploitability | Before reporting any finding |
| superhackers:exploit-development | PoC/exploit creation | When verification requires custom exploit |
| superhackers:infra-pentesting | Infrastructure testing | Network/server infra in scope |
| superhackers:android-pentesting | Mobile app testing | Android apps in scope |
| superhackers:writing-security-reports | Deliverable creation | Always at end of engagement |

## When to Use

- Starting a new security assessment, pentest, or red team engagement
- Defining scope, rules of engagement, or methodology for a security project
- Coordinating multiple testing activities across different attack surfaces
- Performing threat modeling (STRIDE, attack trees, DFDs)
- Rating vulnerabilities with CVSS and mapping to compliance frameworks
- Managing assessment timeline, milestones, and deliverables
- Communicating findings to stakeholders (emergency, interim, final)
- Deciding which specialized skill to invoke for a given task
- Synthesizing findings from multiple testing phases into a unified report

## Core Pattern

```
PLAN  → Define scope, methodology, threat model, timeline
  ↓
RECON → Discover and enumerate the attack surface
  ↓
TEST  → Execute testing activities using specialized skills
  ↓
ANALYZE → Rate findings, assess risk, map to frameworks
  ↓
REPORT → Compile deliverables, present to stakeholders
```

### Execution Discipline

- **Persist**: Continue working through ALL steps of the Core Pattern until completion criteria are met. Do NOT stop after a single tool run or partial result.
- **Scope**: Work ONLY within this skill's methodology. Do NOT jump to another phase (e.g., don't start writing the report while still testing).
- **Negative Results**: If thorough testing reveals no vulnerabilities, that IS a valid result. Document what was tested and report "no findings" — do NOT invent issues.
- **Retry Limit**: Max 3 attempts per test. If blocked, classify the failure and proceed.

## Quick Reference

### Assessment Type Decision Matrix

| Assessment Type | Scope | Depth | Stealth | Duration | Deliverable |
|----------------|-------|-------|---------|----------|-------------|
| Vulnerability Assessment | Broad | Shallow | No | 1-3 days | Vuln list + risk ratings |
| Penetration Test | Defined | Deep | Optional | 1-3 weeks | Full report + PoCs |
| Red Team Engagement | Goal-based | Varies | Yes | 2-8 weeks | Narrative + TTPs |
| Security Audit | Comprehensive | Review-level | No | 1-4 weeks | Compliance report |
| Code Review | Source code | Deep | N/A | 3-10 days | Code findings report |
| Bug Bounty Triage | Single target | Deep | No | Ongoing | Per-finding reports |

### Skill Orchestration Flowchart

```
External Assessment (no source):
  recon-and-enumeration → webapp-pentesting / api-pentesting / infra-pentesting
    → vulnerability-verification → exploit-development (if needed)
    → writing-security-reports

Internal Assessment (with source):
  secure-code-review → vulnerability-verification
    → webapp-pentesting / api-pentesting (validate in running app)
    → writing-security-reports

Full Engagement:
  recon-and-enumeration → secure-code-review (if source available)
    → webapp-pentesting + api-pentesting + infra-pentesting + android-pentesting
    → vulnerability-verification → exploit-development
    → writing-security-reports
```

### CVSS v4.0 Quick Scoring

CVSS 4.0 uses a lookup-based algorithm rather than a simple formula with individual metric weights. Use the FIRST calculator or Python `cvss` library for accurate scores.

**Note:** Use Python cvss library (`pip install cvss`) for accurate score calculation: `from cvss import CVSS4`

| Metric | Values | Description |
|--------|--------|-------------|
| AV | N, A, L, P | Attack Vector |
| AC | L, H | Attack Complexity |
| AT | N, P | Attack Requirements (NEW) |
| PR | N, L, H | Privileges Required |
| UI | N, P, A | User Interaction (changed: P=passive, A=active) |
| VC | H, L, N | Confidentiality impact on vulnerable system |
| VI | H, L, N | Integrity impact on vulnerable system |
| VA | H, L, N | Availability impact on vulnerable system |
| SC | H, L, N | Confidentiality impact on subsequent systems |
| SI | H, L, N | Integrity impact on subsequent systems |
| SA | H, L, N | Availability impact on subsequent systems |

| Score Range | Rating |
|------------|--------|
| 0.0 | None |
| 0.1 – 3.9 | Low |
| 4.0 – 6.9 | Medium |
| 7.0 – 8.9 | High |
| 9.0 – 10.0 | Critical |

## Implementation

### Phase 1: Assessment Planning

#### 1.1 Scope Definition

Establish clear boundaries before any testing begins.

```markdown
## Assessment Scope Document

### In-Scope Assets
- [ ] Web applications (list URLs/domains)
- [ ] APIs (list endpoints, documentation links)
- [ ] Infrastructure (list IP ranges, cloud accounts)
- [ ] Mobile applications (list app IDs, platforms)
- [ ] Source code repositories (list repos, branches)
- [ ] Internal networks (list VLANs, subnets)

### Out-of-Scope
- [ ] Third-party services not owned by client
- [ ] Production databases (unless explicitly authorized)
- [ ] Denial-of-service testing (unless explicitly authorized)
- [ ] Social engineering (unless explicitly authorized)
- [ ] Physical security testing (unless explicitly authorized)

### Rules of Engagement
- Testing window: [dates and times]
- Emergency contact: [name, phone, email]
- Escalation procedure: [steps for critical findings]
- Data handling: [classification, storage, destruction]
- Credential usage: [provided creds, credential stuffing policy]
- Automated scanning limits: [rate limiting, excluded scanners]
```

#### 1.2 Engagement Depth Selection

Before selecting methodology, determine the engagement depth. This setting propagates to ALL downstream skills and controls how much time and effort is invested in each phase.

| Depth | Duration | Focus | Skip | Mindset |
|-------|----------|-------|------|---------|
| **Quick** | 1-2 hours | Auth bypass, BOLA/IDOR, RCE, SQLi, SSRF, exposed secrets | Exhaustive enum, deep fuzzing, info disclosure, theoretical issues | Time-boxed bug bounty hunter |
| **Standard** | Half-day to full day | OWASP Top 10 + business logic for critical flows | Persistent retesting, edge cases, deep chaining | Methodical, systematic |
| **Deep** | Multi-day | Full attack surface including edge cases, chaining, persistence | Nothing — exhaustive coverage | Relentless, creative, patient |

**Quick Depth:**
- Recon: Map auth + critical flows only, identify high-value endpoints, skip deep discovery
- Testing: Focus on critical/high-impact vulns only (auth bypass, RCE, SQLi, SSRF, exposed secrets)
- Subagents: Only for parallel high-priority targets
- Validation: Minimal PoC, demonstrate real impact
- Chaining: When a strong primitive is found, attempt ONE high-impact pivot immediately
- Scanner config: `nuclei -severity critical,high` only

**Standard Depth:**
- Recon: Full crawl, endpoint enumeration, role mapping, tech fingerprinting
- Testing: Systematic by category with focused subagents (input validation, auth, access control, business logic)
- Subagents: One per testing category, run in parallel
- Validation: Working PoC with impact demonstration, try one chain per finding
- Chaining: Always ask "what does this finding enable next?" — prefer complete end-to-end paths
- Scanner config: `nuclei -severity critical,high,medium`

**Deep Depth:**
- Recon: Whitebox analysis — every code path, data model, integration point. If source available, map every file/module
- Business Logic: Map every user flow, state machine, trust boundary, invariant. Identify implicit assumptions
- Testing: Hierarchical decomposition — component → feature → vulnerability level. Each area gets dedicated analysis
- Subagents: Spawn specialized agents per component, scale horizontally
- Chaining: Every finding is a pivot point — continue to maximum privilege. Validate full sequence
- Persistence: Research tech-specific bypasses, alternative techniques, edge cases. Revisit with new info from other findings
- Scanner config: `nuclei` with all templates, custom templates if needed

**How to determine depth:**
- User says "quick check", "sanity test", "before deployment" → **Quick**
- User says "pentest", "security assessment", "vulnerability assessment" → **Standard**
- User says "comprehensive", "thorough", "annual assessment", "red team" → **Deep**
- If unclear → Ask: "Should I do a quick high-impact check, a standard systematic assessment, or a deep comprehensive review?"

**Propagating depth to downstream skills:**
When invoking sub-skills, pass the depth context:
```
Engagement depth: [Quick|Standard|Deep]
→ recon-and-enumeration: adjust scope per depth level above
→ webapp/api/infra-pentesting: adjust testing breadth and tool configuration
→ vulnerability-verification: adjust PoC depth (minimal for Quick, full for Deep)
→ exploit-development: skip for Quick, selective for Standard, comprehensive for Deep
```

### Time Distribution Within Each Phase

Regardless of engagement depth, distribute effort within each phase as:

| Allocation | Activity | Example |
|---|---|---|
| ~10% | Setup and orientation | Review scope, configure tools, create working dirs |
| ~30% | Broad exploration | Run multiple scan types, enumerate widely, try diverse payloads |
| ~30% | Evaluation and triage | Analyze results, prioritize findings, eliminate false positives |
| ~30% | Focused exploitation | Deep-dive on highest-priority findings, build exploit chains, gather evidence |

**Anti-patterns:**
- Spending 80% on automated scanning — miss manual-only findings
- Spending 80% on one attack vector — miss breadth
- Skipping evaluation — report unverified findings

**Plan Adaptation**: When findings change priorities, adjust the remaining plan using minimal modifications — don't restart from scratch. Add new targets, remove dead ends, reorder by updated priority.

#### 1.3 Methodology Selection

Choose methodology based on assessment type and client requirements:

| Framework | Best For | Key Focus |
|-----------|----------|-----------|
| OWASP Testing Guide (OTG) | Web app pentests | Structured web testing categories |
| OWASP ASVS | Security audits, code review | Verification levels (L1/L2/L3) |
| PTES | Full pentests | End-to-end pentest lifecycle |
| OSSTMM | Comprehensive assessments | Operational security metrics |
| NIST SP 800-115 | Government/compliance | Technical security testing |
| MITRE ATT&CK | Red team engagements | Adversary TTPs mapping |

#### 1.3 Threat Modeling

Perform threat modeling BEFORE testing to focus effort on highest-risk areas.

**STRIDE Model — Apply to each component in the data flow:**

| Threat | Question | Example |
|--------|----------|---------|
| **S**poofing | Can an attacker impersonate a user or system? | Stolen JWT, forged SAML assertion |
| **T**ampering | Can data be modified in transit or at rest? | MITM on API calls, database manipulation |
| **R**epudiation | Can actions be performed without audit trail? | Missing logging on admin actions |
| **I**nformation Disclosure | Can sensitive data leak? | Error messages with stack traces, exposed API keys |
| **D**enial of Service | Can availability be impacted? | ReDoS, resource exhaustion, algorithmic complexity |
| **E**levation of Privilege | Can a user gain unauthorized access? | IDOR, privilege escalation, broken RBAC |

**Building an Attack Tree:**

```
Goal: Access admin panel without authorization
├── Bypass authentication
│   ├── Brute-force credentials
│   ├── Exploit password reset flow
│   ├── Steal session token (XSS, session fixation)
│   └── Exploit SSO/OAuth misconfiguration
├── Bypass authorization
│   ├── IDOR on admin API endpoints
│   ├── Modify role claim in JWT
│   ├── Exploit mass assignment to set admin flag
│   └── Access admin routes without auth middleware
└── Exploit infrastructure
    ├── Access admin interface on internal port
    ├── Exploit SSRF to reach admin panel
    └── Pivot from compromised internal host
```

**Data Flow Diagram Approach:**
1. Identify all data entry points (user inputs, API calls, file uploads, third-party webhooks)
2. Map data flows between components (frontend → API → database → cache)
3. Mark trust boundaries (internet → DMZ → internal network → database tier)
4. Identify where data crosses trust boundaries — these are your priority testing points
5. Document data sensitivity levels at each point

### Phase 2: Reconnaissance

**REQUIRED SUB-SKILL:** Use superhackers:recon-and-enumeration for detailed reconnaissance methodology.

Orchestration approach for recon:

```bash
# 1. Passive reconnaissance first — no direct target interaction
# Domain enumeration, OSINT, technology fingerprinting
# → Output: list of subdomains, IPs, technologies, exposed services

# 2. Active reconnaissance — direct target interaction
# Port scanning, service enumeration, directory discovery
# → Output: detailed service map, application inventory

# 3. Synthesis — combine passive and active findings
# Build target inventory with:
#   - Each application/service identified
#   - Technology stack per target
#   - Authentication mechanisms observed
#   - Potential attack vectors per target
```

### Phase 3: Testing Execution

#### 3.1 Testing Orchestration

Execute testing in priority order based on threat model:

```
Priority 1: Authentication & Authorization
  REQUIRED SUB-SKILL: Use superhackers:webapp-pentesting for web auth testing
  REQUIRED SUB-SKILL: Use superhackers:api-pentesting for API auth testing
  Focus: Login bypass, privilege escalation, session management, OAuth/OIDC flows

Priority 2: Injection & Input Handling
  REQUIRED SUB-SKILL: Use superhackers:webapp-pentesting for web injection testing
  REQUIRED SUB-SKILL: Use superhackers:api-pentesting for API injection testing
  REQUIRED SUB-SKILL: Use superhackers:secure-code-review for source-level analysis
  Focus: SQLi, XSS, SSTI, command injection, deserialization

Priority 3: Business Logic
  No specific sub-skill — requires manual analysis based on application context
  Focus: Payment manipulation, workflow bypass, race conditions, IDOR

Priority 4: Infrastructure
  REQUIRED SUB-SKILL: Use superhackers:infra-pentesting for infrastructure testing
  Focus: Service misconfigurations, default credentials, network segmentation

Priority 5: Client-Side & Mobile
  REQUIRED SUB-SKILL: Use superhackers:android-pentesting for Android testing
  Focus: Local storage, certificate pinning, reverse engineering, IPC

Priority 6: Configuration & Hardening
  REQUIRED SUB-SKILL: Use superhackers:secure-code-review for configuration review
  Focus: Headers, TLS, CORS, cookie flags, error handling
```

#### 3.2 Testing Tracker

Maintain a testing checklist during execution:

```markdown
## Testing Progress

### Authentication (P1)
- [ ] Registration flow — input validation, email verification
- [ ] Login — brute force protection, credential stuffing, timing attacks
- [ ] Password reset — token entropy, expiration, reuse
- [ ] Session management — token generation, expiration, invalidation
- [ ] Multi-factor auth — bypass techniques, fallback mechanisms
- [ ] OAuth/OIDC — redirect_uri validation, state parameter, token leakage

### Authorization (P1)
- [ ] Horizontal access control — IDOR on all resource endpoints
- [ ] Vertical access control — privilege escalation paths
- [ ] Function-level access — admin functionality accessible to users
- [ ] API authorization — missing auth on endpoints

### Injection (P2)
- [ ] SQL injection — all input points, blind, time-based
- [ ] Cross-site scripting — reflected, stored, DOM-based
- [ ] Command injection — OS command contexts
- [ ] Template injection — server-side template engines
- [ ] LDAP/XPath injection — directory service queries
- [ ] Header injection — HTTP response splitting, host header

### Data Exposure (P2)
- [ ] Sensitive data in responses — PII, credentials, tokens
- [ ] Error handling — stack traces, debug info, verbose errors
- [ ] API response filtering — excessive data exposure
- [ ] Caching — sensitive data in cache headers

### Business Logic (P3)
- [ ] Payment/transaction manipulation
- [ ] Workflow bypass — skipping required steps
- [ ] Race conditions — TOCTOU, parallel request abuse
- [ ] Rate limiting — absence or bypass

### Infrastructure (P4)
- [ ] TLS configuration — protocol version, cipher suites
- [ ] Security headers — CSP, HSTS, X-Frame-Options, etc.
- [ ] CORS configuration — origin validation
- [ ] Cookie attributes — Secure, HttpOnly, SameSite
```

#### 3.3 Emergency Finding Protocol

When a critical vulnerability is discovered during testing:

1. **Stop and document** — capture full evidence immediately (request/response, screenshot, reproduction steps)
2. **Assess blast radius** — determine if actively exploited or if others could discover it
3. **Notify immediately** — contact emergency contact from scope document
4. **Provide quick remediation** — give the client actionable steps to mitigate RIGHT NOW
5. **Continue testing** — don't let one critical finding halt the entire assessment
6. **Follow up in report** — include full write-up in final deliverable

```markdown
## EMERGENCY FINDING NOTIFICATION

**Date/Time:** [timestamp]
**Severity:** CRITICAL
**Title:** [concise title]

**Description:** [1-2 sentences]

**Evidence:** [screenshot/request/response]

**Immediate Risk:** [what's exposed RIGHT NOW]

**Recommended Immediate Action:**
1. [specific step to mitigate]
2. [specific step to mitigate]

**Full details will be provided in the final report.**
```

### Phase 4: Risk Analysis

#### 4.1 CVSS Scoring Process

For each finding, calculate CVSS 4.0 base score:

```
1. Determine Attack Vector — how does attacker reach the vulnerable component?
   Network = remotely exploitable over internet
   Adjacent = requires same network segment
   Local = requires local access or user interaction to deliver payload
   Physical = requires physical access

2. Determine Attack Complexity — are there conditions beyond attacker's control?
   Low = no special conditions, works reliably
   High = requires specific configuration, race condition, or MITM position

3. Determine Attack Requirements — are there prerequisites for exploitation?
   None = no preconditions needed
   Present = specific deployment/config requirements

4. Determine Privileges Required — what access level is needed?
   None = unauthenticated
   Low = regular user account
   High = admin/privileged account

5. Determine User Interaction — does a victim need to do something?
   None = fully attacker-driven
   Passive = victim must access the vulnerable system (e.g., visit a page)
   Active = victim must actively interact (e.g., submit a form, accept a prompt)

6. Determine Vulnerable System Impact — what's the effect on the vulnerable component?
   Confidentiality (VC): None / Low (limited data) / High (all data)
   Integrity (VI): None / Low (limited modification) / High (full modification)
   Availability (VA): None / Low (degraded) / High (full DoS)

7. Determine Subsequent System Impact — does exploitation impact resources beyond the vulnerable component?
   Confidentiality (SC): None / Low / High
   Integrity (SI): None / Low / High
   Availability (SA): None / Low / High
```

#### 4.2 Business Impact Assessment

CVSS alone is insufficient. Overlay business context:

| Factor | Questions to Answer |
|--------|-------------------|
| Data Sensitivity | What data is exposed? PII, financial, health, credentials? |
| Regulatory Impact | Does this trigger breach notification? GDPR, HIPAA, PCI? |
| Reputation Risk | Would public disclosure cause significant brand damage? |
| Operational Impact | Does exploitation disrupt critical business operations? |
| Financial Exposure | What's the estimated financial loss from exploitation? |
| Affected Users | How many users/customers are impacted? |

Adjust severity based on business context:
- SQLi on a public-facing app with 10M user records → stays Critical
- SQLi on an internal tool with test data only → downgrade to Medium
- XSS on marketing site with no auth → Low
- XSS on banking portal → High/Critical

#### 4.3 Compliance Mapping

Map each finding to relevant compliance frameworks:

**OWASP Top 10 (2021) Mapping:**

| Category | ID | Findings That Map Here |
|----------|----|-----------------------|
| Broken Access Control | A01 | IDOR, privilege escalation, missing auth, CORS misconfig |
| Cryptographic Failures | A02 | Weak crypto, plaintext transmission, exposed secrets |
| Injection | A03 | SQLi, XSS, SSTI, command injection, LDAP injection |
| Insecure Design | A04 | Business logic flaws, missing threat modeling artifacts |
| Security Misconfiguration | A05 | Default creds, unnecessary features, missing hardening |
| Vulnerable Components | A06 | Outdated libraries, known CVEs in dependencies |
| Auth Failures | A07 | Brute force, credential stuffing, session fixation |
| Data Integrity Failures | A08 | Insecure deserialization, missing integrity checks |
| Logging Failures | A09 | Missing audit logs, insufficient monitoring |
| SSRF | A10 | Server-side request forgery |

**SANS/CWE Top 25 — Map findings to specific CWE IDs:**

| CWE | Name | Common Findings |
|-----|------|----------------|
| CWE-79 | XSS | Reflected, stored, DOM-based XSS |
| CWE-89 | SQL Injection | Any SQL injection variant |
| CWE-78 | OS Command Injection | Command injection via user input |
| CWE-22 | Path Traversal | Directory traversal, file inclusion |
| CWE-352 | CSRF | Missing CSRF tokens on state-changing operations |
| CWE-434 | Unrestricted Upload | File upload without type validation |
| CWE-862 | Missing Authorization | Endpoints without access control checks |
| CWE-798 | Hardcoded Credentials | Passwords/keys in source code |
| CWE-918 | SSRF | Server-side request forgery |
| CWE-502 | Insecure Deserialization | Deserialization of untrusted data |

**PCI DSS Mapping (for payment-related targets):**

| PCI DSS Req | Security Control | Related Findings |
|------------|-----------------|-----------------|
| 2.1 | Change vendor defaults | Default credentials |
| 3.4 | Render PAN unreadable | Plaintext card data storage |
| 4.1 | Encrypt transmission | Missing TLS, weak ciphers |
| 6.5 | Address common vulns | Injection, XSS, broken auth |
| 6.6 | WAF or code review | Missing security review process |
| 8.2 | Proper authentication | Weak password policy, missing MFA |
| 10.2 | Audit trail | Missing logging of security events |

**SOC 2 Trust Service Criteria Mapping:**

| Criteria | Category | Related Findings |
|----------|----------|-----------------|
| CC6.1 | Logical Access | Broken authentication, weak access controls |
| CC6.3 | Role-Based Access | Privilege escalation, missing RBAC |
| CC6.6 | System Boundaries | Missing network segmentation, SSRF |
| CC6.7 | Data Transmission | Weak TLS, missing encryption |
| CC7.1 | Monitoring | Missing logging, no intrusion detection |
| CC7.2 | Anomaly Detection | No rate limiting, no brute-force detection |
| CC8.1 | Change Management | No security review in CI/CD |

**ISO 27001 Annex A Controls:**

| Control | Area | Related Findings |
|---------|------|-----------------|
| A.9.4.2 | Secure logon | Brute force, credential stuffing, session flaws |
| A.10.1.1 | Cryptographic controls | Weak algorithms, key management issues |
| A.12.6.1 | Technical vulnerability mgmt | Unpatched vulnerabilities, outdated dependencies |
| A.14.1.2 | Securing app services | Injection, XSS, access control failures |
| A.14.2.5 | Secure development | Missing SAST/DAST, no security review process |

### Phase 5: Reporting & Deliverables

**REQUIRED SUB-SKILL:** Use superhackers:writing-security-reports for detailed report writing methodology.

#### 5.1 Report Structure

```
1. Executive Summary (1-2 pages)
   - Assessment overview and scope
   - Key findings summary (Critical/High counts)
   - Overall risk posture assessment
   - Top 3 recommendations

2. Methodology
   - Testing approach and tools used
   - Assessment timeline
   - Limitations and caveats

3. Findings (bulk of report)
   - Ordered by severity (Critical → Info)
   - Each finding: description, evidence, impact, remediation, references
   - CVSS score and compliance mapping per finding

4. Risk Summary
   - Finding distribution by severity
   - Finding distribution by category
   - Trend analysis (if repeat assessment)

5. Remediation Roadmap
   - Prioritized action items
   - Quick wins (< 1 day effort)
   - Medium-term fixes (1-2 weeks)
   - Strategic improvements (1-3 months)

6. Appendices
   - Full vulnerability details
   - Tool output
   - Scope document
   - Testing evidence
```

#### 5.2 Stakeholder Communication Timeline

| Timing | Audience | Content | Format |
|--------|----------|---------|--------|
| Day 1 | Technical POC | Kickoff confirmation, scope finalized | Email |
| During testing | Technical POC | Emergency findings (Critical only) | Phone + email |
| Mid-engagement | Technical POC | Status update, preliminary findings | Email/call |
| End of testing | Technical POC | Draft report for fact-checking | Document |
| +3-5 days | Leadership + Technical | Final report presentation | Meeting + PDF |
| +30-60 days | Technical POC | Retest of remediated findings | Email + doc |

#### 5.3 Assessment Closeout Checklist

```markdown
## Closeout Checklist

### Evidence & Data
- [ ] All testing evidence organized and stored securely
- [ ] Client data purged from testing systems
- [ ] Credentials rotated or returned
- [ ] VPN/access tokens revoked
- [ ] Testing tools removed from client environment

### Deliverables
- [ ] Executive summary delivered
- [ ] Technical report delivered
- [ ] Raw findings exported (CSV/JSON if requested)
- [ ] Remediation roadmap included
- [ ] Presentation slides prepared (if requested)

### Follow-Up
- [ ] Retest date scheduled
- [ ] Remediation guidance provided for each finding
- [ ] Client questions addressed
- [ ] Lessons learned documented internally
```

## Common Mistakes

### 1. Starting Testing Without a Plan
**Wrong:** Jump straight into scanning and exploitation.
**Right:** Define scope, rules of engagement, threat model, and methodology FIRST. Testing without a plan leads to missed areas, scope creep, and client conflicts.

### 2. Using Only One Testing Approach
**Wrong:** Run automated scanners and report the output.
**Right:** Combine automated scanning, manual testing, and code review. Scanners miss business logic flaws, auth issues, and complex injection chains. Each approach catches what others miss.

### 3. Skipping Threat Modeling
**Wrong:** Test everything with equal depth.
**Right:** Build a threat model first to identify highest-risk areas. A threat model focusing testing on auth and payment flows is more valuable than broad shallow coverage.

### 4. Reporting Vulnerabilities Without Verification
**Wrong:** Report scanner output as confirmed findings.
**Right:** Verify every finding before including in the report. False positives destroy credibility.
**REQUIRED SUB-SKILL:** Use superhackers:vulnerability-verification for confirmation methodology.

### 5. Poor Severity Rating
**Wrong:** Using tool-assigned severity without context.
**Right:** Calculate CVSS manually and overlay business impact. A "Critical" finding on an internal dev server with no sensitive data is not the same as one on the production payment system.

### 6. Missing the Forest for the Trees
**Wrong:** Listing 150 individual findings without synthesis.
**Right:** Identify systemic issues. "50 XSS findings across the application indicate a systemic lack of output encoding, not 50 separate problems." Root cause analysis is more valuable than finding enumeration.

### 7. Incomplete Scope Coverage
**Wrong:** Spending all time on the main web app and ignoring APIs, mobile, or infra.
**Right:** Track coverage against the scope document. Use the testing tracker from Phase 3 to ensure every in-scope asset gets tested. Flag under-tested areas in the report.

### 8. Not Communicating Critical Findings Immediately
**Wrong:** Waiting until the final report to disclose a critical RCE.
**Right:** Follow the emergency finding protocol. If you find a critical vulnerability that is actively exploitable, notify the client IMMEDIATELY. Waiting until the report is irresponsible.

### 9. Ignoring Compliance Context
**Wrong:** Delivering findings without compliance mapping.
**Right:** Ask the client about their compliance requirements upfront. Map findings to OWASP Top 10, PCI DSS, SOC 2, or ISO 27001 as relevant. This makes findings actionable for compliance teams.

### 10. No Remediation Guidance
**Wrong:** "Fix the SQL injection."
**Right:** Provide specific, actionable remediation with code examples. Show the vulnerable code AND the fixed version. Include framework-specific guidance (e.g., "Use Django ORM's parameterized queries instead of raw SQL").
**REQUIRED SUB-SKILL:** Use superhackers:writing-security-reports for structured remediation guidance.

## Completion Criteria

This skill's work is DONE when ALL of the following are true:
- [ ] Scope boundaries are clearly defined (in-scope targets, out-of-scope exclusions)
- [ ] Engagement depth has been selected (Quick / Standard / Deep)
- [ ] Skill sequence has been determined (which testing skills apply to this target)
- [ ] Rules of engagement are documented (testing windows, restricted actions, escalation contacts)
- [ ] All todo items created during this phase are marked complete

When all conditions are met, state "Phase complete: security-assessment" and stop.
Transition to `recon-and-enumeration` as the next phase.
