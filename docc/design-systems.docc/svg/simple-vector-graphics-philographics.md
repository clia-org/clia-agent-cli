# SVG Philographics (Emotive Tiles)

@Metadata {
  @PageImage(purpose: icon, source: "svg-simple-vector-graphics-philographics-icon", alt: "Icon")
  @PageImage(purpose: card, source: "svg-simple-vector-graphics-philographics-card", alt: "Card")
}
@Image(source: "svg-simple-vector-graphics-philographics-hero", alt: "Hero")


Philographics are simple, geometric SVG tiles designed to carry **tone** (not data). In DocC they
are most useful as:

- page **card** images (grid hubs), and
- page **hero** banners (top-of-page mood).

This page documents the SVG constraints and best practices so philographics stay portable,
accessible, and DocC-friendly.

For the DocC authoring guidance (how to map moods to page intent), see:

- <doc:docc-design-system-philographics>

## Recommended SVG Structure

- Use a responsive `viewBox` (no reliance on fixed `width`/`height`).
- Keep the SVG self-contained:
  - no scripts
  - no external CSS
  - no external fonts
  - no linked images (`<image href="...">`) unless you validate packaging
- Avoid `filter`, `mask`, and `blend` unless you have a clear compatibility reason.
- Add accessibility metadata:
  - `role="img"`
  - `aria-label="..."`
  - a `<title>...</title>` node

## Artboard and Safe Area

- **Tile** (recommended): `viewBox="0 0 512 512"`
- Keep a safe area: avoid important geometry within ~48px of the tile edge.
- Use a consistent corner radius across a set (for example, `rx="72"` on a 512 tile).
- Align strokes to whole pixels when possible (crisper rendering).

## Color and Theming

- Prefer a small palette:
  - 1 background color
  - 1–2 accent fills
  - 1 neutral stroke color (often off-white) with controlled opacity
- Keep contrast high enough that the tile still reads when displayed small on DocC cards.
- If your bundle uses theme tokens (DocC CSS), keep philographic colors aligned with those tokens.
  Avoid one-off “random” brand colors.

## Naming Conventions

For shared, reusable tiles:

- `svg-philographics-<mood>-card.svg`

For bundle-specific branding:

- `[bundle-slug]-[page-path]-philographic-<mood>-card.svg`

## Quick Checklist

- `viewBox` present
- no scripts
- no external CSS/fonts
- no linked images
- safe area respected
- minimal primitives (2–4 shapes)
- one focal point
- accessibility metadata present
- tested in DocC preview
