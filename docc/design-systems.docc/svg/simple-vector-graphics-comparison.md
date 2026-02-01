# SVG Animations: SMIL vs CSS

@Metadata {
  @PageImage(purpose: icon, source: "svg-simple-vector-graphics-comparison-icon", alt: "Icon")
  @PageImage(purpose: card, source: "svg-simple-vector-graphics-comparison-card", alt: "Card")
}
@Image(source: "svg-simple-vector-graphics-comparison-hero", alt: "Hero")


Use this page to decide which animation approach fits a DocC diagram. Both
models can look great, but they trade off portability, theming, and motion
control.

@Redirected(from: "simple-vector-graphics-svg-comparison")

## Decision Matrix

| Topic | SMIL | CSS |
| --- | --- | --- |
| Best for | Small, single-element tweens | Shared motion systems across many SVGs |
| Where it lives | On the SVG element | In a `<style>` block with classes |
| Reduced motion | Manual fallback | `prefers-reduced-motion` support |
| Theming | Limited | Strong (CSS variables, tokens) |
| Complexity | Low | Medium |
| Coordination | Harder | Easier (shared keyframes) |

## Shared Motion Tokens

Use a shared timing/color palette so SMIL and CSS animations feel consistent.
SMIL cannot read CSS variables, so copy these values into SMIL attributes.

```css
:root {
  --ink: #2B2B2B;
  --accent: #2B2B2B;
  --loop: 2.2s;
  --ease: cubic-bezier(0.4, 0, 0.2, 1);
  --delay-sm: 0.2s;
}
```

Token usage examples (CSS vs SMIL):

```css
.ring { animation: dash var(--loop) var(--ease) infinite; }
```

```svg
<animate attributeName="opacity" values="0.7;0" dur="2.2s"
  repeatCount="indefinite" calcMode="spline" keySplines="0.4 0 0.2 1" />
```

## Multi-step Sequencing Examples

These show how linking multiple steps differs by style. The CSS versions are
more composable because they reuse shared keyframes and per-element delays.

### Example: BFS Node Highlight (Step 1 -> Step 2 -> Step 3)

SMIL (per-element timing):

![SMIL BFS sequence](svg-anim-bfs-smil.svg)

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 220 60">
  <circle id="n1" cx="30" cy="30" r="10" fill="#2B2B2B">
    <animate attributeName="fill" values="#2B2B2B;#00A3FF;#2B2B2B"
      begin="0s" dur="3s" repeatCount="indefinite" />
  </circle>
  <circle id="n2" cx="110" cy="30" r="10" fill="#2B2B2B">
    <animate attributeName="fill" values="#2B2B2B;#00A3FF;#2B2B2B"
      begin="1s" dur="3s" repeatCount="indefinite" />
  </circle>
  <circle id="n3" cx="190" cy="30" r="10" fill="#2B2B2B">
    <animate attributeName="fill" values="#2B2B2B;#00A3FF;#2B2B2B"
      begin="2s" dur="3s" repeatCount="indefinite" />
  </circle>
</svg>
```

CSS (shared keyframes + per-node delay):

![CSS BFS sequence](svg-anim-bfs-css.svg)

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 220 60">
  <style>
    :root { --loop: 3s; --ink: #2B2B2B; --hit: #00A3FF; }
    .node { fill: var(--ink); animation: hit var(--loop) ease-in-out infinite; }
    .s1 { animation-delay: 0s; }
    .s2 { animation-delay: 1s; }
    .s3 { animation-delay: 2s; }
    @keyframes hit { 0%,100% { fill: var(--ink); } 40% { fill: var(--hit); } }
  </style>
  <circle class="node s1" cx="30" cy="30" r="10" />
  <circle class="node s2" cx="110" cy="30" r="10" />
  <circle class="node s3" cx="190" cy="30" r="10" />
</svg>
```

### Example: Edge Traversal (Edge a -> Edge B -> Edge C)

SMIL (each edge repeats its own timing):

