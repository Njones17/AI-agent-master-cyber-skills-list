# Report Templates

Professional, ready-to-use security report templates. All templates are in Markdown — paste into Google Docs, Notion, Word, or any doc tool.

| Template | Use When |
|---|---|
| [`pentest-report/`](pentest-report/) | Full penetration test engagement (external, internal, web app, red team) |
| [`vulnerability-assessment/`](vulnerability-assessment/) | Scan-based assessment without exploitation |
| [`bug-bounty/`](bug-bounty/) | Submitting findings to HackerOne, Bugcrowd, or private programs |
| [`code-security-review/`](code-security-review/) | Source code security review / SAST engagement |
| [`incident-response/`](incident-response/) | Post-incident blameless post-mortem |

## Usage

Tell Claude which template to use:
> "Generate a pentest report for the findings we identified, using the pentest report template."

Claude will populate the template with your actual findings, maintaining the professional structure while filling in the relevant details.

## Tips

- Every finding in every template uses the same core structure: **Description → Impact → Evidence → Remediation**
- All severity ratings align with `CLAUDE.md` definitions (Critical/High/Medium/Low/Info + CVSS)
- ATT&CK technique IDs are included in pentest and IR templates
- Templates are designed for two audiences: executive summary (non-technical) + technical detail (developers/engineers)
