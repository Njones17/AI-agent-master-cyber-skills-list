---
name: gen-report
description: Generates a professional security report from findings. Supports pentest, vulnerability assessment, bug bounty, code review, and IR post-mortem formats. Pass the report type and any notes or findings as arguments.
argument-hint: "[pentest|vuln|bugbounty|codereview|ir] [optional: findings notes or path]"
disable-model-invocation: true
---

# Generate Security Report: $ARGUMENTS

Parse the arguments to determine report type and any provided context.

**Report types:**
- `pentest` → Full penetration test report
- `vuln` → Vulnerability assessment report
- `bugbounty` → Bug bounty submission
- `codereview` → Code security review
- `ir` → Incident response post-mortem

## Step 1: Gather Findings

If findings haven't been provided inline, ask the user to supply them in any format:
- Paste raw notes
- List bullet points of what was found
- Reference a findings/ directory to read from
- Provide scanner output to parse

Read any files in `findings/` subdirectories if they exist in the current engagement directory.

## Step 2: Normalize Findings

For each finding, extract or ask for:
1. **Title** — one-line descriptive name
2. **Severity** — Critical/High/Medium/Low/Info
3. **Affected component** — URL, IP, file, service
4. **Description** — what is the vulnerability
5. **Evidence** — screenshot reference, HTTP request, tool output
6. **Impact** — what can an attacker do
7. **Remediation** — specific fix

If any field is missing, prompt for it before generating the report. A finding without evidence or remediation is incomplete.

## Step 3: Load the Appropriate Template

Read the template from the templates directory:
- Pentest: `templates/pentest-report/PENTEST-REPORT.md`
- Vuln assessment: `templates/vulnerability-assessment/VULN-ASSESSMENT.md`
- Bug bounty: `templates/bug-bounty/BUG-BOUNTY-REPORT.md`
- Code review: `templates/code-security-review/CODE-SECURITY-REVIEW.md`
- IR post-mortem: `templates/incident-response/IR-POST-MORTEM.md`

## Step 4: Populate the Template

Fill in all sections with actual content. Rules:
- Remove all placeholder text — no `[example]` or `[description here]` in the final output
- Order findings by severity: Critical → High → Medium → Low → Informational
- Number findings sequentially: F-001, F-002... or CR-001, VA-001... per template convention
- Executive summary must be jargon-free and answer: what was tested, what was found, what's the risk, what to do first
- Every finding must have: severity, evidence reference, specific remediation
- Remediation roadmap must have timeline tiers (immediate / 30-day / 90-day)
- CVSS vectors required for Critical and High findings

## Step 5: CVSS Scoring Assistance

For any finding missing a CVSS score, calculate it:

Ask about each metric:
1. **AV** — Is this network-accessible (N), adjacent network (A), local (L), or physical (P)?
2. **AC** — Is exploitation straightforward (L) or requires specific conditions (H)?
3. **PR** — No auth needed (N), low-privilege account (L), or admin (H)?
4. **UI** — No user interaction needed (N), or victim must do something (R)?
5. **S** — Does impact stay within the vulnerable component (U), or extend beyond (C)?
6. **C/I/A** — What's the impact on confidentiality, integrity, availability? None/Low/High each.

Calculate the score and produce the vector string.

## Step 6: ATT&CK Mapping

For pentest and IR reports, map each significant finding to an ATT&CK technique:

Common mappings:
- SQL injection → T1190 (Exploit Public-Facing Application)
- Credential reuse → T1078 (Valid Accounts)
- XSS → T1059.007 (JavaScript) + T1185 (Browser Session Hijacking)
- Directory traversal → T1083 (File and Directory Discovery)
- SSRF → T1090 (Proxy) or T1010 (Application Window Discovery)
- Weak passwords → T1110 (Brute Force)
- Exposed secrets → T1552 (Unsecured Credentials)
- RCE via deserialization → T1059 (Command and Scripting Interpreter)

If MITRE ATT&CK MCP is available, use it to look up the precise technique and tactic.

## Step 7: Output the Report

Write the completed report to a file:
- `engagement-<target>/report-draft-YYYY-MM-DD.md`
- Or `report-<type>-YYYY-MM-DD.md` if no engagement directory exists

After writing:
1. Display a summary of what was included
2. List any sections that still need user input (e.g., screenshots not yet referenced)
3. Note any findings that were incomplete and what's still needed

## Quality Check Before Finalizing

Run through this checklist mentally before outputting:

- [ ] Executive summary is non-technical and business-focused
- [ ] Every finding has severity + CVSS + evidence + remediation
- [ ] No placeholder text remains
- [ ] Findings ordered by severity
- [ ] Remediation roadmap has specific owners and timelines
- [ ] No false precision — only claim what was actually confirmed
- [ ] ATT&CK IDs included for significant findings (pentest/IR only)
- [ ] Word count appropriate — not padded, not missing critical detail
