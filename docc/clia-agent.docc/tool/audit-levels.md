# Audit Levels and Status

@Metadata {
  @PageImage(purpose: icon, source: "tool-audit-levels-icon", alt: "tool-audit-levels icon")
  @PageImage(purpose: card, source: "tool-audit-levels-card", alt: "tool-audit-levels card")
}


CLIA agent audits use levels and statuses to indicate severity and outcome.
@Image(source: "tool-audit-levels-hero", alt: "Audit Levels and Status hero")


## Levels

- blocking — must pass for a healthy configuration
- advisory — guidance; does not block

## Status

- pass — check succeeded
- fail — check failed
- warn — partial/needs attention
- skip — not applicable or insufficient context

These values match the outputs exposed by the `CLIAAgentAudit` library so tools
like Foundry can map them directly.
