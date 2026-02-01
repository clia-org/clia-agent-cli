# Code-swiftly DocC Warnings Cleanup

@Metadata {
  @PageColor(blue)
  @PageImage(purpose: icon, source: "memory-icon-warning", alt: "icon warning icon")
}

## Problem

- DocC conversion for code-swiftly emitted warnings about invalid metadata directives, unsupported
  tutorial structure, summary links, and missing resources.
- Warnings surfaced in the DocC build output for the code-swiftly catalog.

Observed warnings (examples):

```text
warning: Cannot convert '.purple' to type 'Color'
PageColor expects an argument for an unnamed parameter that's convertible to 'Color'

warning: 'Assessments' directive is unsupported as a child of the 'Section' directive
These directives are allowed: 'Comment', 'ContentAndMedia', 'Redirected', 'Stack', 'Steps'

warning: Unknown argument '' in Justification. These arguments are currently unused but allowed: 'reaction'.

warning: Link in document summary will not be displayed
Summary should only contain (formatted) text.

warning: Resource 'pattern_01_prefix_sum.png' couldn't be found
```

## Solution

- Normalize `@PageColor` arguments to bare allowed color names and remap unsupported teal to blue
  for DocC validation.
  - `/Users/rismay/todo3/job-hunting/code-swiftly/swift-interview-guide.docc/Swift-Interview-Guide.md`
  - `/Users/rismay/todo3/job-hunting/code-swiftly/swift-interview-guide.docc/concurrency-beginners-guide.md`
  - `/Users/rismay/todo3/job-hunting/code-swiftly/swift-interview-guide.docc/concurrency-dispatch-design.md`
  - `/Users/rismay/todo3/job-hunting/code-swiftly/swift-interview-guide.docc/swift-data-processing-pipelines-in-mono.md`
  - `/Users/rismay/todo3/job-hunting/code-swiftly/swift-interview-guide.docc/behavioral-and-day-of.md`
  - `/Users/rismay/todo3/job-hunting/code-swiftly/swift-interview-guide.docc/apple-wallet-interview-guide.md`
  - `/Users/rismay/todo3/job-hunting/code-swiftly/swift-interview-guide.docc/coding-interview.md`
  - `/Users/rismay/todo3/job-hunting/code-swiftly/swift-interview-guide.docc/general-guide.md`
  - `/Users/rismay/todo3/job-hunting/code-swiftly/swift-interview-guide.docc/system-design.md`
- Move `@Assessments` blocks to the tutorial top level (not nested under `@Section`) in:
  - `/Users/rismay/todo3/job-hunting/code-swiftly/swift-interview-guide.docc/Tutorials/concurrency-quiz.tutorial`
- Use `@Justification(reaction: "...")` to avoid "unknown argument" warnings in:
  - `/Users/rismay/todo3/job-hunting/code-swiftly/swift-interview-guide.docc/Tutorials/concurrency-quiz.tutorial`
  - `/Users/rismay/todo3/job-hunting/code-swiftly/swift-interview-guide.docc/Tutorials/wallet-add-pass-to-wallet.tutorial`
  - `/Users/rismay/todo3/job-hunting/code-swiftly/swift-interview-guide.docc/Tutorials/wallet-shareable-passes.tutorial`
  - `/Users/rismay/todo3/job-hunting/code-swiftly/swift-interview-guide.docc/Tutorials/wallet-verify-with-wallet-identity.tutorial`
- Remove missing pattern image references from:
  - `/Users/rismay/todo3/job-hunting/code-swiftly/swift-interview-guide.docc/top-15-patterns.md`
- Move DocC summary links out of the summary region in:
  - `/Users/rismay/todo3/job-hunting/code-swiftly/swift-interview-guide.docc/data-structures-reference.md`

## Verify

```bash
xcrun docc convert \
  /Users/rismay/todo3/job-hunting/code-swiftly/swift-interview-guide.docc \
  --output-path /Users/rismay/todo3/.wrkstrm/tmp/docc/code-swiftly
```

- Expected: DocC conversion completes without warnings.

## Owner Date

- Owner: carrie
- Date: 2025-12-21
