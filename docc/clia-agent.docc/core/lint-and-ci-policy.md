# Lint and CI Policy (Lineage + Types)

@Metadata {
  @PageImage(purpose: icon, source: "core-lint-and-ci-policy-icon", alt: "core-lint-and-ci-policy icon")
  @PageImage(purpose: card, source: "core-lint-and-ci-policy-card", alt: "core-lint-and-ci-policy card")
}


@Image(source: "core-lint-and-ci-policy-hero", alt: "Lint and CI policy (lineage + types) hero")

## Goals

Keep triads and agencies deterministic, well‑typed, and free of drift across
lineage and inheritance.

## Rules (Entries)

- missing-types (warn → error): new entries must include `types`.
- unknown-id (error): type id not in registry.
- duplicate-types (error): dedupe per entry.
- over-cap (warn): more than 5 types per entry.
- emoji-mismatch (warn): `typeEmojis` diverges from registry/ordering (fixed on next write).

## Rules (Focus)

- window-missing (warn): expected assignment but no active `focusPlan` window.
- focus-gap (warn): XP behind plan for current window.

## Rules (Lineage)

- missing-inherits (warn): agent missing root directives inheritance.
- duplicate-guardrails (warn): duplicates after merge.
- unknown-extension (info): non‑standard extensions present (document in DocC).

## Modes

- Warn‑only: adoption phase; CI passes but prints diagnostics.
- Strict: enforcement; CI fails on unknown/missing types for new entries; lineage errors.

## CI Integration

- Add a job that runs lineage lint (read‑only) at repo root and prints JSON.
- Block merges in strict mode on error severities.

## References

- Agent Types & Focus (Design)
- Contributions Registry Spec (Design)
- Deterministic Lineage Merge (Design)
