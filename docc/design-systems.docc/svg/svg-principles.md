# SVG Design System Principles

@Metadata {
  @PageImage(purpose: icon, source: "svg-svg-principles-icon", alt: "Icon")
  @PageImage(purpose: card, source: "svg-svg-principles-card", alt: "Card")
}

@Image(source: "svg-svg-principles-hero", alt: "Hero")

## Principles

- **Self-contained and script-free:** SVGs must be self-contained and not rely on external scripts or resources.
- **Deterministic and version-controlled:** SVGs should be generated in a deterministic way and their source (e.g., Mermaid code) should be version-controlled.
- **Accessible and themeable:** SVGs should be designed to be accessible (e.g., with proper `alt` text and ARIA attributes) and support theming (e.g., via CSS variables for colors).
- **Signed when generated:** Generated SVGs should be "signed" with a suffix to indicate their origin (e.g., `placeholder.svg`, `mermaid.svg`, `castor.svg`, and `codex.svg`).
- **Optimized for performance:** SVGs should be optimized for file size and rendering performance.
