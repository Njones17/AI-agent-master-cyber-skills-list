# Wordlists Reference

> Don't ship massive wordlists in this repo. Reference SecLists and use targeted lists.
> Install SecLists: `sudo apt install seclists` or clone https://github.com/danielmiessler/SecLists

---

## SecLists Paths Reference

### Directory/Path Discovery
```
/usr/share/seclists/Discovery/Web-Content/common.txt               ← 4,700 entries — fast, good coverage
/usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt  ← 220k entries — thorough
/usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt    ← 30k — high quality
/usr/share/seclists/Discovery/Web-Content/api/api-endpoints.txt   ← API endpoints
/usr/share/seclists/Discovery/Web-Content/swagger.txt             ← API docs paths
/usr/share/seclists/Discovery/Web-Content/big.txt                 ← 20k entries
```

### Subdomain Enumeration
```
/usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt  ← quick
/usr/share/seclists/Discovery/DNS/subdomains-top1million-20000.txt ← medium
/usr/share/seclists/Discovery/DNS/namelist.txt                     ← 1.5M entries
/usr/share/seclists/Discovery/DNS/dns-Jhaddix.txt                  ← curated by Jason Haddix
```

### Parameters / Fuzzing
```
/usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt ← common param names
/usr/share/seclists/Fuzzing/SQLi/Generic-SQLi.txt
/usr/share/seclists/Fuzzing/XSS/XSS-Jhaddix.txt
/usr/share/seclists/Fuzzing/LFI/LFI-Jhaddix.txt
```

### Passwords
```
/usr/share/seclists/Passwords/Leaked-Databases/rockyou.txt.tar.gz  ← classic
/usr/share/seclists/Passwords/Common-Credentials/10-million-password-list-top-10000.txt
/usr/share/seclists/Passwords/Common-Credentials/top-passwords-shortlist.txt  ← 25 common
/usr/share/seclists/Passwords/Default-Credentials/default-passwords.txt
```

### Usernames
```
/usr/share/seclists/Usernames/top-usernames-shortlist.txt    ← 17 most common
/usr/share/seclists/Usernames/Names/names.txt                ← first names
/usr/share/seclists/Usernames/xato-net-10-million-usernames-dup.txt
```

---

## Built-In Quick Lists

### Top 25 Passwords
```
123456
password
12345678
qwerty
123456789
12345
1234
111111
1234567
dragon
123123
baseball
abc123
football
monkey
letmein
shadow
master
666666
qwertyuiop
123321
mustang
1234567890
michael
654321
```

### Top 20 Default Credentials
```
admin:admin
admin:password
admin:123456
admin:(blank)
root:root
root:password
root:toor
root:(blank)
admin:admin123
user:user
guest:guest
test:test
admin:Pass123
administrator:password
admin:changeme
pi:raspberry
ubnt:ubnt
cisco:cisco
netgear:netgear
(blank):(blank)
```

### Common API Endpoints
```
/api
/api/v1
/api/v2
/api/v3
/swagger
/swagger-ui
/swagger-ui.html
/api-docs
/openapi.json
/openapi.yaml
/graphql
/graphiql
/playground
/health
/healthz
/metrics
/status
/info
/debug
/console
/admin
/api/admin
/api/users
/api/auth
/api/login
/api/register
/api/token
/api/refresh
```

### Common Backup/Config Files
```
.env
.env.local
.env.backup
.env.bak
.env.old
config.php
config.bak
config.php.bak
database.yml
settings.py
settings.py.bak
wp-config.php
wp-config.php.bak
application.properties
application.yml
appsettings.json
web.config
.git/config
.git/HEAD
.svn/entries
.DS_Store
Thumbs.db
robots.txt
sitemap.xml
crossdomain.xml
phpinfo.php
info.php
test.php
```

### Sensitive Paths to Always Check
```
/admin
/administrator
/login
/wp-admin
/wp-login.php
/phpmyadmin
/pma
/mysql
/cpanel
/plesk
/.git
/.svn
/.htaccess
/.htpasswd
/server-status
/server-info
/jmx-console
/web-console
/manager/html
/actuator
/actuator/env
/actuator/heapdump
/env
/console
/h2-console
```

---

## ffuf Quick Reference

```bash
# Directory fuzzing
ffuf -w /usr/share/seclists/Discovery/Web-Content/common.txt -u https://target.com/FUZZ

# File fuzzing with extensions
ffuf -w /usr/share/seclists/Discovery/Web-Content/common.txt -u https://target.com/FUZZ -e .php,.html,.txt,.bak,.old

# Subdomain fuzzing
ffuf -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt -u https://FUZZ.target.com -H "Host: FUZZ.target.com"

# Parameter fuzzing (GET)
ffuf -w /usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt -u "https://target.com/page?FUZZ=test"

# Parameter value fuzzing
ffuf -w payloads.txt -u "https://target.com/page?id=FUZZ"

# POST body fuzzing
ffuf -w /usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt -u https://target.com/login -X POST -d "FUZZ=admin" -H "Content-Type: application/x-www-form-urlencoded"

# Filter by response code, size, or words
ffuf -w wordlist.txt -u https://target.com/FUZZ -fc 404 -fs 1234 -fw 10

# Rate limiting
ffuf -w wordlist.txt -u https://target.com/FUZZ -rate 50
```
