# SVG Animations: SMIL

@Metadata {
  @PageImage(purpose: icon, source: "svg-simple-vector-graphics-smil-icon", alt: "Icon")
  @PageImage(purpose: card, source: "svg-simple-vector-graphics-smil-card", alt: "Card")
}
@Image(source: "svg-simple-vector-graphics-smil-hero", alt: "Hero")


DocC does not create animations. It renders SVG files that already include
animation instructions. SMIL is SVG's native animation model, expressed with
`<animate>` and `<animateTransform>` elements inside the SVG.

@Redirected(from: "simple-vector-graphics-svg-smil")

## When to Use SMIL

- You need small, self-contained animations that change SVG attributes.
- You want minimal CSS and no external dependencies.
- The animation is simple: pulse, fade, scale, or stroke progression.

## How SMIL Works in DocC

- The SVG carries animation elements directly on shapes.
- Playback happens in the browser if SMIL is supported.
- DocC does not run scripts or external CSS for SVGs.

## Core SMIL Primitives

- `<animate>` for scalar attributes (opacity, r, stroke-dashoffset).
- `<animateTransform>` for scale, rotate, and translate transforms.
- `<animateMotion>` for path motion (use sparingly and test).

## Timing and Pacing

- Use short loops (2-4s) and subtle easing.
- Prefer `repeatCount="indefinite"` for looping motion.
- Use `values` for stepwise transitions and `keyTimes` for pacing.

## Shared Motion Tokens

Keep values aligned with the shared palette so CSS and SMIL animations feel
consistent. SMIL cannot read CSS variables, so copy the values directly into
`dur`, `keyTimes`, and `keySplines`.
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

Token usage example (SMIL easing mapped from `--ease`):

```svg
<animate attributeName="opacity" values="0.7;0" dur="2.2s"
  repeatCount="indefinite" calcMode="spline" keySplines="0.4 0 0.2 1" />
```

## Accessibility and Motion Control

- SMIL does not automatically respect `prefers-reduced-motion`.
- If you need a reduced-motion variant, add a non-animated fallback layer and
  control visibility with CSS media queries inside the SVG.
- Keep the static composition readable if animation is disabled.

## Compatibility Notes

- SMIL support varies across renderers; always test in DocC preview and the
  published site.
- Keep SMIL animations simple; advanced features can be inconsistent.
- Avoid external CSS, scripts, or fonts.

## Differences vs CSS SVG Animation

- SMIL is compact and lives on the element; CSS centralizes motion in styles.
- SMIL is best for attribute tweens; CSS is better for shared timing systems.
- CSS supports `prefers-reduced-motion`; SMIL does not by default.
- SMIL is easy to keep self-contained; CSS is easier to theme across diagrams.

## Example: Pulse Ring (SMIL)

![SMIL pulse ring](svg-anim-pulse.svg)

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 140 140" role="img"
  aria-label="Pulse ring">
  <title>Pulse ring</title>
  <style>
    :root {
      --ink: #2B2B2B;
      --accent: #2B2B2B;
      --loop: 2.2s;
      --ease: cubic-bezier(0.4, 0, 0.2, 1);
      --delay-sm: 0.2s;
    }
    .pulse-ring {
      fill: none;
      stroke: var(--ink);
      stroke-width: 6;
    }
    .pulse-core {
      fill: var(--ink);
    }
  </style>
  <circle class="pulse-ring" cx="70" cy="70" r="18">
    <animate attributeName="r" values="18;52" dur="2.2s"
      repeatCount="indefinite" />
    <animate attributeName="opacity" values="0.7;0" dur="2.2s"
      repeatCount="indefinite" />
  </circle>
  <circle class="pulse-core" cx="70" cy="70" r="18">
    <animate attributeName="r" values="16;18;16" dur="2.2s"
      repeatCount="indefinite" />
  </circle>
</svg>
```

## Animated Gradients (SMIL)

SMIL can animate gradient transforms for slow “living” backgrounds. Keep the motion subtle and
always verify it renders in DocC preview (support varies by renderer).

![Slow gradient drift](svg-anim-gradient-slow-smil.svg)

```svg
<linearGradient id="g" x1="0" y1="0" x2="1200" y2="360" gradientUnits="userSpaceOnUse">
  <stop offset="0" stop-color="#0B1B3F"/>
  <stop offset="0.55" stop-color="#5EDCFF" stop-opacity="0.35"/>
  <stop offset="1" stop-color="#FF9F6E" stop-opacity="0.35"/>
  <animateTransform attributeName="gradientTransform" type="translate"
    values="-120 -24; 80 16; -120 -24" dur="18s" repeatCount="indefinite"/>
</linearGradient>
```

## Motion Primitive Examples (SMIL)

These are SMIL counterparts to the CSS motion primitives.

### Sweep Ring

![SMIL sweep ring](svg-anim-sweep-smil.svg)

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 140 140" role="img"
  aria-label="Sweep ring (SMIL)">
  <title>Sweep ring (SMIL)</title>
  <circle class="sweep" cx="70" cy="70" r="32">
    <animateTransform attributeName="transform" type="rotate" from="0 70 70"
      to="360 70 70" dur="2.8s" repeatCount="indefinite" />
  </circle>
</svg>
```

### Orbit Dot

![SMIL orbit dot](svg-anim-orbit-smil.svg)

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 140 140" role="img"
  aria-label="Orbit dot (SMIL)">
  <title>Orbit dot (SMIL)</title>
  <g>
    <circle class="dot" cx="70" cy="34" r="4" />
    <animateTransform attributeName="transform" type="rotate" from="0 70 70"
      to="360 70 70" dur="3.2s" repeatCount="indefinite" />
  </g>
</svg>
```

### Shimmer Ring

![SMIL shimmer ring](svg-anim-shimmer-smil.svg)

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 140 140" role="img"
  aria-label="Shimmer ring (SMIL)">
  <title>Shimmer ring (SMIL)</title>
  <circle class="shimmer" cx="70" cy="70" r="34" pathLength="136">
    <animate attributeName="stroke-dashoffset" values="0;-136" dur="2.4s"
      repeatCount="indefinite" />
  </circle>
</svg>
```

## Unique SMIL Example: Packet Along a Path

SMIL's `animateMotion` is ideal for path-following motion that is hard to
express in CSS without `offset-path`.

![SMIL packet path](svg-anim-packet-smil.svg)

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 120" role="img"
  aria-label="Packet along path (SMIL)">
  <path class="path" d="M20 80 C70 20 170 20 220 80" />
  <circle class="packet" r="6">
    <animateMotion dur="3.2s" repeatCount="indefinite"
      path="M20 80 C70 20 170 20 220 80" />
  </circle>
</svg>
```

## Multi-step Sequencing Examples (SMIL)

SMIL sequencing repeats timing per element. For CSS variants and composability
notes, see <doc:simple-vector-graphics-comparison>.

### BFS Node Highlight (Step 1 -> Step 2 -> Step 3)

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

### Edge Traversal (Edge a -> Edge B -> Edge C)

## Sketch Animation Example

A pencil-style line that draws stroke-by-stroke, then reverses.

@Image(source: "svg-sketch-pencil-animate", alt: "Sketch line animating forward then reversing")

```xml
%% file: svg-sketch-pencil-animate.svg
```

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
