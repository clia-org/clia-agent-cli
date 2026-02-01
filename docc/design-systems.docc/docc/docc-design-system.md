# DocC Design System

@Metadata {
  @PageImage(purpose: icon, source: "docc-docc-design-system-icon", alt: "Icon")
  @PageImage(purpose: card, source: "docc-docc-design-system-card", alt: "Card")
}
@Image(source: "docc-docc-design-system-hero", alt: "Hero")


Human interface guidelines for DocC bundles across the repo.
Use the templates below to keep DocC guidance consistent across bundles.
Agents must read this guide before creating DocC.

Core expectations:

- Every bundle has an explicit technology root with `@TechnologyRoot`.
- Use lower-case kebab-case for all DocC paths and filenames.
- Keep assets in a flat `resources/` directory at the bundle root.

Recommended minimum layout:

- Root article with `@TechnologyRoot` and `## Topics`.
- `overview.md`: purpose, scope, and audience.
- `motivation.md`: why the work exists and what constraints shape it.
- `design.md`: design principles and trade-offs.
- `architecture.md`: component map and data flows.
- `implementation.md`: key paths, conventions, and extension points.
- `getting-started.md`: the smallest working path for new users.

Each section should be brief, skimmable, and focused on one intent. Add how-to, reference, and
tutorials only when they serve real workflows.

Minimum layout pages:

- <doc:overview>
- <doc:motivation>
- <doc:design>
- <doc:architecture>
- <doc:implementation>
- <doc:getting-started>

@Options {
  @TopicsVisualStyle(detailedGrid)
  @AutomaticSeeAlso(disabled)
}

> Important: `## Topics` is navigation-only. Do not put prose, code blocks, tables, or other narrative content under `## Topics`—DocC may not render it, and the page can appear empty. Keep `## Topics` as the final section in the document. Put narrative content above `## Topics` (or use normal `##` sections + `@Links`).

## Topics

### Minimum layout

- <doc:overview>
- <doc:motivation>
- <doc:design>
- <doc:architecture>
- <doc:implementation>
- <doc:getting-started>

### Core

- <doc:docc-design-system-principles>
- <doc:docc-design-system-patterns>
- <doc:docc-design-system-authoring>
- <doc:executive-product-roundup-design>
- <doc:docc-design-system-checklists>
- <doc:docc-design-system-anti-patterns>
- <doc:docc-design-system-examples>

### Organization

- <doc:docc-design-system-file-organization>
- <doc:docc-design-system-filesystem-alignment>
- <doc:docc-design-system-docc-packages>
- <doc:docc-design-system-docc-packages-usage-map>

### Publishing

- <doc:docc-design-system-published-websites>

### Navigation

- <doc:docc-design-system-navigation>
- <doc:docc-design-system-structure>
- <doc:docc-design-system-layout>
- <doc:docc-design-system-preview>

### Assets

- <doc:docc-design-system-resource-naming>
- <doc:docc-design-system-assets>
- <doc:docc-design-system-philographics>
- <doc:docc-design-system-philographics-agents>
- <doc:docc-design-system-philographics-castor-reimagined>
- <doc:docc-design-system-philographics-castor-concepts>
- <doc:docc-design-system-visualization-engines>
- <doc:docc-ui-light-dark-examples>
