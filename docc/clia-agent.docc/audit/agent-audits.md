# Agent Audits (Library)

@Metadata {
  @PageImage(purpose: icon, source: "audit-agent-audits-icon", alt: "audit-agent-audits icon")
  @PageImage(purpose: card, source: "audit-agent-audits-card", alt: "audit-agent-audits card")
}


Use the CLIAAgentAudit library to perform deterministic, read‑only audits of CLIA agents. The audit emits a stable set of check IDs with levels and messages that downstream tools (like Foundry) can consume without re‑implementing agent semantics.
@Image(source: "audit-agent-audits-hero", alt: "Agent Audits (Library) hero")


## Overview

- Owner: CLIA
- Product: `CLIAAgentAudit` (SwiftPM library)
- Schema version: `1.0.0` (`CLIAAgentAudit.auditSchemaVersion`)
- Engines:
  - `local` — in‑process file scan using CLIAModels + CLIACore lineage
  - `docs` — reserved (future), DocC‑backed analysis when available as a Swift library

## Check IDs

Repo‑level

- `clia-stack` — `.clia` present (blocking)
- `agents-stack` — `.clia/agents` exists and has ≥1 agent (blocking)
- `agents-roster` — `AGENTS.md` presence + roster status (advisory)

Per‑agent (for each `<slug>`, sorted ascending)

- `agent-<slug>-files` — requires `<slug>.agent.triad.md`, `<slug>.agenda.triad.md`, `<slug>.agency.triad.md`; agent.md must include “> Slug: `<slug>`” (blocking)
- `agent-<slug>-placeholders` — flags template phrases in mirrors (advisory)
- `agent-<slug>-json` — checks presence of `*.agent.json`, `*.agenda.json`, `*.agency.json` (advisory)
- `agent-<slug>-json-core` — `purpose`, `responsibilities`, `guardrails` must be set (advisory)
- `agent-<slug>-json-notes` — agenda `notes.blocks` non‑empty (advisory)
- `agent-<slug>-roster` — roster token “`.clia/agents/<slug>/`” present in `AGENTS.md` (advisory)

Statuses: `pass`, `fail`, `warn`, `skip`.

## Determinism

- Order: repo‑level checks first → per‑agent checks grouped by slug, in a fixed order.
- Messages are stable and concise for snapshot comparison.

## Example (Local Engine)

```swift
import CLIAAgentAudit
import Foundation

let root = URL(fileURLWithPath: "/path/to/repo")
let result = try CLIAAgentAudit.auditAgents(at: root, options: .init(engine: .local))

for check in result.checks {
  print("\(check.id): \(check.status) — \(check.message)")
}
```

## Integration with Foundry

Foundry imports `CLIAAgentAudit` and maps `AgentAuditCheck` → `CheckResult` 1:1 (id, title, level, status, message, base?, penalty?). This keeps Foundry read‑only and avoids divergent implementations.

## Versioning

- Bump `auditSchemaVersion` when introducing breaking changes to check IDs or semantics.
- Consumers can warn on unknown schema versions but should parse known IDs robustly.
