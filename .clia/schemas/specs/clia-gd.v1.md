# clia good-day — v1 spec (human-readable)

A human‑readable companion to `clia-gd.v1.json` for quick review.

- Tool: `clia`
- Subcommand: `good-day`
- Abstract: Midday check-in: print current heartbeat summary and optional note.

## Behavior

1. Ensure a detached task heartbeat exists at `.wrkstrm/tmp/task-heartbeat.json`.
   - If missing, write one labeled `gd` (single write; detached).
2. Read and print a compact status summary to stdout:
   - task, status, started (localized), next-check (localized), elapsed (mm:ss), points
3. Optional: `--append-agency` appends a concise check‑in entry to the agency triad (JSON).

## Options

- `--note <text>` — Optional note to include in the printed summary.
- `--slug <agent>` — Agent slug to write to (default: auto‑resolve).
- `--append-agency` — Append a concise check-in entry to agency triad (JSON).

## I/O

- Writes heartbeat (`.wrkstrm/tmp/task-heartbeat.json`) only if missing.
- Appends to `.clia/agents/<slug>/root@todo3.<slug>.agency.json` when `--append-agency` is set.

## Examples

```bash
clia good-day --no-banner
clia good-day --no-banner --note "Quick stretch + water"
clia good-day --no-banner --append-agency --slug patch
```

Notes:

- Canonical JSON lives at: `.clia/specs/clia-gd.v1.json`
