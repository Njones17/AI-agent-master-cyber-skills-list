---
name: using-payload-library
description: Guides Claude in selecting and using the right security testing payloads from the payload library. Use when testing web application vulnerabilities, choosing attack vectors, or escalating from detection to impact. Automatically loads the relevant payload file based on vulnerability type.
---

# Using the Payload Library

## Payload Selection by Vulnerability

| Situation | Load |
|---|---|
| Input reflects back in HTML output | `payloads/xss/xss-payloads.md` |
| Input appears in a database query | `payloads/sqli/sqli-payloads.md` |
| Application fetches a URL you control | `payloads/ssrf/ssrf-payloads.md` |
| Input appears in a system command | `payloads/cmdi/cmdi-payloads.md` |
| Input renders in a template engine | `payloads/ssti/ssti-payloads.md` |
| JWT authentication is used | `payloads/jwt/jwt-payloads.md` |
| File path is user-controlled | `payloads/path-traversal/path-traversal-payloads.md` |
| Need directory/subdomain lists | `payloads/wordlists/wordlists-reference.md` |

## Testing Order (Always Follow This)

1. **Detect** — Use the minimal detection payload to confirm the bug exists
   - XSS: `<script>alert(1)</script>`
   - SQLi: `'` (single quote) — look for error or behavior change
   - SSRF: Replace URL with Burp Collaborator/interactsh URL — look for callback
   - CMDi: `; sleep 5` — look for time delay
   - SSTI: `{{7*7}}` — look for `49` in response
   - Path traversal: `../../../../etc/passwd` — look for passwd content

2. **Confirm** — Verify the behavior is consistent and reproducible

3. **Impact** — Escalate to show real impact
   - XSS: Cookie theft, session hijacking
   - SQLi: Data extraction, auth bypass
   - SSRF: Cloud metadata, internal service access
   - CMDi: Reverse shell, data exfiltration
   - SSTI: RCE, file read
   - Path traversal: Read sensitive files, log poisoning

4. **Document** — Screenshot/capture every step before moving on

## WAF Bypass Strategy

If initial payloads are blocked:
1. Check if WAF is blocking or just the app returning an error
2. Try encoding variants (URL encode, double encode, HTML encode)
3. Try case variations and whitespace substitutes
4. Try alternative syntax for the same operation
5. Use the WAF bypass section in the relevant payload file

## Payload Modification Guidelines

Never use payloads exactly as written without considering context:
- Replace `attacker.com` with your actual callback server
- Replace `4444` with your actual listener port
- Adjust traversal depth (`../../../../`) based on app's working directory
- Use application-specific separators (the app may use `|` not `;` for commands)

## Confirming No False Positives

Before reporting any finding:
- Reproduce it twice with slightly different payloads
- Confirm the response contains what you expect
- For time-based: run the baseline (no payload) first to establish normal response time
- For DNS callbacks: confirm the DNS query came from the target server, not your browser
