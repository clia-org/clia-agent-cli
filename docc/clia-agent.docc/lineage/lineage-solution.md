# The Solution — Inheritance + Deterministic Merge

@Metadata {
  @PageImage(purpose: icon, source: "lineage-lineage-solution-icon", alt: "lineage-lineage-solution icon")
  @PageImage(purpose: card, source: "lineage-lineage-solution-card", alt: "lineage-lineage-solution card")
}


@Image(source: "lineage-lineage-solution-hero", alt: "The Solution — Inheritance + Deterministic Merge hero")

## Summary

We extend lineage to include an inheritance layer and codify deterministic
merge rules. Agents may declare:

```json
{
  "extensions": {
    "inherits": [".clia/agents/root/root@<dirTag>.agent.triad.json"]
  }
}
```

The merger loads inherited documents first (lower precedence) and then the
referencing document, before applying lineage precedence across ancestor paths.

## Design Pillars

- Inheritance-first: Load `inherits` (top-level) prior to the referencing triad.
- Stable unions: Arrays and links dedupe deterministically.
- Cycle‑safe: Track visited paths to avoid infinite loops.
- Read‑only: Never mutate lineage sources; consolidations archive history first.

## Implementation

- `Merger.loadDocs` decodes raw JSON to discover `inherits`. Each inherited
  path is resolved (repo‑relative or absolute), loaded if present, then the current
  document is appended.
- Lineage discovery remains unchanged (ancestors/submodules → preferred local).
- Unit tests validate that inherited guardrails are included alongside local ones.

## Migration

- Add root directives once to `root` and reference them via the top-level `inherits` field in
  active agents.
- For consolidations, copy the old triad into `legacy-imports/` under the destination
  agent prior to removal.

## Future Work

- Expand models to tolerate richer arrays (objects + strings) while retaining canonical
  projections for unions.
- Add a `profile` command to print merged views with a root chain.
- Integrate a linter and CI gate for missing inheritance and lossless merge policy.
