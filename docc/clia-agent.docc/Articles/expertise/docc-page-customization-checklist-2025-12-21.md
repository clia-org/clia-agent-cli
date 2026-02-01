# DocC Page Customization Checklist (2025-12-21)

@Metadata {
  @PageColor(blue)
  @PageImage(purpose: icon, source: "expertise-docc-page-customization-checklist-2025-12-21-icon", alt: "expertise-docc-page-customization-checklist-2025-12-21 icon")
  @PageImage(purpose: card, source: "expertise-docc-page-customization-checklist-2025-12-21-card", alt: "expertise-docc-page-customization-checklist-2025-12-21 card")
}

@Options {
  @TopicsVisualStyle(list)
}

This checklist groups every DocC page customization into a few predictable buckets so pages stay
consistent and fast to scan.
@Image(source: "expertise-docc-page-customization-checklist-2025-12-21-hero", alt: "DocC page customization checklist (2025-12-21) hero")


## Checklist: Page Identity (Metadata)

- Title line (`# Page title`) with a short, focused summary paragraph below it.
- `@Metadata { ... }` directly after the title:
  - `@TechnologyRoot` for hubs.
  - `@PageKind(...)` when you need a specific page type.
  - `@PageColor(blue|purple|gray|green|orange)` for the topic lane.
  - `@PageImage(purpose: icon|card, source: "icon-clia-agent", alt: "...")`.
  - `@CallToAction(url: "...", label: "...")` for hub actions.
  - `@Availability(...)`, `@SupportedLanguage(...)` when applicable.
  - `@TitleHeading("...")` for eyebrow text on hubs.
  - `@DisplayName(...)`, `@DocumentationExtension`, `@AlternateRepresentation` when you need them.

## Checklist: Rendering Options

- `@Options { ... }` near the top of the page:
  - `@TopicsVisualStyle(list|compactGrid|detailedGrid|hidden)`
  - `@AutomaticTitleHeading(...)`
  - `@AutomaticSeeAlso(...)`

## Checklist: Navigation and Curation

- `## Topics` section with grouped headings (`### Start here`, `### Deep dives`, `### Reference`).
- `Links(visualStyle: ...) { - doc-ellipsis }` for card grids anywhere.
- `@TabNavigator { @Tab("...") { ... } }` for hub pages with multiple categories.
- `@Row { @Column { ... } }` for icon or callout grids.
- `@Small { ... }` for footnotes and constraints.
- `@Redirected(from: "old/path")` when URLs change.

## Checklist: Content Building Blocks

- Sections: `## Overview`, `## Discussion`, `## Topics`, `## See Also`.
- Callouts:
  - `> Note:` for quick reminders.
  - `> Warning:` include the exact error text and a verify step.
  - `> Important:` call out risk and ownership.
- Code blocks with language hints (` ```bash `, ` ```swift `) and plain lists or tables.
- Links:
- Symbol links use double backticks (\\`\\`MyModule/MyType/myFunc(_:)\\`\\`).
- Doc links use `doc\\:SomeArticle` or `doc\\:MyModule/MyType`.

## Checklist: Media and Assets

- `Image(source: "hero-clia-agent", alt: "...")` with required alt text.
- `Video(source: "hero-expertise-banner", poster: "hero-clia-agent", alt: "...")` for tutorials or demos.
- Keep assets in `resources/` with kebab-case names.
- Use `@PageImage` for badges or cards rather than inline images.

## Checklist: Tutorials

- `@Tutorials` for a tutorials index.
- `@Tutorial` for each tutorial.
- Inside tutorials: `@Intro`, `@Chapter`, `@Steps`, `@Step`, `@Section`, `@Code`.
- `@Assessments` must be top-level, not inside `@Section`.

## Checklist: Snippets

- `@Snippet` for reusable code examples.
- Treat snippet support as catalog-first; do not rely on Quick Help parity.

## Grouping Strategy (How to Organize a Page)

- Group by reader intent: Start here, Learn, Do, Reference.
- Use the same order on every hub: Summary, Quick links, Tabs, Topics.
- Keep each group to 5 to 7 links so grids stay readable.
- Use one icon and one color lane per topic to avoid visual noise.

Example hub skeleton:

```md
# Title

@Metadata {
  @TechnologyRoot
  @PageColor(blue)
  @PageImage(purpose: card, source: "hero-expertise-banner", alt: "Hero banner")
}

@Options {
  @TopicsVisualStyle(detailedGrid)
}

Summary paragraph.

## Topics

### Start here

- <doc:docc-authoring-cheat-sheet-2025-12-21>

### Deep dives

- <doc:docc-visual-style-kit>
```

## Custom Styles (How to Theme a Page)

- Use `@PageColor`, `@PageImage`, and `@TitleHeading` for identity.
- Use `@Links` visual styles and `@Row/@Column` grids for layout rhythm.
- Keep callout usage consistent with the palette and icon system.
- Apply catalog-wide CSS with `theme-settings.json` and a CSS file in `resources/`.
- Reuse the Carrie palette via `docc-wrkstrm palette` for consistent tokens.

See also:

- <doc:docc-visual-style-kit>
- <doc:docc-authoring-cheat-sheet-2025-12-21>
