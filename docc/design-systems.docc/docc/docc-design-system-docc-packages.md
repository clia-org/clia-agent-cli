# DocC Package Types and Boundaries

@Metadata {
  @PageImage(purpose: icon, source: "docc-docc-design-system-docc-packages-icon", alt: "Icon")
  @PageImage(purpose: card, source: "docc-docc-design-system-docc-packages-card", alt: "Card")
}
@Image(source: "docc-docc-design-system-docc-packages-hero", alt: "Hero")


Use this guide to understand which DocC-related package owns which responsibility.
Keep the filesystem as the source of truth; treat DocC archives as derived outputs.

## Layers and Responsibilities

### SwiftDocC (Library + CLI)

What it does

- Renders symbol graphs + markdown into DocC output (render nodes, indexes, archives).
- Defines DocC model types (e.g., `TopicReference`, `RenderNode`) for navigation data.

What it does not do

- Does not provide a preview server.
- Does not discover arbitrary bundle files or raw assets.

Use when

- You need the canonical DocC data model or want to render in-process.
- You want to replace custom archive indexing with DocC-native types.

### SwiftDocC Preview Plugin (SwiftPM)

What it does

- Orchestrates DocC builds for SwiftPM packages.
- Handles preview lifecycle, output paths, and sandboxing defaults.

What it does not do

- It is not a library API; it cannot be imported into app code.

Use when

- You want the standard SwiftPM preview flow (`swift package preview-documentation`).

### WrkstrmDocCPreviewCore

What it does

- Serves already-rendered DocC output with SPA-safe routing.
- Normalizes deep-link paths to match DocC expectations.

What it does not do

- Does not render DocC or generate archives.
- Does not import SwiftDocC.

Use when

- You need a lightweight, in-process server for existing DocC output.

### DocC Preview CLI

What it does

- Wraps `WrkstrmDocCPreviewCore` to serve DocC output.
- Provides tooling (Mermaid render, SVG generation, palette tooling).

What it does not do

- It does not replace SwiftDocC rendering; it expects output to exist.

Use when

- You want the CLI-driven preview flow and asset tooling.

### CodeSwiftly App (DocC UI)

What it does

- Browses DocC bundle files and shows raw content or previews.
- Optionally maps files to DocC preview URLs when an archive is available.

What it does not do

- It should not treat the DocC archive as the truth.

Use when

- You want a file-first DocC authoring UX with best-effort preview mapping.

## Hybrid Mapping Behaviors

Treat the archive as a best-effort index, not a canon. The UI should always be able to render
something even when DocC output is missing or stale.

- Always load the file content from disk first.
- If a DocC preview URL resolves, show the preview; otherwise, fall back to raw content.
- Treat missing archive entries as normal (not an error).
- Surface a small status note when a file is not part of the rendered archive.

## Project Usage Map (Today)

Use the detailed usage map to see which parts of the repo depend on which DocC packages.

@Links(visualStyle: list) {
  - <doc:docc-design-system-docc-packages-usage-map>
}

## Source-of-truth Rule

- Filesystem = source of truth.
- DocC archive/index = derived layer for preview and navigation.
- When a file exists but lacks a DocC topic, show raw content and surface that the archive does not include it.

## Conflict Risks to Watch

- Archive produced by a different renderer or version than the UI expects.
- Stale archives vs live filesystem edits.
- Incomplete or partial DocC builds that omit certain files.
