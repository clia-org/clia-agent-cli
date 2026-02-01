# Tau Secrets Migration

@Metadata {
  @PageColor(green)
  @PageImage(purpose: icon, source: "expertise-tau-secrets-migration-2025-10-03-icon", alt: "expertise-tau-secrets-migration-2025-10-03 icon")
  @PageImage(purpose: card, source: "expertise-tau-secrets-migration-2025-10-03-card", alt: "expertise-tau-secrets-migration-2025-10-03 card")
}

This note documents the fixes applied after migrating Tau to the
`WrkstrmSecrets` stack. It captures the problem, the minimal code changes,
and how to verify the build locally.
@Image(source: "expertise-tau-secrets-migration-2025-10-03-hero", alt: "Tau secrets migration hero")


## Problem Space

After introducing `WrkstrmSecrets` and the TauKit bridge, the following
issues blocked Tau builds:

- Debug views in the status app referenced legacy types (`SecureData`,
  `TypedMetadata`) behind `#if canImport(WrkstrmSecrets)`, which excluded the
  `WrkstrmKeychain` import that actually defines those legacy types.
- `TauKit` secret models (`NotionSecret`, `SchwabCredentialsSecret`) had
  internal initializers, preventing callers from constructing canonical
  values during migrations and debug flows.
- The build system warned that `TauKit` was missing an explicit dependency on
  `WrkstrmSecretsAppleBackend` discovered during dependency scanning.
- Deployment targets must remain at 26.0 for Catalyst to enable API
  availability (e.g., `UISplitViewController.show(.inspector)`).

## Changes

- Status app (debug): always import `WrkstrmKeychain` for legacy types.
  - File: external/tau/mac-status-app/Debug/KeychainDebugView.swift:1
  - Also corrected optional handling when reading raw secret bytes.
    - File: external/tau/mac-status-app/Debug/KeychainDebugView.swift:387
- TauKit models: make initializers `public`.
  - File: external/TauKit/Sources/TauKit/SecretsCoders.swift:36
  - File: external/TauKit/Sources/TauKit/SecretsCoders.swift:69
- TauKit target deps: wire `WrkstrmSecretsAppleBackend` explicitly to silence
  dependency‑scan warnings.
  - File: external/TauKit/Package.swift:8
- Deployment targets: keep 26.0 for iOS/macOS/tvOS/watchOS/xrOS in Tau
  project to satisfy Catalyst API availability.
  - File: external/tau/tau-group.xcodeproj/project.pbxproj:896

## Verification

Build (Mac Catalyst):

```
xcodebuild \
  -project external/tau/tau-group.xcodeproj \
  -scheme tau-cross \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64,variant=Mac Catalyst' \
  build
```

Expected: build succeeds; embedded login item (`tau-mac-status-app`) compiles
and signs. If failures occur, surface the first error lines for triage.

## Rationale

- WrkstrmSecrets is the typed canonical store; legacy views still need access
  to transitional data structures during migration. Importing
  `WrkstrmKeychain` unblocks debug paths without affecting the canonical read
  and write flows.
- Public initializers on canonical models enable scheduled migrations, debug
  tooling, and UI scaffolds to construct values deterministically.
- Explicit backend dependency removes ambiguity in builds and aligns with the
  repository’s type‑safety and explainability goals.

## Future Work

- Remove legacy `SecureData`/`TypedMetadata` usages once canonical secrets are
  fully backfilled, and move remaining debug panels to the new bridge API.
- Add Swift Testing coverage for secrets preflight and migration receipts in
  the TauKit package.
