# Contributions Registry Spec (Design)

@Metadata {
  @PageImage(purpose: icon, source: "core-contributions-registry-spec-icon", alt: "core-contributions-registry-spec icon")
  @PageImage(purpose: card, source: "core-contributions-registry-spec-card", alt: "core-contributions-registry-spec card")
}


@Image(source: "core-contributions-registry-spec-hero", alt: "Contributions registry spec (design) hero")

## Purpose

Define a curated subset of all‑contributors contribution types for use as
“agency types” in triads and agency entries.

## File & Format (Design)

- Path: `.clia/specs/contributions.v1.json`
- Shape:

```json
{
  "version": "1.0",
  "types": [
    { "id": "code", "emoji": "💻", "label": "Code", "description": "Implementation work", "weight": 90, "xpWeight": 1.0 },
    { "id": "doc", "emoji": "📚", "label": "Docs", "description": "Documentation and guides", "weight": 80, "xpWeight": 1.0 },
    { "id": "tool", "emoji": "🛠️", "label": "Tooling", "description": "CLIs, infra adapters", "weight": 75, "xpWeight": 1.0 }
  ],
  "aliases": { "governance": ["projectManagement","review"] }
}
```

## Semantics

- `weight`: ordering in merged arrays (higher first; ties by `id`).
- `xpWeight`: multiplier for XP contribution (default 1.0).
- `aliases`: map local terms to upstream ids (for authoring clarity).

## Policy

- Only ids present here are valid for `types` in agency entries.
- Changes require PR with rationale and DocC update; lint rules updated in lockstep.

## References

- Upstream: all‑contributors emoji key
- Local: Agent Types & Focus (Design)
