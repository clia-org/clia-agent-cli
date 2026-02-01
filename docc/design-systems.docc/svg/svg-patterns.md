# SVG Patterns

@Metadata {
  @PageImage(purpose: icon, source: "svg-svg-patterns-icon", alt: "Icon")
  @PageImage(purpose: card, source: "svg-svg-patterns-card", alt: "Card")
}

@Image(source: "svg-svg-patterns-hero", alt: "Hero")

Common structural and visual patterns for creating high-quality SVGs for DocC.

## SVG Structure
- **Use a `<title>` element:** Every SVG should have a descriptive title that explains its content.
- **Use a `<style>` block for CSS:** Keep all CSS within a `<style>` block in the SVG file. Use CSS variables for theming.
- **Group elements with `<g>`:** Use groups to organize related elements and to apply transformations.
- **Use descriptive IDs:** Assign descriptive IDs to all groups and elements that are targeted by animations or scripts.

## Visual Style
- **Use the design system's color palette:** All SVGs should use the color palette defined in the design system.
- **Use a consistent stroke width:** Use a consistent stroke width for all shapes and lines.
- **Use a consistent corner radius:** Use a consistent corner radius for all rounded rectangles.
- **Use a consistent font:** Use the design system's font for all text elements.

## Animation
- **Use CSS animations or SMIL:** Prefer CSS animations for simple animations and SMIL for more complex ones.
- **Keep animations short and meaningful:** Animations should be used to enhance understanding, not to distract.
- **Use easing functions:** Use easing functions to make animations feel more natural and engaging.

## Accessibility
- **Provide `alt` text:** All `@Image` tags that reference SVGs should have descriptive `alt` text.
- **Use ARIA attributes:** Use ARIA attributes to make SVGs more accessible to screen readers.
- **Ensure sufficient color contrast:** Ensure that the color contrast between text and background is sufficient for people with visual impairments.
