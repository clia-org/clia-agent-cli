# PassKit Doc Mirroring — Sosumi Skill

@Metadata {
  @PageColor(purple)
  @PageImage(purpose: icon, source: "memory-icon-passkit-mirroring", alt: "icon passkit mirroring icon")
}

## Context

- Goal: give Carrie a repeatable way to mirror PassKit docs from `sosumi.ai` into local `.md` files
  under `job-hunting/code-swiftly/swift-interview-guide.docc`, so Wallet/Apple Pay prep stays
  stable and grep‑able.
- Source index: `https://sosumi.ai/documentation/passkit`
  - Link pattern: pages whose paths start with `/documentation`, resolved as
    `https://sosumi.ai/documentation…`.
  - Current size: ~1,391 PassKit links (2025‑12‑15 snapshot).
- Storage:
  - Raw mirrors live under:
    - `job-hunting/code-swiftly/swift-interview-guide.docc/apple-passkit-raw/`
  - Tracking lives in:
    - `job-hunting/code-swiftly/swift-interview-guide.docc/apple-passkit-traversal.md`

This is a documentation skill: Carrie knows how to update the mirror, not just read from it.

## File Layout and Naming

- Raw PassKit pages:
  - Directory: `job-hunting/code-swiftly/swift-interview-guide.docc/apple-passkit-raw/`
  - Filename pattern: `<short-slug>-raw.md`
    - Examples:
      - `/documentation/passkit` → `passkit-raw.md`
      - `/documentation/passkit/wallet` → `wallet-raw.md`
      - `/documentation/passkit/requesting-identity-data-from-a-wallet-pass`
        → `requesting-identity-data-from-a-wallet-pass-raw.md`
- Tracker:
  - `apple-passkit-traversal.md` holds:
    - Scope/size.
    - Conventions.
    - A small table of “important” sosumi paths and the local raw/design coverage.

Rule: keep raw mirrors and the traversal tracker in sync whenever Carrie adds a new area.

## Step 1 — Refresh the PassKit Paths List

From repo root (`todo3`):

```bash
cd job-hunting/code-swiftly/swift-interview-guide.docc

curl -s https://sosumi.ai/documentation/passkit \
  | rg "\]\(/documentation/passkit" \
  | sed -E 's#.*\(/documentation(/passkit[^)]*)\).*#\1#' \
  | sort -u \
  > apple-passkit-raw/passkit-paths.txt
```

- Input: rendered markdown from the PassKit index.
- Output: `apple-passkit-raw/passkit-paths.txt` with one `/documentation/passkit…` path per line.
- Idempotent: safe to rerun; it rewrites the list in place.

## Step 2 — Map Paths to Filenames

For each line in `passkit-paths.txt`:

- Strip the prefix:

  ```bash
  slug=${path#/documentation/passkit/}
  slug=${slug:-passkit}  # top-level /documentation/passkit
  ```

- Sanitize to a filesystem‑friendly slug:

  ```bash
  slug=${slug//[^a-zA-Z0-9._-]/-}
  outfile="apple-passkit-raw/${slug}-raw.md"
  ```

This keeps filenames stable and predictable so other tools (Carrie, Cody, CLIA) can reference them.

## Step 3 — Download Missing Pages Only

Still from `swift-interview-guide.docc`:

```bash
while read -r path; do
  slug=${path#/documentation/passkit/}
  slug=${slug:-passkit}
  slug=${slug//[^a-zA-Z0-9._-]/-}
  outfile="apple-passkit-raw/${slug}-raw.md"

  if [[ -f "$outfile" ]]; then
    echo "skip (exists): $outfile"
    continue
  fi

  url="https://sosumi.ai${path}"
  echo "fetch: $url -> $outfile"
  curl -s "$url" > "$outfile"
  sleep 0.1  # polite pacing
done < apple-passkit-raw/passkit-paths.txt
```

- Behavior:
  - Skips files that already exist (no churn).
  - Writes new `.md` files for any missing PassKit pages.
- Carrie’s role:
  - When asked to “mirror another PassKit area,” Carrie can run this loop (or a Swift CLI that
    wraps it) and confirm which new files were created.

## Step 4 — Update the Traversal Tracker

After new areas are mirrored:

- Edit `apple-passkit-traversal.md`:
  - Add rows for new **topic / collection** pages that deserve design coverage:
    - Example rows:
      - `/documentation/passkit/apple-pay`
      - `/documentation/passkit/setting-up-apple-pay`
      - `/documentation/passkit/implementing-wallet-extensions`
  - Point `notes` at:
    - The raw file path (`apple-passkit-raw/<slug>-raw.md`).
    - Any design/overview pages once they exist.
- Leave low‑level symbol pages (individual properties, etc.) tracked implicitly via the raw
  directory; no need to list all 1.3k in the table.

This keeps the table readable while still giving a high‑level map of Carrie's coverage.

## Step 5 — Layer Design Guides on Top

Once raw mirrors exist for a cluster of docs:

- Add or update focused design pages, for example:
  - `apple-passkit-common-api-practices.md` — cross‑cutting patterns.
  - `apple-wallet-passkit-wallet-apis.md` — Wallet‑specific types and flows.
  - `apple-wallet-requesting-identity-data-design.md` +
    `apple-wallet-iso18013-data-processing.md` — Verify with Wallet end‑to‑end.
- Link them into:
  - `apple-interview-guide.md` under **Patterns and references**.
  - `apple-passkit-traversal.md` `notes` column.

Carrie’s documentation skill is not just “download everything,” but “download → index → design
summary for the parts that matter.”

## Guardrails

- Do not hammer `sosumi.ai`:
  - Keep the small `sleep` between requests.
  - Prefer incremental runs over full re‑fetches.
- Keep mirrors word‑for‑word:
  - Raw files are for reference; do not edit them manually.
  - Any commentary or normalization happens in separate `*-design.md` or
    `*-common-api-practices.md` files.
- Respect repo policies:
  - No new Makefiles.
  - Prefer small, reviewable diffs when adding new raw mirrors or traversal entries.

## How Carrie Presents This Skill

When asked about PassKit documentation, Carrie can:

- Point to:
  - The raw mirrors in `apple-passkit-raw/`.
  - The traversal tracker for coverage.
  - The design pages for synthesis.
- Offer:
  - To mirror additional sosumi paths.
  - To extract and summarize common API patterns from any new area (payments, Wallet passes,
    identity, issuer provisioning).

This becomes a repeatable “doc ingestion” skill that keeps Apple Wallet and PassKit prep grounded in
real, versioned documentation.
