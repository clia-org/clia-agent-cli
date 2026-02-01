# clia gm — Command Spec (v1)

A human‑readable companion to `clia-gm.v1.json` for quick review.

## Overview

- Tool: `clia`
- Subcommand: `gm`
- Purpose: print a concise environment snapshot to stdout (no writes), start a detached task timer
  labeled `gm`, and ensure/update today’s note with wake time, activities, and optional news.
- Default style: On Kawara (use `--no-kawara-style` for plain format).

## Usage

```bash
clia gm [--kawara-style|--no-kawara-style] [--news <text>] [--did <text> ...] [--no-note] [--no-timer]
```

## Options

- `--kawara-style` / `--no-kawara-style`
  - Type: flag (default: on)
  - Renders wake text in On Kawara style (e.g., “I WOKE UP AT 7:49 A.M.”).
- `--news <text>`
  - Type: string
  - One‑line news summary appended to today’s note.
- `--did <text>` (repeatable)
  - Type: string[]
  - Activities already done; appears under “Activities so far:”.
- `--no-note`
  - Type: flag (default: off)
  - Do not write to notes; still prints environment snapshot.
- `--no-timer`
  - Type: flag (default: off)
  - Do not start detached task timer.

## Behavior

- Prints environment snapshot (plain text) to stdout:
  - OS/arch, host, user/root, shell, cwd+writable
  - Git: in‑repo status, branch, remotes, submodules
  - `clia` path on `PATH`
  - Task timer status if heartbeat JSON exists
- Starts/updates detached task timer:
  - Path: `.wrkstrm/tmp/task-heartbeat.json`
  - Label: `gm`
- Updates note idempotently:
  - File: `notes/<YYYY>/<YYYY-MM-DD>.md` (creates from `notes/daily-note-template.md` if missing)
  - Section: “## Already did today”
  - Updates a single “Woke up:” line (On Kawara by default)
  - Merges/dedupes “Activities so far” bullets
  - Adds/replaces one “News” line

## Execution Plan

1. Print environment (`EnvironmentProbe.snapshot().renderPlain()`)
2. Start timer (`TaskTimer` detached) unless `--no-timer`
3. Update note (wake + activities + news) unless `--no-note`

## Paths

- Heartbeat JSON: `.wrkstrm/tmp/task-heartbeat.json`
- Notes template: `notes/daily-note-template.md`
- Daily note: `notes/<YYYY>/<YYYY-MM-DD>.md`

## Examples

- Print snapshot, start timer, update note with activity + news:

```bash
clia gm --no-banner \
  --did "Showered." \
  --news "Producer prices dropped; markets at ATHs."
```

- Print‑only (no writes):

```bash
clia gm --no-banner --no-note --no-timer
```

- Plain wake format:

```bash
clia gm --no-banner --no-kawara-style
```

## JSON Spec

- Canonical JSON lives at: `.clia/specs/clia-gm.v1.json`
- Includes: version, options with types/defaults, IO, paths, executionPlan, and mapping hints.

## Forward Compatibility

- Future: a `WrkstrmCLI` `JSONInstantiable` protocol can consume this JSON to instantiate and run
  `gm` via `AsyncArgumentParser`, translating fields to argv using the provided mapping.
