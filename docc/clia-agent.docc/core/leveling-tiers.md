# Leveling Tiers (Design)

@Metadata {
  @PageImage(purpose: icon, source: "core-leveling-tiers-icon", alt: "core-leveling-tiers icon")
  @PageImage(purpose: card, source: "core-leveling-tiers-card", alt: "core-leveling-tiers card")
}


@Image(source: "core-leveling-tiers-hero", alt: "Leveling tiers (design) hero")

## Overview

We map continuous experience to human‑friendly tiers for each contribution type.
The tiers communicate mastery at a glance without hiding the underlying math.

## Micro vs Macro Levels

- Micro: level n ∈ [1, 100] driven by the Slow curve `EXP(n) = (5 n^3)/4`.
- Macro: five tiers derived from normalized cut lines.

## Tier Names (Working)

1. Apprentice
2. Adept
3. Expert
4. Steward
5. Champion

## Cut Lines (Normalized)

Using `F(n) = EXP(n) / EXP(100)`:

- T1: `F ≤ 0.10`
- T2: `0.10 < F ≤ 0.25`
- T3: `0.25 < F ≤ 0.50`
- T4: `0.50 < F ≤ 0.75`
- T5: `0.75 < F ≤ 1.00`

These lines are consistent across all types; the XP totals are type‑specific.

## XP Per Entry

- Default: 1 XP per entry shared equally among `types`.
- Registry modifiers: optional `xpWeight` per type (e.g., `code: 1.2`).
- Context modifiers (optional later): `kind` multipliers (e.g., `decision: 1.2`).

## Windows and Progress

- Present lifetime XP/tiers alongside window XP (e.g., quarter) for focus.
- Window summaries show goals (from `focusPlan`) and current % completion.

## Determinism & Auditing

- All thresholds are documented and versioned.
- Numeric inversion of `EXP(n)` uses lookup tables or fixed‑precision method
  (implementation detail); behavior must be test‑covered and stable.
