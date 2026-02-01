# DocC Design System Patterns

@Metadata {
  @PageImage(purpose: icon, source: "tui-terminal-design-system-patterns-icon", alt: "Icon")
  @PageImage(purpose: card, source: "tui-terminal-design-system-patterns-card", alt: "Card")
}

@Image(source: "tui-terminal-design-system-patterns-hero", alt: "Hero")

Common structural patterns

## Agent Reply Posture (Copy/Paste Safe)

When an agent replies in chat, treat the response as terminal UI output:

- Lead with the outcome (what changed / what you found).
- Prefer short, scannable bullets over paragraphs.
- Provide copy/paste-ready commands and full, clickable references.
- When asking multiple questions, number them and include explicit answer choices, always
  including an `other` option so operators can respond quickly.

## Absolute Paths 📁

- Always print repository-relative paths when pointing to files.
- **Clickable expectation:** if you expect the operator to click the reference, print the full
  absolute path from `/` (for example, `/Users/example/workspace/code/spm/tools/foundry/README.md`).
  Relative paths are
  acceptable only when the link is informational and not meant for clicking.
- If a path or URL is longer than ~100 characters, do not inline it inside a sentence. Put it on its
  own line so it remains readable and clickable.
- **Why:** In some terminals/IDEs, `~/...` may not be detected as a clickable link, while
  `/Users/...` reliably Control-clicks.
- When a tool emits a path, wrap it in backticks so terminals render it distinctly and IDEs keep
  them clickable.
- Prefer file references with separate line indicators when pointing at a specific location (do not
  append `:line` directly to the path if it breaks clickability in your terminal). For example:
  - `sources/core/clia-agent-tool/Clia.swift` (line 74)

## Command Formatting 🧾

- Use fenced blocks for multi-line commands:

  ```bash
  swift package --package-path /Users/example/workspace/code/spm/tools/foundry \
    generate-documentation --target FoundryCoreDocumentation \
    --output-path .docc-build
  ```

- Prefer explicit flags over shorthand; align continuations for readability.
- For single-line commands embedded in sentences, wrap them with backticks.
- If a runnable command line is longer than ~100 characters, do not print it as a single long line.
  Wrap it with `\` continuations and prefer one flag per line so it stays copy/paste-safe.
- **Never use ellipses in commands** (no `...`, no “trimmed for brevity”). If a command is long,
  wrap it and keep it complete.
- Prefer “one flag per line” for any command longer than ~100 characters.

## Link Posture 🔗

- When referencing URLs, print the full URL so terminals with link detection allow one-click
  navigation.
- Don’t output shortened or partial URLs (for example, `example.com`); print the full URL string.
- Don’t output placeholders like `<URL>` or “link goes here” in final answers.
- If a link is longer than ~100 characters, put the URL/path on its own line (avoid embedding it
  mid-sentence).
- When the operator asks for “the link”, output only the path/URL on its own line (no emoji prefix,
  no surrounding prose).
- For internal references, keep the path clickable by printing the path alone, then add line
  information separately when needed. Use absolute paths whenever you need the operator to click.
  For example:
  - `/Users/example/workspace/code/spm/tools/foundry/README.md`
  - `line 42`

## Rio-friendly Terminal Links

- For TUI output that must be clickable in Rio, emit OSC 8 links instead of raw paths.
- Use `swift-terminal-link-rewriter osc8` to convert `path:line:col` tokens into `vscode://` or
  `file://` links.
- Required behavior: CLI output that expects clicks must either emit OSC 8 links directly or be
  piped through `swift-terminal-link-rewriter osc8`.

Usage:

```bash
swift run --package-path ../tooling/swift-terminal-link-rewriter \
  swift-terminal-link-rewriter osc8 vscode < build.log
```

Example (OSC 8 link):

```
]8;;vscode://file//Users/example/workspace/code-swiftly/README.md:12:1\ /Users/example/workspace/code-swiftly/README.md:12:1 ]8;;\
```

## Output Normalization (Canonical Tool)

Use `swift-terminal-link-rewriter` to normalize generated output (logs, transcripts, generated
docs) so file references remain clickable and long links don’t wrap mid-token.

```bash
swift run \
  --package-path ../tooling/swift-terminal-link-rewriter \
  swift-terminal-link-rewriter \
  --glob "**/*.md" \
  --check
```

## Structuring Output 🧱

- Group related sections with blank lines and short headers (for example, `== Build Summary ==`).
- Keep each bullet or log statement under ~100 characters unless quoting source.
- Surface next actions at the end of scripts or commands so operators know what to do immediately.

## Scratchpad Utilities (Continuous Improvement)

- 2026-01-06: Added a Codex scratchpad recipe (`docc-kebab-case-renamer.swift`) to rename DocC
  sources to kebab-case and rewrite `<doc:...>` references. Keep these helpers under
  `/Users/example/.clia/agents/codex/spm/launchpad/scratchpad` so they are discoverable,
  reviewable, and easy to reuse.
