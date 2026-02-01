# Philographics for Main Agents (Codex + CLIA Take)

@Metadata {
  @PageImage(purpose: icon, source: "docc-docc-design-system-philographics-agents-icon", alt: "Icon")
  @PageImage(purpose: card, source: "docc-docc-design-system-philographics-agents-card", alt: "Card")
}
@Image(source: "docc-docc-design-system-philographics-agents-hero", alt: "Hero")


This page explores a small set of philographic tiles—Codex + CLIA’s take—branding our “main”
agents:

- Claude
- Codex
- CLIA
- Gemini
- Goose

The goal is not literal illustration. The goal is a consistent, emotive visual language that:

- reads at DocC card size,
- stays compatible with DocC (no scripts, no external fonts),
- and can be extended without style drift.

All tiles live in this bundle’s `resources/` directory:

- `philographic-agent-claude`
- `philographic-agent-codex`
- `philographic-agent-clia`
- `philographic-agent-gemini.castor`
- `philographic-agent-goose`

## The Set (Quick View)

@Row {
  @Column {
    @Image(source: "philographic-agent-claude", alt: "Philographic tile for agent Claude")
    Claude
  }
  @Column {
    @Image(source: "philographic-agent-codex", alt: "Philographic tile for agent Codex")
    Codex
  }
  @Column {
    @Image(source: "philographic-agent-clia", alt: "Philographic tile for agent CLIA")
    CLIA
  }
}

@Row {
  @Column {
    @Image(source: "philographic-agent-gemini.castor", alt: "Philographic tile for agent Gemini")
    Gemini
  }
  @Column {
    @Image(source: "philographic-agent-goose", alt: "Philographic tile for agent Goose")
    Goose
  }
}

## Rationale by Agent

### Claude

Design intent: calm, empathetic, and “holding space”.

- **Two soft halos** (left/right) read as an embrace and imply collaboration.
- **A central core** anchors the composition: clarity without sharpness.
- **Breathing animation** reinforces steady, human-paced guidance.

### Codex

Design intent: precise, build-oriented, “ship the patch”.

- **Angle brackets** cue code without using text.
- **A blinking cursor** suggests editing in place and iteration.
- **A sweep line** reads as validation/compilation: repeatable, deterministic progress.

### CLIA

Design intent: orchestration, structure, and repeatable rituals.

- **Three stacked pills** reference the “three-line header” and consistent UX surface.
- **A triangle** references triads (agent/agenda/agency) without naming them.
- **Pulsing nodes** communicate coordination: one system, many moving parts.

### Gemini

Design intent: duality, comparison, and multi-perspective synthesis.

- **Overlapping circles** represent parallel viewpoints and their intersection.
- **Mirrored arcs** hint at “two sides of the same system”.
- **Counter-drift motion** keeps the composition alive while staying balanced.

### Goose

Design intent: momentum, scouting, and playful forward motion.

- **A head + beak motif** keeps it recognizable with minimal geometry.
- **Curved trails** suggest navigation and “go-to” movement.
- **Dash + bob animation** reads as motion without feeling chaotic.

## How to Use These in DocC

- Use these tiles for **card** and **hero** imagery (branding), not as diagrams (content).
- Keep icons simple; agent philographics are usually too detailed for nav badges.
- If you derive a per-bundle card/hero from these:
  - keep the same primitives, radii, and palette logic
  - change only the framing (artboard + safe area)

See also:

- <doc:docc-design-system-philographics>
- <doc:simple-vector-graphics-philographics>
- <doc:docc-design-system-philographics-castor-reimagined>
