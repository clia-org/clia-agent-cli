# ADR: Generable Command Proposals for CLIA

**Status**: Draft  
**Date**: 2026-01-07  
**Decision**: Use `@Generable` response schema to emit `proposedCommands` while preserving the
existing response shape in P0.

## Context

CLIA currently relies on inline `!` shell commands or ad-hoc parsing of free-form text. This
creates ambiguity around when a command is being proposed, how to validate it, and how to capture
structured details (arguments, rationale, approvals).

The `@Generable` macro provides schema-constrained output for model responses, ensuring the model
emits only known fields with predictable structure.

## Decision

Adopt a `@Generable` response type that includes:

- `responseText`: natural language for the operator.
- `proposedCommands`: an optional array of command proposals.

Each proposal includes `command`, `arguments`, `rationale`, `approvalRequired`, and `policyTags`.

P0 constraint: keep the existing response shape and defer extra command detail fields.

## Consequences

### Positive

- Deterministic structure for proposed commands.
- Removes ad-hoc parsing and reduces ambiguity.
- Enables consistent approval flows and policy checks.

### Negative

- Requires schema generation and explicit prompting to enforce the output format.
- Larger response payloads can increase context size.
- P0 defers richer command detail fields, so some metadata remains implicit.

## Parity Guardrails

Any transition away from google-ai-swift must preserve:

- JSON schema responses (`responseMIMEType`, `responseSchema`).
- Tool calling.
- Streaming responses.
- Token counting.
- Provider-specific configuration (for example, Gemini thinking modes and server tools).

## Alternatives Considered

1) Free-form text with regex parsing.
   - Rejected: brittle, error-prone, not schema-safe.
2) External JSON schema validation without `@Generable`.
   - Rejected: extra glue, more drift risk, weaker toolchain support.

## Notes

This ADR pairs with the v2 spec:
`docc/specs.docc/articles/clia-command-proposals-v2.md`.
