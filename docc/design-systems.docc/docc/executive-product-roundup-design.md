# Executive Product Roundup Design

Design pattern for executive product roundups in DocC. Use this for year
summaries, monthly summaries, and weekly rollups so founders can scan outcomes
quickly while preserving traceable sources.

## Goals

- Give executives a newest-first scan with clear outcomes.
- Keep sources and details lower on the page for fast review.
- Enable reuse across year, month, and week pages.

## Information Hierarchy

1. Executive summary (top of page)
2. Key results, misses, and backlog (year or quarter pages)
3. Monthly summaries (year pages)
4. Weekly timeline (roundup page)
5. Sources and references (bottom)

## Page Types

### Year Page

Recommended sections:

- Executive summary
- Key results
- Misses
- Backlog (next year seed)
- Monthly summaries (each month with embedded weekly synopsis + key events)
- Topics (navigation-only)

### Month Page

Recommended sections:

- Executive summary
- Weekly roundup (each week with synopsis + key events)
- Topics (navigation-only)

### Week Page

Recommended sections:

- Executive summary (1-3 sentences)
- Key events grouped by day (use headings per date)
- Libraries (what changed to enable outcomes)
- Sources
- Details (long-form notes, optional)

## Ordering

- Newest-first for navigation and lists.
- Use ISO week dates with human-readable ranges in headings.
- Keep weeks and months stable; add new entries at the top.

## Base Draft + Cleanup Pass

Treat the CLI output as a base draft. It should dedupe identical events, normalize
whitespace, and avoid duplicate misses/backlog lines. After rendering, run a
manual cleanup pass to tighten summaries and polish language. Document that pass
in this design system so future editors know what is intentional human curation.

Cleanup pass checklist:

- Trim duplicate bullet entries that slipped through source merges.
- Shorten long event summaries into one crisp sentence.
- Ensure “Next steps” callouts are action-oriented and stable.
- Confirm Topics sections only link forward (avoid cycles).

## Templates

Year page (summary-first):

```markdown
# Product 2025

Executive summary for Product 2025 milestones, ordered newest-first.

## 2025 outcomes

### Key results

- Outcome 1
- Outcome 2

### Misses

- Miss 1

### 2026 backlog (seed)

- Backlog item 1

## 2025 monthly summaries

### Product 2025 September

Summary line.

#### Week 38 (Sep 15-Sep 21)

Synopsis line.

##### Key events

- 2025-09-16: Event summary.

##### Week page

- <doc:product-2025-week-38>

## Topics

### Overview

- <doc:product-2025-roundup>
```

Week page (day sections):

```markdown
# Product 2025 Week 38 (Sep 15-Sep 21)

One-paragraph executive summary.

## Key events

### 2025-09-16

- Event summary.

## Libraries

- Library or module impact summary.

## Sources

- `path/to/source.md`
```

## Topics

### Related Patterns

- <doc:docc-design-system-patterns>
