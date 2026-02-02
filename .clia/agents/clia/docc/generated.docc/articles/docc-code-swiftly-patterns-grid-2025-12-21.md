# Code-swiftly Pattern Hub and Per-pattern Pages

@Metadata {
  @PageColor(blue)
  @PageImage(purpose: icon, source: "memory-icon-docc-style-kit", alt: "DocC visual style icon")
}

## Problem

- The Top 15 patterns page bundled every explanation into one long document, making it harder to
  browse, link, and scan during drills.
- Pattern cards needed distinct icons and palettes so the grid feels navigable at a glance.

## Solution

- Split the Top 15 patterns into 15 dedicated pages with consistent Problem/Solution/Example
  structure.
- Rebuilt the hub as a categorized grid (linear, sorting/intervals, search, pointer mechanics,
  stacks/heaps, graph, backtracking/DP) so each card links to its pattern page.
- Designed a new per-pattern SVG icon set with unique palettes and a shared dot-cluster motif to
  keep the system coherent.

## Verify

```bash
xcrun docc preview \
  /Users/rismay/todo3/job-hunting/code-swiftly/swift-interview-guide.docc \
  --fallback-display-name "Swift Interview Guide" \
  --fallback-bundle-identifier "me.rismay.swift-interview-guide" \
  --fallback-bundle-version "1.0.0" \
  --port 8098
```

- Expected: `top-15-patterns` renders as a categorized grid and each pattern card links to its
  dedicated page with a unique icon.

## Owner Date

- Owner: carrie
- Date: 2025-12-21
