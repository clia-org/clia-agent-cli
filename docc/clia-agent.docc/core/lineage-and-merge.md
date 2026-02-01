# Lineage & Merge

@Metadata {
  @PageImage(purpose: icon, source: "core-lineage-and-merge-icon", alt: "core-lineage-and-merge icon")
  @PageImage(purpose: card, source: "core-lineage-and-merge-card", alt: "core-lineage-and-merge card")
}


Understand how merged views are built across repo trees and submodules.
@Image(source: "core-lineage-and-merge-hero", alt: "Lineage & Merge hero")


## Discovery

- Ancestor chain: from `--path` (or CWD) up to filesystem root, collect any `.clia/agents/<slug>/` directories.
- Submodules: parse `.gitmodules` at each ancestor root; for each `path = <subpath>`, include that submodule root and scan for `.clia/agents/<slug>/`.

## Merge Semantics

- Scalars: last non‑empty wins (nearest layer overrides).
- Arrays (mentors, tags, responsibilities, entries): stable union (dedupe, preserve first‑seen order).
- Links: union by `(title|url)` composite key.
- Notes and extensions: last non‑empty wins.
- Context chain: optional `(prefix, path)` list can be attached for transparency.

Swift

```swift
import CLIACore
import Foundation

let root = URL(fileURLWithPath: ".")
let preview = Merger.mergeAgent(slug: "dot", under: root)
print(preview.title)
```

## Precedence

1) Local repo layer (closest to `--path`)
2) Higher ancestors (project → workspace)
3) Submodule roots discovered via `.gitmodules`

Local still wins for scalar conflicts; unions incorporate all distinct entries.

## Options

- `includeSources`: attach source provenance to merged outputs (for previews)
- `includeDuplicates`: expose per‑source arrays before union (for auditing)
