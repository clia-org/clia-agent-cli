# Audit Problem Space

@Metadata {
  @PageImage(purpose: icon, source: "audit-audit-problem-space-icon", alt: "audit-audit-problem-space icon")
  @PageImage(purpose: card, source: "audit-audit-problem-space-card", alt: "audit-audit-problem-space card")
}


Agent documentation and audits were split across multiple tools, which caused
drift and duplicated logic. Teams need a single source of truth for agent
triads (JSON), in‑process lineage/merge, and deterministic checks that other
tools can consume without shelling out.
@Image(source: "audit-audit-problem-space-hero", alt: "Audit problem space hero")


Constraints:

- No `Foundation.Process` in app/CLI code; type‑safe libraries
- Cross‑platform (macOS + Linux) with predictable outputs
- Deterministic ordering for snapshot tests and CI stability
