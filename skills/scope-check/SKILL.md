---
name: scope-check
description: Verifies whether a target (IP, domain, URL, or system) is within the authorized scope of the current engagement before testing begins. Always run this before touching a new target. Reads scope.md from the current engagement directory if it exists.
argument-hint: "[IP address | domain | URL | system name]"
disable-model-invocation: true
allowed-tools: Read, Glob
---

# Scope Check: $ARGUMENTS

Before testing any target, verify it is explicitly authorized. Unauthorized testing is illegal and unethical.

## Step 1: Load Current Scope

Look for a scope file in the current directory or engagement directory:

1. Check for `scope.md` in current directory
2. Check for `engagement-*/scope.md`
3. Check for `.claude/scope.md`

If found, read it and extract:
- In-scope targets (IPs, CIDR ranges, domains, URLs)
- Out-of-scope targets
- Testing constraints (time windows, techniques)

If no scope file found, ask the user to provide scope information before proceeding.

## Step 2: Normalize the Target

Parse the provided target:
- **IP address:** Check if it falls within any in-scope CIDR ranges
- **Domain:** Check for exact match and wildcard matches (e.g., `*.example.com`)
- **URL:** Extract hostname, check domain, then check path restrictions
- **Hostname:** Resolve or check against known in-scope hostnames

## Step 3: Scope Determination

**IN SCOPE if:**
- IP is within an explicitly listed CIDR range
- Domain exactly matches or is a subdomain of an in-scope domain
- URL path is not explicitly excluded
- System name appears in the in-scope list

**OUT OF SCOPE if:**
- IP, domain, or URL appears in the explicit out-of-scope list
- Domain is not a subdomain of any in-scope domain
- System belongs to a third party (CDN, SaaS, hosting provider) unless explicitly included
- Testing window is currently outside the authorized hours

**UNCLEAR if:**
- IP or domain is adjacent to in-scope systems but not explicitly listed
- System was discovered during recon and wasn't in the original scope
- Third-party component that may or may not be in scope

## Step 4: Output Verdict

Produce a clear verdict with reasoning:

### ✅ IN SCOPE
```
TARGET: $ARGUMENTS
VERDICT: IN SCOPE
REASON: [IP falls within authorized range X.X.X.0/24 / Domain is subdomain of example.com / Explicitly listed]
RESTRICTIONS: [Any specific testing restrictions that apply]
CLEARED TO TEST: Yes
```

### 🚫 OUT OF SCOPE
```
TARGET: $ARGUMENTS
VERDICT: OUT OF SCOPE
REASON: [Explicitly excluded / Not within authorized range / Third-party system]
CLEARED TO TEST: No

DO NOT TEST THIS TARGET.
Document that you encountered this during the engagement.
Notify the client if appropriate (e.g., if it represents a path to in-scope systems).
```

### ⚠️ UNCLEAR — CONFIRM BEFORE TESTING
```
TARGET: $ARGUMENTS
VERDICT: UNCLEAR
REASON: [Target discovered during recon but not explicitly in scope / Adjacent to in-scope range]
CLEARED TO TEST: NO — CONFIRM FIRST

Action required:
1. Contact the engagement owner / client before testing
2. Get explicit written confirmation that this target is authorized
3. Do not test until confirmed

Suggested message to client:
"During reconnaissance on [in-scope target], we discovered [new target]. 
Is [new target] within scope for this engagement? Please confirm in writing."
```

## Step 5: Third-Party Assessment

For any target, also check:

- **CDN providers:** Cloudflare, Akamai, Fastly — testing these may be out of scope even if the domain is in scope. Clarify with client.
- **Cloud infrastructure:** AWS, GCP, Azure — shared infrastructure has separate terms of service. Verify if cloud testing is explicitly authorized.
- **SaaS applications:** Salesforce, Workday, etc. — these are almost never in scope without explicit authorization from the vendor.
- **ISPs and hosting:** Testing upstream network providers is never in scope.

## Step 6: Log the Check

Append to the engagement notes if a notes file exists:

```
[TIMESTAMP] Scope check: $ARGUMENTS → [IN SCOPE / OUT OF SCOPE / UNCLEAR]
```

This creates an audit trail showing due diligence on scope verification.
