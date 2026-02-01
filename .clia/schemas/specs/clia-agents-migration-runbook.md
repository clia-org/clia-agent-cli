# CLIA Agents — Migration Runbook (Foundry → CLIA)

Status: draft

## Steps

1) Land schema bump in clia-models (optional fields: `handle`, `focusDomains`).
2) Add CLIAAgents* libs and `clia agents` CLI.
3) Port commissioning logic; write triads with mentors and persona.
4) Map legacy `agentExpertise` arrays into `focusDomains` entries (identifier/label) and remove the legacy key.
5) Port mirrors/audit/transfer/journal flows to CLIA.
6) Update Foundry docs; remove Foundry commands in follow‑up.
7) Run self‑audit and mirror render; update DocC.

## Rollback

- Commissioning can fall back to existing triads; mirrors/audit remain stable.
