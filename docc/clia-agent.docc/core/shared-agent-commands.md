# Shared Agent Commands

@Metadata {
  @DisplayName("Shared Agent Commands")
}

This article lists the shared subcommands provided by ``CLIAAgentCoreCLICommands``.
Client CLIs can register them via ``AgentCoreCommands.standard`` or
``agentCoreSubcommands`` to get consistent, deterministic behavior.

## Mirrors — `Mirrors`

- Purpose: render Markdown mirrors from JSON triads under `.clia/agents`.
- Flags:
  - `--agents-dir <path>`: agents root (default `.clia/agents`).
  - `--dry-run`: print planned writes, do not modify files.
- Notes: safe, read-only in dry-run.

## Triads Render (Agenda) — `Triads Render --Kind Agenda`

- Purpose: render a single agent’s `*.agenda.json` to Markdown.
- Flags:
  - `--kind agenda`: triad kind to render (required).
  - `--slug <agent>`: agent slug (required).
  - `--path <dir>`: working directory for lineage resolution (default CWD).
  - `-w, --write`: write `.generated/<slug>.agenda.md` next to JSON.
- Notes: uses lineage to prefer nearest context.

## Triads Aggregate (Agenda) — `Triads Aggregate --Kind Agenda`

- Purpose: aggregate agenda triads across agents and print JSON or Markdown.
- Flags:
  - `--kind agenda`: triad kind to aggregate (required).
  - `--root <path>`: root directory to scan (default CWD).
  - `--format json|md`: output format (default `json`).
  - `--calendar day|week|month|all`: calendar view (optional).
  - `--current-only`: include only current (Next) items.
  - `--backlog-only`: include only backlog items.
  - `--active-only`: include only agendas with status=active.
- Notes: read-only; scans `.clia/agents/**/ *.agenda.json`.

## Agent DocC — `Agents Generate-docc`

- Purpose: generate `generated.docc` and `memory.docc` bundles under the agent docc directory.
- Flags:
  - `--slug <agent>` (required)
  - `--path <dir>` (default CWD)
  - `--generated-bundle <name>` (default `generated.docc`)
  - `--memory-bundle <name>` (default `memory.docc`)
  - `--expertise-bundle <name>` (default `expertise.docc`)
  - `--journal-bundle <name>` (default `journal.docc`)
  - `--include-launchpad-docc` / `--no-include-launchpad-docc` (default include)
  - `--write` (apply; default dry run)
- Notes:
  - Uses `memory.docc/expertise` + `memory.docc/journal` as read-only sources; these must
    exist before running.
  - Copies expertise + journal into `generated.docc` and writes a memory view
    under `generated.docc/memory`, prefixing resources with `memory-`.
  - Strips extra `@TechnologyRoot` from copied root pages.
  - Copies any `spm/launchpad/**.docc` bundles into `generated.docc/launchpad` when included
    (default on).
  - Not part of `AgentCoreCommands.standard`; clia exposes it under
    `agents generate-docc`.

## Journal — `Journal`

- Purpose: append a JSON journal entry at the parent submodule root.
- Flags:
  - `--slug <agent>`: agent slug (default `codex`).
  - `--path <dir>`: working directory (default CWD).
  - `--agent-version <semver>`
  - `--highlight <text>` (repeatable)
  - `--focus <text>` (repeatable)
  - `--next-step <text>` (repeatable)
  - `--dirs-touched <path>` (repeatable; stored as `x-dirsTouched`).
- Notes: resolves write target via repo root discovery; append-only.

## Roster Update — `Roster-update`

- Purpose: add/update the agent’s row in `AGENTS.md` at the parent submodule root.
- Flags:
  - `--title <text>`
  - `--slug <agent>`
  - `--summary <text>`
  - `--path <dir>`
- Notes: idempotent row update (append/replace as needed).

## Roster Coverage — `Core Roster`

- Purpose: audit contribution coverage across all discovered agents and highlight missing
  All-Contributors types.
- Flags:
  - `--path <dir>`: working directory (default CWD).
  - `--format text|json`: choose human or machine-friendly output (default `text`).
  - `--require-complete`: exit with a non-zero status when canonical types are missing.
- Output:
  - Overall counts per type with agent slugs.
  - Aggregated share totals: Σ (primary) and Σ₂ (secondary) when contribution mixes declare them.
  - "Missing types" summary and optional unknown-type hints.
  - Per-segment sections that split coverage by workspace root (for example, `/Users/example/workspace`
    vs `/Users/example/workspace/code`).
