# DocC Design System Patterns

@Metadata {
  @PageImage(purpose: icon, source: "docc-docc-design-system-patterns-icon", alt: "Icon")
  @PageImage(purpose: card, source: "docc-docc-design-system-patterns-card", alt: "Card")
}

@Image(source: "docc-docc-design-system-patterns-hero", alt: "Hero")

Common structural patterns are split into focused guides.

@Links(visualStyle: list) {
  - <doc:docc-design-system-structure>
  - <doc:docc-design-system-authoring>
  - <doc:docc-design-system-assets>
  - <doc:simple-vector-graphics>
  - <doc:docc-design-system-layout>
  - <doc:docc-design-system-preview>
}
 
Patterns we expect across every DocC bundle:

- Require a technology root with a clear title, purpose, and entry topics.
- Add `@Metadata { @TechnologyRoot }` to the root article so DocC renders a landing page.
- The root article becomes the top-level entry at `/documentation/<bundle>/`.
- Link modules and curated articles from the root to build the hierarchy.
- Use predictable page naming and stable slugs; favor lower-case file names.
- Group pages by intent: overview, tutorials, how-to, reference, and guides.

## Recommended Minimum Layout

- Root article with `@TechnologyRoot` and `## Topics`.
- `overview.md`: purpose, scope, and audience.
- `motivation.md`: why the work exists and what constraints shape it.
- `design.md`: design principles and trade-offs.
- `architecture.md`: component map and data flows.
- `implementation.md`: key paths, conventions, and extension points.
- `getting-started.md`: the smallest working path for new users.

## Documentation.md vs Technology Root

- DocC will render a default `Documentation.md` entry when no explicit root is provided.
- Prefer an explicit root article with `@TechnologyRoot` so the landing page and URL are clear.
- Use `index.md` as the root filename to avoid `/documentation/documentation` URLs.
- `Documentation.md` is banned in this repo; always author an explicit root article instead.
- Standardize on `index.md` so lint rules can enforce a single `@TechnologyRoot` per bundle.
- The technology root filename should be `index.md` so the bundle name controls the root URL
  (for example, `index.md` → `/documentation/<bundle>/`).

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

## Navigation and Topics

- Keep the Topics section short and scannable; use nested lists sparingly.
- Link laterally with `doc:` only when it improves flow; avoid circular loops.
- Promote the primary narrative path before optional deep dives.
- Split dense hubs into dedicated pages with a consistent structure.
- Use categorized grids for large sets so cards are scannable at a glance.

## Page Types

- Overview: purpose, scope, and audience.
- Motivation: constraints, risks, and why the work matters.
- Design: architecture choices and trade-offs.
- Architecture: component map and data flows.
- Implementation: conventions, extension points, and practical details.
- Getting started: smallest working path for new users.
- How-to: goal-oriented, step-driven instructions.
- Reference: precise, minimal, and anchored to API symbols.
- Tutorials: Swift-based `*.tutorial` files with `@Tutorials` and `@Tutorial` blocks.

## Tutorials

- Keep one `@Tutorial` per `*.tutorial` file with `@Intro`, `@Section`, `@ContentAndMedia`, and
  `@Steps`.
- Use a `Tutorials.tutorial` root with `@Tutorials`, `@Chapter`, and `@TutorialReference` entries.
- Write plain prose in tutorial blocks; avoid `Text("...")` wrappers.
- Prefer `@Code(file:)` and place snippet files under `resources/`.
- Use `@Code(name:file:)` with `.swift` in the name so the pane reads like a file.
- Use `reset: true` when a step should show a clean reference implementation.
- Keep `@Assessments` at the tutorial top level, not under `@Section`.

## Visual System

- Use consistent page images and color metadata when provided.
- Keep diagrams accessible: legible text size and clear contrast.
- Prefer neutral, readable palettes for DocC pages and embedded SVGs.
- Use `@PageColor` to keep related topics visually grouped.
- Choose one style mode per hub: elegant, colorful, or minimal.
- Add callouts for intent: use Note, Warning, and Important with short guidance.
- Use `theme-settings.json` plus a CSS file in `resources/` to apply DocC theming.
- Keep palette tokens in CSS and JSON so diagrams and tooling can share the same colors.
- Use distinct icons for cards while keeping a shared motif so hubs feel cohesive.

## Overview Images and Hero Banners

