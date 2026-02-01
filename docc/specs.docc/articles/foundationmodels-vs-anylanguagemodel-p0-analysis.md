# P0 Analysis: FoundationModels vs AnyLanguageModel

**Created**: 2026-01-07  
**Status**: Draft  
**Scope**: Compare FoundationModels and AnyLanguageModel for schema-constrained responses in CLIA.

## Goal

Decide whether P0 should stay on FoundationModels `@Generable` or pivot to AnyLanguageModel for
schema-constrained CLIA responses.

## What Matters for P0

- Schema-constrained responses that match the existing CLIA response shape.
- Minimal integration risk with current CommonAI providers.
- Clear migration path if we later choose AnyLanguageModel.

## Comparison Summary

### FoundationModels

- Pros:
  - Native to Apple platforms; on-device execution.
  - `@Generable` gives a first-class schema mechanism.
  - Tight integration with `LanguageModelSession`.
- Risks:
  - Apple-only; no cross-provider abstraction.
  - Requires CommonAI plumbing to support schema output.

### AnyLanguageModel

- Pros:
  - Library aims to unify multiple providers behind a single API.
  - Could reduce custom abstraction in CommonAI over time.
  - README shows `@Generable` support as a drop-in replacement for `FoundationModels`.
  - Supports Apple Foundation Models, Gemini, OpenAI, Anthropic, Ollama, and local backends.
- Risks:
  - Requires integration effort and evaluation of schema support parity.
  - Unknown alignment with `@Generable` output vs FoundationModels schema paths.
  - Requires Swift 6.1+ and iOS 17+/macOS 14+/visionOS 1+.

## Feature Comparison (Generative-ai-swift vs AnyLanguageModel)

<table header-row="true">
<tr>
<td>Capability</td>
<td>google-ai-swift (Gemini)</td>
<td>AnyLanguageModel</td>
</tr>
<tr>
<td>Providers</td>
<td>Google Gemini only</td>
<td>Apple Foundation Models, Gemini, OpenAI, Anthropic, Ollama, local (CoreML/MLX/llama.cpp)</td>
</tr>
<tr>
<td>Structured output</td>
<td>JSON schema via responseMIMEType/responseSchema</td>
<td>`@Generable` schema output (drop-in replacement)</td>
</tr>
<tr>
<td>Tool calling</td>
<td>Supported</td>
<td>Supported (Tools API)</td>
</tr>
<tr>
<td>Streaming</td>
<td>Supported</td>
<td>Supported</td>
</tr>
<tr>
<td>On-device</td>
<td>No</td>
<td>Yes (FoundationModels/CoreML/MLX/llama.cpp)</td>
</tr>
<tr>
<td>Platforms</td>
<td>Swift; Linux supported; not Android</td>
<td>Swift 6.1+; iOS/macOS/visionOS/Linux</td>
</tr>
</table>

## Parity Checklist (AnyLanguageModel vs Generative-ai-swift)

- Schema-constrained output: **yes** (`@Generable`, `GenerationSchema`, `includeSchemaInPrompt`).
- Streaming responses: **yes** (`streamResponse` in tests).
- Tool calling: **yes** (`LanguageModelSession` tools; `toolOutput` in transcript entries).
- Token counting: **unknown** (not found in repo scan).
- Provider-specific config (Gemini thinking/server tools): **unknown** (not found in repo scan).

## Recommendation for P0

- Stay on FoundationModels `@Generable` for the immediate P0 implementation.
- Start a P0 investigation to evaluate AnyLanguageModel’s schema support and identify
  any blocking gaps for CLIA command proposals.
 - AnyLanguageModel is viable if we accept losing Gemini-specific `safetySettings`, with
   mitigation to preserve safety via provider defaults and policy checks.

## Simplification Potential (AnyLanguageModel)

### Where it Helps

- A unified model interface could replace multiple provider adapters in CommonAI.
- Centralized schema handling if AnyLanguageModel exposes a first-class schema API.

### Where it Does Not Help

- If AnyLanguageModel lacks `@Generable`-equivalent schema output, CommonAI still needs custom
  schema plumbing.
- Provider-specific behavior (Apple on-device, OpenAI tool calling) may still require adapter
  logic or feature flags.

## Open Questions

- Does AnyLanguageModel expose a schema/JSON output API equivalent to `@Generable`?
- Can AnyLanguageModel run on-device or is it provider-only?
- How would CommonAI map response schemas to AnyLanguageModel without breaking existing APIs?
 - What safety controls should replace Gemini `safetySettings` if we switch?