- Notes: derives canonical types from `resources/specs/all-contributors-types.v1.json`; JSON output
  includes `missingTypes`, `unknownTypes`, `primaryShares`, `secondaryShares`, and a detailed
  `segments` array for automation. Text output shows aggregated share totals (`Σ` for primary,
  `Σ₂` for secondary) next to each type.

## Doctor — `Doctor`

- Purpose: quick health check for a triad.
- Flags:
  - `--slug <agent>` (required)
  - `--path <dir>` (default CWD)
  - `--json` (emit JSON)
  - `--strict` (non-zero exit on warnings)
- Surfaces: write target, triad presence, merge decode warnings, planned mirrors, roster hints.

## Profile — `Profile`

- Purpose: print a merged view of a triad with optional lineage chain.
- Flags:
  - `--slug <agent>` (required)
  - `--kind agent|agenda|agency` (default `agent`)
  - `--path <dir>` (default CWD)
  - `--root-chain` (include lineage directory chain)
  - `--json` (JSON output; default true)
- Notes: merged view includes triads referenced by top-level `inherits` when present.

## Lineage Lint — `Lineage-lint`

- Purpose: lint lineage/inheritance determinism (read-only).
- Flags:
  - `--slug <agent>` (optional; otherwise scans agents dir)
  - `--path <dir>` (default CWD)
  - `--json` (JSON report)
  - `--strict` (non-zero exit on warnings)
- Checks: missing top-level `inherits` reference to root directives; duplicate guardrails after merge.

## Triads Agency Log — `Triads Agency Log`

- Purpose: append a log entry to one or more agency JSON files using lineage write target.
- 0.4.0 only: writes a ContributionEntry (grouped, evidenced contributions). Refuses to write when
  the target schemaVersion is not `0.4.0`; run `normalize-schema` first.
- Flags:
  - `--agent/-a <slug>` (repeatable)
  - `--summary <text>` (required)
  - `--kind log|request|decision` (default `log`)
  - `--title <text>`
  - `--detail <text>` (repeatable; 0.4.0 details array)
  - `--details <text>` (legacy single body; folded into 0.4.0 details)
  - `--participants codex,cadence,rismay` (merged into `tags`)
  - `--tags t1,t2` (optional; merged with participants in 0.4.0)
  - `--link "href"` or `--link "href|kind|title"` (repeatable)
  - `--contrib "by=<slug>,type=<type>,evidence=<text>[,weight=<n>]"` (repeatable)
  - `--path <dir>` (default CWD)
  - `--create-if-missing`
  - `--upsert` (replace existing entry for the same date by title/kind)
- Notes:
  - If no `--contrib` is provided, a minimal group is inferred per participant (or the document’s
    slug) with `type = kind` and `evidence = summary` to satisfy schema requirements.

## Triads Normalize — `Triads Normalize`

- Purpose: normalize triads (format/order) per kind.
- Kinds:
  - `--kind agent` — format-first canonical save for AgentDoc; always re-saves when the canonical
    encoding differs byte-for-byte. Minimal list normalization:
    - `links` sorted by title (case-insensitive; nil last), then URL (nil last).
    - `extensions.operationModes` (if array of strings) sorted asc.
  - `--kind agency` — sorts `entries` by `timestamp` (newest-first) and writes canonical JSON.
  - `--kind agenda` — milestone status-bucket ordering and optional backlog sort.
- Flags:
  - `--kind agency|agenda|agent` (default `agency`)
  - `--slug <agent>` or `--dir <path>` (mutually exclusive)
  - `--path <dir>` (default CWD; used with `--slug`)
  - `--write` (apply changes; otherwise dry run)
  - `--sort-backlog none|title|id` (agenda only)
- Behavior:
  - AgentDoc: canonical re-save on byte-diff, even when no order changes.
  - Agency/Agenda: also canonical re-save on byte-diff (in addition to ordering changes).
  - Directory mode scans recursively; skips heavy/generated dirs (`.git`, `.build`, `DerivedData`,
    `node_modules`, `.generated`).

### Migration

- Legacy top-level commands are removed in favor of triads group:
  - `agency-log` → `triads agency log`
  - `agency-sort` → `triads normalize --kind agency`
  - `render-agenda` → `triads render --kind agenda`
  - `agenda-aggregate` → `triads aggregate --kind agenda`
  - Use `triads normalize --kind agent|agenda` for AgentDoc/AgendaDoc maintenance.

## Registration

```swift
import ArgumentParser
import CLIAAgentCoreCLICommands

@main
struct App: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "my-cli",
    abstract: "Agent utilities",
    subcommands: AgentCoreCommands.standard
  )
}
```
