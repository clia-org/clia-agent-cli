# Philographics for DocC Branding

@Metadata {
  @PageImage(purpose: icon, source: "docc-docc-design-system-philographics-icon", alt: "Icon")
  @PageImage(purpose: card, source: "docc-docc-design-system-philographics-card", alt: "Card")
}
@Image(source: "docc-docc-design-system-philographics-hero", alt: "Hero")


Philographics are emotive, geometric “tiles” that communicate a tone at a glance. They work well as
DocC **card** and **hero** imagery because they stay legible when scaled down and they do not
compete with code or diagrams.

Use them as a *branding layer*:

- pick a consistent mood for a DocC bundle (or a section within a bundle),
- reuse a small set of motifs across pages, and
- let titles and content carry the meaning.

This page includes ready-to-use examples in the design-systems bundle resources:

- `philographic-calm`
- `philographic-focus`
- `philographic-clarity`
- `philographic-curious`
- `philographic-balance`
- `philographic-growth`
- `philographic-celebrate`
- `philographic-stability`
- `philographic-danger`

## Agent Philographics (Exploration)

The same “emotive tile” approach also works for branding an *agent persona*.
See the exploration page (with rationale):

- <doc:docc-design-system-philographics-agents>

For an alternative, holographic take on agent identity:

- <doc:docc-design-system-philographics-castor-reimagined>

## When to Use Philographics

Best fits:

- **Technology roots** and hub pages (card images on grid layouts).
- **Overview** pages where the goal is orientation, not precision.
- **How-to** pages where a calm, consistent look reduces friction.
- **Checklists** and “shipping gates” pages where you want a strong visual “this matters” banner.

Avoid:

- **Reference** pages where the image distracts from symbol navigation.
- **Diagrams** where the image can be mistaken for data.
- **Color-only meaning** (accessibility): the shape should still convey intent without hue.

## Rules for “Emotive, Not Distracting”

- Prefer **2–4 primitives** (circle, triangle, rectangle, line) per tile.
- Keep **1 focal point**; avoid tiny details.
- Use **layers and opacity** instead of many colors.
- Keep a **safe area** around edges (no important geometry within ~48px of the border on a 512px
  tile).
- Choose **one motif family** per bundle (targets, overlaps, wedges, rays) and reuse it.
- If the bundle uses DocC theming, align tile colors with your palette tokens (no random one-offs).

## Mapping Moods to DocC Intent

Use a simple, consistent mapping so readers learn the visual language:

- **Calm** → orientation, onboarding, getting-started
- **Focus** → deep dives, concentrated tasks, “do this carefully”
- **Clarity** → definitions, glossary pages, “here is the model”
- **Curious** → exploration, experiments, research notes
- **Balance** → trade-offs, architecture, comparisons
- **Growth** → roadmap, iteration, migration
- **Celebrate** → release notes, milestones, wins
- **Stability** → invariants, contracts, compatibility
- **Danger** → incidents, breaking changes, sharp edges

## Examples (Ready-to-use Tiles)

@Row {
  @Column {
    @Image(source: "svg-philographics-calm-card", alt: "Philographic tile: calm")
    Calm
  }
  @Column {
    @Image(source: "svg-philographics-focus-card", alt: "Philographic tile: focus")
    Focus
  }
  @Column {
    @Image(source: "svg-philographics-clarity-card", alt: "Philographic tile: clarity")
    Clarity
  }
}

@Row {
  @Column {
    @Image(source: "svg-philographics-curious-card", alt: "Philographic tile: curious")
    Curious
  }
  @Column {
    @Image(source: "svg-philographics-balance-card", alt: "Philographic tile: balance")
    Balance
  }
  @Column {
    @Image(source: "svg-philographics-growth-card", alt: "Philographic tile: growth")
    Growth
  }
}

@Row {
  @Column {
    @Image(source: "svg-philographics-celebrate-card", alt: "Philographic tile: celebrate")
    Celebrate
  }
  @Column {
    @Image(source: "svg-philographics-stability-card", alt: "Philographic tile: stability")
    Stability
  }
  @Column {
    @Image(source: "svg-philographics-danger-card", alt: "Philographic tile: danger")
    Danger
  }
}

## How to Apply to a DocC Page

- Prefer `@PageImage(purpose: card, ...)` + `@Image(source: "...-hero", ...)` for consistent
  navigation and scanning.
- Keep the card/hero images **derived** from your chosen philographic motif (same primitives,
  radii, and color logic), even if the artboard changes.

See also:

- <doc:simple-vector-graphics-images>
- <doc:simple-vector-graphics-docc-considerations>
- <doc:docc-design-system-philographics-castor-concepts>
