# Gradient Craft

@Metadata {
  @PageColor(blue)
  @PageImage(purpose: icon, source: "core-gradient-expertise-icon", alt: "core-gradient-expertise icon")
  @PageImage(purpose: card, source: "core-gradient-expertise-card", alt: "core-gradient-expertise card")
}

These gradients define the CLIA Agent Core mood: precise, layered, and bright
without feeling noisy. They are designed for SVG so DocC renders them sharply.
@Image(source: "core-gradient-expertise-hero", alt: "Gradient craft hero")


@Image(source: "hero-clia-agent", alt: "CLIA Agent Core hero gradient")

## Palette Anchors

- Deep base: `#0B1020` to `#1C356B`
- Electric accents: `#5EDCFF`, `#7B8CFF`, `#FF8EC6`
- Signal highlights: `#89F94F`, `#FFFC67`
- Neutral text: `#CFE3FF`

## Composition Recipe

1. Start with a two-stop or three-stop linear gradient background.
2. Add a subtle grid pattern at 12-26px to keep the space technical.
3. Layer one soft glow rectangle at 50-60% opacity.
4. Add crisp panels and strokes to imply instrumentation.

@Image(source: "diagram-a3-triad", alt: "Triad diagram with gradient panel")

## SVG Rules

- Keep SVGs ASCII-only and use fixed viewBox sizes.
- Prefer simple shapes over filters or blur for deterministic rendering.
- Keep stroke widths between 2 and 3 for diagrams at 720-1200px widths.
- Align gradient ids and pattern names so they stay stable across edits.

## File References

- Hero: `resources/hero-clia-agent.svg`
- Triad diagram: `resources/diagram-a3-triad.svg`
- Loop diagram: `resources/diagram-a3-loop.svg`
