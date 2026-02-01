# Agent lineage: root chains and domain boundaries

CLIA agents can be authored and resolved across multiple nested domains (repo, mono, submodules). The lineage system must be deterministic, domain-driven, and safe.

This page specifies how CLIA resolves agent triads across domains today, and proposes an extension for explicitly selecting a chain of "root" contexts for an agent.

## Goals

- Deterministic context resolution (no filesystem-order dependence).
- Domain-driven design (DDD): a domain does not need to know about broader domains.
- Most-local-wins merge behavior (for now).
- Ability to intentionally compose root contexts for specific agents (future).

## Terms

- Domain root: a directory that may contain `.clia/agents/`.
- Context: one layer in the resolution chain where a matching agent directory exists.
- Default lineage chain: contexts discovered by walking containment upward from a working path.
- Root chain injection (proposed): explicitly selected roots to include in an agent's lineage.

## Default lineage resolution (current)

Given a working path `P` (CLI `--path`, or cwd), resolve contexts as follows:

1. Walk ancestor directories from filesystem root to `P`.
2. For each ancestor directory `A`, include context `.clia/agents/<slug>` if it exists.
3. Also include submodule roots discovered via `.gitmodules`, but only submodules that *contain* `P`.
4. Order contexts global -> local.
5. Merge triads using "most local wins" (later contexts override earlier ones).

### Domain boundary rule

A submodule must not inherit from unrelated sibling submodules. Therefore, submodules discovered from `.gitmodules` are only eligible if:

- `P` is inside that submodule root (i.e. `P == submoduleRoot` or `P` has prefix `submoduleRoot/`).

This preserves domain-driven boundaries while still allowing a submodule to inherit from repo-level and mono-level roots that are in its containment chain.

### Determinism requirements

When multiple agent documents exist in a context directory, selection must be stable:

- Candidate `*.agent.json` files must be sorted and selected deterministically.
- No reliance on filesystem directory listing order.

## Merge semantics (current)

For a given slug and a resolved list of contexts ordered global -> local:

- Merge is deep (object fields merge recursively).
- Conflict resolution: most-local-wins.

This is a pragmatic default. Inheritance-specific semantics (e.g. sealed fields, field-level strategies) can be introduced later.

## Proposed: explicit root chain injection

Some agents should be able to intentionally select a specific chain of roots (while still respecting domain boundaries). This is a schema-level feature request.

### Requirements

- Must be expressed in the definitive CLIA triad schema (not `extensions.*`).
- Must not violate DDD boundaries.
- Must preserve deterministic ordering.

### Proposed schema addition (AgentDoc)

Add a new field to `*.agent.json`:

```json
{
  "rootChain": {
    "mode": "default" | "explicit" | "hybrid",
    "roots": [
      { "kind": "path", "path": "code/mono" }
    ],
    "policy": {
      "enforceContainment": true
    }
  }
}
```

- `mode: default` (or missing): use the default lineage chain.
- `mode: explicit`: use only the explicitly specified roots (plus the agent's local context).
- `mode: hybrid`: start from default chain and inject the specified roots.

### Containment enforcement

If `enforceContainment` is true, each injected root must be "reachable" from the agent's domain:

- It must be an ancestor of the working path `P`, or
- It must be the containing submodule root of `P`.

Otherwise resolution fails with a validation error.

### Ordering

The final chain must remain ordered global -> local. Conflicts continue to resolve as most-local-wins.

### Recommended CLI support (future)

- `clia agents context --slug <slug> --path <path> --explain`
  - show default chain
  - show injected roots (if any)
  - show final chain and why each context was included

## Non-goals

- Field-level merge strategies ("sealed" fields, append-only lists, etc.).
- Cross-domain imports that bypass containment.
- Multiple `@TechnologyRoot` in a single DocC bundle.
