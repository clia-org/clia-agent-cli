# SVG Anti-Patterns

@Metadata {
  @PageImage(purpose: icon, source: "svg-svg-anti-patterns-icon", alt: "Icon")
  @PageImage(purpose: card, source: "svg-svg-anti-patterns-card", alt: "Card")
}

@Image(source: "svg-svg-anti-patterns-hero", alt: "Hero")

Common mistakes and anti-patterns to avoid when creating SVGs.

## Anti-Patterns

- **Using inline styles:** Do not use inline styles. Use a `<style>` block instead.
- **Using non-standard fonts:** Do not use non-standard fonts. Use the design system's font.
- **Using complex animations:** Do not use complex or distracting animations. Animations should be used to enhance understanding, not to distract.
- **Not providing `alt` text:** Always provide descriptive `alt` text for all `@Image` tags that reference SVGs.
- **Ignoring accessibility:** Do not ignore accessibility. Ensure that your SVGs are accessible to people with disabilities.
- **Not optimizing SVGs:** Do not forget to optimize your SVGs for file size and performance.
- **Using meaningless filenames:** Do not use meaningless filenames. Use descriptive filenames that explain the content of the SVG.
- **Not version-controlling the source:** If the SVG is generated, do not forget to version-control the source file.
- **Using external resources:** Do not use external resources in your SVGs. All resources should be self-contained.
- **Using scripts:** Do not use scripts in your SVGs. DocC does not execute scripts.
- **Hard-coding colors:** Do not hard-code colors. Use CSS variables for theming.
