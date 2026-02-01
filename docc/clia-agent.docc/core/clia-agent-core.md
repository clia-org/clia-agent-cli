# CLIAAgentCore

@Metadata {
  @PageImage(purpose: icon, source: "core-clia-agent-core-icon", alt: "core-clia-agent-core icon")
  @PageImage(purpose: card, source: "core-clia-agent-core-card", alt: "core-clia-agent-core card")
}


Core building blocks for CLIA agent CLIs: write targets, journaling, mirrors, and roster updates. Works alongside lineage + merge views (`CLIACore`) and shared models (`CLIAModels`).
@Image(source: "core-clia-agent-core-hero", alt: "CLIAAgentCore hero")


## Reference

### Journaling

- `JournalWriter`
- `WriteTargetResolver`

### Mirrors

- `MirrorRenderer`

### Roster

- `RosterUpdater`

### CLI Commands

- `DoctorCommand`
- `MirrorsCommand`
- `TriadsCommandGroup`
- `AgentDocCCommandGroup`
- `RosterUpdateCommand`
- `ProfileCommand`
- `LineageLintCommand`
- `AgencyLogCommand`

### Design

- <doc:deterministic-lineage-merge>
- <doc:agent-types-and-focus>
- <doc:contributions-registry-spec>
- <doc:experience-curves>
- <doc:leveling-tiers>
- <doc:lint-and-ci-policy>
- <doc:lossless-merge-policy>

## Overview

- Knowledge capture writes to the parent repository (submodule) root by walking up to a directory containing `.git`.
- Journal entries are appended under `ROOT/.clia/agents/<slug>/journal/<YYYY-MM-DD>.json`.
- Optional `x-dirsTouched` is stored on the entry and unioned into the agent’s Agency document extensions.
- Mirrors (non‑canonical) render Markdown next to JSON triads for human review.

## Example: Append a Journal Entry

```swift
import CLIAAgentCore
import Foundation

let out = try JournalWriter.append(
  slug: "dot",
  workingDirectory: URL(fileURLWithPath: "."),
  highlights: ["DocC index fixed"],
  dirsTouched: ["docc/.wrkstrm", "docs/"]
)
print(out.path)
```

## Example: Render All Mirrors Under Agents

```swift
import CLIAAgentCore
import Foundation

let root = URL(fileURLWithPath: ".clia/agents")
let outputs = try MirrorRenderer.mirrorAgents(at: root)
for u in outputs { print(u.path) }
```

## Example: Update AGENTS.md Roster

```swift
import CLIAAgentCore
import Foundation

let roster = try RosterUpdater.update(
  startingAt: URL(fileURLWithPath: "."),
  title: "Cadence",
  slug: "cadence",
  summary: "Governance cadence and issues flow; keeps the team on time."
)
print(roster.path)
```

## See Also

- `CLIACore` — lineage discovery and merged triad views
- `CLIAModels` — agent/agenda/agency models
- Requests Archive — `docc/requests.docc/requests.md`
