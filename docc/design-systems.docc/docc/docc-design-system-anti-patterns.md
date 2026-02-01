# DocC Design System Anti-patterns

@Metadata {
  @PageImage(purpose: icon, source: "docc-docc-design-system-anti-patterns-icon", alt: "Icon")
  @PageImage(purpose: card, source: "docc-docc-design-system-anti-patterns-card", alt: "Card")
}

@Image(source: "docc-docc-design-system-anti-patterns-hero", alt: "Hero")

What to avoid

## Anti-pattern: Missing Technology Root

Avoid:

- A catalog with no `@TechnologyRoot` entry page.

Preferred:

- A root article with `@Metadata { @TechnologyRoot }` and a clear Topics list.

## Anti-pattern: Invalid Metadata Arguments

Avoid:

- `@PageColor(.purple)` or other dot-prefixed colors.
- `@PageImage` without a `purpose: icon|card` argument.

Preferred:

- Use `@PageColor(purple)` with bare color names.
- Always include `purpose: icon` or `purpose: card` for `@PageImage`.

### Warning Text

```text
warning: Cannot convert '.purple' to type 'Color'
PageColor expects an argument for an unnamed parameter that's convertible to 'Color'
```

Fix: use `@PageColor(purple)` with a bare color name.

## Anti-pattern: Summary with Links

Avoid:

- Links in the summary paragraph.

Preferred:

- Keep the summary text-only and move links into sections or lists.

### Warning Text

```text
warning: Link in document summary will not be displayed
Summary should only contain (formatted) text.
```

Fix: move links out of the summary paragraph.

## Anti-pattern: Tutorial Directives in the Wrong Scope

Avoid:

- `@Assessments` inside a `@Section` block.

Preferred:

- Keep `@Assessments` at the tutorial top level.

### Warning Text

```text
warning: 'Assessments' directive is unsupported as a child of the 'Section' directive
These directives are allowed: 'Comment', 'ContentAndMedia', 'Redirected', 'Stack', 'Steps'
```

Fix: move `@Assessments` to the tutorial top level, not inside `@Section`.

## Anti-pattern: Invalid Directive Arguments

Avoid:

- `@Justification("")` or missing argument labels.

Preferred:

- Use `@Justification(reaction: "...")`.

### Warning Text

```text
warning: Unknown argument '' in Justification. These arguments are currently unused but allowed: 'reaction'.
```

Fix: use `@Justification(reaction: "...")` with the label.

## Anti-pattern: Mixing Tutorial Links in `@Links`

Avoid:

- Placing tutorial identifiers inside `@Links` lists.

Preferred:

- Keep `@Links` for DocC pages and list tutorials separately.

## Anti-pattern: Missing Assets

Avoid:

- References to images or snippets that do not exist in `resources/`.

Preferred:

- Add assets with matching names and keep references in sync.

### Warning Text

```text
warning: Resource 'pattern_01_prefix_sum.png' couldn't be found
```

Fix: add the missing asset or remove the reference.

## Anti-pattern: Large Inline Code Listings

Avoid:

- Inline `CodeListing` blocks for multi-step or non-trivial code.

Preferred:

- Use `@Code(name:file:)` with snippets stored in `resources/`.

## Anti-pattern: `@Code` in Articles

Avoid:

- Using `@Code` inside `*.md` articles to include snippets or Mermaid sources.

Preferred:

- Use fenced code blocks in articles and reserve `@Code` for tutorials only.
- If you want one source of truth, use a generator to inject snippet content into the article
  before preview/build.

## Anti-pattern: Single Long Hub Page

Avoid:

- One oversized page that mixes many patterns or topics without split pages.

Preferred:

- Split into dedicated pages and present them in a categorized hub grid.

## Anti-pattern: Tabs That Hide Required Steps

Avoid:

- Using `@TabNavigator` for sequential instructions where the reader must see every section.

Preferred:

- Use headings (`##`) and short, copy-pastable code blocks so the page reads top-to-bottom.
- Reserve tabs for parallel comparisons (for example, light vs dark screenshots).
