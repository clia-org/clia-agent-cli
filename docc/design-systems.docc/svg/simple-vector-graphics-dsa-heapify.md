# Heapify (Sift-down) — Mixed SVG Animation

@Metadata {
  @PageImage(purpose: icon, source: "svg-simple-vector-graphics-dsa-heapify-icon", alt: "Icon")
  @PageImage(purpose: card, source: "svg-simple-vector-graphics-dsa-heapify-card", alt: "Card")
}
@Image(source: "svg-simple-vector-graphics-dsa-heapify-hero", alt: "Hero")


@Redirected(from: "simple-vector-graphics-svg-dsa-heapify")

This sample highlights a heapify sift-down. The CSS layer handles node and edge
emphasis while SMIL animates the comparison path.

## Max-heap Example (Choose Larger Child)

![Heapify sift-down (max-heap, mixed)](svg-anim-heapify-mixed.svg)

## Min-heap Example (Choose Smaller Child)

![Heapify sift-down (min-heap, mixed)](svg-anim-heapify-mixed-min.svg)

## Max-heap vs Min-heap

- Max-heap: parent >= children. Sift-down picks the larger child.
- Min-heap: parent <= children. Sift-down picks the smaller child.

## Algorithm Flow (Sift-down)

1. Start at the root and compare its value with both children.
2. Select the larger child (max-heap) or smaller child (min-heap).
3. If the child should be above the parent, swap them.
4. Continue from the child position until the heap property holds or you reach a leaf.

In the animations, the blue path marks the comparisons and the pulsing nodes
show the swap path.

## Why This Works

- CSS manages shared timing, colors, and pulses across nodes/edges.
- SMIL drives the path motion without needing `offset-path`.
- The diagram reads as a static heap even if animation is disabled.

## Example SVG

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 360 220" role="img"
  aria-label="Heapify sift-down (mixed)">
  <style>
    :root { --ink: #2B2B2B; --hit: #00A3FF; --loop: 3.6s; }
    .edge { stroke: var(--ink); stroke-width: 4; opacity: 0.25; }
    .edge.active { animation: edgePulse var(--loop) ease-in-out infinite; }
    .node { fill: #FFFFFF; stroke: var(--ink); stroke-width: 3; }
    .node.hit { animation: nodePulse var(--loop) ease-in-out infinite; }
    @keyframes nodePulse { 0%,100% { stroke: var(--ink); } 35% { stroke: var(--hit); } }
    @keyframes edgePulse { 0%,100% { stroke: var(--ink); } 35% { stroke: var(--hit); } }
  </style>
  <line class="edge active" x1="180" y1="40" x2="110" y2="100" />
  <line class="edge active" x1="110" y1="100" x2="150" y2="160" />
  <circle class="node hit" cx="180" cy="40" r="22" />
  <circle class="node hit" cx="150" cy="160" r="22" />
  <circle r="8" fill="var(--hit)">
    <animateMotion dur="3.6s" repeatCount="indefinite"
      path="M180 40 L110 100 L150 160" />
  </circle>
</svg>
```
