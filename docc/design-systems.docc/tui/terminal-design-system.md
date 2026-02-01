# Terminal Design System 🎨🖥️

@Metadata {
  @PageImage(purpose: icon, source: "tui-terminal-design-system-icon", alt: "Icon")
  @PageImage(purpose: card, source: "tui-terminal-design-system-card", alt: "Card")
}
@Image(source: "tui-terminal-design-system-hero", alt: "Hero")


The terminal is one of our primary user interfaces, so we treat it like a product surface.
This design system captures the rules for readable, resilient, and expressive terminal output
across Foundry, CLIA, and every Swift CLI we ship.

Agents must read this guide before responding via TUI.

Use it like you stole it - every log line is a UI moment.

This system emphasizes clear success, progress, and error patterns so operators can act fast.

@Options {
  @TopicsVisualStyle(detailedGrid)
  @AutomaticSeeAlso(disabled)
}

## Swift

- Prefer Swift over Python for CLI and automation; keep new tools in SwiftPM launchpads per agent.
- Use SwiftPM + ArgumentParser + CommonShell/CommonProcess (no Foundation.Process); one subcommand per task.
- Target macOS 15+/Linux; document minimums and cross-compile notes.
- Logging/telemetry via CommonLog; outputs should stay TUI-aligned.
- Tests: Swift Testing (`import Testing`), deterministic fixtures; avoid XCTest.
- Dependency hygiene: favor in-repo packages; pin only when required; release builds under `.build/.../release`.

## Python

- Avoid new Python for automation; favor Swift replacements.
- Leave historical Python intact but do not expand it; plan migrations to Swift when feasible.
- There is no need for quick REPL behavior now that AI can code.
- If forced to use Python, log the rationale and set a Swift replacement plan; no new Python deps/virtualenv scaffolding.
- Migration playbook: identify legacy scripts, replace with Swift CLI, deprecate old entrypoints.

## Topics

### Guidance

- <doc:terminal-design-system-principles>
- <doc:terminal-design-system-patterns>
- <doc:terminal-design-system-git>
- <doc:terminal-design-system-emoji-palette>
- <doc:terminal-design-system-examples>
- <doc:terminal-design-system-anti-patterns>
- <doc:terminal-design-system-checklists>
