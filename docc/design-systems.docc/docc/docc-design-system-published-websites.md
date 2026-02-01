# Published DocC websites

DocC bundles in this repo are split into **public** (GitHub Pages) and **private** (local host)
destinations. This page documents the canonical hosting paths and workflows.

## GitHub Pages (public)

Public DocC bundles are published to GitHub Pages and live under the top-level GitHub workspace.

todo3:

- Users: `github/users/<user>/public/docc/pages/<user>.github.io/<brand>.docc/index.md`
- Orgs: `github/orgs/<org>/public/docc/pages/<org>.github.io/<brand>.docc/index.md`

mono:

- `code/mono/docc/public/host/github/<bundle>.docc/index.md`

### Workflows

- todo3: per-site GitHub Pages repos under
  `github/users/<user>/public/docc/pages/<user>.github.io/` or
  `github/orgs/<org>/public/docc/pages/<org>.github.io/` each include
  `.github/workflows/publish.yml`
  - example: `github/users/rismay/public/docc/pages/rismay.github.io/.github/workflows/publish.yml`
  - example: `github/orgs/laussat-studio/public/docc/pages/laussat-studio.github.io/.github/workflows/publish.yml`
- mono: `code/mono/.github/workflows/docs.yml`

Only public bundles are published by workflows.

### Tooling notes

- macOS: use `xcrun docc` (DocC ships inside Xcode, not on PATH by default).
- Linux CI: use `docc` from the Swift toolchain (install with `swift-actions/setup-swift`).

## GitHub profile READMEs (public)

Profile READMEs live alongside DocC sites in the GitHub workspace.

todo3:

- Users: `github/users/<user>/public/readmes/public-readme/README.md`
- Orgs: `github/orgs/<org>/public/readmes/public-readme/profile/README.md`

These folders are published directly by GitHub; no DocC build is involved.

## CodeSwiftly local host (private)

Private bundles are rendered by local apps (for example, the `code-swiftly` host) and are **not**
published.

todo3:

- `docc/private/host/local/<bundle>.docc/index.md`

mono:

- `code/mono/docc/private/host/local/<bundle>.docc/index.md`

Keep `index.md` only inside `.docc` bundles. Use `README.md` for non‑bundle folders.
