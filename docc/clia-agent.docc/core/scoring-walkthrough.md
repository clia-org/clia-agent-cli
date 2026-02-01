# Scoring Walkthrough (Design)

@Metadata {
  @PageImage(purpose: icon, source: "core-scoring-walkthrough-icon", alt: "core-scoring-walkthrough icon")
  @PageImage(purpose: card, source: "core-scoring-walkthrough-card", alt: "core-scoring-walkthrough card")
}


@Image(source: "core-scoring-walkthrough-hero", alt: "Scoring walkthrough (design) hero")

## Scenario

Agent Codex logs three entries this week:

1) Decision: adopt typed timestamps (types: `tool, infra, doc`)
2) Log: profile/lineage lint commands shipped (types: `tool, code`)
3) Log: docs outline for Agent Types (types: `doc`)

Assume registry `xpWeight = 1.0` for all types and no `kind` multipliers.

## Per‑entry XP

- Entry 1: 1.0 XP split across 3 types → +0.333 XP each (`tool, infra, doc`)
- Entry 2: 1.0 XP split across 2 types → +0.5 XP each (`tool, code`)
- Entry 3: 1.0 XP for `doc` → +1.0 XP

Totals (this week):

- tool: 0.333 + 0.5 = 0.833 XP
- infra: 0.333 XP
- doc: 0.333 + 1.0 = 1.333 XP
- code: 0.5 XP

## Lifetime + Window

- Lifetime XP accumulates across all time; window XP resets each window.
- Focus dashboards show both; linter compares window XP to `focusPlan.targets`.

## Mapping to Levels

- Convert XP to micro‑level n by inverting `EXP(n) = (5 n^3)/4`.
- Normalize with `F(n) = EXP(n)/EXP(100)`.
- Assign macro tier via cut lines (see Leveling Tiers).

The implementation will use a deterministic lookup or numeric solve with tests;
the design here defines the expectations and display semantics.