![SMIL edge traversal](svg-anim-edges-smil.svg)

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 220 60">
  <line x1="30" y1="30" x2="90" y2="30" stroke="#2B2B2B" stroke-width="4">
    <animate attributeName="stroke" values="#2B2B2B;#00A3FF;#2B2B2B"
      begin="0s" dur="3s" repeatCount="indefinite" />
  </line>
  <line x1="110" y1="30" x2="170" y2="30" stroke="#2B2B2B" stroke-width="4">
    <animate attributeName="stroke" values="#2B2B2B;#00A3FF;#2B2B2B"
      begin="1s" dur="3s" repeatCount="indefinite" />
  </line>
  <line x1="190" y1="30" x2="210" y2="30" stroke="#2B2B2B" stroke-width="4">
    <animate attributeName="stroke" values="#2B2B2B;#00A3FF;#2B2B2B"
      begin="2s" dur="3s" repeatCount="indefinite" />
  </line>
</svg>
```

CSS (shared class + per-edge delay):

![CSS edge traversal](svg-anim-edges-css.svg)

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 220 60">
  <style>
    :root { --loop: 3s; --ink: #2B2B2B; --hit: #00A3FF; }
    .edge { stroke: var(--ink); stroke-width: 4; }
    .edge { animation: glow var(--loop) ease-in-out infinite; }
    .s1 { animation-delay: 0s; }
    .s2 { animation-delay: 1s; }
    .s3 { animation-delay: 2s; }
    @keyframes glow { 0%,100% { stroke: var(--ink); } 40% { stroke: var(--hit); } }
  </style>
  <line class="edge s1" x1="30" y1="30" x2="90" y2="30" />
  <line class="edge s2" x1="110" y1="30" x2="170" y2="30" />
  <line class="edge s3" x1="190" y1="30" x2="210" y2="30" />
</svg>
```

## Practical Differences

- SMIL is compact and local to the element. It is quick to author for a single
  ring, pulse, or fade.
- CSS is better when you want a shared timing system or a reusable motion
  vocabulary (sweep, orbit, shimmer).
- CSS can honor user motion preferences with media queries; SMIL needs manual
  fallbacks or a static layer.
- SMIL is ideal for pure attribute tweens; CSS excels at coordinated motion
  across multiple elements.

## Mixing SMIL and CSS

You can combine SMIL and CSS in the same SVG. This is useful when you want a
CSS-driven timing system for most elements, but need SMIL for path motion or
attribute animation not easily expressed in CSS.

Guidelines:

- Keep responsibilities clear: use CSS for shared timing and color tokens, SMIL
  for element-specific motion like `animateMotion`.
- Avoid duplicating the same animation in both systems.
- Test in DocC preview and the published site to ensure both models run.
- Always keep a readable static state if animation is disabled.

Example: CSS pulse + SMIL path motion:

![Mixed CSS + SMIL](svg-anim-mixed.svg)

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 120">
  <style>
    :root { --loop: 2.4s; --ink: #2B2B2B; --hit: #00A3FF; }
    .node { fill: var(--ink); animation: pulse var(--loop) ease-in-out infinite; }
    @keyframes pulse { 0%,100% { fill: var(--ink); } 40% { fill: var(--hit); } }
  </style>
  <circle class="node" cx="20" cy="80" r="6" />
  <circle class="node" cx="220" cy="80" r="6" />
  <circle r="6" fill="var(--hit)">
    <animateMotion dur="2.4s" repeatCount="indefinite"
      path="M20 80 C70 20 170 20 220 80" />
  </circle>
</svg>
```

## DSA Showcase: Heapify Sift-down (Mixed)

This example combines CSS node/edge pulses with an SMIL path to show the sift
path during heapify.

![Heapify sift-down (mixed)](svg-anim-heapify-mixed.svg)

See the full write-up: <doc:simple-vector-graphics-dsa-heapify>.

## Compatibility Notes

- Support varies by renderer and browser; always test in DocC preview and the
  published site.
- Keep animation features simple: transforms, opacity, and stroke dashes are
  safest.
- Avoid external scripts, fonts, or stylesheets in SVGs.

## Suggested Usage

- Use SMIL for single-element pulses, fades, or simple scale loops.
- Use CSS when you plan to build a reusable motion system (shared timing tokens across diagrams).
  tokens.
- Always make the static diagram readable if animation is disabled.
