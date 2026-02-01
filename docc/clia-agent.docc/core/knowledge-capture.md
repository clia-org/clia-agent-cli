# Knowledge Capture

@Metadata {
  @PageImage(purpose: icon, source: "core-knowledge-capture-icon", alt: "core-knowledge-capture icon")
  @PageImage(purpose: card, source: "core-knowledge-capture-card", alt: "core-knowledge-capture card")
}


Keep knowledge consistent across repo trees and submodules.
@Image(source: "core-knowledge-capture-hero", alt: "Knowledge Capture hero")


## Write Target Resolution

- Parent submodule root: ascend from the working directory until a directory contains a `.git` directory/file. This is the repository root (submodule root if inside one).
- Agent directory: `ROOT/.clia/agents/<slug>/` (created if missing).
- Journal path: `ROOT/.clia/agents/<slug>/journal/<YYYY-MM-DD>.json` (append‑only).

Swift

```swift
import CLIAAgentCore
import Foundation

let cwd = URL(fileURLWithPath: ".")
let target = try WriteTargetResolver.resolve(for: "carrie", startingAt: cwd)
print(target.repoRoot)  // …/.git parent
print(target.agentDir.path)  // …/.clia/agents/carrie
```

## Journaling Entries

- Auto‑signature: resolved from triad extensions.
  - `extensions.journalSignature` (e.g., "-CR").
- Dirs touched: optional `x-dirsTouched: [String]` on each entry.
- Agency extensions: `extensions.x-dirsTouched` is unioned (non‑destructive) to snapshot surfaces over time.

Swift

```swift
let out = try JournalWriter.append(
  slug: "carrie",
  workingDirectory: URL(fileURLWithPath: "."),
  highlights: ["DocC warnings triaged"],
  focus: ["Publish status docs"],
  nextSteps: ["Regenerate palette CSS"],
  signature: "auto",
  dirsTouched: ["docc/", ".wrkstrm/docs/"]
)
print(out.path)
```

### JSON Shape (Entry)

```json
{
  "date": "2025-09-28",
  "timestamp": "2025-09-28T04:19:00Z",
  "agentVersion": "",
  "highlights": ["DocC warnings triaged"],
  "focus": ["Publish status docs"],
  "nextSteps": ["Regenerate palette CSS"],
  "signature": "-CR",
  "x-dirsTouched": ["docc/", ".wrkstrm/docs/"]
}
```

## Provenance

- Writes are localized to a single repo root; no cross‑tree mutation occurs implicitly.
- Promotion is explicit via transfer or mirrors (see related articles).

## Errors

- If no `.git` is found, `WriteTargetResolver` throws; pass an explicit `--path` or create a repository root.
