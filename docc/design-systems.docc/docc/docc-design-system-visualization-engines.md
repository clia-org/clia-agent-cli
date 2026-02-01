# Visualization Engines

@Metadata {
  @PageImage(purpose: icon, source: "docc-docc-design-system-visualization-engines-icon", alt: "Icon")
  @PageImage(purpose: card, source: "docc-docc-design-system-visualization-engines-card", alt: "Card")
}

@Image(source: "docc-docc-design-system-visualization-engines-hero", alt: "Hero")

Guidance on using specific visualization engines

DocC does not render Mermaid code blocks directly. Our default workflow treats diagrams like other
assets: keep a reviewable source file, generate a deterministic SVG, and embed the SVG.

## Goals

- Deterministic, diff-friendly sources.
- Renderable in DocC without bespoke hosting logic.
- Readable in the repo even when SVGs are not opened.

## Engines

### Mermaid (Default)

- Use when: you need simple flowcharts, dependency graphs, or horizon swimlanes.
- Store: `.mmd` under `resources/mermaid/`.
- Render: `swift-svg-render mermaid` → `.mermaid.svg` into `resources/` (bundle root).
- Laussat Studio sources: `docc/websites/laussat-studio.docc/resources/mermaid/`
  → `docc/websites/laussat-studio.docc/resources/`.

### Graphviz (Dot)

- Use when: you need strict left-to-right constraints, ranked columns, or large graphs.
- Notes: requires Graphviz as a toolchain dependency; prefer a typed wrapper in a Swift CLI if we
  standardize it.

### D2 (Terrastruct)

- Use when: you want strong automatic layout and clean visuals with less manual tweaking.
- Notes: requires a renderer path (future `docc-wrkstrm` subcommand or a dedicated CLI).

### PlantUML

- Use when: you need sequences/activities and the UML vocabulary is an advantage.
- Notes: heavier runtime (Java) and stylistically “UML-first”; avoid by default for roadmaps.

## Options (Workflow)

### Source of Truth

- Keep a text-based diagram source (`.mmd`, `.dot`, `.d2`) as the canonical artifact.
- Treat rendered assets (`.svg`) as generated outputs committed for DocC preview/build stability.

### Rendering

Mermaid (canonical):

```bash
../tooling/swift-svg-render/.build/release/swift-svg-render mermaid \
  --input-dir <bundle>.docc/resources/mermaid \
  --docc-root <bundle>.docc \
  --theme neutral
```

Mermaid (inline extraction):

- If a markdown file contains fenced ```mermaid code blocks, the renderer should extract those
  blocks into `resources/mermaid/` and render them as `.mermaid.svg`.
- Keep the source block in the markdown for readability, but treat the extracted `.mmd` as the
  canonical render input.

### Embedding

Prefer standard Markdown images:

```
![Alt text](diagram-name.mermaid.svg)
```

### Diagram Source Placement

When you use a diagram in an article, include the source immediately after the
image (for example, a fenced `mermaid` block). Diagrams should live with the
narrative that explains them, not in a separate gallery page.

### SVG Upgrade Lists

Use `swift-svg-render list-upgradable` to produce the list you hand to Castor. The list includes
`.codex.svg` files by default, and `--include-all-svg` can include other `.svg` assets. The list
always excludes `.mermaid.svg` and `.castor.svg`, since those are already generated outputs.
