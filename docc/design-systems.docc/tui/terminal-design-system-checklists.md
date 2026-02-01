# Terminal Design System Checklists

@Metadata {
  @PageImage(purpose: icon, source: "tui-terminal-design-system-checklists-icon", alt: "Icon")
  @PageImage(purpose: card, source: "tui-terminal-design-system-checklists-card", alt: "Card")
}

@Image(source: "tui-terminal-design-system-checklists-hero", alt: "Hero")

## Readiness Checklists

## Agent Reply Checklist (Chat)

Before you send a response:

1. Include the three-line CLIA conversation header first (mode, identity, incident if active).
2. Use bullets by default; avoid dense paragraphs.
3. When asking multiple questions, number them and include clear answer choices (for example,
   `1a`, `1b`, `2a`), always including an `other` option so the operator can respond succinctly.
4. Prefer emoji checklists over plain bulleted checklists when listing action items.
5. For any file reference the operator should open, include a full absolute path from `/` (or a
   repo-relative path when it’s informational). If you need a line number, print it separately (for
   example: `line 74`) so the path remains clickable.
6. For any URL reference, print the full URL string (no shortening, no placeholders).
7. If a URL/path is longer than ~100 characters, put it on its own line (avoid embedding it inside
   a sentence).
8. When the operator asks for “the link”, output only the path/URL on its own line (no emoji prefix,
   no surrounding prose).
9. For any command longer than ~100 characters, use a fenced `bash` block with `\` continuations
   and keep the command complete (no `...`).
10. Use emoji sparingly and only from the approved palette; at most one emoji per bullet.
11. When pointing to DocC content, prefer CodeSwiftly deep links (bundle + article) over raw
    `docc preview` servers so operators can open the exact page immediately.

## Output Normalization Checklist

When you need to “fix” generated output to match the terminal design system:

1. Run `swift-terminal-link-rewriter` on the generated files (for example, Markdown transcripts).
2. Prefer `--check` in CI; use `--write-to` for mirrored outputs when you want to keep sources
   unchanged.

## Destructive Actions Checklist

1. Create replacement content first (new files, migrated content, updated references).
2. Move files into their new locations.
3. Build the new product.
4. Test the new product.
5. Add tests when possible.
6. Remove legacy files last.

## Implementation Checklist ✅

All terminal-facing tools should:

1. Adopt the emoji palette and path formatting rules above.
2. Print repo-relative paths for anything informational, and use full absolute paths from `/`
   whenever a clickable link is intended.
3. Wrap long commands in fenced blocks or multi-line strings with explicit line breaks.
4. Keep summaries and next steps grouped at the end of each run.
5. Provide a `--quiet` or `--json` mode for automation while keeping human defaults delightful.

## Governance 🛡️

- Product owners review terminal UX as part of feature readiness.
- Engineering design keeps this doc updated when patterns evolve.
- Foundry and CLIA lint new terminal output during audit passes (feature flag in progress).
