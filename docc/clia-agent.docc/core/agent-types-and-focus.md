# Agent Types and Focus (All-contributors)

@Metadata {
  @PageImage(purpose: icon, source: "core-agent-types-and-focus-icon", alt: "core-agent-types-and-focus icon")
  @PageImage(purpose: card, source: "core-agent-types-and-focus-card", alt: "core-agent-types-and-focus card")
}


@Image(source: "core-agent-types-and-focus-hero", alt: "Agent types and focus (all-contributors) hero")

## Overview

- Purpose: unify “agency type” as all‑contributors contribution codes.
- Entries may carry multiple types (1–5) to reflect multi‑domain work.
- Focus lets Cadence/Rismay steer an agent toward target types in a time window.
- Deterministic lineage + lint policies ensure auditability and stable merges.

## Upstream Mapping

- Source: all‑contributors emoji key.
- Use a curated subset; keep an internal registry (design doc) with id → emoji/label.
- Alias uncommon needs to nearest upstream id; record alias in registry notes.

## Agency Entry Schema (Per Event)

- `types: [String]` — array of all‑contributors ids (ordered, deduped).
- `typeEmojis: [String]` — optional render cache derived from registry.
- Ordering: `weight desc` (from registry), then `id asc` (stable).
- Cardinality: 1–5 per entry (lint warns when exceeded).

## Agent Triad Schema (Per Persona)

- `extensions.contributions: [{ id, since?, scope?, weight? }]` — long‑term strengths.
- `extensions.focusPlan: {`
  - `windows: [{ id, title, from, to, owner }]`
  - `targets: [{ windowId, typeId, goalXP?, minPerWeek?, priority, notes? }]`
  - `constraints: { maxTypesPerEntry, enforceLegend }`
- } (design‑time fields; lineage‑aware, read‑only in this phase)

## Deterministic Rules

- `types` sorted by registry `weight desc`, then `id asc`.
- Arrays are deduped; unknown ids flagged by lint (no write mutation).
- Registry is single source for emoji/label/weight; lineage merges remain read‑only.

## XP and Levels (Pokemon‑style)

- XP per entry: default 1 XP shared across `types` (equal split).
- Modifiers (design): per‑type `xpWeight` in registry; optional `kind` multiplier.
- Levels (example thresholds): L1=5, L2=15, L3=40, L4=80, L5=140.
- Present lifetime and per‑window XP; show compact badges (e.g., `code L3`).

## Focus Assignments (How to Steer Work)

- Cadence/Rismay set `focusPlan.targets` (types + goals) for a window.
- Log decision in agencies; agent acknowledges with an entry (types = assigned set).
- Lint highlights focus gaps (warns when behind plan in current window).

## Surfaces & UX

- Mirrors: show `Contribs: <emoji string>` per entry; include legend link.
- Roster: optional `Contribs` and `Levels` columns for agents.
- Profile: merged view shows agent‐level contributions, focus window summary, latest entries with types.

## Lint & CI (See Separate Article)

- Entry: missing/unknown/duplicate/over‑cap; emoji mismatch is advisory.
- Focus: window missing; gap vs targets (advisory).
- Modes: warn‑only (adoption) → strict (enforcement) in CI.

## Lineage Integration

- Inherits root directives via top-level `inherits` (deterministic merge).
- Registry resolves emoji/labels; no inference writes to source triads.

## Open Questions

- Finalize XP thresholds per type vs global.
- Cap types per entry at 5 (confirm).
- Apply `kind` multipliers now vs later (keep simple first).

## References

- Contributions Registry Spec (design)
- Deterministic Lineage Merge (design)
- Shared Agent Commands (profile, lineage‑lint, agency‑log)
