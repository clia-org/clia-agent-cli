# CLIA DocC Bundles (local to CLIA)

This folder hosts CLIA-specific DocC bundles for local previews.

- clia-requests-spec.docc — CLIA Active/Proposed requests (spec)
  - Preview:

    ```bash
    xcrun docc preview \
      docc/clia-requests-spec.docc \
      --fallback-display-name "CLIA Requests Spec" \
      --fallback-bundle-identifier "com.example.clia.requests.spec" \
      --fallback-bundle-version "1.0.0" \
      --port 8082
    ```

- specs.docc — CLIA Spec Kit command documentation
  - Preview:

    ```bash
    xcrun docc preview \
      docc/specs.docc \
      --fallback-display-name "CLIA Spec Kit" \
      --fallback-bundle-identifier "com.example.clia.specs" \
      --fallback-bundle-version "1.0.0" \
      --port 8083
    ```

Notes

- Archived CLIA items live under each project’s `archive/` directory.
- For external archives, point to your organization’s shared requests bundle; none is required for this package.
