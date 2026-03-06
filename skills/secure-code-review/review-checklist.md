# Security Code Review Checklist

**Load this reference when:** performing a security-focused code review, auditing a pull request, or doing a pre-engagement code assessment.

## How to Use This Checklist

Work through each section in order. Mark items as you go. The checklist is ordered by priority — authentication and injection issues first, configuration and best practices last.

**For each finding:** document the file, line number, CWE, and severity using the format in `superhackers:writing-security-reports`.

---

## Pre-Review: Orientation

Before diving into code, understand the landscape.

```
□ Identify primary language(s) and framework(s)
□ Identify entry points (HTTP routes, WebSocket handlers, GraphQL resolvers, CLI)
□ Identify data stores (SQL, NoSQL, cache, file system, cloud storage)
□ Identify authentication mechanism (JWT, session, OAuth, API key)
□ Identify external integrations (APIs, SMTP, DNS, cloud SDKs)
□ Note the deployment environment (cloud provider, container, serverless)
□ Check if static analysis tools are already configured (ESLint security rules, Bandit, etc.)
□ Review .gitignore for missing sensitive file exclusions
```

---

## P0: Authentication & Authorization

**Impact: Direct access control bypass. Review these FIRST.**

### Authentication

```
□ Password storage uses bcrypt/argon2/scrypt (NOT MD5/SHA1/SHA256 unsalted)
□ Password policy enforced server-side (not just client-side validation)
□ Login endpoint has rate limiting / account lockout
□ JWT tokens:
  □ Verified with explicit algorithm (not algorithms: ['HS256', 'RS256'])
  □ verify_signature is NOT disabled
  □ Expiration (exp) claim enforced
  □ Signing key is not hardcoded in source
□ Session tokens are cryptographically random (not sequential or predictable)
□ Session invalidation works on logout (server-side, not just cookie deletion)
□ Password reset tokens expire and are single-use
□ Multi-factor authentication endpoints can't be bypassed by skipping steps
□ OAuth/OIDC:
  □ state parameter validated (CSRF protection)
  □ redirect_uri strictly validated (not open redirect)
  □ Token exchange happens server-side (not in client JS)
```

### Authorization

```
□ Every API endpoint has server-side authorization check
□ Authorization checked on resource access, not just navigation
  (i.e., GET /api/users/123 checks if requester owns user 123)
□ Role checks use allowlists, not blocklists
  ("user must be admin" NOT "user must not be guest")
□ No horizontal privilege escalation (user A accessing user B's data)
□ No vertical privilege escalation (regular user accessing admin functions)
□ Admin endpoints not accessible by changing URL/method
□ GraphQL:
  □ Authorization on resolvers, not just UI-level
  □ Introspection disabled in production
  □ Query depth/complexity limited
□ File access operations check authorization (not just authentication)
```

---

## P1: Input Handling & Injection

**Impact: RCE, data theft, server compromise.**

### SQL Injection

```
□ All SQL queries use parameterized queries / prepared statements
□ No string concatenation in SQL (f-strings, +, format, %)
□ ORM used correctly (no raw() queries with user input)
□ Stored procedures don't build dynamic SQL with user input
□ Search/filter endpoints parameterize LIKE clauses and ORDER BY
□ Database user has minimum required privileges (not DBA/root)
```

### Command Injection

```
□ No os.system(), subprocess with shell=True, exec(), or backticks with user input
□ If shell commands necessary: use array form (subprocess.run(['cmd', arg]))
□ User input validated against strict allowlist before use in commands
□ No user input in file paths passed to shell commands
```

### Template Injection (SSTI)

```
□ No render_template_string() or Template() with user input
□ No eval(), new Function(), vm.runInNewContext() with user input
□ Template engine auto-escaping is enabled (not disabled per-template)
□ No |safe, Markup(), or {% autoescape false %} on user-controlled data
```

### XSS Prevention

