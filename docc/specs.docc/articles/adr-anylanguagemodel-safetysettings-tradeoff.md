# ADR: AnyLanguageModel Adoption with SafetySettings Tradeoff

**Status**: Draft  
**Date**: 2026-01-07  
**Decision**: AnyLanguageModel is acceptable if we give up Gemini `safetySettings` and apply
mitigations.

## Context

Generative‑ai‑swift exposes Gemini `safetySettings` (harm categories + block thresholds). The
AnyLanguageModel API does not expose an equivalent in its public surface. Switching to
AnyLanguageModel simplifies provider integration but drops this request‑level safety control.

## Decision

Proceed with AnyLanguageModel as a viable path **only** if we accept the loss of Gemini
`safetySettings` and adopt mitigations that preserve safety behavior at the CommonAI/CLIA layer.

## Mitigations

- Rely on provider‑default safety thresholds where available.
- Apply policy checks before execution (tool policies, command approval flow).
- Add response validation and refusal handling for unsafe outputs.
- Document the safety feature gap as a parity exception in the P0 analysis.

## Consequences

### Positive

- Simplifies provider surface area and unifies schema output via `@Generable`.
- Reduces custom adapter logic in CommonAI over time.

### Negative

- Loses request‑level Gemini safety tuning.
- Requires compensating safeguards at higher layers.

## Alternatives Considered

1) Stay on generative‑ai‑swift to retain `safetySettings`.
2) Extend AnyLanguageModel with a Gemini‑specific safety options hook.

## References

- P0 analysis: <doc:foundationmodels-vs-anylanguagemodel-p0-analysis>
