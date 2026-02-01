# Experience Curves (Design)

@Metadata {
  @PageImage(purpose: icon, source: "core-experience-curves-icon", alt: "core-experience-curves icon")
  @PageImage(purpose: card, source: "core-experience-curves-card", alt: "core-experience-curves card")
}


@Image(source: "core-experience-curves-hero", alt: "Experience curves (design) hero")

## Motivation

We need a predictable, explainable function to translate agency activity into
experience (XP) and levels. A cubic curve provides smooth progression with
stronger requirements at higher levels, discouraging shallow gaming while
rewarding sustained focus.

## Slow Curve (Adopted)

- Definition (level n in [1, 100]):
  - `EXP(n) = (5 * n^3) / 4`
- Properties:
  - Monotonic increasing, smooth, and convex (harder at higher n).
  - At n = 100, `EXP(100) = 1,250,000` (arbitrary units; serves as a scale).
  - Deterministic and easy to reason about; integer math is not required at design time.

## Normalized View

To compare across curves or compress to fewer macro levels, use:

- `F(n) = EXP(n) / EXP(100)` → fraction in [0, 1].
- Example cut lines for macro tiers: 0.10, 0.25, 0.50, 0.75, 1.00.

## Macro Tiers (Design Target)

We retain 100 micro-levels internally (for scoring displays) and compress to
five macro tiers for UX:

- Tier 1: `F(n) ≤ 0.10` (Apprentice)
- Tier 2: `0.10 < F(n) ≤ 0.25` (Adept)
- Tier 3: `0.25 < F(n) ≤ 0.50` (Expert)
- Tier 4: `0.50 < F(n) ≤ 0.75` (Steward)
- Tier 5: `0.75 < F(n) ≤ 1.00` (Champion)

These names are placeholders; finalize in the leveling article.

## Type‑local Scoring

Levels are computed per contribution type (e.g., `code`, `doc`). For each type:

1. Accumulate XP from entries that include that type.
2. Convert to micro-level n by inverting `EXP(n)` (lookup or numeric solve).
3. Compress to macro tier using the normalized cut lines.

XP aggregation and cut lines are deterministic and documented; no hidden weights
outside the published registry.

## Alternatives (for Future)

- Standard curve: `EXP(n) = n^3` (baseline)
- Fast curve: `EXP(n) = (4 * n^3) / 5` (accelerated)

We keep a single adopted curve (Slow) for the initial release to simplify mental
models and auditing.
