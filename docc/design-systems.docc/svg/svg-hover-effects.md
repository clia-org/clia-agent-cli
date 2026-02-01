# SVG Hover Effects (DocC)

@Metadata {
  @PageImage(purpose: icon, source: "svg-svg-hover-effects-icon", alt: "Icon")
  @PageImage(purpose: card, source: "svg-svg-hover-effects-card", alt: "Card")
}
@Image(source: "svg-svg-hover-effects-hero", alt: "Hero")


DocC does not run scripts. SVG hover effects are therefore **best-effort** and must never be
required to understand the diagram.

@Redirected(from: "simple-vector-graphics-svg-hover-effects")

## Constraints (DocC)

- No JavaScript (no cursor tracking). Hover effects must be simple `:hover` styling.
- Hover is not guaranteed on touch devices.
- DocC typically renders SVGs as images; some browsers do not deliver reliable hover state into
  SVG image documents. Treat hover as a bonus.

## Pattern: Hover = Emphasis

Use hover to *emphasize* what is already there (stroke/brightness/annotation), not to reveal
essential information.

Static preview of the intended hover state (always visible):

![Hover state preview](svg-hover-effects-cards-hover.svg)

Best-effort interactive hover (may not trigger in all DocC renderers/browsers):

![Best-effort hover](svg-hover-effects-cards.svg)

## CSS Snippets

Global hover (the entire image reacts):

```css
/* Keep it snappy and obvious (not slow). */
.card, .hint, .shine { transition: opacity 120ms ease-out; }
svg:hover .card { stroke-opacity: 0.85; }
svg:hover .hint { opacity: 1; }
```
