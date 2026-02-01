# DocC Design System Layout

@Metadata {
  @PageImage(purpose: icon, source: "docc-docc-design-system-layout-icon", alt: "Icon")
  @PageImage(purpose: card, source: "docc-docc-design-system-layout-card", alt: "Card")
}
@Image(source: "docc-docc-design-system-layout-hero", alt: "Hero")


Layout helpers for DocC content.

## Related Minimum Layout Pages

- <doc:overview>
- <doc:motivation>
- <doc:design>
- <doc:architecture>
- <doc:implementation>
- <doc:getting-started>

## Layout and Navigation Helpers

- Use `@Row` and `@Column` for grid layouts.
- Use `@TabNavigator` and `@Tab` for multi-category hubs where sections are interchangeable
  (for example, light vs dark screenshots).
- Use `@Links(visualStyle: ...) { - <doc:...> }` to render link cards outside Topics.
- Use `@Small { ... }` for footnotes and constraints.

## Tabs (When to Use Them)

Use tabs to compare parallel views of the same content.

Good fits:

- Light vs dark mode images.
- Platform-specific UI screenshots that have the same narrative step.
- Two equivalent renderings of a diagram (static vs animated) when both are optional.

Avoid tabs when the reader must see both sections to complete the story:

- Sequential “do this, then that” flows (use headings and code blocks instead).
- Checklists where hiding a section increases mistakes.
