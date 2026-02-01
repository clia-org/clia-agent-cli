# DocC Design System Authoring

@Metadata {
  @PageImage(purpose: icon, source: "docc-docc-design-system-authoring-icon", alt: "Icon")
  @PageImage(purpose: card, source: "docc-docc-design-system-authoring-card", alt: "Card")
}
@Image(source: "docc-docc-design-system-authoring-hero", alt: "Hero")


Authoring conventions for DocC articles and tutorials.

## Metadata Directives

- Place `@Metadata { ... }` directly after the title.
- Malformed `@Metadata` blocks can prevent a page from rendering; keep the block valid and closed.
- Use `@TechnologyRoot` for hub pages.
- Use bare color names with `@PageColor(blue)` (no leading dot).
- Provide `@PageImage(purpose: icon|card, source: "...", alt: "...")` when needed.
- Add `@TitleHeading`, `@CallToAction`, and availability directives only when applicable.

## Options Directives

- Use `@Options { @TopicsVisualStyle(list|compactGrid|detailedGrid|hidden) }` for Topics layout.
- Disable auto sections only when you provide an explicit alternative.

## Link Syntax

- Use double backticks for real symbols, not DocC article slugs.
- Doc links use `<doc:docc-design-system>` for rendered pages.
- When a page is a folder index (for example, `ios-scaling-challenges.md` at the bundle root),
  link to its child pages with `<doc:child-article>` so DocC resolves the topics as siblings.

## Authoring Conventions

- Write in a clear, concise voice; avoid abbreviations and one-letter shorthand.
- Use fenced code blocks with language tags; keep lines within markdown limits.
- In articles (`*.md`), keep code in fenced blocks; `@Code` is tutorial-only and ignored in
  articles.
- When you want a single source of truth for Mermaid or other diagram sources, use a generator
  to inject the source into the article before preview/build; do not rely on `@Code` in articles.
- Keep lists and headings structured; avoid walls of text.

## Code Blocks (Commands and Recipes)

- Prefer small, copy-pastable command blocks with an explicit language tag (`bash`, `swift`).
- Keep one primary intent per block (validate, render, preview); avoid mixing steps.
- Favor long-form flags in examples so usage is self-documenting.
- If a command produces a canonical URL, print it in the surrounding prose, not in the code block.

## Redirects and Media

- Use `@Redirected(from: "old/path")` when you change a page slug.
- Provide `@Image` and `@Video` with clear `alt` text.
