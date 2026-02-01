# DocC Filesystem Alignment

@Metadata {
  @PageImage(purpose: icon, source: "docc-docc-design-system-filesystem-alignment-icon", alt: "Filesystem alignment icon")
  @PageImage(purpose: card, source: "docc-docc-design-system-filesystem-alignment-card", alt: "Filesystem alignment hero")
}

@Image(source: "docc-docc-design-system-filesystem-alignment-hero", alt: "Filesystem alignment hero")

Patterns for aligning DocC navigation with the physical file structure.

## Core Rule

**Navigation mimics the filesystem.**

The organization of articles in the `## Topics` section should reflect the directory structure of the source files. This reduces cognitive load when moving between the rendered site and the source code.

## File Naming

- **Kebab-case:** All files and directories must use `lower-case-kebab-case`.
- **Extensions:** Use `.md` for articles and `.docc` for bundles.
- **Root:** The main landing page file must be `index.md` (e.g., `brands.docc/index.md`).

## Topics Mirroring

When defining `## Topics` in a container article:

1.  **Groups:** Create a `### Group Name` for each subdirectory.
2.  **Links:** List the articles contained within that subdirectory.
3.  **Ordering:** Maintain a logical order (e.g., alphabetical or pedagogical) within the group, but keep the group boundary aligned with the folder.

### Example

**Filesystem:**
```text
brands.docc/
  index.md
  personal/
    alex.md
    bailey.md
  technical/
    engine.md
    platform.md
```

**index.md Topics:**
```markdown
## Topics

### Personal
- <doc:alex>
- <doc:bailey>

### Technical
- <doc:engine>
- <doc:platform>
```

## Anti-patterns

- **Virtual Folders:** Creating `### Group` headers that imply a folder structure that doesn't exist on disk.
- **Scattered Links:** Linking to a deep file (e.g., `technical/deep/ref.md`) from a high-level root without traversing the intermediate container.
- **Case Mixing:** Using `CamelCase` or `snake_case` filenames.

## Resources

- **Location:** Place all assets (images, videos, code files) in a single `resources/` directory at the root of the `.docc` bundle.
- **Uniqueness:** Filenames must be unique across the entire bundle because DocC flattens them during compilation.
- **Naming:** Use `kebab-case` for resource files (e.g., `hero-banner-v1.png`).
- **Referencing:** Reference assets by filename only, without paths (e.g., `@Image(source: "hero-banner-v1")`).

## Related guidance

- <doc:docc-design-system-file-organization>
- <doc:docc-design-system-published-websites>
