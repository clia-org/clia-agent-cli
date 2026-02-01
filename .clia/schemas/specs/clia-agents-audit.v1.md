# CLIA Agents — Audit Rules (v1)

Status: draft

## Rules

- Dirs to skip: names starting with `_`, `templates`, `chats`.
- Only audit directories that contain at least one triad.
- agent triads must include:
  - `slug` matching the directory name
  - `handle` (non‑empty)
  - `focusDomains` (identifier/label pairs; unique; non‑empty)
- Mirrors: non‑canonical; generated under `.generated/`.
