# Agents Roster Updates (v1)

Status: draft

## Purpose

- Define a safe, deterministic way to add/update agent roster rows in `AGENTS.md`.
- Allow any `*-agent-cli` to perform roster updates while commissioning remains CLIA-only.

## Write target

- Parent submodule root: locate the nearest directory containing `.git` (file or folder) above `--path` and write to `ROOT/AGENTS.md`.
- No git commands; pure filesystem checks.

## Row format

- Markdown table with three columns: `| <Title> | <Summary> | <Path> |`
- Path is repo-relative agent dir: `` `.clia/agents/<slug>/` ``
- Summary should be a concise, single-line mission.

## Behavior

- If `AGENTS.md` exists:
  - Insert row directly under the header separator line `| ----- | ------- | -------- |` if present; else append to end.
  - Dedupe by exact row string; avoid duplicate entries.
  - Remove transitional rows containing `_(commissioned via CLI)_`.
- If missing:
  - Create a minimal table with header + separator, then insert row.

## Inputs

- `title: String` (human-friendly)
- `slug: String` (kebab-case)
- `summary: String` (single line)
- `agentsPath: String` (defaults to `` `.clia/agents/<slug>/` ``)

## Guardrails

- Never rewrite existing text outside the roster table.
- Keep line length reasonable (~100 chars) per markdown lint.
- Do not run git commands.

## Suggested API (CLIACore)

- `RosterUpdater.update(root: URL, title: String, slug: String, summary: String) throws`
- Internals mirror CLIA’s current `registerAgentInRoster` with submodule-root resolution.

## References

- Example logic: code/mono/apple/spm/clis/agents/clia/Sources/CliaAgentCLI/Commands/AgentsCommand.swift:696
- Lineage/write target: `.clia/specs/agents-lineage.v1.md`
