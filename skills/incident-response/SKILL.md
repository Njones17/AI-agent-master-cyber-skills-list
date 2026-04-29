---
name: incident-response
description: "Triage security alerts, execute containment and eradication playbooks, collect volatile forensic evidence, coordinate breach communication, and conduct post-incident reviews. Use when responding to a security breach, compromise, ransomware event, phishing incident, or SOC alert escalation, or when building incident response runbooks and tabletop exercises."
license: MIT
metadata:
  author: devops-skills
  version: "1.0"
---

# Incident Response

Execute structured incident response from initial alert through post-incident review.

## Severity Classification

| Level | Impact | Response Time |
|-------|--------|---------------|
| Critical | Data breach, full outage | Immediate |
| High | Service degraded, potential breach | < 1 hour |
| Medium | Limited impact, contained | < 4 hours |
| Low | Minimal impact | Next business day |

## Workflow

### Step 1: Detect and Triage

Confirm the alert is a true positive and classify severity.

```bash
# Query SIEM for correlated events around the alert
# Example: Splunk query for brute-force pattern
index=auth sourcetype=linux_secure "Failed password" | stats count by src_ip | where count > 50

# Check if source IP appears in threat intel feeds
# Check if affected account has elevated privileges
```

**Checkpoint**: Alert confirmed as true positive and severity classified before activating response team.

### Step 2: Contain the Threat

Isolate affected systems while preserving evidence.

```bash
# Network isolation
iptables -A INPUT -s <compromised-ip> -j DROP
iptables -A OUTPUT -d <compromised-ip> -j DROP

# Disable compromised accounts
passwd -l <compromised-user>
```

**Checkpoint**: Verify no new outbound connections from isolated hosts (`ss -tunapl | grep <compromised-ip>`) before collecting evidence.

### Step 3: Collect Volatile Evidence

Capture ephemeral state before remediation destroys it.

```bash
# Running processes with full command lines
ps auxww > /evidence/$(hostname)_procs_$(date +%Y%m%d_%H%M%S).txt

# Active network connections
ss -tunapl > /evidence/$(hostname)_conns_$(date +%Y%m%d_%H%M%S).txt

# Login history
w > /evidence/$(hostname)_active_users.txt
last -a -n 100 > /evidence/$(hostname)_login_history.txt

# Preserve logs before rotation
tar czf /evidence/$(hostname)_logs_$(date +%Y%m%d).tar.gz /var/log/

# Hash all evidence files
sha256sum /evidence/* > /evidence/checksums.sha256
```

**Checkpoint**: All evidence files timestamped and hash-verified before any eradication begins.

### Step 4: Eradicate and Recover

Remove attacker presence, patch the entry vector, and restore services.

```bash
# Kill malicious processes
kill -9 <malicious-pid>

# Check for persistence mechanisms
crontab -l -u <compromised-user>
find /etc/systemd/system -name "*.service" -newer /etc/os-release
grep -r "ssh-" /home/*/.ssh/authorized_keys

# Patch vulnerability or misconfiguration that enabled entry
# Restore from known-good backup if system integrity is uncertain
```

**Checkpoint**: Re-scan host for IOCs after eradication confirms threat removal. Monitor for 24 hours before closing containment.

### Step 5: Post-Incident Review

Document findings and improve defenses within 72 hours of closure.

- **Root cause**: How did the attacker gain initial access?
- **Detection gap**: Why wasn't this caught earlier? What new detection rules are needed?
- **Response effectiveness**: What slowed containment? What playbook changes are needed?
- **Remediation verification**: Has the entry vector been permanently closed?
