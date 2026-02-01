# Audit Solution

@Metadata {
  @PageImage(purpose: icon, source: "audit-audit-solution-icon", alt: "audit-audit-solution icon")
  @PageImage(purpose: card, source: "audit-audit-solution-card", alt: "audit-audit-solution card")
}


`CLIAAgentAudit` centralizes agent audits as a reusable Swift library.
@Image(source: "audit-audit-solution-hero", alt: "Audit solution hero")


- Single owner for check IDs, semantics, and schema (`auditSchemaVersion`)
- In‑process engines:
  - `local` — file scan + `CLIAModels` + `CLIACore` lineage
  - `docs` — reserved for future DocC‑backed engine
- Deterministic output ordering; stable messages for consumers (Foundry)

Example:

```swift
import CLIAAgentAudit
import Foundation

let root = URL(fileURLWithPath: ".")
let result = try CLIAAgentAudit.auditAgents(at: root)
for c in result.checks { print("\(c.id): \(c.status) — \(c.message)") }
```
