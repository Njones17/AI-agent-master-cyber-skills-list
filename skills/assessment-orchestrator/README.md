# Assessment Orchestration System

## Overview

The Assessment Orchestration System automatically discovers related security components (APIs, subdomains, backend services, CDNs) when a security assessment is requested and triggers appropriate assessments on all discovered targets. This ensures comprehensive security coverage without manual scope expansion.

## Architecture

```
User Request (e.g., "test example.com")
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│              Request Ingestion & Validation              │
│  - Parse target from request                              │
│  - Validate accessibility                                  │
│  - Establish expansion boundaries                          │
└─────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│              Component Discovery Engine                   │
│  - Static rule-based discovery (api.*, www.*, etc.)       │
│  - Active discovery (subdomain enumeration, JS analysis)  │
│  - Component classification (API, CDN, backend, etc.)      │
└─────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│            Assessment Expansion Rules Engine               │
│  - Map component types to required assessments              │
│  - Build dependency graph (parallel vs sequential)         │
│  - Generate comprehensive assessment plan                  │
└─────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│              Orchestration & Execution                    │
│  - Present expanded plan to user for approval              │
│  - Dispatch parallel assessments via Agent tool            │
│  - Monitor progress and handle failures                    │
└─────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│              Result Aggregation & Correlation              │
│  - Collect findings from all assessments                   │
│  - Identify cross-target impact chains                     │
│  - Generate unified report with relationship context       │
└─────────────────────────────────────────────────────────┘
```

## Components

### 1. Skills

| Skill | Purpose |
|-------|---------|
| `assessment-orchestrator` | Main orchestration skill that coordinates the entire process |

### 2. Scripts

| Script | Purpose |
|--------|---------|
| `parse-request.sh` | Extract primary target and assessment type from user request |
| `validate-target.sh` | Verify target is accessible and in-scope |
| `apply-static-rules.sh` | Apply pre-defined relationship patterns to discover components |
| `discover-components.sh` | Active discovery via subdomain enumeration, JS analysis, link parsing |
| `classify-components.sh` | Classify discovered components by type and confidence |
| `expand-assessments.sh` | Map components to required security assessments |
| `build-dependency-graph.sh` | Determine which assessments can run in parallel |
| `generate-assessment-plan.sh` | Create human-readable assessment plan |
| `init-orchestration.sh` | Initialize orchestration state |
| `dispatch-assessments.sh` | Prepare dispatch of parallel assessments |
| `aggregate-findings.sh` | Collect and merge findings from all assessments |
| `correlate-findings.sh` | Identify cross-target impact chains |

### 3. Configuration

| File | Purpose |
|------|---------|
| `relationship-rules.yaml` | Defines static patterns for discovering related components |
| `assessment-mapping-rules.yaml` | Maps component types to required security assessments |

## Usage

### Basic Workflow

```bash
# 1. Load the orchestration skill
Skill superhackers:assessment-orchestrator

# 2. Parse user request
bash $SUPERHACKERS_ROOT/scripts/orchestration/parse-request.sh \
  --request "test example.com" \
  --output /tmp/engagement/parsed-request.json

# 3. Validate primary target
bash $SUPERHACKERS_ROOT/scripts/orchestration/validate-target.sh \
  --target "example.com" \
  --output /tmp/engagement/target-validation.json

# 4. Discover related components
bash $SUPERHACKERS_ROOT/scripts/orchestration/discover-components.sh \
  --primary-target "example.com" \
  --discovery-methods "subdomain,js_analysis,link_parsing" \
  --output /tmp/engagement/discovered-components.json

# 5. Classify components
bash $SUPERHACKERS_ROOT/scripts/orchestration/classify-components.sh \
  --input /tmp/engagement/discovered-components.json \
  --output /tmp/engagement/classified-components.json

# 6. Expand assessments
bash $SUPERHACKERS_ROOT/scripts/orchestration/expand-assessments.sh \
  --components /tmp/engagement/classified-components.json \
  --primary-assessment "webapp_penetration_test" \
  --output /tmp/engagement/expanded-assessments.json

# 7. Generate assessment plan
bash $SUPERHACKERS_ROOT/scripts/orchestration/generate-assessment-plan.sh \
  --primary "example.com" \
  --components /tmp/engagement/classified-components.json \
  --assessments /tmp/engagement/expanded-assessments.json \
  --output /tmp/engagement/assessment-plan.md

# 8. Present plan to user for approval

# 9. Execute assessments (via dispatching-parallel-agents skill)

# 10. Aggregate findings
bash $SUPERHACKERS_ROOT/scripts/orchestration/aggregate-findings.sh \
  --state /tmp/engagement/orchestration-state.json \
  --findings-dirs /tmp/engagement/*/findings \
  --output /tmp/engagement/aggregated-findings.json

# 11. Correlate findings
bash $SUPERHACKERS_ROOT/scripts/orchestration/correlate-findings.sh \
  --findings /tmp/engagement/aggregated-findings.json \
  --relationships /tmp/engagement/classified-components.json \
  --output /tmp/engagement/correlated-findings.json
```

## Discovery Methods

### Static Rule-Based Discovery

Pre-defined patterns automatically identify common related components:

- **Subdomain patterns**: `api.*`, `www.*`, `cdn.*`, `admin.*`, `docs.*`, `graphql.*`
- **Service patterns**: `auth.*`, `payments.*`, `backend.*`, `mail.*`
- **Infrastructure patterns**: `static.*`, `assets.*`, `shop.*`, `store.*`

