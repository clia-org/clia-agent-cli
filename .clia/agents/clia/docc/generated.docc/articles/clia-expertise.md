# CLIA Expertise

@Metadata {
  @PageColor(blue)
  @TitleHeading("DocC field guide")
  @PageImage(purpose: card, source: "memory-hero-expertise-banner", alt: "CLIA expertise banner")
  @CallToAction(
    url: "/documentation/clia-expertise/docc-authoring-cheat-sheet-2025-12-21",
    label: "Start with DocC authoring"
  )
}

@Options {
  @TopicsVisualStyle(detailedGrid)
}

CLIA expertise is the shared DocC playbook: hard-won fixes, visual systems, and
release-grade workflows. It exists so every team can ship documentation with
speed, clarity, and a clean audit trail.

## Recent Work

- Defined the CLIA container epic and feature requests, including smoke-check commands and a
  verification log schema under
  `.clia/requests/clia-tools/epics/clia-container-project-epic.docc`.

@Image(source: "memory-hero-expertise-banner", alt: "CLIA expertise banner")

## LeetCode Article Layout

- Subtitle is the problem summary; keep it to one tight sentence.
- Place the hero image directly below the subtitle (no Overview header before it).
- Warnings render as red callout boxes in a numbered chart (`@Row` + `@Column` + `> Warning:`).

> Note: Keep slugs and filenames kebab-case; DocC derives article URLs from
> filenames, so `clia-memory-docc.md` yields
> `/documentation/clia-requests/clia-memory-docc` instead of a collapsed
> camel-case slug.

> Tip: Treat warnings as evidence. Capture exact messages and pair them with the
> smallest fix and a verify step.

> Warning: DocC build drift is real. If a change alters output, log it and
> preserve the previous behavior.

> Important: Every error needs a minimal fix plus a testable verification step.

> Note: Refer to agents with monospaced handles (example: `^carrie`,
> `^clia`, `^rismay`) so DocC references stay consistent and searchable.

> Note: Requests docc uses a project-per-page model with features listed as
> level 3 topics. Keep the full registry in an appendix page to avoid bloating
> the root navigator.

> Note: Project pages should use a three-letter code in the title (example:
> `[WSM] Wrkstrm`) and include a short theme block with primary, accent, and
> gradient colors.

> Note: When listing hex colors, include an inline color swatch next to the
> value (for example: `![Primary swatch](...)` + `#1B2F5B`), and provide
> icon/card/hero SVG assets per project.

> Note: Project pages should include a visible “Project header” row (code,
> scope, palette), while keeping the full theme spec in HTML comments for
> reference.

> Note: Feature request pages should use consistent H2 headings: Summary,
> Scope, Rationale, Proposed structure, Contributor types, Contributor groups,
> Icon set, Notes, Next steps, Operator notes.

@Row {
  @Column {
    **Rigor**
    Write once, verify twice, ship with confidence.
  }
  @Column {
    **Speed**
    Reuse patterns and templates to move fast without chaos.
  }
  @Column {
    **Memory**
    Preserve decisions so future teams do not relearn the same lessons.
  }
}

@Small {
  CLIA is the first documentor. This is the standard it keeps.
}

## Current DocC Warnings (Code Swiftly)

- `@Tip` is not allowed inside `ContentAndMedia` or `Step`. Replace with
  `@Comment` or move the text into the step paragraph.
- `@PageImage(purpose: hero, ...)` is invalid. Use `icon` or `card` only.
- `@Links` requires `visualStyle` (for example, `@Links(visualStyle: list)`).
- Task group list items must be links only. Move narrative bullets outside the
  task group list.
- `@Justification` strings cannot contain unescaped quotes. Use plain text or
  escape quotes when needed.

## Palette

@Image(source: "memory-palette-clia", alt: "CLIA palette swatches")

@Small {
  Primary colors lead, but at 40% brightness: inked blue, bruised red, dusty
  yellow. Green signals success, magenta marks highlights. The soft gradient
  keeps the system rugged, warm, and readable.
}

## Quick Dashboard

