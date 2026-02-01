# SVG Animations: CSS

@Metadata {
  @PageImage(purpose: icon, source: "svg-simple-vector-graphics-css-icon", alt: "Icon")
  @PageImage(purpose: card, source: "svg-simple-vector-graphics-css-card", alt: "Card")
}
@Image(source: "svg-simple-vector-graphics-css-hero", alt: "Hero")


DocC does not create animations. It renders SVG files that already include
animation instructions. CSS animations live in a `<style>` block inside the SVG
and are applied via classes.

@Redirected(from: "simple-vector-graphics-svg-css")

## When to Use CSS

- You want a shared motion vocabulary (timing, easing, tokenized colors).
- You need `prefers-reduced-motion` support.
- You plan to reuse the same animation system across multiple diagrams.

## How CSS Animations Work in DocC

- The SVG embeds a `<style>` block with class-based rules.
- The browser runs CSS keyframes when the SVG is rendered.
- Keep all CSS inside the SVG so DocC can package it.

## Motion System Patterns

- Use CSS variables for shared timing and colors.
- Define a base loop (`--loop: 2.2s`) and offsets (`--delay-sm: 0.2s`).
- Keep the set of motions small: sweep, pulse, rotate, fade.

## Shared Motion Tokens

Use a shared timing/color palette so CSS and SMIL animations feel consistent.
Canonical palette: <doc:simple-vector-graphics-comparison>.

```css
:root {
  --ink: #2B2B2B;
  --accent: #2B2B2B;
  --loop: 2.2s;
  --ease: cubic-bezier(0.4, 0, 0.2, 1);
  --delay-sm: 0.2s;
}
```

Token usage example (CSS easing from `--ease`):

```css
.ring { animation: dash var(--loop) var(--ease) infinite; }
```

## Reduced Motion

Use `@media (prefers-reduced-motion: reduce)` to disable animation when needed.
This is the cleanest way to honor user motion preferences inside an SVG.

```svg
@media (prefers-reduced-motion: reduce) {
  .ring { animation: none; }
}
```

## Compatibility Notes

- CSS animation support is browser-dependent; keep selectors and features
  simple for best coverage.
- For dashed strokes, set `pathLength` so your dash pattern divides evenly and
  match the `stroke-dashoffset` loop to that length to avoid boundary seams.
- If seams persist, prefer `stroke-linecap: butt` for looping dash patterns.
- Test in DocC preview and the published site to verify timing and motion.
- Avoid external stylesheets and scripts.

## Differences vs SMIL SVG Animation

- CSS centralizes motion and supports shared tokens; SMIL is element-local.
- CSS has strong reduced-motion support; SMIL requires manual fallbacks.
- SMIL is more compact for single-element tweens; CSS scales better across
  multiple diagrams.
- CSS lets you coordinate multiple elements with shared keyframes.

## Shader-like Effects (SVG Filters)

DocC cannot run real GPU shaders (GLSL/WGSL/WebGL). The closest portable equivalent is SVG
filters: a small, declarative per-pixel pipeline (`feTurbulence`, `feDisplacementMap`,
`feColorMatrix`, `feBlend`) that behaves like a tiny shader graph.

Use these sparingly: keep the effect subtle, clip it to rounded bounds, and always provide a
reduced-motion fallback.

## Animated Gradients (CSS)

Use CSS animations to add slow, calm energy to overview diagrams and hub pages.
Keep gradients subtle and always honor `prefers-reduced-motion`.

![Slow gradient pan](svg-anim-gradient-pan-css.svg)

Pattern:

```svg
<style>
  :root { --loop: 18s; }
  @keyframes pan { 0% { transform: translateX(-120px); } 100% { transform: translateX(80px); } }
  .layer { animation: pan var(--loop) ease-in-out infinite; }
  @media (prefers-reduced-motion: reduce) { .layer { animation: none; } }
</style>
```

Notes:

- When panning a gradient layer, clip it to the intended rounded bounds (`clipPath`) and animate an
  oversized rectangle inside the clip. This prevents edge gaps and “off” corners during motion.
- For “shader-like noise”, use `feTurbulence` as a subtle grain overlay (SVG filters, not GPU
  shaders). Keep it low-opacity so it does not fight readability.
- For hover-only interactions, keep them optional and best-effort: <doc:simple-vector-graphics-hover-effects>.
- Prefer calm motion. If it competes with reading, slow it down.

### Sweep Ring

![CSS sweep ring](svg-anim-sweep.svg)

### Orbit Dot

![CSS orbit dot](svg-anim-orbit.svg)

### Shimmer Ring

![CSS shimmer ring](svg-anim-shimmer.svg)

## Example: Dash Ring (CSS)

![CSS dash ring](svg-anim-dash.svg)

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 140 140" role="img"
  aria-label="Dash ring">
  <title>Dash ring</title>
  <style>
    :root {
      --ink: #2B2B2B;
      --accent: #2B2B2B;
      --loop: 2.2s;
      --ease: cubic-bezier(0.4, 0, 0.2, 1);
      --delay-sm: 0.2s;
    }
    .ring {
      fill: none;
      stroke: var(--ink);
      stroke-width: 8;
      stroke-linecap: butt;
      stroke-dasharray: 12 16;
      animation: dash var(--loop) var(--ease) infinite;
    }
    @keyframes dash {
      to { stroke-dashoffset: -112; }
    }
    @media (prefers-reduced-motion: reduce) {
      .ring { animation: none; }
    }
  </style>
  <circle class="ring" cx="70" cy="70" r="36" pathLength="112"
    vector-effect="non-scaling-stroke" />
</svg>
```

## Unique CSS Example: Signal Equalizer Wave

CSS excels at coordinating many elements with shared keyframes and staggered
delays. This is hard to maintain with SMIL when diagrams grow.

![CSS signal equalizer](svg-anim-equalizer-css.svg)

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 90" role="img"
  aria-label="Signal equalizer (CSS)">
  <style>
    :root { --loop: 2.4s; --accent: #00A3FF; }
    .bar { fill: var(--accent); animation: level var(--loop) ease-in-out infinite; }
    .b1 { animation-delay: 0s; }
    .b2 { animation-delay: 0.2s; }
    .b3 { animation-delay: 0.4s; }
    .b4 { animation-delay: 0.6s; }
    .b5 { animation-delay: 0.8s; }
    @keyframes level { 0%,100% { height: 16px; y: 64px; } 40% { height: 56px; y: 24px; } }
  </style>
  <rect class="bar b1" x="20" y="64" width="18" height="16" rx="4" />
  <rect class="bar b2" x="50" y="64" width="18" height="16" rx="4" />
  <rect class="bar b3" x="80" y="64" width="18" height="16" rx="4" />
  <rect class="bar b4" x="110" y="64" width="18" height="16" rx="4" />
  <rect class="bar b5" x="140" y="64" width="18" height="16" rx="4" />
</svg>
```

## Multi-step Sequencing Examples (CSS)

CSS sequencing composes shared keyframes with per-element delays. SMIL variants
and composability notes live in <doc:simple-vector-graphics-comparison>.

### BFS Node Highlight (Step 1 -> Step 2 -> Step 3)

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

### Edge Traversal (Edge a -> Edge B -> Edge C)

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
