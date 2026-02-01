# SVG Authoring

@Metadata {
  @PageImage(purpose: icon, source: "svg-svg-authoring-icon", alt: "Icon")
  @PageImage(purpose: card, source: "svg-svg-authoring-card", alt: "Card")
}

@Image(source: "svg-svg-authoring-hero", alt: "Hero")

Guidelines for authoring SVGs for DocC.

## Tooling
- **Use a vector graphics editor:** Use a vector graphics editor like Sketch, Figma, or Adobe Illustrator to create SVGs.
- **Optimize SVGs:** Use a tool like SVGO to optimize SVGs for file size and performance.
- **Use a code editor for fine-tuning:** Use a code editor to fine-tune the SVG markup and to add animations and interactivity.

## Workflow
1. **Create the SVG in a vector graphics editor.**
2. **Export the SVG and optimize it.**
3. **Add the SVG to the `resources` directory of the DocC bundle.**
4. **Reference the SVG in your markdown file using the `@Image` tag.**
5. **Add a descriptive `alt` text to the `@Image` tag.**
6. **If the SVG is generated, add the appropriate suffix to the filename (e.g., `.castor.svg`).**

## Best Practices
- **Keep it simple:** Avoid unnecessary complexity in your SVGs.
- **Use meaningful filenames:** Use descriptive filenames that explain the content of the SVG.
- **Keep the source file:** If the SVG is generated from another format (e.g., Mermaid, PlantUML), keep the source file in the repository.
- **Document your SVGs:** Add comments to your SVG markup to explain complex or non-obvious parts.
