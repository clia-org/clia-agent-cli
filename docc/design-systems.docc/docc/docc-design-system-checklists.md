# DocC Design System Checklists

@Metadata {
  @PageImage(purpose: icon, source: "docc-docc-design-system-checklists-icon", alt: "Icon")
  @PageImage(purpose: card, source: "docc-docc-design-system-checklists-card", alt: "Card")
}

@Image(source: "docc-docc-design-system-checklists-hero", alt: "Hero")

## Readiness Checklists

## Authoring Checklist

- Entry page describes purpose, audience, and scope.
- Place `@Metadata { ... }` directly after the title line.
- Use `@TechnologyRoot` for hub pages.
- Set a topic lane with `@PageColor(...)`.
- Add `@PageImage(purpose: icon|card, source: "...", alt: "...")`.
- Use `@Options { @TopicsVisualStyle(...) }` near the top when needed.
- Keep the summary paragraph text-only (no links or images).
- Prefer a hero or overview image immediately after the summary (`@Image(...)`).
- Topics section is short, ordered, and scannable.
- Group Topics by intent: Start here, Deep dives, Reference.
- Code examples use fenced blocks with language tags.
- Callouts are consistent: Note, Warning (with verify step), Important (risk + owner).
- Assets live in `resources/` with lower-case file names.

## Review Checklist

- Navigation is predictable and links resolve.
- Visuals are readable and consistent with DocC style.
- Hero and diagram SVGs render cleanly (gradients, strokes, and text remain legible).
- README pointers align with DocC entry points.
- Topics groups stay readable: 5 to 7 links per group.
- Tutorials have a `Tutorials.tutorial` root and references for each entry.
- Known DocC warnings are listed with fixes or a planned follow-up.
- Diagram assets have a rendered SVG version committed for DocC.

## Publish Checklist

- Preview commands are documented and reproducible.
- Custom renderer or CSS overrides are called out.
- Known warnings are listed with a follow-up plan.
- If preview fails due to file limits, raise `ulimit -n` for the preview shell.
- Verify the root URL is `/documentation/<bundle>/` (avoid `/documentation/documentation`).
- Destructive actions happen last: move files first, build the new product, test it, add tests when
  possible, then remove legacy files.
