# Agency Contributions (Grouped)

@Metadata {
  @PageImage(purpose: icon, source: "core-agency-contributions-icon", alt: "core-agency-contributions icon")
  @PageImage(purpose: card, source: "core-agency-contributions-card", alt: "core-agency-contributions card")
}


Status: Implemented • Schema: 0.4.0 • Audience: Engineers, Docs
@Image(source: "core-agency-contributions-hero", alt: "Agency Contributions (Grouped) hero")


## Overview

Agency entries record realized work. Contributions are grouped per actor to make
both per‑person and team weighting straightforward and traceable.

- Grouped shape: contributions: [{ by, types: [{ type, weight, evidence }] }]
- Evidence is required per contribution item.
- Participants are derived (rendered as “{role} (^{slug})”); no `participants`
  field is persisted in the schema.

## JSON Example

```json
{
  "timestamp": "2025-10-05T12:34:56Z",
  "kind": "feature",
  "title": "Scoring prototype",
  "contributions": [
    { "by": "codex",  "types": [
      { "type": "code",   "weight": 4, "evidence": "PR #42" },
      { "type": "doc",    "weight": 2, "evidence": "Doc MR #15" }
    ]},
    { "by": "carrie", "types": [
      { "type": "design", "weight": 3, "evidence": "Figma v3" }
    ]}
  ],
  "tags": ["s-types"],
  "links": [
    { "title": "PR", "url": "https://example.com/pr/42" }
  ]
}
```

## Mirror Rendering

- Participants: rendered from groups via Agent roles (AgentDoc.role):
  - “Participants: Codex (^{codex}), Carrie (^{carrie})”
- Contributions:
  - “Contributions:” then one line per actor:
  - “Codex (^{codex}): code=4 — PR #42; doc=2 — Doc MR #15”

## Notes

- Aggregation: per‑entry shares are computed by summing weights per type across
  all groups then normalizing; no derived scores are persisted.
- Validation: the audit enforces evidence per item and validates contribution
  types against the S‑Types map when available.
