# Lossless Merge Policy

@Metadata {
  @PageImage(purpose: icon, source: "core-lossless-merge-policy-icon", alt: "core-lossless-merge-policy icon")
  @PageImage(purpose: card, source: "core-lossless-merge-policy-card", alt: "core-lossless-merge-policy card")
}


@Image(source: "core-lossless-merge-policy-hero", alt: "Lossless merge policy hero")

## Principle

Merges are archival operations. Do not delete history.

## Steps

1) Copy the full source triad under `destination/legacy-imports/`.
2) Update destination agent (identity, aliases, imported sections).
3) Log decision in agencies (participants listed; timestamps ISO‑8601 Z).
4) After human confirmation, remove the old triad path (history preserved in legacy).

## Determinism

- Archive filenames preserved; links remain navigable.
- Agency logs include participants and a summary.

## References

- Deterministic Lineage Merge (Design)
- Shared Agent Commands (profile, lineage‑lint, agency‑log)
