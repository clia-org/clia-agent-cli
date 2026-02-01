# Swift Testing

Swift Testing is the preferred and default testing framework for this repository. XCTest is not
used for new tests.

## Why the XCTest runner still appears

`swift test` currently builds and prints the XCTest runner harness even when all tests are written
with Swift Testing. This is expected SwiftPM behavior and does not indicate XCTest tests exist.

Typical output looks like this:

```
Test Suite 'All tests' started...
Test Suite 'All tests' passed...
  Executed 0 tests ...
Test run started.
...
Test run with N tests in M suites passed ...
```

Interpretation:

- The `Test Suite 'All tests'` block is the XCTest harness.
- The `◇ Test run started` block is the Swift Testing run and is authoritative.

## Guardrails

- Do not add `import XCTest` to new tests.
- If XCTest appears in fixtures as a string literal, it must be scoped to auditing or linting
  coverage only.

## Recommended practice

- Treat Swift Testing output as the source of truth.
- When reporting test status, cite the Swift Testing summary line, not the XCTest harness.
