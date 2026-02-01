# Agents Lineage (v1)

Status: draft

## Problem

Multiple context trees can define the same agent (root repo, submodules, app workspaces). We need a deterministic way for every `*-agent-cli` to:

- Read a merged view of that agent’s triads (agent/agenda/agency) across lineage.
- Write new knowledge (usually agency entries) to the correct layer without breaking provenance.

## Reading (merge semantics)

- Discovery: climb ancestors from the current working directory; collect `.clia/agents/<slug>/` at each level.
- Submodules: read `.gitmodules` at each ancestor root and include agent directories found under each submodule root.
- Inputs: nearest + every ancestor with a triad file (`*.agent.json`, `*.agenda.json`, `*.agency.json`).
- Inheritance: when an agent document declares `extensions.inherits: [<path>...]`, read those JSON
  documents as additional, lower-precedence layers before applying lineage precedence. Use a
  cycle-safe traversal (track visited paths) and treat referenced paths as repo-relative unless
  absolute. Typical use: inherit root communal directives from
  `.clia/agents/root/root@todo3.agent-directives.agent.json`.
- Merge rules (already implemented in `CLIACore.Merger`):
  - Scalars: last non‑empty wins (closest layer overrides).
- Arrays (mentors, tags, responsibilities, entries): stable union (preserve order, dedupe).
  - links: union by `(title|url)` key.
  - notes/extensions: last non‑empty wins.
  - contextChain: optional list of `(prefix, path)` for transparency.

Inheritance nuance (v1.1):

- `guardrails` and `sections` are arrays and continue to union across both inheritance and lineage.
- An agent may strengthen root policies (add stricter guardrails) but should not weaken them without
  explicit human approval logged in agency.
-

## Writing (knowledge accumulation)

- Default target: parent submodule root — resolve the nearest repository boundary (directory containing a `.git` directory or file) above the working path and write under that root: `ROOT/.clia/agents/<slug>/`.
- If the agent directory is missing at that root, create it on first write (append‑only files only; no destructive ops).
- Agency appends: write a new entry (with timestamp + signature), never mutate history in ancestors.
- Promotion: when desired, use `clia-agent-cli agents mirrors|transfer` to render Markdown mirrors or copy curated entries up.
- Provenance: include a `source` tag in the entry (resolved repo root path or short prefix) and sign with the configured journal signature (e.g., `-CL`).

Future (non-functional placeholder):

- Include `extensions.x-dirsTouched: [String]` on agency/journal entries to list directories impacted during the update. Used later to assist submodule splits.

Write target resolution (no git commands required):

- Start at `--path` (or CWD). Ascend until a directory contains `.git` (folder or file) → this is the repo root (submodule root if inside one).
- Use that root’s `.clia/agents/<slug>/` as the write location.
- Fallback: if no `.git` is found before filesystem root, use the provided `--agents-dir` or error with guidance.

## Display identity

- Per‑agent triads may carry `extensions.x-badge` and `x-emoji`. Display roles come from top‑level `role`.

## Adoption in `*-agent-cli`

- Reuse `CLIACore` + `CLIAModels` from the `clia` package.
- Provide standard subcommands:
  - `profile` → print merged `agent.json` (with `--root-chain`).
  - `plan` → print merged `agenda.json`.
  - `journal` → append agency entry at the parent submodule root (with `--note`, `--tags`, `--signature auto|<SIGNATURE>`). Include `--write-scope local|submodule|workspace` override (default: `submodule`).
- Common options: `--path <dir>`, `--agent-slug <slug>` (defaults to the tool’s own slug).

## Guarantees

- Read is pure and deterministic given a working directory.
- Write is localized and idempotent (append‑only for agency).
- No cross‑tree side effects unless `transfer`/`mirrors` is invoked explicitly.

## References

- Code: `code/mono/apple/spm/clis/agents/clia/Sources/CLIACore/{Lineage.swift,Merger.swift,MergeOptions.swift}`
- Specs: `.clia/schemas/specs/roles.v1.json`, `.clia/schemas/specs/multi-persona-chats.v1.*`
