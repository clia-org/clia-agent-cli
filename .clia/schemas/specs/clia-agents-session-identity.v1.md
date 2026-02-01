# CLIA Agents — Session‑Scoped Identity (proposal)

Status: proposal
Owner: CLIA (Chief of Staff)

## Motivation

- Multiple sessions (terminals, chats, CI jobs) can run concurrently. A single
  global “active agent” file causes conflicts and surprises.
- Chat UIs handle agent switching via session memory, but CLIs sometimes need a
  default identity when `--slug` is omitted.
- Goal: provide an optional, ephemeral, session‑scoped pointer that never leaks
  across sessions and is safe to ignore.

## Non‑goals

- No global, repo‑tracked “active agent” file.
- No change to canonical sources: agent triads remain authoritative under
  `.clia/agents/<slug>/`.
- No change to incidents: the conversation header’s incident line continues to
  read `.clia/incidents/active.json` only.

## Design

- Session ID (optional): `CLIA_SESSION_ID`
  - When set, tools may use it to namespace any ephemeral state.
  - When absent, tools may generate a short, local identifier (e.g., PID/UUID)
    for the current process and avoid persisting it beyond the run.

- Ephemeral pointer path (ignored by Git):
  - `.wrkstrm/tmp/sessions/<session-id>/active-agent.json`
  - Example shape:

    ```json
    {
      "slug": "codex",
      "handle": "Utility Engineer",
      "updatedAt": "2025-10-16T00:00:00Z",
      "source": "whoami set --slug codex"
    }
    ```

- Read fallback chain (CLIs):
  1) explicit argument `--slug <agent>`
  2) environment `CLIA_AGENT_SLUG`
  3) session pointer `.wrkstrm/tmp/sessions/<id>/active-agent.json`
  4) default: `codex`

- Write behavior:
  - Only explicit commands (e.g., a future `whoami set --slug <agent>`) write
    the session pointer. Read‑only commands never write identity.
  - No writes to `.clia/agents/.active.json` (deprecated).

- Strict mode:
  - `CLIA_IDENTITY_MODE=strict` disables env and session fallbacks; CLIs require
    explicit `--slug` when identity matters (especially on write operations).

- Concurrency and cleanup:
  - Each session writes to its own directory; no cross‑session collisions.
  - Files live under `.wrkstrm/tmp/` which is already ignored; tools may prune
    old session directories opportunistically.

## Acceptance criteria

- No tool relies on a global active‑agent file; `.clia/agents/.active.json` is
  treated as deprecated and ignored.
- CLIs that need a default identity follow the fallback chain above.
- Strict mode enforces explicit identity for write operations.
- Documentation clearly distinguishes incidents (banner) from identity.

## Out of scope

- Implementations of `whoami set/clear` commands; these will be proposed under
  CLI roadmaps separately.

## Notes

- This proposal complements the deprecation of `.clia/agents/.active.json` and
  avoids single‑source persistence by keeping any identity state ephemeral and
  session‑scoped.