```
□ Output encoding applied for context (HTML, JavaScript, URL, CSS)
□ No innerHTML, outerHTML, document.write() with user input
□ No dangerouslySetInnerHTML with unsanitized data
□ CSP header configured (script-src without 'unsafe-inline')
□ Cookie flags set: HttpOnly, Secure, SameSite
□ User-generated HTML sanitized with allowlist-based sanitizer (not regex)
```

### Deserialization

```
□ No pickle.loads() / pickle.load() on untrusted data
□ yaml.safe_load() used instead of yaml.load()
□ No ObjectInputStream.readObject() on untrusted data
□ No unserialize() on untrusted data (PHP)
□ JSON preferred over language-specific serialization formats
```

---

## P2: Cryptography & Data Protection

**Impact: Data exposure, key compromise, regulatory violations.**

### Encryption

```
□ AES-GCM or AES-CBC with HMAC (NOT AES-ECB)
□ Key size ≥ 256 bits for AES, ≥ 2048 for RSA, ≥ 256 for EC
□ Keys stored in environment variables or secrets manager (NOT source code)
□ IVs/nonces are random and unique per operation (NOT static or reused)
□ TLS 1.2+ enforced for all external communications
□ Certificate verification NOT disabled (verify=False, InsecureSkipVerify)
□ No deprecated algorithms (DES, 3DES, RC4, Blowfish for sensitive data)
```

### Hashing

```
□ Passwords: bcrypt (work factor ≥ 12), argon2, or scrypt
□ NOT MD5, SHA1, or SHA256 without salt for passwords
□ HMAC used for message authentication (not plain hash)
□ Timing-safe comparison for secrets (hmac.compare_digest, not ==)
```

### Randomness

```
□ Security-sensitive randomness uses crypto PRNG:
  - Python: secrets module or os.urandom()
  - Node.js: crypto.randomBytes() or crypto.randomUUID()
  - Java: SecureRandom
  - Go: crypto/rand
□ NOT Math.random(), random.random(), rand(), srand()
```

---

## P2: SSRF & Network Access

**Impact: Internal network access, cloud credential theft.**

```
□ User-supplied URLs validated against allowlist (not blocklist)
□ URL validation happens AT REQUEST TIME (not earlier — DNS rebinding)
□ Private IP ranges blocked (127.0.0.0/8, 10.0.0.0/8, 172.16.0.0/12,
  192.168.0.0/16, 169.254.0.0/16)
□ Non-HTTP protocols blocked (file://, gopher://, dict://)
□ Redirects limited or disabled in server-side requests
□ DNS resolution result checked against blocked ranges
□ Cloud metadata endpoint (169.254.169.254) explicitly blocked
```

---

## P2: Host Header Injection

**Impact: Cache poisoning, password reset poisoning, access control bypass, phishing.**

```
□ Host header validated against allowlist before security-sensitive use
□ Password reset/verification URLs use configured base URL (not request.Host)
□ Redirects do not use Host header for destination (use allowlist or config)
□ X-Forwarded-Host, X-Forwarded-Server not trusted without proxy validation
□ CRLF injection prevented in Host header parsing
□ Framework protections enabled:
  - Django: ALLOWED_HOSTS is specific (not ['*'])
  - Express: trust proxy disabled or set to specific IPs
  - Rails: config.hosts restricted (not /.*/)
□ URL generation uses safe base URL from config/env vars
□ No business logic tied to Host header (auth bypass, feature flags)
□ Cache keys not solely dependent on Host header (or validated)
```

---

## P2: File Handling

**Impact: Path traversal, arbitrary file read/write, RCE via upload.**

```
□ User-supplied filenames sanitized (no ../, no absolute paths)
□ Path.resolve() + startsWith() validation for file access
□ File uploads:
  □ File type validated server-side (magic bytes, not just extension)
  □ Filename sanitized (strip path components, generate random name)
  □ Upload directory outside web root (no direct URL access)
  □ File size limited
  □ Content-Type verified (not just trusted from client)
  □ No executable permissions on upload directory
□ No symlink following in user-controlled paths
□ Temp files created with secure permissions
```

---

## P3: Configuration & Headers

