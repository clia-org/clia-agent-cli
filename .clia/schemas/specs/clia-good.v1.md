# clia good — v1 spec (human-readable)

A human‑readable companion to `clia-good.v1.json` for quick review.

- Tool: `clia`
- Subcommand: `good`
- Abstract: Super-command hosting `morning`, `day`, and `night` rituals.

## Behavior

- Morning: print environment snapshot, start detached timer, update today's note (“Already did today”).
- Day: print compact status summary from `.wrkstrm/tmp/task-heartbeat.json`; optionally append to `AGENCY.md`.
- Night: append wind‑down entry to agency triad (JSON) and, when `--on-deck` items are present, ensure tomorrow's note exists and update its “On deck” section with merged, de‑duplicated items.

## Subcommands & options

- Morning (`morning`, alias `m`):
  - Options: `--kawara-style/--no-kawara-style`, `--news <text>`, `--did <text>` (repeatable), `--no-note`, `--no-timer`
  - Usage: `clia good morning [options]`

- Day (`day`, alias `d`):
  - Options: `--note <text>`, `--append-agency`
  - Usage: `clia good day [options]`

- Night (`night`, alias `n`):
  - Options: `--message <text>` (required), `--on-deck <text>` (repeatable), `--append-journal`, `--dirs-touched <path>` (repeatable)
  - Usage:

    ```bash
    clia good night \
      --message "..." \
      --on-deck "..." \
      --append-journal \
      --dirs-touched ".clia/agents/patch/docc/expertise.docc"
    ```

## I/O

- Heartbeat: `.wrkstrm/tmp/task-heartbeat.json` (morning starts/refreshes; day ensures if missing; night writes winddown)
- Notes: `notes/YYYY/YYYY-MM-DD.md` (morning today; night tomorrow when `--on-deck`)
- Agency triad: `.clia/agents/<slug>/root@todo3.<slug>.agency.json` (night; day when `--append-agency`)

## Examples

```bash
clia good --no-banner morning --did "Showered." --news "Markets at ATHs."
clia good --no-banner day --append-agency
clia good --no-banner night --message "Ship safely." --on-deck "Finish docs" --on-deck "Plan sprint W37"

# Shorthand aliases
clia good m --no-banner
clia good d --no-banner
clia good n --no-banner --message "Wrapping up"
```

Notes:

- Canonical JSON lives at: `.clia/specs/clia-good.v1.json`

## Flow Details

- Morning
  - stdout: environment snapshot (no writes)
  - heartbeat: ensure `.wrkstrm/tmp/task-heartbeat.json` (task `gm`, detached)
  - notes: ensure `notes/YYYY/YYYY-MM-DD.md`; update `## Already did today` with wake time,
    activities (merged), optional news; idempotent updates

- Day
  - heartbeat: ensure it exists (task `gd`, detached if missing)
  - stdout: print compact status summary (task, status, started, next-check, elapsed, points)
  - agency (optional): append "Midday check‑in" entry at the top insertion point; update `updated:`

- Night
  - heartbeat: write detached `#winddown` with message, tags `winddown,summary`, +12 manual points
  - agency: append Wind‑down entry with banner, tags, startedAt, your note; update `updated:`
  - notes (optional): ensure tomorrow’s `notes/YYYY/<tomorrow>.md`; merge `--on-deck` items under
    `## On deck`
