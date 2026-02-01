# Terminal Design System Anti-patterns

@Metadata {
  @PageImage(purpose: icon, source: "tui-terminal-design-system-anti-patterns-icon", alt: "Icon")
  @PageImage(purpose: card, source: "tui-terminal-design-system-anti-patterns-card", alt: "Card")
}

@Image(source: "tui-terminal-design-system-anti-patterns-hero", alt: "Hero")

What to avoid

## Anti-pattern: Dense Walls of Text

Avoid:

```
This command failed because the requested file could not be found or opened and the fallback
was also missing which could mean the path is wrong or the permissions are wrong or the file was
renamed and the only way to fix this is to check the logs and re-run the command with the right
flags and possibly try again.
```

Why it fails:

- Too long to scan quickly.
- No next step.
- No concrete path.

Preferred:

```
Error: missing file
Path: /Users/example/workspace/.clia/tmp/report.json
Next: check the file path or re-run the generator
```

## Anti-pattern: Unreadable Commands

Avoid:

```
swift package --package-path /Users/example/workspace/code/spm/tools/foundry generate-documentation --target FoundryCoreDocumentation --output-path .docc-build
```

Why it fails:

- Hard to copy or edit.
- Flags are not scannable.

Preferred:

```
swift package --package-path /Users/example/workspace/code/spm/tools/foundry \
  generate-documentation \
  --target FoundryCoreDocumentation \
  --output-path .docc-build
```

## Anti-pattern: Vague Status

Avoid:

```
Done.
```

Why it fails:

- No context or next step.
- Outcome is not verifiable.

Preferred:

```
Status: completed
Output: /Users/example/workspace/.clia/tmp/report.md
Next: open the report and review warnings
```
