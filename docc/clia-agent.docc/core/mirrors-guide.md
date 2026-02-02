# Mirrors Guide

@Metadata {
  @PageImage(purpose: icon, source: "core-mirrors-guide-icon", alt: "core-mirrors-guide icon")
  @PageImage(purpose: card, source: "core-mirrors-guide-card", alt: "core-mirrors-guide card")
}


Render non‑canonical Markdown mirrors for triads.
@Image(source: "core-mirrors-guide-hero", alt: "Mirrors Guide hero")


## What Mirrors Are

- Human‑readable Markdown generated next to JSON triads under `.../.generated/`.
- Not a source of truth; do not edit by hand. Regenerate from JSON.

## Rendering All Mirrors

Swift

```swift
import CLIAAgentCore
import Foundation

let agentsRoot = URL(fileURLWithPath: ".clia/agents")
let outputs = try MirrorRenderer.mirrorAgents(at: agentsRoot, dryRun: false)
for url in outputs { print(url.path) }
```

- `dryRun: true` returns planned output URLs without writing files.

## Render a Single Agenda File

Swift

```swift
import CLIAAgentCore
import Foundation

let url = URL(fileURLWithPath: ".clia/agents/dott/dott@mono.agenda.triad.json")
let (slug, markdown) = try MirrorRenderer.agendaMarkdown(from: url)
print(slug)
print(markdown)
```

## File Naming and Location

- Mirrors live next to JSON under `.generated/<slug>.(agent|agenda|agency).md`.
- Agenda rendering includes a simple scaffold for cadence sections and notes.
