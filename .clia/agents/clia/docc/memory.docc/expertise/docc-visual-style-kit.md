# DocC Visual Style Kit

@Metadata {
  @PageColor(blue)
  @PageImage(purpose: icon, source: "memory-icon-docc-style-kit", alt: "DocC visual style icon")
}

A quick style playbook for DocC pages: color lanes, callouts, and a consistent icon system.

## Color Lanes

Use `@PageColor` to visually separate topics while keeping a unified surface.

| Topic | Color | Use case |
| --- | --- | --- |
| DocC authoring | blue | Hubs, cheat sheets, layout playbooks |
| PassKit | purple | Wallet and PassKit coverage |
| CLIA triads | gray | Naming and triad system notes |
| Migrations | green | Repo structure and migration notes |
| Tooling | orange | CLI tooling and spec guidance |
| Templates | gray | Reusable patterns and motifs |

## Callout Palette

Use callouts to break up long sections and surface intent.

> Note: Favor short, actionable notes that can be applied in one pass.

> Warning: Warnings must include the exact error text and a verify step.

> Important: If the fix is risky, say why and point to the owner.

## Style Modes

Pick one style mode per hub so the catalog feels intentional.

### Elegant

- Low contrast, restrained icons, and a single accent color.
- Best for executive or historical pages.

@Image(source: "memory-style-elegant", alt: "Elegant DocC style example")

Example:

```md
@Metadata {
  @PageColor(gray)
  @PageImage(purpose: icon, source: "memory-icon-triads-naming", alt: "Triads icon")
}

@Options {
  @TopicsVisualStyle(list)
}

> Note: Keep the summary calm and precise.
```

### Colorful

- Uses the full palette, icon grid, and a hero image for energy.
- Best for onboarding hubs and guides that need momentum.

@Image(source: "memory-style-colorful", alt: "Colorful DocC style example")

Example:

```md
@Metadata {
  @PageColor(blue)
  @PageImage(purpose: card, source: "memory-hero-expertise-banner", alt: "Hero banner")
}

@Options {
  @TopicsVisualStyle(detailedGrid)
}

@Image(source: "memory-palette-carrie", alt: "Palette swatches")
```

### Minimal

- Text-first, no hero image, and compact topic lists.
- Best for checklists and fast references.

@Image(source: "memory-style-minimal", alt: "Minimal DocC style example")

Example:

```md
@Metadata {
  @PageColor(gray)
}

@Options {
  @TopicsVisualStyle(list)
}
```

## Icon System

- Keep a 24x24 grid, 1.7 to 2.0 stroke, rounded caps, and simple geometry.
- Store icons in `Resources/` using kebab-case names like `icon-docc-style-kit.svg`.
- Reuse one icon per topic to keep the visual system predictable.

## Page Imagery

- Use `@PageImage(purpose: icon, ...)` for navigation badges.
- Use `@PageImage(purpose: card, ...)` for card imagery on hub pages.
- Pair every image with an `alt` description so DocC stays accessible.

## Asset Kit

@Image(source: "memory-palette-carrie", alt: "Carrie palette swatches")

@Row {
  @Column {
    @Image(source: "memory-icon-note", alt: "Note callout icon")
    Note
  }
  @Column {
    @Image(source: "memory-icon-warning", alt: "Warning callout icon")
    Warning
  }
  @Column {
    @Image(source: "memory-icon-error", alt: "Error callout icon")
    Error
  }
}

@Small {
  Carrie keeps the system minimal and ship-ready: locked and shipping, every time.
}

## SVG Output

- Creating SVG assets for the style examples was successful and renders cleanly in DocC.
- Keep SVGs ASCII-only, 24x24 for icons, and use stable filenames in `Resources/`.

## Palette Standardization

- `docc-palette` now includes a `carrie` palette for CSS/JSON output.
- Use it for DocC theme tokens to keep hub styling consistent with Carrie assets.
- Generated outputs live in <doc:docc-palette-carrie>.
