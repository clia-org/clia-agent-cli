# CLIA Agents — Motto Publish (Later) v1

Status: spec (no code yet)
Owner: CLIA (Chief of Staff)
Intent: Draft now, publish later. No real‑time uploads.

## Objective

- Allow motto drafts (blog/X) to be queued for later publishing by a separate, explicit step.
- Keep drafts private and non‑canonical under `.generated/` until promoted.
- Record a machine‑readable queue entry per draft so the later publisher can act deterministically.

## Queue layout

- Per agent directory:
  - `.clia/agents/<slug>/.generated/mottos/YYYY-MM-DD/HH-mm-ss/{blog.md,twitter.txt}`
  - Queue entries live under:
    - `.clia/agents/<slug>/receipts/publish-queue/`
  - When promoted, a publish receipt is written under:
    - `.clia/agents/<slug>/receipts/published/`

## Queue item JSON shape (v1)

```json
{
  "schema": "https://wrkstrm.dev/schemas/clia/motto-publish-queue.v1.json",
  "id": "2025-09-26T01-45-00Z-carrie-credential-motto-3a1c",
  "created": "2025-09-26T01:45:00Z",
  "slug": "carrie-credential",
  "agentHandle": "Carrie Credential",
  "motto": "Credentials matter most when they're invisible.",
  "author": "Carrie Credential",
  "length": "long",          
  "includeChats": true,
  "maxChats": 2,
  "sources": {
    "blog": ".clia/agents/carrie-credential/.generated/mottos/2025-09-26/01-45-00/blog.md",
    "twitter": ".clia/agents/carrie-credential/.generated/mottos/2025-09-26/01-45-00/twitter.txt"
  },
  "targets": {
    "blog": {
      "enabled": true,
      "dest": "docs/blog/2025/09/carrie-credential-2025-09-26-motto.md"
    },
    "twitter": { "enabled": false }
  },
  "state": "queued",
  "attempts": 0,
  "notes": [
    "Draft created locally; queued for manual publish.",
    "No network actions performed."
  ]
}
```

Notes

- `id`: timestamp + slug + short hash (e.g., from motto text) for stable filenames.
- `targets.blog.dest`: precomputed destination path for later move/copy.
- `state`: one of `queued|published|skipped|failed`.
- `attempts`: incremented by the publisher; keep under a sensible cap.

## CLI runner (later)

- Command: `clia agents agency publish`
- Modes:
  - `--from queue` (default): reads entries under `publish-queue/`.
  - `--dry-run`: prints planned moves/copies and output paths.
  - `--apply`: copies assets to destinations, writes a published receipt, and updates `state`.
  - `--filter slug=<agent>`: limit to a single agent.
  - `--filter id=<id>`: publish a single queue item.
- Output receipts:
  - `.clia/agents/<slug>/receipts/published/<id>.json` with summary of copied files.

## Acceptance

- Creating a motto draft writes (or updates) a queue item JSON with the shape above.
- The later publisher can act purely from the queue file (no guessing paths).
- No network activity is required; copy/move within the repo only unless configured otherwise.
- Agency entry is appended when items are published (title, id, destination paths).

## Security & privacy

- Drafts and queues remain private. Do not write public links until the publish step.
- When adding Twitter/X integration in future, require explicit approval and token configuration.

## Migration & docs

- Keep mirrors and queue entries deterministic and diff‑friendly (sorted keys, stable ordering).
- README: link the motto drafting command and explain that publication is a later, explicit step.

## Motto

- "Apply with the carcasses of dead targets. Great developers kill code." — Rismay