**Impact: Information disclosure, clickjacking, protocol downgrade.**

### Security Headers

```
□ Content-Security-Policy set (script-src without 'unsafe-inline' 'unsafe-eval')
□ Strict-Transport-Security set (max-age ≥ 31536000, includeSubDomains)
□ X-Content-Type-Options: nosniff
□ X-Frame-Options: DENY (or CSP frame-ancestors)
□ Referrer-Policy configured (strict-origin-when-cross-origin or stricter)
□ Permissions-Policy set (camera, microphone, geolocation restricted)
```

### CORS

```
□ Access-Control-Allow-Origin NOT set to * for authenticated endpoints
□ Origin NOT reflected without validation
□ Credentials (withCredentials) not allowed with wildcard origin
□ Allowed methods and headers explicitly listed
```

### Error Handling

```
□ Stack traces not exposed in production responses
□ Database error messages not leaked to client
□ Custom error pages for 4xx/5xx (no framework defaults)
□ Debug mode disabled in production
□ Verbose logging server-side only (not in API responses)
```

---

## P3: Secrets in Code

**Impact: Credential exposure, account compromise.**

```
□ No API keys in source code (check for AWS: AKIA*, Google: AIza*, etc.)
□ No private keys committed (BEGIN RSA PRIVATE, BEGIN EC PRIVATE)
□ No connection strings with passwords in source
□ No hardcoded JWT secrets
□ .env files excluded from version control
□ Secrets managed via environment variables or secrets manager
□ No credentials in CI/CD pipeline configuration files (check GitHub Actions,
  Jenkinsfile, .gitlab-ci.yml)
□ No tokens in URL query strings (logged in server access logs)
```

---

## P4: Business Logic

**Impact: Context-dependent, often high. Requires understanding application purpose.**

```
□ Race conditions: concurrent requests can't bypass limits
  (double-spending, multiple redemptions, quota bypass)
□ Rate limiting on sensitive operations (password reset, OTP verify, API calls)
□ Numeric limits enforced server-side (negative amounts, integer overflow)
□ Multi-step processes can't skip steps (checkout, password reset, MFA)
□ Unique constraints enforced at database level (not just application)
□ Idempotency keys for financial operations
□ Audit logging for security-relevant actions (login, privilege change,
  data access, admin operations)
```

---

## P5: Dependencies & Supply Chain

```
□ Lock file present and committed (package-lock.json, poetry.lock, go.sum)
□ No known CVEs in direct dependencies (npm audit, pip audit, govulncheck)
□ No abandoned/unmaintained packages (check last commit date)
□ No typosquatting risk (verify package names match official)
□ Dependency versions pinned (not using * or latest)
□ Sub-resource integrity for CDN-loaded scripts
```

---

## Post-Review: Findings Compilation

```
□ All findings have: file path, line number, CWE, CVSS, severity
□ Findings prioritized by exploitability × impact
□ Vulnerable code AND fixed code provided for each finding
□ False positives eliminated (framework protections considered)
□ Positive observations documented (what's done well)
□ Chain exploitation opportunities identified
```

## Severity Assignment Quick Reference

| Finding | Typical Severity | Adjust If... |
|---------|-----------------|-------------|
| SQLi with data extraction | Critical (9.1) | Lower if auth required (7.2) |
| RCE via deserialization | Critical (9.8) | Lower if local only (7.8) |
| Stored XSS | Medium-High (5.4-6.1) | Higher if admin context (8.0+) |
| IDOR read access | Medium (6.5) | Higher if sensitive data (8.1+) |
| Hardcoded credentials | High (7.5) | Critical if admin/prod creds |
| Missing security header | Low (3.1) | Info if CSP covers it |
| Debug mode in prod | Medium (5.3) | Higher if exposes secrets |
| Weak password policy | Low (3.7) | Higher if no rate limiting |

---

Cross-reference: Use `superhackers:vulnerability-verification` to confirm findings are exploitable before reporting. Use `superhackers:writing-security-reports` to compile findings into deliverables.