### Active Discovery

Dynamic discovery methods that probe for related components:

| Method | Tools | Output |
|--------|-------|--------|
| **Subdomain enumeration** | subfinder, assetfinder, amass | List of subdomains |
| **JavaScript analysis** | rg, jsbeautifier | Embedded API endpoints and domains |
| **Link parsing** | curl, katana, httpx | External links and referenced domains |
| **Certificate transparency** | crt.sh, crlfuzz | Subdomains from certificate logs |
| **OpenAPI discovery** | curl, httpx | API documentation and schemas |

## Relationship Types

| Type | Description | Example |
|------|-------------|---------|
| `subdomain` | DNS subdomain of primary domain | `api.example.com` from `example.com` |
| `embedded_api` | API endpoints in JavaScript | `/api/v1/users` from JS bundle |
| `backend_service` | Backend for frontend/mobile | `backend.example.com` |
| `cdn_asset` | CDN for static assets | `cdn.example.com` |
| `api_version` | Different API version | `v2.api.example.com` |
| `documentation` | API/docs endpoints | `docs.example.com` |
| `external_link` | Linked from main target | External service links |

## Assessment Mapping

The system automatically maps discovered components to appropriate security assessments:

| Component Type | Primary: Webapp | Primary: API | Primary: Mobile |
|----------------|-----------------|--------------|----------------|
| `rest_api` | API Security Assessment | API Security Assessment | API Security Assessment |
| `graphql_api` | GraphQL Security Assessment | GraphQL Security Assessment | GraphQL Security Assessment |
| `cdn_asset` | Dependency Chain Assessment | - | Mobile Asset Security Review |
| `documentation` | Info Disclosure Review | API Schema Review | - |
| `admin_panel` | Webapp Penetration Test | - | - |
| `auth_service` | Authentication Security Review | - | Authentication Security Review |
| `payment_service` | Payment Security Assessment | - | - |
| `backend_service` | Web Service Security Assessment | - | Web Service Security Assessment |

## Confidence Levels

| Level | Description | Auto-Include |
|-------|-------------|--------------|
| **High** | Pattern match or direct observation | Yes (always) |
| **Medium** | Inferred from related patterns | Yes (standard mode) |
| **Low** | Indirect correlation | No (user approval required) |

## Error Handling

| Scenario | Handling |
|----------|----------|
| Primary target validation fails | Halt expansion, notify user |
| Discovery returns no results | Continue with static rules only |
| Related target inaccessible | Mark as skipped, continue with others |
| Assessment times out | Include partial results, mark timeout |
| User cancels specific assessment | Remove from plan, continue with others |

## Expansion Modes

| Mode | Description | When to Use |
|------|-------------|-------------|
| **Conservative** | Static rules only | Limited time, known simple targets |
| **Standard** | Static + safe active discovery | Default for most assessments |
| **Aggressive** | All discovery methods, deeper enumeration | Comprehensive assessments, red team |

## Output Formats

### Orchestration State

```json
{
  "orchestration_id": "ORCH-12345678",
  "primary_target": "example.com",
  "status": "in_progress",
  "assessments": [...],
  "findings": {
    "total": 42,
    "by_severity": {...},
    "by_target": {...}
  },
  "progress": {
    "pending": 2,
    "running": 3,
    "completed": 5,
    "failed": 0,
    "skipped": 1
  }
}
```

### Correlated Findings

```json
{
  "correlations": [
    {
      "correlation_type": "api_auth_impact",
      "description": "API authentication bypass may allow web app session hijacking",
      "affected_components": ["web_application", "api"],
      "findings_involved": ["FIND-001", "FIND-015"]
    }
  ],
  "impact_chains": [
    {
      "chain_type": "session_hijacking_chain",
      "description": "Session vulnerabilities allow account takeover across all components",
      "impact": "account_takeover",
      "severity": "critical"
    }
  ]
}
```

## Integration with Existing Skills

The orchestration system integrates with existing superhackers skills:

- **security-assessment**: Plans overall engagement, calls orchestration for component discovery
- **recon-and-enumeration**: Provides component discovery capabilities
- **dispatching-parallel-agents**: Executes parallel assessments on independent targets
- **All testing skills** (webapp-pentesting, api-pentesting, etc.): Receive component-specific assignments
- **vulnerability-verification**: Verifies findings from all assessments
- **writing-security-reports**: Compiles unified report with cross-target analysis

## Best Practices

1. **Always validate primary target** before expanding
2. **Present expanded plan to user** before execution
3. **Use parallel execution** for independent targets
4. **Document all expansion decisions** in audit trail
5. **Handle failures gracefully** - one failure shouldn't stop all assessments
6. **Correlate findings** across targets for complete impact analysis
7. **Respect scope boundaries** - never expand beyond authorized targets

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Discovery returns no results | Check DNS resolution, verify target accessibility |
| Assessments stuck in pending | Check for rate limiting, verify agent dispatch |
| Cross-target correlation not working | Ensure findings have target metadata, check relationship mapping |
| Plan generation fails | Validate input JSON files, check configuration syntax |

## Contributing

To add new relationship patterns or assessment mappings:

1. Edit `config/component-registry/relationship-rules.yaml`
2. Edit `config/component-registry/assessment-mapping-rules.yaml`
3. Test with `parse-request.sh` → `discover-components.sh` → `expand-assessments.sh`
4. Verify plan generation includes expected components

## License

This orchestration system is part of the superhackers project.
