# DocC Interview Drills Playbook

@Metadata {
  @PageColor(blue)
  @PageImage(purpose: icon, source: "expertise-docc-interview-drills-2025-12-16-icon", alt: "expertise-docc-interview-drills-2025-12-16 icon")
  @PageImage(purpose: card, source: "expertise-docc-interview-drills-2025-12-16-card", alt: "expertise-docc-interview-drills-2025-12-16 card")
}

This note captures the practical lessons learned while evolving
`job-hunting/code-swiftly/swift-interview-guide.docc` into an interview-grade DocC catalog.
@Image(source: "expertise-docc-interview-drills-2025-12-16-hero", alt: "DocC interview drills playbook hero")


## 1) Tutorial Code That Highlights Correctly

For DocC tutorials (`*.tutorial`), prefer `@Code` over inline `CodeListing` for anything non-trivial.

- Put Swift snippets in the catalog’s `resources/` directory as real `.swift` files.
- Reference them from steps using `@Code(name:file:)`.

Example:

```swift
@Step {
  Introduce a helper that wraps `PKPassLibrary`.
  @Code(
    name: "WalletPassManager.swift",
    file: "wallet-add-pass-wallet-pass-manager.swift"
  )
}
```

Notes:

- `file:` points to the snippet file inside the DocC catalog `resources/` folder.
- `name:` is the “file the reader edits” label in the UI; include `.swift` so the pane reads like
  Apple’s own tutorials and stays unambiguous.

## 2) Recall Drills: Show the Answer Without Diff Noise

If you are creating a “write it from memory” drill, you usually want each step to be a clean
reference implementation, not a diff from the previous step. Use `reset: true`.

Example pattern used for the Top‑15 patterns recall drill:

```swift
@Step {
  Write the prefix sum template from memory, then compare.
  @Code(
    name: "Patterns.swift",
    file: "pattern-prefix-sum.swift",
    reset: true
  )
}
```

## 3) Assessments: Important Structural Constraint

In our current DocC toolchain (Xcode DocC), `@Assessments` is **not** a supported child of
`@Section`. It must live at the `@Tutorial` level.

If you want “questions at the bottom of each screen”:

- Prefer a **series**: create multiple `@Tutorial` files (one per screen), each with its own
  `@Assessments` at the end.
- Then add the series to navigation via `Tutorials.tutorial` using `@TutorialReference`.

This keeps validation clean and matches DocC’s supported directive tree.

## 4) Running `Docc Preview` Reliably (macOS)

DocC preview can fail on large catalogs due to low per-shell open-file limits:

- Symptom: “Watching the source bundle failed because it contains N files… more than your shell
  session limit… Verify your current session limit by running `ulimit -n`”.
- Fix: raise the limit for the shell running DocC preview.

Working command (example):

```bash
ulimit -n 4096
xcrun docc preview job-hunting/code-swiftly/swift-interview-guide.docc \
  --port 8082 \
  --output-path .clia/tmp/docc/swift-interview-guide \
  --fallback-display-name "Swift Interview Guide" \
  --fallback-bundle-identifier "com.example.swift-interview-guide" \
  --fallback-bundle-version "1.0.0"
```

Quick health checks:

- `lsof -iTCP:8082 -sTCP:LISTEN`
- `curl -i http://localhost:8082/documentation/swift-interview-guide`

## 5) Avoiding 404 Confusion (DocC URL Mental Model)

DocC serves:

- Articles under `http://localhost:<port>/documentation/<catalog-id>/<article-id>`
- Tutorials under `http://localhost:<port>/tutorials/<catalog-id>/<tutorial-id>`

If you see a 404, trust the “Starting Local Preview Server” banner first; it prints the canonical
root URLs for that catalog.

## 6) Diagrams and Images: Keep Them DocC-friendly

- Prefer `resources/*.svg` with embedded CSS variables and `prefers-color-scheme` for
  dark/light-friendly diagrams.
- Reference the SVG from an article with a normal Markdown image:
  `\\!\\[Alt\\]\\(diagram.svg\\)`

When you need a diagram source format (Mermaid, etc.), keep it as a source artifact, but commit
the rendered SVG for DocC consumption.
