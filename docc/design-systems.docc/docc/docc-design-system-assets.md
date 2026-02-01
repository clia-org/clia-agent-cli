# DocC Design System Assets

@Metadata {
  @PageImage(purpose: icon, source: "docc-docc-design-system-assets-icon", alt: "Icon")
  @PageImage(purpose: card, source: "docc-docc-design-system-assets-card", alt: "Card")
}
@Image(source: "docc-docc-design-system-assets-hero", alt: "Hero")


Guidance for DocC visuals, SVGs, and asset naming.

## Visual System

- Use consistent page images and color metadata when provided.
- Keep diagrams accessible: legible text size and clear contrast.
- Prefer neutral, readable palettes for DocC pages and embedded SVGs.
- Use `@PageColor` to keep related topics visually grouped.
- Choose one style mode per hub: elegant, colorful, or minimal.
- Add callouts for intent: use Note, Warning, and Important with short guidance.
- Use `theme-settings.json` plus a CSS file in `resources/` to apply DocC theming.
- Keep palette tokens in CSS and JSON so diagrams and tooling can share the same colors.
- Use distinct icons for cards while keeping a shared motif so hubs feel cohesive.
- Default to transparent backgrounds for hero, card, and icon SVGs (no hard backplates).
- Every SVG asset must include a generator signature (`castor`, `codex`, or `mermaida`).

## Overview Images and Hero Banners

- Use `@PageImage(purpose: icon, ...)` so the page has a consistent navigation badge.
- Use `@PageImage(purpose: card, ...)` for hub pages so topic cards look intentional.
- Keep the summary paragraph text-only, then place the hero image directly after it:
  `@Image(source: "...", alt: "...")`.
- Prefer a consistent hero artboard (for example, 1200x360) and reuse it across a small set of
  related pages.

## Hero Image Styles (Edge Transparency)

Hero images must be transparent or fade to transparent at the edges. Avoid hard backplates.
This transparency rule is the default for hero, card, and icon assets.

@Row {
  @Column {
    @Image(source: "docc-docc-design-system-assets-hero-style-transparent-halo.castor",
      alt: "Hero style: transparent halo")
    **Transparent halo**
    @Small { No background fill. Use soft glow geometry only. }
  }
  @Column {
    @Image(source: "docc-docc-design-system-assets-hero-style-edge-fade.castor",
      alt: "Hero style: edge fade")
    **Edge fade overlay**
    @Small { Shapes stay centered while edges blend to transparent. }
  }
  @Column {
    @Image(source: "docc-docc-design-system-assets-hero-style-radial-fade.castor",
      alt: "Hero style: radial fade")
    **Radial fade mask**
    @Small { Mask the composition so the outer ring dissolves. }
  }
}

## Gradients (for DocC-friendly SVGs)

- Prefer simple `linearGradient` fills with 2 to 3 stops.
- Layer a subtle grid pattern on top for texture; keep stroke opacity low.
- Avoid filters, masks, and blend modes unless you have a clear compatibility reason.
- Keep gradients as background accents; do not reduce body text contrast.
- Keep SVG backgrounds transparent and avoid hard-coded light/dark backplates; ensure strokes/fills
  stay legible in both light and dark DocC themes.

## Card SVGs and Dashboards

- Keep the artboard transparent; any card fill must be inset and softly faded (not full-bleed).
- Use card primitives: `rx` corner radius, a soft border stroke, and a calm, low-opacity fill.
- Prefer a small set of recurring radii (for example, 14, 18, 22) to keep the system cohesive.
- Keep stroke widths consistent across a diagram family and align to whole or half pixels.
- Use a single visual rhythm: columns, cards, and labels should share a baseline grid.
- Treat the first screen as an overview: one diagram that explains the system at a glance.

## The Triple Visual Standard (3 SVGs Per Page)

Every high-intent article (Overview, How-to, Epic) must provide three distinct SVG assets to ensure consistent rendering across all DocC surfaces:

1.  **Icon (24x24):** Simple geometry, stroke-focused. Used for navigation badges.
    - *Naming:* `[page-path]-icon.svg`
    - *Metadata:* `@PageImage(purpose: icon, source: "...")`
    - *Constraint:* Do not use animation in icon SVGs. Animation is reserved for card and hero SVGs.
    - *Background:* Transparent only. Avoid any full-bleed backplate.
2.  **Card (512x512):** The primary Philographic tile. Used for Topic grids.
    - *Naming:* `[page-path]-card.svg`
    - *Metadata:* `@PageImage(purpose: card, source: "...")`
    - *Background:* Transparent artboard; use inset, softly faded fills only.
3.  **Hero (1200x360):** Wide banner. Establishes the "mood" at the top of the body.
    - *Naming:* `[page-path]-hero.svg`
    - *Placement:* Use `@Image(source: "...", alt: "...")` directly after the summary.
    - *Background:* Transparent or fades to transparent at the edges.

## Philographics (Emotive Branding)



- Use philographics as a consistent **card/hero visual language** for a DocC bundle.
- Keep them emotive, not literal: the shape signals the page’s intent, while the title and prose
  carry the meaning.
- Pick a small, reusable set per bundle (motifs + colors) so grids feel cohesive.
- Avoid using philographics as diagrams or data: they are branding, not content.

See: <doc:docc-design-system-philographics>.
