# Using Agents Commands

This guide covers the `agents` subcommands consolidated into `clia`.

## Validate Triads

```bash
clia agents validate-triad --path .
```

Checks each agent directory contains `*.agent.triad.json`, `*.agenda.triad.json`, and
`*.agency.triad.json`, and flags slug mismatches.

## Lineage Context

```bash
clia agents context --slug ios-engineer --path .
```

Prints the lineage chain used for merged previews (root prefix + path).

## Merged Previews

```bash
clia agents preview-agent  --slug ios-engineer --path . --pretty
clia agents preview-agenda --slug ios-engineer --path . --pretty
clia agents preview-agency --slug ios-engineer --path . --pretty
```

Options:

- `--with-sources`: include provenance
- `--show-duplicates`: include per‑source arrays before union
- `--root-chain`: attach context entries (prefix + path)

## Render Agenda Mirrors (via CLIAAgentCore)

```bash
clia core triads render --kind agenda --path . --write
```

Writes `.generated/<slug>.agenda.triad.md` next to each agenda JSON file. Mirrors are
non‑canonical; edit the JSON and regenerate.

Implementation note: agenda rendering is centralized in `CLIAAgentCore.MirrorRenderer.agendaMarkdown(_:)`.

## Aggregate Agenda Triads (via CLIAAgentCore)

```bash
clia core triads aggregate --kind agenda --format md
```

Scans `.clia/agents/**/ *.agenda.triad.json` and prints a consolidated Markdown view. Use `--calendar`
for day/week/month rollups. Read-only.

## Generate Agent DocC Bundles (via CLIAAgentCore)

```bash
clia agents generate-docc --slug carrie --path . --write
```

Writes `generated.docc` under `.clia/agents/<slug>/docc/` (including a memory
view at `generated.docc/memory/`). It reads `docc/memory.docc/expertise/` and
`docc/memory.docc/journal/` as sources (these are not modified), prefixes
resources with `memory-`, and strips extra `@TechnologyRoot` entries from copied
roots. Default behavior is dry-run; pass `--write` to apply.

Merged rendering (lineage-aware):

```bash
clia agents generate-docc --slug carrie --path . --merged --write
```

## Render All Mirrors (Agent/Agenda/Agency) via CLIAAgentCore

```bash
clia core mirrors \
  --agents-dir .clia/agents
```

Renders `.generated/<slug>.(agent|agenda|agency).md` for each agent triad.
Use the mirrors only for reading; JSON triads remain the source of truth.
Implementation note: mirrors are rendered by
`CLIAAgentCore.MirrorRenderer.mirrorAgents(at:slugs:dryRun:)`.

Filter to specific agent(s):

```bash
clia core mirrors \
  --agents-dir .clia/agents \
  --slug codex \
  --slug carrie
```

## Set Contribution Mix (S‑Types)

```bash
clia agents set-contribution-mix \
  --slug codex \
  --primary code=5,design=2,doc=1 \
  --secondary research=1,infra=1 \
  --s-type-contribution-map .clia/specs/s-type-collaboration-system.json \
  [--contribution-focus code --contribution-focus design] \
  [--merge] [--dry-run]
```

## Set Focus Domains

```bash
clia agents set-focus-domains \
  --slug codex \
  --domain "Platform iOS Engineer=ios-platform:3" \
  --domain "Tau app UI Designer=tau-app-ui:2" \
  --domain "DocC infra=docc-infra" \
  [--merge] [--dry-run]
```

Flags

- `--slug <agent>`: agent slug (kebab‑case)
- `--domain "Label=identifier[:weight]"`: repeatable; weight is optional (> 0 when provided)
- `--merge`: merge with existing (last‑wins by slug); default replaces
- `--dry-run`: print updated JSON; do not write

Notes

- Identifiers allow A–Z, a–z, 0–9, '.', '-', '_' (tag-like). Labels are free‑form strings.
- When weights are provided, mirrors normalize and show percentages.

Flags

- `--slug <agent>`: agent slug (kebab‑case)
- `--primary <csv>`: required CSV of `<type=weight>` pairs (e.g., `code=5,design=2,doc=1`)
- `--secondary <csv>`: optional CSV of `<type=weight>` pairs
- `--s-type-contribution-map <path>`: JSON spec whose `types` keys define allowed contribution types
- `--contribution-focus <type>`: additional allowed contribution types (repeatable)
- `--merge`: merge into existing mix (last‑wins per type); default replaces
- `--dry-run`: print updated JSON to stdout; do not write

Notes

- Weights must be > 0; values do not need to sum to 1.0 (normalized on read).
- Unknown contribution types are rejected when a focus/set is provided via
  `--s-type-contribution-map` and/or `--contribution-focus`.

## Transfer (Plan)

```bash
clia agents transfer \
  --from .clia/agents/old \
  --to   .clia/agents/new \
  [--new-slug new-slug] [--include chats,codex,summaries] --dry-run
```

Prints a JSON plan with file renames/edits and a receipt outline. No changes
are applied in plan mode.

## Journal (via CLIAAgentCore)

```bash
clia core journal --slug ios-engineer \
  --highlight "Shipped previews" --focus "Docs polish" --next-step "Add tests"
```

Writes `journal/<YYYY-MM-DD>.json` at the parent submodule root. Signature is
auto‑resolved from `extensions.journalSignature`. Uses
`CLIAAgentCore.JournalWriter.append(...)` and `WriteTargetResolver`.

## Mentions (Caret ^)

- Caret mentions resolve to the agent slug (`slug`). Examples: `^codex`, `^carrie`.
- Display role (`role`) does not affect mention resolution; it is for profiles only.

## Migrate Role

```bash
clia agents migrate-role --from product-manager --to product-owner --path . --dry-run
```

Plans renames and JSON edits for role/slug across triads and mirrors. Use dry‑run
to review changes before applying.