@Links(visualStyle: detailedGrid) {

- <doc:docc-authoring-cheat-sheet-2025-12-21>
- <doc:docc-visual-style-kit>
- <doc:typing-practice>
- <doc:docc-palette-carrie>
- <doc:docc-code-swiftly-warnings-2025-12-21>
- <doc:docc-code-swiftly-patterns-grid-2025-12-21>
- <doc:docc-renderer-pipeline-2025-12-21>
- <doc:docc-page-customization-checklist-2025-12-21>
- <doc:passkit-doc-mirroring-2025-12-15>
- <doc:common-process-command-spec-ci-2025-10-28>
- <doc:fix-template>
}

## Topic Tabs

@TabNavigator {
  @Tab("DocC") {
    @Links(visualStyle: detailedGrid) {
    - <doc:docc-authoring-cheat-sheet-2025-12-21>
    - <doc:docc-visual-style-kit>
    - <doc:docc-palette-carrie>
    - <doc:docc-interview-drills-2025-12-16>
    - <doc:docc-code-swiftly-warnings-2025-12-21>
    - <doc:docc-code-swiftly-patterns-grid-2025-12-21>
    - <doc:docc-renderer-pipeline-2025-12-21>
    - <doc:docc-page-customization-checklist-2025-12-21>
    }
  }
  @Tab("PassKit") {
    @Links(visualStyle: detailedGrid) {
    - <doc:passkit-doc-mirroring-2025-12-15>
    }
  }
  @Tab("CLIA") {
    @Links(visualStyle: detailedGrid) {
    - <doc:naming-a-star-triads-and-s-type>
    - <doc:clia-root-rename-2025-10-06>
    }
  }
  @Tab("Migrations") {
    @Links(visualStyle: detailedGrid) {
    - <doc:todo3-structure-update-2025-10-03>
    - <doc:tau-secrets-migration-2025-10-03>
    }
  }
  @Tab("Tooling") {
    @Links(visualStyle: detailedGrid) {
    - <doc:common-process-command-spec-ci-2025-10-28>
    }
  }
  @Tab("Templates") {
    @Links(visualStyle: detailedGrid) {
    - <doc:fix-template>
    - <doc:motifs-future-me>
    }
  }
}

## Symbol Set

@Row {
  @Column {
    @Image(source: "memory-icon-docc-authoring", alt: "DocC authoring icon")
    DocC authoring
  }
  @Column {
    @Image(source: "memory-icon-docc-style-kit", alt: "DocC visual style icon")
    DocC visual style
  }
  @Column {
    @Image(source: "memory-icon-passkit-mirroring", alt: "PassKit mirroring icon")
    PassKit mirroring
  }
}

@Row {
  @Column {
    @Image(source: "memory-icon-triads-naming", alt: "Triads and naming icon")
    CLIA triads
  }
  @Column {
    @Image(source: "memory-icon-repo-migrations", alt: "Repo migrations icon")
    Repo migrations
  }
  @Column {
    @Image(source: "memory-icon-tooling-specs", alt: "Tooling and specs icon")
    Tooling and specs
  }
}

@Row {
  @Column {
    @Image(source: "memory-icon-templates-motifs", alt: "Templates and motifs icon")
    Templates and motifs
  }
}

## Callout Symbols

@Row {
  @Column {
    @Image(source: "memory-icon-note", alt: "Note callout icon")
    Note callout
  }
  @Column {
    @Image(source: "memory-icon-warning", alt: "Warning callout icon")
    Warning callout
  }
  @Column {
    @Image(source: "memory-icon-error", alt: "Error callout icon")
    Error callout
  }
}

## Topics

### DocC Authoring and Layout

- <doc:docc-authoring-cheat-sheet-2025-12-21>
- <doc:docc-visual-style-kit>
- <doc:docc-palette-carrie>
- <doc:docc-interview-drills-2025-12-16>
- <doc:docc-code-swiftly-warnings-2025-12-21>
- <doc:docc-code-swiftly-patterns-grid-2025-12-21>
- <doc:docc-renderer-pipeline-2025-12-21>
- <doc:docc-page-customization-checklist-2025-12-21>

### PassKit and Wallet DocC

- <doc:passkit-doc-mirroring-2025-12-15>

### CLIA Triads and Naming

- <doc:naming-a-star-triads-and-s-type>
- <doc:clia-root-rename-2025-10-06>

### Repo Structure and Migrations

- <doc:todo3-structure-update-2025-10-03>
- <doc:tau-secrets-migration-2025-10-03>

### Tooling and Specs

- <doc:common-process-command-spec-ci-2025-10-28>

### Templates and Motifs

- <doc:fix-template>
- <doc:motifs-future-me>
