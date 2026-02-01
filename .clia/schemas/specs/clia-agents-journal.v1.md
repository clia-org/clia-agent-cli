# CLIA Agents — Journal Spec (v1)

Status: draft
Owner: CLIA (Chief of Staff)

## Objective

- Persist daily JSON entries per agent with date and timestamp (UTC) and persona signature.

## Path & Shape

- Path: `.clia/agents/<slug>/journal/YYYY-MM-DD.json`
- Fields:
  - `date`: `YYYY-MM-DD`
  - `timestamp`: ISO‑8601 UTC (e.g., `2025-09-25T22:05:10Z`)
  - `agentVersion`: String (semantic or calendar)
  - `highlights`: Array<String>
  - `focus`: Array<String>
  - `nextSteps`: Array<String>
  - `signature` (optional): String (from `extensions.journalSignature`)

## Persona signatures

- `extensions.journalSignature` in triads defines the shorthand signature for mirrors and journals.
- Example: Carrie Credential uses `"-CC"`.

## Acceptance

- Entry exists for a given day; mirrors link to the journal folder when appropriate.
- Agency entries may summarize important journal items but the canonical journal stays in JSON.
