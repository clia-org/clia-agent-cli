# Rismay (clia-agent-core-sample)

Purpose: public-safe sample triad modeled on Rismay. All All-Contributors types are equally weighted so downstream agents can narrow scope.

How to create your own agent:
1) Copy this directory to `.clia/agents/<your-agent>/` (or feed it to your generator).
2) Edit the triads: set `slug/handle/title`, adjust `contributionMix`, focus domains, guardrails.
3) Refresh persona/reveries/system instructions to match your tone and boundaries.
4) Add your slug to `.clia/workspace.clia.json` header defaults if you want it in the conversation header.
5) Regenerate DocC if you add docs: `clia agents generate-docc --slug <your-slug> --merged --write`.

Notes: keep samples free of private data; prefer generic paths/domains and permissive licenses. Docs live in `docc/` (legacy `docs/` is deprecated).
