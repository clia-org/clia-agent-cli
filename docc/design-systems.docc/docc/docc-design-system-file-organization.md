# DocC File Organization

@Metadata {
  @PageImage(purpose: icon, source: "docc-docc-design-system-file-organization-icon", alt: "File organization icon")
  @PageImage(purpose: card, source: "docc-docc-design-system-file-organization-card", alt: "File organization hero")
}

@Image(source: "docc-docc-design-system-file-organization-hero", alt: "File organization hero")

Standards for the physical layout of DocC bundles in the repository.

## Overview

A standardized directory structure ensures that all DocC bundles are predictable, easy to navigate in the terminal, and consistent with the TUI design system.

## The Standard Directory Tree

Every `.docc` bundle must follow this organization pattern:

```text
[bundle-name].docc/
├── index.md               # Mandatory Technology Root
├── resources/             # Mandatory Flat asset directory
│   ├── [path]-icon.svg
│   ├── [path]-card.svg
│   └── [path]-hero.svg
├── [module]/              # Sub-directory for nested content
│   ├── [container].md     # Container article for the directory
│   └── [leaf-node].md     # Individual articles
└── tutorials/             # Optional: Interactive tutorials
    ├── tutorials.tutorial # Tutorial root
    └── resources/         # Tutorial-specific code snippets
```

## Core Rules

1.  **No `Documentation.md`:** The root article must be named `index.md`;
    `Documentation.md` is banned to prevent URL collisions. Standardizing on
    `index.md` also makes it possible to lint for exactly one `@TechnologyRoot`
    per bundle.
2.  **Lower-case kebab-case:** Every file and folder name must be lower-case and use hyphens as
    separators.
    - SwiftPM naming note: keep the repo URL path component and package name in lower-case
      kebab-case, while product names remain `UpperCamelCase` for imports. See
      https://louzell.com/notes/spm/ and
      https://forums.swift.org/t/repo-convention-and-swiftpm-library-name-for-least-surprises/75696.
3.  **Globally unique filenames:** DocC identifiers are derived from file paths. If you want
    short links like `doc:meta-2025` (no directory prefix), the file must live at the bundle
    root and the filename must be unique across the entire bundle (for example,
    `meta-2025.md`). Avoid directory-qualified identifiers like `doc:meta/meta-2025`.
4.  **Flat Resources:** All images, videos, and static files live in the top-level `resources/`
    directory. Sub-folders inside `resources/` are prohibited.
5.  **Container Articles:** Any directory containing more than 2 files must have a sibling `.md`
    file (or a file inside it) that serves as the container index.

## Hosting Layout (public vs private)

Public DocC bundles are hosted on GitHub Pages; private bundles are rendered by local apps.

- **Public (GitHub Pages):**
  - Users: `github/users/<user>/public/docc/pages/<user>.github.io/<bundle>.docc/index.md`
  - Orgs: `github/orgs/<org>/public/docc/pages/<org>.github.io/<bundle>.docc/index.md`
- **Private (Local app):** `docc/private/host/local/<bundle>.docc/index.md`

Keep `index.md` only inside `.docc` bundles. Use `README.md` for non‑bundle folders.

## GitHub Pages publishing flow

Only public bundles are published via GitHub Pages workflows.

- **todo3:** each public GitHub Pages repo under
  `github/users/<user>/public/docc/pages/<user>.github.io/` or
  `github/orgs/<org>/public/docc/pages/<org>.github.io/` ships its own
  `.github/workflows/publish.yml`.
- **mono:** `code/mono/.github/workflows/docs.yml` builds public bundles under
  `code/mono/docc/public/host/github/`.

Private bundles are not published; they live under `docc/private/host/local/` and are rendered by
local apps.

## Related guidance

- <doc:docc-design-system-published-websites>

## Structure Examples

### 1. Flat Bundle (Simple)
For small bundles with few articles.

```text
portfolio.docc/
├── index.md
├── about.md
├── projects.md
└── resources/
    ├── portfolio-icon.svg
    └── ...
```

### 2. Nested Bundle (Complex)
For documentation with logical sub-sections (e.g., a blog or multi-brand registry).

```text
brands.docc/
├── index.md
├── resources/
├── personal/
│   ├── personal.md        # Container for this folder
│   ├── alex.md
│   └── bailey.md
└── technical/
    ├── technical.md       # Container for this folder
    ├── engine.md
    └── platform.md
```

## Anti-patterns

- **Deep Nesting:** Avoid nesting directories more than 3 levels deep. Flatten the structure where possible.
- **Dangling Files:** Every `.md` file must be physically located in the directory corresponding to its logical curation.
- **Mixing Case:** Never use `Resources/` or `Articles/`. Stick to `resources/` and kebab-case folder names.

## Syncing Filesystem & Navigation

The physical directory structure should be invisible to the user but intuitive to the developer. To keep them in sync:

1.  **Directory Mapping:** For every subdirectory in your bundle, create a corresponding `### Topic Group` in the parent article's `## Topics` section.
2.  **Container Articles:** If a folder is named `blog/`, there should be a `blog.md` article at the same level as the folder (or inside it) that serves as the logical "Folder" in the DocC UI.
3.  **One-to-One Curation:** Only curate the immediate contents of a directory in its container article. This creates the "Nested Folder" look in the navigation panel.
4.  **Shadow Paths:** If you move a file into a subdirectory on disk, you MUST update its curation link in the Markdown to ensure the breadcrumbs and sidebar reflect the new physical location.

### Rule of Thumb
If you are looking at a folder in your terminal, the files you see should match the links you see in the sidebar when navigating that section of the site.
