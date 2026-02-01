# DocC Resource Naming Guidelines

@Metadata {
  @PageImage(purpose: icon, source: "docc-docc-design-system-resource-naming-icon", alt: "Resource naming icon")
  @PageImage(purpose: card, source: "docc-docc-design-system-resource-naming-card", alt: "Resource naming hero")
}

@Image(source: "docc-docc-design-system-resource-naming-hero", alt: "Resource naming hero")

Standardized conventions for naming and organizing assets in DocC bundles.

## Overview

DocC processes resources (images, videos, snippets) into a **flat global namespace**. To prevent collisions, ensure auditability, and align with the TUI design system, all resources must follow a strict, path-prefixed naming convention that reflects the article path.

## The Naming Formula

All asset filenames MUST follow this structure:

`[page-path]-[resource-name]-[type].[extension]`

- **page-path:** The kebab-cased path to the article using the resource, derived from the `.docc` bundle subpath (for example, `blog/2023-10-30-swift-type-inference-performance` → `blog-2023-10-30-swift-type-inference-performance`).
- **resource-name:** A descriptive name for the asset.
- **type:** The standardized visual role (`icon`, `card`, `hero`, `diagram`).

## Do's and Don'ts

### Do ✅

- **Use lower-case kebab-case:** Always use `my-image-name.svg`, never `MyImageName.svg`.
- **Prefix with the article path:** Ensure the name is unique bundle-wide (e.g., `blog-thoughts-on-friction-hero.svg`).
- **Centralize in `resources/`:** Place all assets in the root `resources/` directory (lowercase) of the bundle.
- **Use meaningful types:** Stick to `icon`, `card`, and `hero` for philographic assets.
- **Reference by filename only:** In Markdown, use `@Image(source: "my-image")` without the file extension or path.

### Don't ❌

- **Don't use generic names:** Never name a file `image.png`, `hero.svg`, or `icon.png`. They WILL collide.
- **Don't use spaces or underscores:** Only hyphens (`-`) are allowed as separators.
- **Don't nest resources:** Do not create subdirectories like `resources/images/`. DocC ignores them or flattens them inconsistently across versions.
- **Don't include the path in Markdown:** Never write `@Image(source: "resources/my-image")`. DocC handles the lookup automatically from the flat namespace.
- **Don't use CamelCase:** It is harder to type in the terminal and inconsistent with the TUI design system.

## Comparison Table

| Scenario | Correct ✅ | Incorrect ❌ |
| :--- | :--- | :--- |
| **Landing Page Hero** | `home-hero.svg` | `hero.svg` |
| **Blog Post Icon** | `blog-swift-performance-icon.svg` | `icon.png` |
| **Technical Diagram** | `foundry-init-flow-diagram.svg` | `FoundryFlow.svg` |
| **Personal Avatar** | `about-me-avatar.jpg` | `My_Photo.JPG` |

## Resource Lifecycle

### Auditability
By including the page path in the filename, we can automatically detect "orphaned" resources. If `blog-post-alpha-hero.svg` exists but `blog/post-alpha.md` does not, the asset is a candidate for deletion.

### Maintenance
Standardized naming allows for batch operations. For example, a script can easily find and update all `-icon.svg` files to a new stroke weight because their role is encoded in their name.
