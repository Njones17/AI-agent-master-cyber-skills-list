# Master Cybersecurity Skills

**741 cybersecurity skills** for AI coding agents — the most comprehensive single-repo collection available. Covers offense, defense, cloud, forensics, CTF, AppSec, DevSecOps, and more.

Follows the [agentskills.io](https://agentskills.io) open standard. Works with Claude, Claude Code, GitHub Copilot, OpenAI Codex, Cursor, Gemini CLI, and 20+ other platforms.

---

## Install

```bash
# Claude Code
/plugin marketplace add Njones17/AI-agent-master-cyber-skills-list

# Or clone directly
git clone https://github.com/Njones17/AI-agent-master-cyber-skills-list .skills/cybersecurity
```

---

## Coverage

| Category | Skills |
|---|---|
| Cloud Security | AWS, Azure, GCP auditing, CSPM, IAM |
| Threat Intelligence | APT analysis, MITRE ATT&CK, STIX/TAXII, OSINT, dark web |
| Web Application Security | XSS, SQLi, SSRF, HTTP smuggling, cache poisoning |
| Offensive / Pentest | Metasploit, Burp Suite, recon, exploitation, C2 |
| Red Teaming | BloodHound, Kerberoasting, AD attacks, evasion |
| Digital Forensics | Volatility, disk imaging, memory, mobile, network |
| Malware Analysis | Ghidra, YARA, Cuckoo, static/dynamic analysis |
| SOC Operations | SIEM, Splunk, Windows Event Logs, detection rules |
| Network Security | Wireshark, Suricata, VLAN, IDS/IPS |
| Identity & Access | SAML, OAuth2, FIDO2, PAM, CyberArk, SailPoint |
| AppSec (SAST/DAST/SCA) | Semgrep, CodeQL, dependency scanning, secrets |
| Container Security | Trivy, Falco, Kubernetes hardening, Harbor |
| DevSecOps | GitLab CI, Gitleaks, supply chain, sbom |
| OT/ICS Security | SCADA, Modbus, Purdue Model |
| Cryptography | TLS, HSM, constant-time analysis, zeroize audit |
| CTF | Web, pwn, crypto, reverse engineering, forensics, OSINT |
| Incident Response | Ransomware, cloud IR, volatile evidence |
| Compliance | GDPR, ISO 27001, PCI DSS, CIS Benchmarks |
| AI/LLM Security | Prompt injection, model supply chain, red teaming |
| Smart Contracts | Solidity audit, timing side-channels, blockchain |

---

## Sources

Merged and deduplicated from 10 high-quality repos:

| Repo | Stars | Contribution |
|---|---|---|
| [trailofbits/skills](https://github.com/trailofbits/skills) | 3.3k | Security research, audit, static analysis, YARA, smart contracts |
| [trailofbits/skills-curated](https://github.com/trailofbits/skills-curated) | — | ffuf, Ghidra, Wooyun legacy, OpenAI security skills |
| [ghostsecurity/skills](https://github.com/ghostsecurity/skills) | 356 | AppSec SAST/DAST/SCA/secrets scanning |
| [itsmostafa/aws-agent-skills](https://github.com/itsmostafa/aws-agent-skills) | 1k | AWS IAM, Secrets Manager, Cognito |
| [mukul975/Anthropic-Cybersecurity-Skills](https://github.com/mukul975/Anthropic-Cybersecurity-Skills) | 9 | 611+ broad cybersecurity skills |
| [narlyseorg/superhackers](https://github.com/narlyseorg/superhackers) | — | Offensive pentest workflow (webapp/API/infra/Android) |
| [ljagiello/ctf-skills](https://github.com/ljagiello/ctf-skills) | 18 | CTF: web, pwn, crypto, RE, forensics, OSINT, malware |
| [BagelHole/DevOps-Security-Agent-Skills](https://github.com/BagelHole/DevOps-Security-Agent-Skills) | 12 | 80+ DevOps/cloud security skills |
| [Ray0907/security-scan](https://github.com/Ray0907/security-scan) | — | CVE/OWASP scanning with Semgrep |
| [openai/skills](https://github.com/openai/skills) | — | Security best practices, threat modeling, ownership map |

See [`SOURCES.json`](./SOURCES.json) for the full skill-level provenance map.

---

## Deduplication

- **Exact duplicates** (same `name:` field): removed, kept best version
- **Similar skills** (different angle/depth): both kept
- See [`DEDUP_REPORT.json`](./DEDUP_REPORT.json) for details

---

## Structure

Each skill follows the agentskills.io standard:

```
skills/{skill-name}/
├── SKILL.md          # YAML frontmatter + workflow instructions
├── references/       # Standards, MITRE ATT&CK, CVE refs (optional)
├── scripts/          # Helper scripts (optional)
└── assets/           # Templates, checklists (optional)
```

---

## License

Individual skills retain their original licenses. See each skill's directory for details.
Collection structure: Apache 2.0.
