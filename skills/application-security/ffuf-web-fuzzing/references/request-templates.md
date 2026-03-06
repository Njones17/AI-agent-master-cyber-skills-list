# Authenticated Request Templates

Pre-built `req.txt` templates for common authenticated fuzzing scenarios. Save the template, replace placeholders with real values, insert `FUZZ` where needed.

## Bearer Token (JWT / OAuth)

```http
GET /api/v1/users/FUZZ HTTP/1.1
Host: api.target.com
Authorization: Bearer YOUR_TOKEN_HERE
Accept: application/json
Content-Type: application/json
```

```bash
ffuf --request req.txt -w wordlist.txt -ac -mc 200,201 -o results.json
```

## Session Cookie + CSRF Token

```http
POST /api/account/update HTTP/1.1
Host: app.target.com
Cookie: sessionid=YOUR_SESSION_ID; csrftoken=YOUR_CSRF_TOKEN
X-CSRF-Token: YOUR_CSRF_TOKEN
Content-Type: application/x-www-form-urlencoded

field=FUZZ&action=update
```

```bash
ffuf --request req.txt -w payloads.txt -ac -fc 403 -o results.json
```

## API Key Header

```http
GET /v2/data/FUZZ HTTP/1.1
Host: api.target.com
X-API-Key: YOUR_API_KEY_HERE
Accept: application/json
```

```bash
ffuf --request req.txt -w endpoints.txt -ac -mc 200 -o results.json
```

## POST JSON with Auth

```http
POST /api/v1/query HTTP/1.1
Host: api.target.com
Authorization: Bearer YOUR_TOKEN_HERE
Content-Type: application/json
Accept: application/json

{"query":"FUZZ","limit":100,"offset":0}
```

```bash
ffuf --request req.txt -w sqli-payloads.txt -ac -fr "error" -o results.json
```

## Multiple FUZZ Points (Custom Keywords)

```http
GET /api/v1/users/USER_ID/documents/DOC_ID HTTP/1.1
Host: api.target.com
Authorization: Bearer YOUR_TOKEN_HERE
Accept: application/json
```

```bash
ffuf --request req.txt \
     -w user_ids.txt:USER_ID \
     -w doc_ids.txt:DOC_ID \
     -mode pitchfork \
     -ac -mc 200 \
     -o idor_results.json
```

## GraphQL Query

```http
POST /graphql HTTP/1.1
Host: api.target.com
Authorization: Bearer YOUR_TOKEN_HERE
Content-Type: application/json
Accept: application/json

{"query":"query { user(id: \"FUZZ\") { id username email role } }","variables":{}}
```

```bash
ffuf --request req.txt -w user-ids.txt -ac -mc 200 -mr '"email"' -o results.json
```

## How to Capture Your Own Request

### From Burp Suite
1. Intercept the authenticated request
2. Right-click > "Copy to file" > save as `req.txt`
3. Replace the fuzz target with `FUZZ`

### From Browser DevTools
1. Open DevTools (F12) > Network tab
2. Perform the authenticated action
3. Right-click the request > Copy > Copy as cURL
4. Convert to raw HTTP format, insert `FUZZ`

### From a curl command
```bash
# If you have:
curl 'https://api.target.com/users/123' -H 'Authorization: Bearer TOKEN'

# Convert to:
GET /users/FUZZ HTTP/1.1
Host: api.target.com
Authorization: Bearer TOKEN
```

## Tips

- ffuf adjusts `Content-Length` automatically
- Use custom keywords (`USER_ID`, `DOC_ID`) with `-w wordlist.txt:KEYWORD` for multiple fuzz points
- Test your `req.txt` with a single-value wordlist first to verify it works
- Have a token refresh strategy ready for short-lived tokens
- Default protocol is HTTPS; use `-request-proto http` for HTTP-only targets
