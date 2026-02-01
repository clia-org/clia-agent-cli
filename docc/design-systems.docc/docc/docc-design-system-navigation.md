# DocC Navigation Systems

@Metadata {
  @PageImage(purpose: icon, source: "docc-docc-design-system-navigation-icon", alt: "Navigation icon")
  @PageImage(purpose: card, source: "docc-docc-design-system-navigation-card", alt: "Navigation hero")
}

@Image(source: "docc-docc-design-system-navigation-hero", alt: "Navigation hero")

Patterns for predictable, hierarchical navigation in DocC.

## Overview

DocC navigation is derived from the **Curation Tree** defined in your `## Topics` sections. A well-structured tree results in a clean sidebar, helpful breadcrumbs, and a responsive mobile experience.

## Static Hosting URL Mapping

DocC uses a fixed `/documentation/` prefix for article URLs when exporting for static hosting. The
**bundle name** is part of the URL for documentation catalogs.

- **Tech Root filename:** `index.md` resolves to `/documentation/<bundle>/`.
- **Other articles:** `ios-scaling-challenges.md` resolves to
  `/documentation/<bundle>/ios-scaling-challenges/`.
- **Nested articles:** `ios-scaling-challenges/01-state-management.md` resolves to
  `/documentation/<bundle>/01-state-management/`. Directory names do **not** appear in the URL.

For the GitHub Pages DocC sites in this repo, the tech root filename is `index.md`.

Resources follow the same rule: DocC flattens them, so nested resource
folders do not appear in the published URLs.
Example: `resources/mermaid/ios-scaling-challenges-01-state-management-context.svg` resolves to
`/documentation/<bundle>/ios-scaling-challenges-01-state-management-context.svg`.

DocC assets (CSS/JS) are emitted at the root (`/css`, `/js`, etc.). For GitHub Pages at
`https://<user>.github.io/`, set `--hosting-base-path /` so the asset URLs resolve correctly.

## The Curation Rule

Navigation is driven by the **Curation Tree** in `## Topics`, not by folders on disk.

- **Root:** The `@TechnologyRoot` is the source of all navigation.
- **Containers:** Container articles are **pages** (for example, `blog.md`), not folders.
- **Leaf Nodes:** Individual articles or symbols.
- **Filesystem:** Directories are organizational only; they do **not** create nav nodes or dropdowns.
- **Articles list:** Any article not curated into `## Topics` will still appear under **Articles**.

## Sidebar Dropdowns

To achieve nested dropdowns in the sidebar:
1.  The parent (Root) links only to the **Container**.
2.  The **Container** then links to its **Children**.

This creates a "Folder > File" relationship in the UI.

## Anti-Pattern: Double Curation (the Flat List)

Never list a container's children on the container's parent page. This creates a redundant, flat list that clutters the UI and breaks the logical dropdown model.

### Correct (Nested)
- `index.md` (Root)
    - Links to `blog.md`
- `blog.md` (Container)
    - Links to `post-1.md`, `post-2.md`

### Incorrect (Duplicate)
- `index.md`
    - Links to `blog.md`
    - Links to `post-1.md` ❌
    - Links to `post-2.md` ❌

## Navigation Elements

### Breadcrumbs
Breadcrumbs are automatically generated based on the shortest curation path from the root. If you "Double Curate" an article, the breadcrumbs may become unpredictable.

### Sidebar (Local Navigation)
The sidebar displays the current hierarchy. To keep the sidebar scannable:
- Keep `### Group` names short (1-2 words).
- Limit the number of groups per page to 3-5.
- Ensure every article has `@PageKind(article)` to prevent it from being hidden or miscategorized.

## Standardized Topic Groups

Use these standard headers for consistency across the repository:

| Group Name | Intent |
| :--- | :--- |
| `### Overview` | Foundations, principles, and high-level summaries. |
| `### Identity` | Branding, profiles, and personas. |
| `### Ecosystems` | Related catalogs or sub-bundles. |
| `### Guides` | How-to articles and workflows. |
| `### Reference` | Technical specs and API symbols. |
| `### Archive` | Legacy content or historical logs. |

## Disabling Auto-Sections

To maintain total control over the navigation panel, every article MUST include:

```markdown
@Options {
  @AutomaticSeeAlso(disabled)
}
```

This prevents DocC from injecting "See Also" links at the bottom of pages, which often creates duplicate navigation paths.
