# SVG Rendering

@Metadata {
  @PageImage(purpose: icon, source: "svg-svg-rendering-icon", alt: "Icon")
  @PageImage(purpose: card, source: "svg-svg-rendering-card", alt: "Card")
}
@Image(source: "svg-svg-rendering-hero", alt: "Hero")


DocC treats SVGs as static images. Renderers vary, so SVGs must be portable and
self-contained.

@Redirected(from: "simple-vector-graphics-svg-rendering")

## Rendering Rules

- Keep SVGs self-contained: no external CSS, fonts, or scripts.
- Use a `viewBox` and avoid hard-coded `width`/`height` unless required.
- Prefer simple shapes and paths for portability.
- Keep text large and legible; avoid relying on custom fonts.
- Use `pathLength` when you need predictable dash behavior.
- Ensure the diagram still reads if animations are disabled.

## Card SVGs (Dashboards, Boards, Overviews)

- Prefer a calm background, then layered “cards” with `rx` corner radius.
- Use a soft border stroke with reduced opacity (avoid harsh outlines).
- Keep a small, consistent set of radii (for example, 14, 18, 22) across a family.
- Keep label text large enough to read in DocC without zooming.

## Layout and Sizing

- Use a consistent artboard size per diagram family (for example, 140x140 for
  icons, 600x360 for diagrams).
- Align shapes to whole or half pixels to avoid blurry strokes.
- Keep stroke widths consistent across related diagrams.

## Color and Theming

- Use CSS variables (`--ink`, `--accent`) for shared palette control.
- Prefer neutral, high-contrast colors for readability.
- Keep backgrounds transparent unless a fill is required.

## Gradients

- Prefer simple `linearGradient` backgrounds and keep stop counts low (2 to 3).
- Avoid filters and blend modes unless you have a compatibility justification.
- Preserve contrast for any text rendered inside the SVG.
- If you animate a gradient or background layer, clip it to a fixed rounded container using a
  `clipPath` and move an oversized layer inside the clip to avoid edge gaps.
- “Shader-like” grain can be approximated with `feTurbulence` (not a true shader). Keep it subtle
  and verify it renders consistently in DocC preview and your target browsers.

## DocC Integration

- Place SVGs in the bundle `resources/` folder.
- Reference them with markdown images or `@Image` so DocC packages them.
- Preview in DocC and the published site before shipping.

## Compatibility Notes

- Rendering differences across browsers and DocC preview are common.
- Avoid `foreignObject` and embedded HTML.
- Test light/dark backgrounds if the SVG relies on transparency.
