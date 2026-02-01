# SVG Images for DocC Pages (Icon, Card, Hero)

DocC pages are easier to scan and navigate when every page has a consistent image set:

- **Icon**: small navigation badge (purpose: icon)
- **Card**: topic card artwork on hub grids (purpose: card)
- **Hero**: wide banner placed near the top of the page content

## How DocC Uses Each Image

### Icon

- Used in navigation chrome and link cards when present.
- Prefer simple geometry on a 24x24 grid (SFSymbols-inspired).

Recommended directive:

```md
  @PageImage(purpose: icon, source: "svg-simple-vector-graphics-images-icon", alt: "Icon")
```

### Card

- Used for topic cards in grids and hub pages.
- Should remain legible when rendered small.

Recommended directive:

```md
  @PageImage(purpose: card, source: "svg-simple-vector-graphics-images-card", alt: "Card")
```

### Hero

- Used as a top-of-page banner in the page body.
- Keep the summary paragraph text-only, then place the hero image immediately after it.

Recommended placement:

```md
Summary paragraph.

@Image(source: "svg-simple-vector-graphics-images-hero", alt: "Hero")
```

## Tooling (Preferred)

Use `docc-wrkstrm docs` to:

- generate icon/card/hero SVGs for DocC pages, and
- update `@PageImage(...)` markers in markdown.

```bash
../clis/docc-wrkstrm-cli/.build/release/docc-wrkstrm docs \
  --root <path-to-bundle>.docc
```

Defaults from the generator (artboards):

- icon: `viewBox="0 0 256 256"`
- card: `viewBox="0 0 800 600"`
- hero: `viewBox="0 0 1600 720"`

## Naming Conventions

- Assets live in the bundle `resources/` folder.
- Filenames are lower-case and kebab-case.
- The generator uses:
  - `doc-<slug>-icon.svg`
  - `doc-<slug>-card.svg`
  - `doc-<slug>-hero.svg`

## Philographics (Emotive Branding)

Philographics are a good “default style” for DocC card + hero art because they:

- remain legible at small sizes,
- avoid text (no font dependencies), and
- communicate tone without becoming diagrams.

Guidance:

- Use philographics primarily for `card` and `hero`, not for `icon` (icons should stay simple).
- Pick one motif family + palette per bundle so topic grids look cohesive.
- Keep the image “emotive, not literal”; do not encode data or meaning only through color.

See:

- <doc:docc-design-system-philographics>
- <doc:simple-vector-graphics-philographics>

## Good vs Bad Examples

### Good

- Icon is simple and readable at small sizes.
- Card has large, high-contrast title text and minimal clutter.
- Hero uses a consistent artboard and has enough padding for long titles.
- All three are present, and the page uses `@PageImage(icon)` + `@PageImage(card)` consistently.

Example (good):

```md
@Metadata {
  @PageImage(purpose: icon, source: "svg-simple-vector-graphics-images-icon", alt: "Icon")
  @PageImage(purpose: card, source: "svg-simple-vector-graphics-images-card", alt: "Card")
  @PageImage(purpose: icon, source: "svg-simple-vector-graphics-images-icon", alt: "Icon")
  @PageImage(purpose: card, source: "svg-simple-vector-graphics-images-card", alt: "Card")
}
@Image(source: "svg-simple-vector-graphics-images-hero", alt: "Hero")


Summary paragraph.

@Image(source: "svg-simple-vector-graphics-images-hero", alt: "Hero")
```

### Bad

- Missing icon or missing card (hub grids look random or empty).
- Hero is embedded under `## Topics` (DocC may not render it).
- Tiny text in the card/hero that becomes unreadable on topic cards.
- Hover-only or script-driven interactions (DocC does not run scripts; hover is best-effort).
- External fonts or stylesheets (breaks portability).

See also:

- <doc:docc-design-system-patterns>
- <doc:simple-vector-graphics-docc-considerations>
