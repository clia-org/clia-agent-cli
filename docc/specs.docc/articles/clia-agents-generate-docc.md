# Clia Agents Generate-docc

Generate canonical DocC output for a CLIA agent.

## Purpose

- Render `generated.docc` under `.clia/agents/<slug>/docc/` using
  `memory.docc` (read-only) as the source for expertise + journal.
- Keep DocC mirrors in sync with triads and memory sources.

## Command

```bash
clia agents generate-docc --slug <agent> --merged --write
```

## Options

- `--slug <agent>`: required agent slug.
- `--path <dir>`: working directory (default: CWD).
- `--generated-bundle <name>`: generated bundle name (default: `generated.docc`).
- `--memory-bundle <name>`: memory bundle name (default: `memory.docc`).
- `--expertise-bundle <name>`: expertise bundle name (default: `expertise.docc`).
- `--journal-bundle <name>`: journal bundle name (default: `journal.docc`).
- `--merged`: render merged triads across lineage.
- `--write`: apply changes (default is dry run).

## Output

- Writes:
  - `.clia/agents/<slug>/docc/generated.docc/` (including `generated.docc/memory/`)
- Reads (unchanged):
  - `.clia/agents/<slug>/docc/memory.docc/`

## Notes

- The command treats `.clia/agents/<slug>/docc/memory.docc/expertise/` and
  `.clia/agents/<slug>/docc/memory.docc/journal/` as source content; those
  bundles must already exist (they are not modified).
- It writes outputs into `generated.docc`, including a copied memory view under
  `generated.docc/memory/`.
- The memory view prefixes resources with `memory-` for determinism and strips
  extra `@TechnologyRoot` entries from copied roots.
