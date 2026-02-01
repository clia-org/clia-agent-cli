# Multi‑persona chats (v1)

Status: draft

## Purpose

- Enable clear, auditable conversations across multiple agents in a single thread.
- Provide deterministic routing via slugs and handles.

## Addressing

- By handle: `@codex`, `@carrie`, `@dot`, `@clia`, `@cadence`.
- Preferred: start a line with an `agent:<slug>` token or a handle for explicit routing.

## Directives

- `@all` — broadcast to primary agents (codex, carrie, dot, clia, cadence).
- `@triage` — route to `codex` to propose next agent(s).
- `@pair(a,b)` — address two agents (e.g., `@pair(carrie,codex)`).
- `@handoff(a->b)` — transfer ownership to agent `b` with a one‑line reason.

## Precedence

1) `agent:<slug>` at line start (e.g., `agent:carrie ...`).
2) Handle at line start (e.g., `@carrie ...`).
3) Directive with explicit agents.
4) Directive default (`@triage` → codex; `@all` → broadcast set).

## Journaling

- Agency entries SHOULD include a signature suffix: `-<SIGNATURE>`.
- Storage target: parent submodule root (`ROOT/.clia/agents/<slug>/`) per lineage spec.
- When a handoff occurs, log one line: `handoff: a->b — <why>`.

## Storage

- Conversation indices remain JSON under `ai/imports/.../<date>/<slug>/index.json`.
- Messages MAY carry `agent.slug`, `agent.role`, and `routedBy` (`handle`|`role`|`directive`).

## Reference

- Roles: `.clia/schemas/specs/roles.v1.json`.
- Routing: `.clia/schemas/specs/multi-persona-chats.v1.json`.
