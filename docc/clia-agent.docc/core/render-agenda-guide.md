# Render Agenda Guide

@Metadata {
  @PageImage(purpose: icon, source: "core-render-agenda-guide-icon", alt: "core-render-agenda-guide icon")
  @PageImage(purpose: card, source: "core-render-agenda-guide-card", alt: "core-render-agenda-guide card")
}


Render a single agent's agenda to Markdown for quick status visibility.
@Image(source: "core-render-agenda-guide-hero", alt: "Render Agenda Guide hero")


## What it Does

- Finds the nearest `*.agenda.json` for a given slug via lineage.
- Renders human‑readable Markdown and optionally writes it next to JSON under `.generated/`.

## Usage (CLI)

```bash
# Print to stdout
triads render --kind agenda --slug dot

# Write .generated/<slug>.agenda.md next to JSON
triads render --kind agenda --slug dot --write

# Resolve from a different working root
triads render --kind agenda --slug cadence --path path/to/repo
```

## Swift (Embedding)

```swift
import CLIAAgentCore
import CLIACore
import Foundation

let root = URL(fileURLWithPath: ".")
let contexts = LineageResolver.findAgentDirs(for: "dot", under: root)
guard let ctx = contexts.last else { fatalError("no context") }
let files = try FileManager.default.contentsOfDirectory(
  at: ctx.dir, includingPropertiesForKeys: nil)
let agendaURL = files.first { $0.lastPathComponent.hasSuffix(".agenda.json") }!
let (slug, markdown) = try MirrorRenderer.agendaMarkdown(from: agendaURL)
print(slug)
print(markdown)
```

## Notes

- Mirrors are non‑canonical; edit JSON and regenerate.
- Lineage considers ancestor contexts and submodules (`.gitmodules`).
