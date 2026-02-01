# DocC Authoring Cheat Sheet

@Metadata {
  @PageColor(blue)
  @PageImage(purpose: icon, source: "memory-icon-docc-authoring", alt: "DocC authoring icon")
}

## Catalog Contents

- A DocC catalog is a folder ending in `.docc`.
- Articles and symbol extensions: `.md`.
- Tutorials: `.tutorial`.
- Assets: images, video, and downloads (for example `.png`, `.jpg`, `.mov`, `.zip`).
- Optional metadata/customization: `Info.plist`, `theme-settings.json`.

## Link Syntax

- Symbol link (symbols only): wrap a symbol path in double backticks, for example
  ` ``MyModule/MyType/myFunc(_:)`` `.
- Doc link (anything DocC can render): `<doc:SomeArticle>` or `<doc:MyModule/MyType>`.
  Fragments are supported to jump to headings.

## Problem and Solution Pairs

- PageColor dot prefix
  - Problem:

    ```text
    warning: Cannot convert '.purple' to type 'Color'
    PageColor expects an argument for an unnamed parameter that's convertible to 'Color'
    ```

  - Solution: use bare color names (`@PageColor(purple)`) and stick to allowed colors.
- PageImage purpose missing
  - Problem:

    ```text
    warning: Missing argument for purpose parameter
    PageImage expects an argument for the 'purpose' parameter that's convertible to 'Purpose'
    ```

  - Solution: add `purpose: icon` or `purpose: card` to `@PageImage`.
- PageImage purpose not supported
  - Problem:

    ```text
    warning: Cannot convert 'banner' to type 'Purpose'
    PageImage expects an argument for the 'purpose' parameter that's convertible to 'Purpose'
    suggestion: Use allowed value 'icon'
    suggestion: Use allowed value 'card'
    ```

  - Solution: use `@PageImage(purpose: card, ...)` for hero imagery or `icon` for badges.
- Assessments inside a Section
  - Problem:

    ```text
    warning: 'Assessments' directive is unsupported as a child of the 'Section' directive
    These directives are allowed: 'Comment', 'ContentAndMedia', 'Redirected', 'Stack', 'Steps'
    ```

  - Solution: move `@Assessments` to the tutorial top level, not nested in `@Section`.
- Summary contains a link
  - Problem:

    ```text
    warning: Link in document summary will not be displayed
    Summary should only contain (formatted) text.
    ```

  - Solution: move links out of the summary paragraph into a section or list.
- `@Links` list includes tutorials
  - Problem:

    ```text
    warning: Only documentation links are allowed in 'Links' list items
    ```

  - Solution: keep `<doc:...>` links inside `@Links` and list tutorials separately.
- Missing assets
  - Problem:

    ```text
    warning: Resource 'pattern_01_prefix_sum.png' couldn't be found
    ```

  - Solution: add the asset to the catalog or remove the reference.
- `@Justification` argument mismatch
  - Problem:

    ```text
    warning: Unknown argument '' in Justification. These arguments are currently unused but allowed: 'reaction'.
    ```

  - Solution: use `@Justification(reaction: "...")`.
- Symbol link example without symbols
  - Problem:

    ```text
    warning: 'MyModule' doesn't exist at '/expertise/docc-authoring-cheat-sheet-2025-12-21'
    ```

  - Solution: render examples as inline code (not DocC symbol links) unless symbol graphs exist.

## Page Skeleton

- Title: `# My Page Title`.
- Summary paragraph only (no links or images).
- Common sections: `## Overview`, `## Discussion`, `## Topics`, `## See Also`.

## Metadata Directives

- `@Metadata { ... }` goes right after the title and holds page-level directives.
- Common directives:
  - `@TechnologyRoot`
  - `@PageKind`, `@PageColor`, `@PageImage`
  - `@CallToAction`
  - `@Availability`, `@SupportedLanguage`
  - `@TitleHeading`
  - `@DisplayName`, `@DocumentationExtension`, `@AlternateRepresentation`
- Use bare color names, for example `@PageColor(blue)` (no leading dot).

Example:

```md
# Documentation

@Metadata {
  @TechnologyRoot
  @PageColor(blue)
  @TitleHeading("Release Notes")
}
```

## Options Directives

- `@Options { ... }` configures page rendering behavior.
- Common directives:
  - `@TopicsVisualStyle(list | compactGrid | detailedGrid | hidden)`
  - `@AutomaticTitleHeading(...)`
  - `@AutomaticSeeAlso(...)`

Example:

```md
@Options {
  @TopicsVisualStyle(detailedGrid)
  @AutomaticSeeAlso(disabled)
}
```

## Layout and Navigation

- `@Row { @Column { ... } }` for grid layout.
- `@TabNavigator { @Tab { ... } }` for tabs.
- `@Links(...) { - <doc:...> }` renders link cards anywhere, not only in `## Topics`.
- `@Small { ... }` for fine print.

## Styling Toolbox

- Page identity: `@TitleHeading`, `@PageColor`, `@PageImage(purpose: icon|card)`,
  `@CallToAction`.
- Navigation surface: `@Links(visualStyle: detailedGrid|compactGrid)` and `@Row/@Column`.
- Topic switching: `@TabNavigator` for dense dashboards.
- Rendering controls: `@Options` with `@TopicsVisualStyle`,
  `@AutomaticTitleHeading`, `@AutomaticSeeAlso`.
- Emphasis: `@Small` for footnotes and compact cautions.
- Media accents: `@Image` and `@Video` with clear `alt` text.

## Color Lanes

- DocC authoring: `@PageColor(blue)`.
- PassKit: `@PageColor(purple)`.
- CLIA triads and naming: `@PageColor(gray)`.
- Migrations: `@PageColor(green)`.
- Tooling and specs: `@PageColor(orange)`.
- Templates and motifs: `@PageColor(gray)`.

@Image(source: "memory-palette-carrie", alt: "Carrie palette swatches")

@Small {
  Keep the palette consistent across hubs and articles so readers can scan by color.
}

## Callout Palette

Use callouts to break up dense sections and highlight intent.

> Note: Use notes for quick reminders that unblock a reader in one pass.

> Warning: Warnings should include the exact error text and a verify step.

> Important: Call out risk and ownership when a change could affect other teams.

## Icon System (SFSymbols-inspired)

- Keep a standard 24x24 grid, 1.7-2.0 stroke, rounded caps, and simple geometry.
- Use kebab-case filenames under the DocC catalog `Resources/` directory.
- Prefer one icon per topic and reuse across related pages for consistency.
- Avoid heavy fills; use stroke-first icons so they work in light or dark themes.

## Redirects

- `@Redirected(from: "old/path")` emits redirect metadata for moved pages.

## Media Directives

- `@Image(source: ..., alt: ...)` displays an image (alt text required).
- `@Video(source: ..., poster: ..., alt: ...)` displays a video with a poster frame.

## Tutorial System

- `@Tutorials` defines a table-of-contents page for multiple tutorials.
- `@Tutorial` defines an individual tutorial.
- Core building blocks: `@Intro`, `@Chapter`, `@Steps` / `@Step`, `@Section`, `@Code`.
- Place `@Assessments` at the tutorial top level (not under `@Section`).

## Snippets

- `@Snippet` support varies across toolchains and contexts.
- Treat snippets as catalog or SwiftPM plugin first, not guaranteed in Quick Help.
