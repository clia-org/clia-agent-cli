# Terminal Design System Examples

@Metadata {
  @PageImage(purpose: icon, source: "tui-terminal-design-system-examples-icon", alt: "Icon")
  @PageImage(purpose: card, source: "tui-terminal-design-system-examples-card", alt: "Card")
}

@Image(source: "tui-terminal-design-system-examples-hero", alt: "Hero")

Examples of good TUI

## Example: Success Summary

```
Status: build complete
Warnings: 2
Next: open /Users/example/workspace/.clia/tmp/build.log
```

Why it works:

- Clear labels and short lines.
- Paths are absolute for easy clicking.
- Next step is explicit and actionable.

## Example: Progress Update

```
Phase: audit
Items scanned: 128
Issues found: 3
Next: open /Users/example/workspace/.clia/reports/audit.md
```

Why it works:

- Short, scannable lines.
- Consistent labels across messages.
- Clear next action and path.

## Example: Error Report

```
Error: missing file
Path: /Users/example/workspace/.clia/tmp/report.json
Next: check the file path or re-run the generator
```

Why it works:

- States the failure in the first line.
- Shows the exact file path.
- Gives a concrete next step.

## Example: Command Guidance

```
Run this command:

swift package --package-path /Users/example/workspace/code/spm/tools/foundry \
  generate-documentation \
  --target FoundryCoreDocumentation \
  --output-path .docc-build
```

Why it works:

- Multi-line command is copy friendly.
- One flag per line and clear break points.
- The command is fully qualified with an absolute path.

## Example: Multi-question Prompt with Choices

```
Quick questions (reply with the letter/number choice):
1) Which scope should I update?
   1a) Docs only
   1b) Docs + README
   1c) Other (please specify)
2) Where should I record the sync policy?
   2a) README.md
   2b) AGENTS.md
   2c) A new doc under docs/
   2d) Other (please specify)
```

Why it works:

- Questions are numbered and choices are explicit.
- The operator can answer tersely (for example: `1b, 2c`).
