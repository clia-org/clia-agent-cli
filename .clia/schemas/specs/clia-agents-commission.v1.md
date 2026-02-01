# CLIA Agents — Commission Spec (v1)

Status: draft
Owner: CLIA (Chief of Staff)
Routing: General PO (Morrie), PJM

## Scope

- Commissioning is CLIA-only. No other `*-agent-cli` may implement commissioning flows.
- Roster updates (AGENTS.md row insert/dedupe) are separate and may be performed by any agent CLI per the roster spec.

## Objective

- Commission agents via CLIA with typed options and JSON‑first outputs.
- Keep triads canonical; mirrors generated under `.generated/`.
- Support persona signatures and routing defaults.

## Inputs (typed)

- slug (kebab/slug case)
- title (String)
- role (String)
- handle? (String)
- focusDomains (Array<String>; slug‑case identifiers rendered into focus domains)
- mentors? (Array<String> — names/emails resolved by config)
- tags? (Array<String>)
- journalSignature? (String; persona signature, e.g., "-CC")
- notes? (String[]; optional bootstrap notes)

## Effects

- Writes triads under `.clia/agents/<slug>/`:
  - `root@todo3.<slug>.agent.json`
  - `root@todo3.<slug>.agency.json`
  - `root@todo3.<slug>.agenda.json`
- Sets top‑level fields where supported by schema:
  - `handle`, `focusDomains` (Array<String> → rendered as identifier/label pairs)
- Writes persona config in `extensions` (plain JSON map):
  - `extensions.journalSignature` when provided
- Appends Agency entry: `Commissioned — <title>` with tags `[commission,routing]`
- Mirrors plan: `.generated/<slug>.*.md` with Handle/Focus headers

## Schema alignment

- AgentDoc should accept optional fields:
  - `handle: String?`
  - `focusDomains: [FocusDomain]?` (identifier+label[, weight])
- `extensions` remains a plain JSON dictionary for add‑ons (no typed wrapper).

## Validation rules

- slug: `^[a-z0-9]+(-[a-z0-9]+)*$`
- focusDomains input: non‑empty array; slug‑case; unique
- handle: non‑empty when present
- extensions: avoid deep nesting; prefer stable, well‑named keys

## Output (dry‑run)

```
{
  "agentPath": ".clia/agents/<slug>",
  "triads": [
    ".clia/agents/<slug>/root@todo3.<slug>.agent.json",
    ".clia/agents/<slug>/root@todo3.<slug>.agency.json",
    ".clia/agents/<slug>/root@todo3.<slug>.agenda.json"
  ],
  "mirrors": [
    ".clia/agents/<slug>/.generated/<slug>.agent.md",
    ".clia/agents/<slug>/.generated/<slug>.agency.md",
    ".clia/agents/<slug>/.generated/<slug>.agenda.md"
  ]
}
```

## Acceptance criteria

- Triads decode under current schema; mirrors render with Handle/Focus summary.
- Self‑audit passes (handle present, focus domains rendered).
- Agency entry logged with routing tags; mentors resolved (General PO + PJM by default).

## Notes

- No network side‑effects; any issue scaffolding remains local.
- Prefer small, composable libs under CLIA; Foundry should not own commissioning.
