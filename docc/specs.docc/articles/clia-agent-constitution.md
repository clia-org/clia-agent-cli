# Clia Agent Constitution

Version: 0.4.0  
Ratified: 2026-01-04  
Last amended: 2026-01-04

## Purpose

Define the non-negotiable principles for CLIA tooling and documentation in this
repository. These rules apply to all CLIA-facing code, specs, and DocC content.

## Principles

- Only Swift. Production logic, generators, and automation must be implemented
  in Swift. Avoid Python and long shell scripts.
- Runnable everywhere. Prefer SwiftPM and cross-platform APIs so CLIA tools run
  on macOS and Linux without special casing.
- CommonShell only. Do not use `Foundation.Process` directly; use
  CommonProcess/CommonShell adapters.
- DocC-first. Durable documentation for Swift packages lives in DocC bundles,
  with README kept as a quickstart.
- No YAML. Use JSON for front matter or structured metadata.
- No Makefiles. Prefer npm scripts or Swift CLIs for repeatable tasks.
- Swift Testing only. New or migrated tests use `import Testing`, not XCTest.
- Human-readable defaults. Use explicit, long-form flags and descriptive
  identifiers.

## Governance

- Amendments require a semver bump:
  - Major: breaking policy changes or removals.
  - Minor: new principles or material expansions.
  - Patch: clarifications or wording fixes.
- Update `Last amended` on every change.
- Keep dependent templates in sync with these rules.
