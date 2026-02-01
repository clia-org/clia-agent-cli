# Todo3 Structure Update

@Metadata {
  @PageColor(green)
  @PageImage(purpose: icon, source: "memory-icon-repo-migrations", alt: "icon repo migrations icon")
}

This article summarizes the recent restructuring across `todo3`, so other
agents can navigate confidently and contribute in the right places.

## Highlights

- Per‑agent DocC: each agent now owns expertise under
  `.clia/agents/<agent>/docc/expertise.docc`.
- Carrie: added DocC expertise bundle and SPM tools (cloud + local); agent
  profile updated with links and preview instructions.
- Codex: added DocC expertise and a journal bundle capturing docs sprints.
- Cloud: new agent with SPM scaffolding for cloud workflows.
- CLIA docs reshaped: AGENCY/CHARTER moved under `.clia/`; legacy
  templates/specs/requests cleaned up; sessions mirrored from submodule.
- CI simplified: removed older GitHub Actions workflows related to legacy
  DocC publishing and SPM jobs.
- Submodules: added `ai/exports/open-ai/codex/sessions` for memory/catalog.

## Canonical Structure (Go‑to Locations)

- Agents (expertise & tools)
  - `.clia/agents/<agent>/docc/expertise.docc` — per‑agent DocC
  - `.clia/agents/<agent>/spm/**` — local/cloud SPM workspaces
  - Agent profile JSON/MD live under `.clia/agents/<agent>/`

- CLIA docs & governance
  - `.clia/AGENTS.md` — agent guidelines
  - `.wrkstrm/AGENCY.md`, `.clia/CHARTER.md` — moved from root

- App and packages (Apple mono)
  - `code/mono/apple/alphabeta/<app>/...` — Xcode projects & targets
  - `code/mono/apple/spm/<cross|universal|domain>/**` — shared SwiftPM

- Submodule change requests (Apple mono)
  - `code/.clia/submodule-patch-requests/<slug>/` — store diffs/rationales for
    submodule changes originated from Codex Linux.

- CI and workflows
  - `.github/workflows/` — streamlined; older DocC/SPM workflows removed

## What Moved (Examples)

- Carrie DocC expertise article added:
  - `.clia/agents/carrie/docc/expertise.docc/articles/tau-secrets-migration-2025-10-03.md`
- Old common‑scoped copy removed (prefer per‑agent ownership).
- AGENCY/CHARTER documents relocated inside `.wrkstrm/` and `.clia/`.
- Legacy CLIA templates/specs/requests pruned in favor of Foundry scaffolds
  and per‑agent bundles.

## Next Steps

- Consider a short quiz deck to reinforce paths and conventions.
- Keep new work scoped to per‑agent DocC and package docs; avoid re‑adding
  central templates unless shared across agents.

## Intent and Principles (Why the Restructure)

- Decentralize ownership: move expertise to per‑agent DocC so each agent owns
  its stories, tools, and receipts.
- Slim the surface: remove legacy CLIA templates/specs/requests and the
  central DocC; prefer Foundry scaffolds and agent‑local SPM CLIs.
- Simplify CI: prune outdated workflows to reduce noise/cost and keep a lean
  docs/build pipeline.
- Canonicalize paths: make locations explicit — `.wrkstrm/` for governance,
  `code/mono` for Apple, submodule requests under `code/.clia/submodule-patch-requests`.
- Enforce naming and conventions: kebab‑case for slugs; CamelCase in Swift;
  never snake_case (root profile guardrail: NO_SNAKE_CASE).
- Solidify secrets architecture: standardize on `WrkstrmSecrets` + TauKit
  bridge; deprecate brittle legacy paths; fix Tau builds.
- Clarify agent roles: Carrie stewards docs/expertise; ^dott focuses on
  heavier work in `code/mono`.
- Reduce drift: keep AGENCY/CHARTER and policies under `.clia` so all
  agents inherit consistent guardrails.
- Make the repo agent‑friendly: faster navigation, less churn, clearer
  ownership, and typed, auditable workflows.
