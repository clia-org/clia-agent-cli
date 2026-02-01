# SVG + DocC Considerations

@Metadata {
  @PageImage(purpose: icon, source: "svg-svg-docc-considerations-icon", alt: "Icon")
  @PageImage(purpose: card, source: "svg-svg-docc-considerations-card", alt: "Card")
}
@Image(source: "svg-svg-docc-considerations-hero", alt: "Hero")


DocC treats SVGs as image assets. This has sharp constraints: no scripts, limited interaction, and
no guarantees about how hover states or sizing behave across DocC preview vs published hosting.

Use this page as the “gotchas” checklist before shipping new SVG diagrams.

@Redirected(from: "simple-vector-graphics-svg-docc-considerations")

## Interaction Constraints

- No JavaScript. DocC does not execute scripts inside SVGs.
- Hover is best-effort:
  - many renderers treat SVGs as images and do not deliver reliable `:hover` state
  - touch devices may never trigger hover
  - never hide essential information behind hover
- No cursor tracking or pointer-driven animation.

If you still want best-effort hover styling, keep it optional: <doc:simple-vector-graphics-hover-effects>.

## Layout and Sizing Constraints

- You cannot rely on custom “resizing controls” in DocC pages.
- Prefer responsive SVGs:
  - include a `viewBox`
  - avoid hard-coded `width`/`height` unless the asset is an icon with a fixed artboard
- Assume the diagram may be rendered small (cards) or wide (full page) and ensure it remains legible.

## Styling Constraints

- Keep SVGs self-contained:
  - no external stylesheets
  - no external fonts
  - no external images unless you have a strong reason and you validate packaging
- Avoid `foreignObject` and embedded HTML.

## Accessibility Constraints

- Provide meaningful alt text when embedding:

  ```
  ![Alt text](diagram.svg)
  ```

- Ensure the diagram still reads in reduced-motion contexts and with animations disabled.

## Animation Constraints

- Prefer subtle, slow motion that does not compete with reading.
- Always keep a readable static state.
- If you need reduced-motion support, prefer CSS animations because CSS can honor
  `prefers-reduced-motion`:
  - <doc:simple-vector-graphics-css>
  - <doc:simple-vector-graphics-smil>
  - <doc:simple-vector-graphics-comparison>

## Quick Checklist

- `viewBox` present
- no scripts
- no essential hover-only information
- no external CSS/fonts
- static state readable
- tested in DocC preview and target browsers
