# Fix Template — Problem, Solution, Verify

@Metadata {
  @PageColor(gray)
  @PageImage(purpose: icon, source: "expertise-fix-template-icon", alt: "expertise-fix-template icon")
  @PageImage(purpose: card, source: "expertise-fix-template-card", alt: "expertise-fix-template card")
}

Use this scaffold for small, auditable fixes. Keep sections short.
@Image(source: "expertise-fix-template-hero", alt: "Fix template — problem, solution, verify hero")


## Problem

- What failed and why it mattered (1–2 lines).
- First observable error line(s) and affected targets.

## Solution

- Minimal code changes, with file:line references.
- Rationale: why this is the least‑surprising fix.

## Verify

```bash
xcodebuild \
  -project <path/to/project.xcodeproj> \
  -scheme <SchemeName> \
  -configuration Debug \
  -destination '<destination>' \
  build
```

- Expected outcome (build, tests, runtime smoke).

## Rollback (Optional)

- How to revert safely if needed.

## Owner Date

- Owner: carrie
- Date: YYYY‑MM‑DD
