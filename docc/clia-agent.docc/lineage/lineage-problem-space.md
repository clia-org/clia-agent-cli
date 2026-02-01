# The Problem Space — Deterministic Lineage

@Metadata {
  @PageImage(purpose: icon, source: "lineage-lineage-problem-space-icon", alt: "lineage-lineage-problem-space icon")
  @PageImage(purpose: card, source: "lineage-lineage-problem-space-card", alt: "lineage-lineage-problem-space card")
}


@Image(source: "lineage-lineage-problem-space-hero", alt: "The Problem Space — Deterministic Lineage hero")

## Context

Agent triads (agent/agenda/agency) exist at multiple levels: the current repo,
ancestors, and submodules. A single persona (e.g., Cadence) may appear in several
places. We must read and merge these views into a single, auditable picture.

## Challenges

- Global policies: Guardrails like agency logging and ISO‑8601 timestamps apply to all
  agents, but copy/pasting into every triad creates drift.
- Merge correctness: Combining scalars and arrays across lineage must be predictable and
  repeatable, not dependent on filesystem quirks.
- Extensibility: Agents evolve—sections/checklists may become richer structures. The
  merger should tolerate this while preserving determinism.
- Safety: Consolidations (e.g., Project Manager → Cadence) must retain full history.

## Requirements

- Honor top-level `inherits` for communal policies (root directives) without duplication.
- Deterministic order of operations and stable union semantics for arrays/links.
- Cycle‑safe traversal; missing inherited paths should not break merges.
- Lossless, read‑only merges; archival before consolidation.

## Constraints

- No external processes for lineage; file I/O only (CommonShell is for CLIs, not the
  merger core).
- Keep the merger library small, testable, and portable across macOS/Linux.
