# Create agents from the Sammie sample

@Metadata {
  @PageImage(purpose: icon, source: "clia-agent-icon", alt: "CLIA icon")
  @PageKind(article)
}

Use the bundled Rismay triads as a public-safe starting point for new agents.

## What Sammie provides

- Location: `sources/core/clia-agent-core-cli-commands/resources/clia/agent/rismay/`
- Naming: `rismay@clia-agent-core-sample.*` (agent/agenda/agency + persona/reveries/system instructions)
- Contribution mix: every All-Contributors type present with equal weight
- README: quick fork steps and a reminder that `docc/` is the live docs surface

## Fork Sammie into your own agent

1) Copy the Sammie directory to a new slug (kebab-case) under `.clia/agents/<your-slug>/` or reuse it as an input to your generator.
2) Edit triads:
   - Update `slug`, `handle`, `title`.
   - Set `contributionMix` to emphasize your agent’s strengths (keep types from `all-contributors-types.v1.json`).
   - Adjust `focusDomains`, `guardrails`, and notes as needed.
3) Refresh persona/reveries/system instructions to describe tone, scope, and safety boundaries.
4) Add your slug to workspace header defaults in `.clia/workspace.clia.json` so the conversation header lists it.
5) Regenerate DocC if you add docs for your agent:
   ```bash
   clia agents generate-docc --slug <your-slug> --merged --write
   ```

## Tips for contributors

- Keep samples free of private data (paths, URLs, incidents).
- Prefer `com.example.*` bundle identifiers and `/Users/example/...` paths in docs/tests.
- Use the `agents set-contribution-mix` commands to tune weights; they validate against the shared contribution map.
- Remember: `docs/` is deprecated; author new guides under `docc/` so previews and exports stay aligned.
