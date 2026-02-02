# Deterministic Lineage Merge (Design Proposal)

@Metadata {
  @PageImage(purpose: icon, source: "lineage-deterministic-lineage-merge-icon", alt: "lineage-deterministic-lineage-merge icon")
  @PageImage(purpose: card, source: "lineage-deterministic-lineage-merge-card", alt: "lineage-deterministic-lineage-merge card")
}


@Image(source: "lineage-deterministic-lineage-merge-hero", alt: "Deterministic Lineage Merge (Design Proposal) hero")

## Overview

Lineage reads an agent’s triads (agent/agenda/agency) from the current repo and ancestors,
including submodules, then merges them into a single, reviewable view. This design
extends lineage to honor top-level `inherits` and stabilizes ordering so merges are
predictable, auditable, and safe for automation.

- Status: Implemented (v1.1), tests passing
- Targets: CLIACore (Merger), CLIAModels (follow‑up), CLIAAgentCore (CLI commands)
- Source files:
  - `sources/core/clia-core/Merger.swift`
  - `sources/core/clia-core/Lineage.swift`
  - `tests/clia-core-tests/MergerInheritsTests.swift`

## Problem Statement

- Policies that apply to all agents (logging, timestamps, lossless merges) need to be
  inherited without duplicating content in every triad.
- Prior lineage ignored the inheritance field, forcing copy/paste and drift.
- Array unions (guardrails/sections) and path precedence needed stable, documented rules.

## Goals

- Honor `inherits: [String]` as lower‑precedence layers when merging.
- Keep merges deterministic:
  - Stable directory traversal
  - Deterministic union for arrays/links
  - Cycle‑safe inheritance
- Preserve lossless history; never mutate ancestors.

## Non‑Goals

- Changing triad JSON schemas in this phase.
- Writing back merged views into source triads.

## Design

### Reading Order

1. Discover lineage directories (ancestors + submodules) for given `slug`.
2. For each triad file (`*.agent.triad.json`, `*.agenda.triad.json`, `*.agency.triad.json`):
   - Decode raw JSON; if `inherits` exists, recursively load those docs first
     (repo‑relative or absolute paths). Track visited paths to avoid cycles.
   - Append the referencing document after its inherited documents.
3. Apply existing lineage precedence (nearest path wins for scalars; unions for arrays).

### Merge Semantics (Unchanged Intent)

- Scalars (title, purpose, status, etc.): last non‑empty wins.
- Arrays (mentors, tags, responsibilities, entries): stable union (preserve order, dedupe).
- Links: union by `(title|url)` key.
- Notes/extensions: last non‑empty wins.

### Determinism

- Inheritance list is loaded before the referencing document.
- Lineage directories are traversed in a consistent order (ancestors → preferred local repo).
- Arrays use stable union; no duplicate strings or links.
- Missing inherited paths are ignored (warn, continue) for robustness.

### Lossless Merges

- Merges are read‑only. When consolidating roles (e.g., Project Manager → Cadence), the full
  source triad is archived under `cadence/legacy-imports/` before removal.

## Implementation Notes

- `Merger.loadDocs` now decodes the raw JSON first to collect inheritance targets, then appends the
  referencing document. A cycle‑safe `visited` set prevents loops.
- Unit test `MergerInheritsTests.swift` verifies that root and child guardrails both appear.

## Follow‑ups

- CLIAModels: tolerate arrays of objects or strings for `sections`/`checklists`; preserve content
  while providing canonical string projections for unions/search.
- Deterministic sorting keys for unioned arrays (if/when promoting richer shapes).
- `profile` subcommand in CLIAAgentCoreCLICommands to print merged triads with a root chain.
- Linter: flag active agents missing `inherits` to the root directives doc.
- CI: add a lineage smoke step and lossless‑merge policy checks.

## Rollout Plan

- Phase 1: Inheritance + tests (done).
- Phase 2: Models + profile subcommand; document sorting rules.
- Phase 3: Linter + CI; repo‑wide validation.

## Acceptance Criteria

- Merged views include inherited guardrails/sections when `inherits` is present.
- Arrays unify deterministically; no duplicates; cycle‑safe inheritance.
- CLIs (`doctor`/`profile`) reflect inherited policies.

## Alternatives Considered

- Global config file per repo: rejected in favor of explicit, typed inheritance in triads.
- Write‑time materialization: rejected to preserve source of truth and avoid drift.

## References

- Spec: `.clia/specs/agents-lineage.v1.md`
- Root profile: `.clia/agents/root/root@<dirTag>.agent.triad.json` (e.g., `root@todo3.agent.triad.json`, `root@mono.agent.triad.json`)
- Request: `.clia/requests/lineage-inherits-merge.md`
