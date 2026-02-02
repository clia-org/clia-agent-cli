# CLIA Agents

Interact with CLIA agents from a single CLI inside the mono repository. The
`agents` command group owns commissioning, audits, lineage previews, and docs
rendering.

## Subcommands

- ``ValidateTriad`` — validate triad presence/consistency
- ``Context`` — print lineage chain (e.g., `codex@sample → codex@mono → area → local`)
- ``PreviewAgent`` — merged `agent.triad.json` across lineage
- ``PreviewAgenda`` — merged `agenda.triad.json` across lineage
- ``PreviewAgency`` — merged `agency.triad.json` across lineage
- ``Audit`` — agent audits (local/docs engines), JSON previews
- ``Mirrors`` — render Markdown mirrors from JSON triads under .clia/agents (via `CLIAAgentCore.MirrorRenderer.mirrorAgents`)
- `triads render --kind agenda` — render `*.agenda.triad.json` to Markdown mirrors (via `CLIAAgentCore.MirrorRenderer.agendaMarkdown`)
- `triads aggregate --kind agenda` — aggregate agenda triads across agents (read-only)
- `generate-docc` — generate `generated.docc` for an agent, sourcing from
  `memory.docc/expertise` + `memory.docc/journal` (memory bundle is read-only)
- ``Transfer`` — plan safe agent move/rename (dry‑run JSON)
- ``Journal`` — write JSON entries under an agent’s journal/
- ``MigrateRole`` — plan/apply role slug migration across triads and mirrors

> Note: Issues workflows (create/list/audit/sync) have moved to the Cadence
> agent CLI: `cadence-agent-cli issues …`.

## Examples

Render mirrors (non‑canonical, via CLIAAgentCore):

```bash
clia core mirrors \
  --agents-dir .clia/agents
```

Render mirrors for specific agent(s):

```bash
clia core mirrors \
  --agents-dir .clia/agents \
  --slug codex \
  --slug carrie
```

Aggregate agenda triads (read-only):

```bash
clia core triads aggregate --kind agenda --format md
```

Generate agent DocC bundles:

```bash
clia agents generate-docc --slug carrie --path . --write
```

Set focus domains:

```bash
clia agents set-focus-domains \
  --slug codex \
  --domain "Platform iOS Engineer=ios-platform:3" \
  --domain "Tau app UI Designer=tau-app-ui:2" \
  --domain "DocC infra=docc-infra" \
  --merge
```

Set an agent’s contribution mix (S‑Types):

```bash
clia agents set-contribution-mix \
  --slug codex \
  --primary code=5,design=2,doc=1 \
  --secondary research=1,infra=1 \
  --s-type-contribution-map .clia/specs/s-type-collaboration-system.json \
  --contribution-focus code --contribution-focus design --contribution-focus doc
```

Notes

- Agent mirrors write `.generated/<slug>.agent.triad.md` and embed, when present:
  - agent source (`sourcePath`),
  - persona (`persona.profilePath`, typically `*.persona.agent.triad.md`),
  - reveries micro‑behaviors (`persona.reveriesPath`, `*.reveries.agent.triad.md`),
  - compact system instructions (`systemInstructions.compactPath`).
- Agenda/Agency mirrors write `.generated/<slug>.agenda.triad.md` and `.generated/<slug>.agency.triad.md` respectively.

Plan a transfer (move/rename):

```bash
clia agents transfer \
  --from .clia/agents/old \
  --to   .clia/agents/new \
  --new-slug new-slug \
  --include chats,codex,summaries --dry-run
```

Journal entry (daily JSON note):

```bash
clia core journal --slug ios-engineer \
  --highlight "Shipped previews" --next-step "Add tests"
```

Migrate role (dry‑run):

```bash
clia agents migrate-role --from product-manager --to product-owner --path .
```

## Quickstart

```bash
# Validate triads under current directory
clia agents validate-triad --path .

# Lineage chain for an agent
clia agents context --slug ios-engineer --path .

# Preview merged agent view with provenance
clia agents preview-agent \
  --slug ios-engineer --path . \
  --with-sources --show-duplicates --root-chain --pretty

# Render agenda mirrors (via CLIAAgentCore)
clia core triads render --kind agenda --path . --write

# Aggregate agenda triads (via CLIAAgentCore)
clia core triads aggregate --kind agenda --format md
```

## Status Codes

Validation commands exit non‑zero on failures. Preview commands print JSON to
stdout and exit zero when rendering succeeds.
