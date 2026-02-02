# Motifs — Future Me References

@Metadata {
  @PageColor(gray)
  @PageImage(purpose: icon, source: "memory-icon-templates-motifs", alt: "icon templates motifs icon")
}

Date: 2025‑10‑03 · Owner: Carrie

## Summary

Lightweight cultural references we can sprinkle into stories or optional headers
to signal playfulness without muddying specs.

## References

- Trigun — Vash: “Love and peace!”
- How I Met Your Mother — Marshall (and Ted): the “problem for future me” gag.
- The Simpsons — Homer: “That’s a problem for Future Homer.”
- Bill & Ted — future‑us coordination bits.
- Doctor Who — timey‑wimey “future me” handoffs.
- XKCD — meta notes to one’s future self.

## Usage Guidance

- Scope: stories, journals, optional mottos only; avoid specs, errors, tests,
  and identifiers. Keep it tasteful and sparse.
- Opt‑in: surface behind a feature flag or CLI option (for example, `--motto`).
- Attribution: keep series/character names; quotes concise and safe.
- Source of truth: a small unlinked JSON store lives under
  `.clia/agents/clia/resources/fandom-quotes.json`.
