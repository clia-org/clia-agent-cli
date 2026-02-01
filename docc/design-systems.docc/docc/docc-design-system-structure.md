# DocC Design System Structure

@Metadata {
  @PageImage(purpose: icon, source: "docc-docc-design-system-structure-icon", alt: "Icon")
  @PageImage(purpose: card, source: "docc-docc-design-system-structure-card", alt: "Card")
}
@Image(source: "docc-docc-design-system-structure-hero", alt: "Hero")


Use this guide to shape the DocC information architecture and page types.

## Information Architecture

- Require a technology root with a clear title, purpose, and entry topics.
- Add `@Metadata { @TechnologyRoot }` to the root article so DocC renders a landing page.
- The root article becomes the top-level entry at `/documentation/<bundle>/`.
- Link modules and curated articles from the root to build the hierarchy.
- Use predictable page naming and stable slugs; favor lower-case file names.
- Group pages by intent: overview, tutorials, how-to, reference, and guides.

## Recommended Minimum Layout

Every DocC bundle should ship this minimum layout for clarity and consistency:

- Root article with `@TechnologyRoot` and `## Topics`.
- `overview.md`: purpose, scope, and audience.
- `motivation.md`: why the work exists and what constraints shape it.
- `design.md`: design principles and trade-offs.
- `architecture.md`: component map and data flows.
- `implementation.md`: key paths, conventions, and extension points.
- `getting-started.md`: the smallest working path for new users.

Add `how-to`, `reference`, and `tutorials` pages only when they serve real workflows.

### Minimum Layout Pages

- <doc:overview>
- <doc:motivation>
- <doc:design>
- <doc:architecture>
- <doc:implementation>
- <doc:getting-started>

## Documentation.md vs Technology Root

- DocC will render a default `Documentation.md` entry when no explicit root is provided.
- Prefer an explicit root article with `@TechnologyRoot` so the landing page and URL are clear.
- Use `index.md` as the root filename to avoid `/documentation/documentation` URLs.

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
