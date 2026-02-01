# Roster Guide

@Metadata {
  @PageImage(purpose: icon, source: "core-roster-guide-icon", alt: "core-roster-guide icon")
  @PageImage(purpose: card, source: "core-roster-guide-card", alt: "core-roster-guide card")
}


Update the AGENTS.md roster deterministically.
@Image(source: "core-roster-guide-hero", alt: "Roster Guide hero")


## Contribution Coverage (`Core Roster`)

Use the `clia core roster` command to audit coverage across the All-Contributors
taxonomy. The command merges every discovered agent (repo root and submodules), canonicalises
their contribution mix, and reports:

- Sorted counts per contribution type with agent slugs.
- Aggregated primary-share totals (Σ) derived from each agent’s normalized contribution mix, plus
  secondary-share totals (Σ₂) when those support roles are declared.
- A "Missing types" section that lists canonical types not currently represented.
- Optional per-directory segments (for example, `/Users/example/workspace` vs `/Users/example/workspace/code`).
- An `--require-complete` flag that exits with a non-zero status when required types are missing.
- All-contributors emoji displayed alongside each type so gaps are easier to spot at a glance.
- Uses each agent’s `contributionMix` (primary + secondary); legacy `agentTypes` are no longer
  required.

```bash
/Users/example/workspace/.build/release/clia \
  core roster --path /Users/example/workspace
```

Sample text output:

```
== Overall ==
- 📖 doc (5, Σ=1.96): cadence, carrie, clia, rismay, tau
- 🔧 tool (4, Σ=1.06): clia, common, dott, tempo
- 📱 app (1, Σ=0.33): tau
...
- 🤔 ideas (4, Σ=0.37, Σ₂=0.12): cadence, cameron, dott, rismay
...
Summary: types=20 agents=28
Missing types (overall): 🌍 translation, 🛡️ security

== Segments ==
Segment root — /Users/example/workspace
  - 📖 doc (3, Σ=1.29): cadence, carrie, clia
  - 🤔 ideas (2, Σ₂=1.00): cadence, cameron
  Missing types: 📱 app, ✅ tutorial

Segment code — /Users/example/workspace/code
  - 📱 app (1, Σ=0.33): tau
  Missing types: 📖 doc, 💼 business, 🤔 ideas
```

JSON output mirrors the same data and includes arrays for `missingTypes`, `unknownTypes`, a
`primaryShares` map (per type, with 3-decimal precision), and a `segments` block that downstream
tooling can parse.

## Row Format

```
| <Title> | <Summary> | `.clia/agents/<slug>/` |
```

- Insert under the header separator line `| ----- | ------- | -------- |` if present; else create a minimal table.
- Dedupe by exact row match. Remove transitional rows containing `_(commissioned via CLI)_`.

## Write Target

- Parent submodule root (directory containing `.git`) at or above `--path`.
- Writes to `ROOT/AGENTS.md` without running git commands.

Swift

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

## Guardrails

- Never rewrite outside the roster table.
- Keep lines near ~100 chars to satisfy markdown lint.
- No network or git side effects; pure filesystem updates.

### Related Commands

- [Type coverage audit (`core roster`)](#contribution-coverage-core-roster)
