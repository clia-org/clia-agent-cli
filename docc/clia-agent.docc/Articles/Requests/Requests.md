# CLIA Requests

@Metadata {
  @PageImage(purpose: icon, source: "requests-requests-icon", alt: "requests-requests icon")
  @PageImage(purpose: card, source: "requests-requests-card", alt: "requests-requests card")
}


This section describes how CLIA tracks requests in `.clia/requests/`.
Active and proposed items live under project folders. Completed, archived, and
sunset items move under each project's `archive/` directory so active work stays
visible. The `.clia/submodule-patch-requests/` area is reserved for
submodule patch requests and is explicitly excluded from feature requests.
@Image(source: "requests-requests-hero", alt: "CLIA Requests hero")


## Active Trackers

- See the CLIA Requests Spec bundle for active epics.

## How-To Guides

- <doc:how-to-journal-and-create-features>

## Historical Notes

### Proposed

- Integrate feature requests with Backlog/Agency/Agents (Cadence)
- Native Conversation model for triads (ConversationDoc)
- Move workspace to `.clia/workspace.clia.json` scope

### Completed

- Good Morning ritual
- Good Day progress summary
- Show Environment (unified inspector)
- Roster + Roster Resolve
- Core supercommand
- CommonShell/CLI rename (code) + docs-first reorg

### Sunset Rejected

- GM Figlet subcommand (banner-only)

## See Also

- Codex agent triad: `.clia/agents/codex/codex@sample.agent.triad.json`
- Carrie agent triad: `.clia/agents/carrie/carrie@sample.agent.triad.json`
- Cadence agent triad: `.clia/agents/cadence/cadence@sample.agent.triad.json`
- Tau agent triad: `.clia/agents/tau/tau@mono.agent.triad.json`
- Common agent triad: `.clia/agents/common/common@mono.agent.triad.json` (agent),
  `.clia/agents/common/common@mono.agenda.triad.json` (agenda),
  `.clia/agents/common/common@mono.agency.triad.json` (agency);
  DocC memory bundle: `.clia/agents/common/docc/memory.docc`
- CLIA agent triad: `.clia/agents/clia/clia@sample.agent.triad.json` (agent),
   `.clia/agents/clia/clia@sample.agenda.triad.json` (agenda),
   `.clia/agents/clia/clia@sample.agency.triad.json` (agency)
