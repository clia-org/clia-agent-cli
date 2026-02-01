# CLIA Agents — Identity Isolation (BAD COPY)

> Deprecation (2025-10-16)
>
> The agents-level pointer `.clia/agents/.active.json` is deprecated and non-authoritative.
> Do not write or rely on a global "active agent" file. When needed, pass
> explicit slugs to CLIs (e.g., `--slug codex`). In chat UIs, agent switches are
> session-scoped (memory), and multiple agents may be active concurrently across
> sessions. Future options (session namespacing) remain under evaluation.

Status: spec (risk + mitigations)
Owner: CLIA (Chief of Staff)

> Whoa. This environment is shared. Any agent can set `CLIA_AGENT_SLUG`.
> Writing `.clia/agents/.active.json` is deprecated; do not do this.

## Problem

- whoami fallback chain (cwd → env → default) is convenient, not authoritative.
- In shared shells, CI, or multi‑agent sessions, global state can be changed by others.

## Guidance (now)

- Prefer explicit slugs: pass `--slug <agent>` for all agent‑sensitive commands.
- Always surface and record `source` from whoami outputs when acting.
- In CI/multi‑agent runs, disable env/active fallbacks by policy and require explicit slugs.

## Mitigations (near‑term)

- Namespaced identity: explore session-scoped identity (PID/UUID) without a global
  `.active.json` file.
- Add `CLIA_IDENTITY_MODE=strict` to force explicit slugs and ignore env/active files.
- Add a preflight warning when `source != arg` and the command will perform mutations.

## Future

- Policy gates in WrkstrmCLI/CommonCLI to require explicit identity for write operations.
- Tighter isolation per workspace/shell with cleanup on exit.

## Acceptance

- Docs warn clearly (BAD COPY) in README and AGENTS.
- whoami outputs include `source`.
- CI can enforce strict mode (explicit slugs only).