- Use `@PageImage(purpose: icon, ...)` so the page has a consistent navigation badge.
- Use `@PageImage(purpose: card, ...)` for hub pages so topic cards look intentional.
- Keep the summary paragraph text-only, then place the hero image directly after it:
  `@Image(source: "...", alt: "...")`.
- Prefer a consistent hero artboard (for example, 1200x360) and reuse it across a small set of
  related pages.

## Philographics (Emotive Branding)

- Use philographics as a consistent **card/hero visual language** for a DocC bundle.
- Keep them *emotive, not literal*: the shape signals the page’s intent, while the title and prose
  carry the meaning.
- Pick a small, reusable set per bundle (motifs + colors) so grids feel cohesive.
- Avoid using philographics as diagrams or data: they are branding, not content.

See: <doc:docc-design-system-philographics>.

## Gradients (for DocC-friendly SVGs)

- Prefer simple `linearGradient` fills with 2 to 3 stops.
- Layer a subtle grid pattern on top for texture; keep stroke opacity low.
- Avoid filters, masks, and blend modes unless you have a clear compatibility reason.
- Keep gradients as background accents; do not reduce body text contrast.

## Card SVGs and Dashboards

- Use card primitives: `rx` corner radius, a soft border stroke, and a calm background fill.
- Prefer a small set of recurring radii (for example, 14, 18, 22) to keep the system cohesive.
- Keep stroke widths consistent across a diagram family and align to whole/half pixels.
- Use a single visual rhythm: columns, cards, and labels should share a baseline grid.
- Treat the first screen as an overview: one diagram that explains the system at a glance.

## Authoring Conventions

- Write in a clear, concise voice; avoid abbreviations and one-letter shorthand.
- Use fenced code blocks with language tags; keep lines within markdown limits.
- In articles (`*.md`), keep code in fenced blocks; `@Code` is tutorial-only and ignored in
  articles.
- When you want a single source of truth for Mermaid or other diagram sources, use a generator
  to inject the source into the article before preview/build; do not rely on `@Code` in articles.
- Keep lists and headings structured; avoid walls of text.

## Assets and Resources

- Place snippets in `resources/` alongside the bundle.
- Name assets with lower-case, kebab-case file names.
- Document any generated assets and their source inputs.
- Keep icons on a 24x24 grid with simple geometry and consistent stroke weights.
- Use `@PageImage(purpose: icon, ...)` for navigation badges and `@PageImage(purpose: card, ...)`
  for hub cards.
- Keep SVG assets ASCII-only and store them with stable filenames in `resources/`.
- Use `docc-wrkstrm palette` to emit CSS/JSON tokens for DocC theming when needed.
- Prefer SVG diagrams with embedded CSS variables and `prefers-color-scheme` support.
- Keep diagram source formats (Mermaid, etc.) alongside rendered SVG outputs.

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

## Code Blocks (Commands and Recipes)

- Prefer small, copy-pastable command blocks with an explicit language tag (`bash`, `swift`).
- Keep one primary intent per block (validate, render, preview); avoid mixing steps.
- Favor long-form flags in examples so usage is self-documenting.
- If a command produces a canonical URL, print it in the surrounding prose, not in the code block.

## Redirects and Media

- Use `@Redirected(from: "old/path")` when you change a page slug.
- Provide `@Image` and `@Video` with clear `alt` text.

## Tooling and Preview

- Document preview commands and any required renderer configuration.
- Call out custom CSS or renderer overrides explicitly.
- Record known warnings with a plan to resolve or justify them.
- When using a custom renderer, set `DOCC_HTML_DIR` so DocC uses the vendored assets.
- If you customize CSS, inject it into `index.html` and `index-template.html`.
- Use `index.md` as the root article and avoid `Documentation.md` so the URL does not collapse to
  `/documentation/documentation`.
- Ensure preview indexes resolve, including `/index/documentation/index.json`.
- Use `docc-wrkstrm palette-editor` to adjust DocC theme tokens and export CSS/JSON.
- Keep palette editor outputs in `resources/` or `.clia/tmp/` and wire them via theme settings.
- If preview fails with file limit warnings, raise the shell limit with `ulimit -n` before running.
- Use the preview banner to confirm root URLs; articles live under `/documentation/` and tutorials
  live under `/tutorials/`.

## Quality Gates

- Verify DocC builds without warnings where possible.
- Ensure links resolve and Topics render in the intended order.
- Keep README pointers aligned to DocC entry points.
