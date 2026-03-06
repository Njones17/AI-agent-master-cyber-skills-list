# Wordlist Selection Guide

Choose wordlists based on the target stack and engagement scope. All paths are relative to your SecLists installation directory.

## By Scenario

### Directory and File Discovery

| Scope | Wordlist | Entries | When to use |
|-------|----------|---------|-------------|
| Quick scan | `Discovery/Web-Content/common.txt` | ~4.6k | Initial recon, time-limited engagements |
| Standard | `Discovery/Web-Content/directory-list-2.3-medium.txt` | ~220k | Default for most engagements |
| Thorough | `Discovery/Web-Content/directory-list-2.3-big.txt` | ~1.2M | High-value targets, long engagements |
| Raft (dirs) | `Discovery/Web-Content/raft-large-directories.txt` | - | Alternative to directory-list, good coverage |
| Raft (files) | `Discovery/Web-Content/raft-large-files.txt` | - | Focused on file discovery |

### API Testing

| Wordlist | When to use |
|----------|-------------|
| `Discovery/Web-Content/api/api-endpoints.txt` | REST API endpoint discovery |
| `Discovery/Web-Content/common-api-endpoints-mazen160.txt` | Broader API path fuzzing |
| `Discovery/Web-Content/swagger-parameters.txt` | Finding Swagger/OpenAPI docs |

### Subdomain Discovery

| Wordlist | Entries | When to use |
|----------|---------|-------------|
| `Discovery/DNS/subdomains-top1million-5000.txt` | 5k | Quick subdomain check |
| `Discovery/DNS/subdomains-top1million-20000.txt` | 20k | Standard engagement |
| `Discovery/DNS/subdomains-top1million-110000.txt` | 110k | Thorough enumeration |
| `Discovery/DNS/namelist.txt` | - | Combined/alternative list |

### Parameter Names

| Wordlist | When to use |
|----------|-------------|
| `Discovery/Web-Content/burp-parameter-names.txt` | GET/POST parameter discovery |
| `Discovery/Web-Content/raft-large-words.txt` | Broader parameter fuzzing |

### Backup and Config Files

| Wordlist | When to use |
|----------|-------------|
| `Discovery/Web-Content/backup-files-only.txt` | Finding .bak, .old, .save files |
| `Discovery/Web-Content/Common-DB-Backups.txt` | Database dump discovery |

### Technology-Specific

| Wordlist | Stack |
|----------|-------|
| `Discovery/Web-Content/PHP.fuzz.txt` | PHP applications |
| `Discovery/Web-Content/IIS.fuzz.txt` | ASP/ASP.NET on IIS |
| `Discovery/Web-Content/Apache.fuzz.txt` | Apache web servers |
| `Discovery/Web-Content/git-head-potential-file-exposure.txt` | Git repo exposure |

## File Extensions by Technology

Add with `-e` flag. Match extensions to the target stack.

| Stack | Extensions |
|-------|-----------|
| PHP | `.php .php3 .php4 .php5 .phtml .phps` |
| ASP/ASP.NET | `.asp .aspx .ashx .asmx .axd` |
| JSP/Java | `.jsp .jspx .jsw .jsv .jspf` |
| Python | `.py .pyc .pyo` |
| Ruby | `.rb .rhtml` |
| Node.js | `.js .json` |
| Backup/Interesting | `.bak .backup .old .save .tmp .swp .git .env .config .conf .log .sql .db .sqlite` |
