# DocC Light and Dark UI Examples

@Metadata {
  @PageImage(purpose: icon, source: "docc-docc-ui-light-dark-examples-icon", alt: "Icon")
  @PageImage(purpose: card, source: "docc-docc-ui-light-dark-examples-card", alt: "Card")
}
@Image(source: "docc-docc-ui-light-dark-examples-hero", alt: "Hero")


Use this page to compare light and dark UI mocks inside DocC. The dark tab is first so it
renders as the default selection.

@TabNavigator {
  @Tab("dark") {
    ![Dark UI cursor mock](docc-ui-cursor-dark.svg)
  }
  @Tab("light") {
    ![Light UI cursor mock](docc-ui-cursor-light.svg)
  }
}

## Notes

- The cursor uses a simple SVG blink animation to validate DocC rendering.
- Keep the mock centered so visual alignment changes are obvious.
