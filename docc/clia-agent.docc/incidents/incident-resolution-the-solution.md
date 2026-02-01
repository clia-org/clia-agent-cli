# Incident Resolution: The Solution

@Metadata {
  @PageImage(purpose: icon, source: "incidents-incident-resolution-the-solution-icon", alt: "incidents-incident-resolution-the-solution icon")
  @PageImage(purpose: card, source: "incidents-incident-resolution-the-solution-card", alt: "incidents-incident-resolution-the-solution card")
}


Codify the active banner and report lifecycle with small, composable CLIs.
@Image(source: "incidents-incident-resolution-the-solution-hero", alt: "Incident resolution: The solution hero")


- Write ownership: `CLIAIncidentResolutionCommands` creates report templates
  and manages `.clia/incidents/active.json` in a typed, predictable way.
- Read ownership: `CLIAIncidentCoreCommands` and `CLIAAgentCoreCLICommands`
  consume the banner for UIs like conversation headers. Downstreams format
  the banner via `Incident.bannerText`.
- Formatting policy: human‑friendly JSON (prettyPrinted, sortedKeys,
  withoutEscapingSlashes) to keep reviews legible and scripts stable.

Key design choices:

- Explicit, long‑form flags (clarity over brevity).
- Optional fields are omitted when empty to reduce noise.
- Links and blocked tool lists are first‑class to align policy and guidance.
