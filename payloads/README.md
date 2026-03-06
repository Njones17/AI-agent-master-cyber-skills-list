# Payload Library

Curated, annotated security testing payloads organized by vulnerability class.

| Category | File | What's Inside |
|---|---|---|
| [`xss/`](xss/) | `xss-payloads.md` | Reflected, stored, DOM, blind XSS; polyglots; WAF bypasses; CSP bypasses; impact escalation ladder |
| [`sqli/`](sqli/) | `sqli-payloads.md` | Auth bypass, union-based, blind boolean/time, OOB, error-based, file read/write; MySQL/MSSQL/PostgreSQL/Oracle; sqlmap cheatsheet |
| [`ssrf/`](ssrf/) | `ssrf-payloads.md` | Cloud metadata (AWS/GCP/Azure/DO), internal service discovery, localhost bypasses, protocol handlers (gopher/file/dict), filter bypass table |
| [`cmdi/`](cmdi/) | `cmdi-payloads.md` | Linux/Windows detection, reverse shells (bash/python/nc/powershell), WAF bypasses, blind exfiltration, argument injection |
| [`ssti/`](ssti/) | `ssti-payloads.md` | Engine fingerprinting, Jinja2/Twig/FreeMarker/Velocity/ERB/Pebble/Smarty/Handlebars RCE payloads, filter bypasses |
| [`jwt/`](jwt/) | `jwt-payloads.md` | Algorithm none, RS256/HS256 confusion, weak secret cracking, kid injection, jku/x5u header injection, jwt_tool cheatsheet |
| [`path-traversal/`](path-traversal/) | `path-traversal-payloads.md` | Linux/Windows target files, encoding bypasses, PHP wrappers, log poisoning → RCE, RFI |
| [`wordlists/`](wordlists/) | `wordlists-reference.md` | SecLists paths, top passwords, default creds, common API endpoints, backup files, ffuf cheatsheet |

## Usage

Load any payload file when testing the relevant vulnerability class. To use with Claude:

> "Load the XSS payload library and help me test the profile bio field"
> "What SSRF payloads should I try to hit the AWS metadata endpoint?"
> "Show me SQLi auth bypass payloads for a login form"

## Payload Selection Workflow

1. Identify the vulnerability class from recon/initial testing
2. Load the relevant payload file
3. Start with **detection** payloads — smallest, least disruptive, confirm the bug exists
4. Escalate to **impact** payloads only after detection is confirmed
5. Try **WAF bypass** variants if initial payloads are blocked

## Ethics

All payloads are for **authorized security testing only**.
Never use these against systems you don't have explicit written permission to test.
