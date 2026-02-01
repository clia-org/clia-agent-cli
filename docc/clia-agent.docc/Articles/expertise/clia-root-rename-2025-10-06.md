# CLIA Root Rename Notes

@Metadata {
  @PageColor(gray)
  @PageImage(purpose: icon, source: "expertise-clia-root-rename-2025-10-06-icon", alt: "expertise-clia-root-rename-2025-10-06 icon")
  @PageImage(purpose: card, source: "expertise-clia-root-rename-2025-10-06-card", alt: "expertise-clia-root-rename-2025-10-06 card")
}

@Image(source: "expertise-clia-root-rename-2025-10-06-hero", alt: "CLIA root rename notes hero")

## Why it Mattered

- New automation (agent-session, agency-log, CLIA docs commands) already expects `.clia/`. Leaving docs on `.clia/` was a paper cut for contributors and a risk for new tooling.
- Renaming the directory is mechanical, but the story lives in guidance: the README, AGENTS tables, and onboarding checklists are where people look first.

## What Changed

- Updated site-wide documentation (README, AGENTS, terminal design system, generated request briefs) to reference `.clia/` paths.
- Patched CLIA DocC bundles, spec files, and request dossiers so future renders mirror the new root.
- Re-ran `cli-kit json format` on the touched triads to keep diffs tidy and predictable.

## Follow-up

- Partner with CLIA tooling to flip CLI defaults and scaffolds. Until then, docs include a note to prefer `.clia/`.
- Once tooling ships, audit screenshots / snippets for `.clia` stragglers, especially in onboarding.
