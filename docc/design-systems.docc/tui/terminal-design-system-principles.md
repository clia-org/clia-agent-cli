# DocC Design System Principles

@Metadata {
  @PageImage(purpose: icon, source: "tui-terminal-design-system-principles-icon", alt: "Icon")
  @PageImage(purpose: card, source: "tui-terminal-design-system-principles-card", alt: "Card")
}

@Image(source: "tui-terminal-design-system-principles-hero", alt: "Hero")

## Principles

- **Clarity first** - default to explicit, multi-line layouts; never hide context behind terse flags
  or cryptic abbreviations.
- **Delight with purpose** - use emoji sparingly to establish hierarchy, highlight success (✅), warn
  (⚠️), or guide the eye without overwhelming the log stream.
- **Actionable output** - every path printed should be absolute so it becomes a clickable link in
  modern terminals (iTerm, VS Code, Xcode, etc.).
- **Copy/paste safe** - pre-emptively delimit long commands with fenced blocks or shell prompts so
  users can copy and run without trimming ellipses.
- **Explicit choices** - when multiple questions are asked, number them and include clear answer
  choices with an `other` option to keep replies concise and safe.
