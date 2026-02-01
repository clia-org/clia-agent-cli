# DocC Design System Preview

@Metadata {
  @PageImage(purpose: icon, source: "docc-docc-design-system-preview-icon", alt: "Icon")
  @PageImage(purpose: card, source: "docc-docc-design-system-preview-card", alt: "Card")
}
@Image(source: "docc-docc-design-system-preview-hero", alt: "Hero")


Preview and quality gates for DocC bundles.

## Tooling and Preview

- Document preview commands and any required renderer configuration.
- Call out custom CSS or renderer overrides explicitly.
- Record known warnings with a plan to resolve or justify them.
- When using a custom renderer, set `DOCC_HTML_DIR` so DocC uses the vendored assets.
- If you customize CSS, inject it into `index.html` and `index-template.html`.
- Use `index.md` as the root article and avoid `Documentation.md` so the URL does not collapse to
  `/documentation/documentation`.
- Ensure preview indexes resolve, including `/index/documentation/index.json`.
- Use `docc-wrkstrm palette-editor` to adjust DocC theme tokens and export CSS/JSON.
- Keep palette editor outputs in `resources/` or `.clia/tmp/` and wire them via theme settings.
- If preview fails with file limit warnings, raise the shell limit with `ulimit -n` before running.
- Use the preview banner to confirm root URLs; articles live under `/documentation/` and tutorials
  live under `/tutorials/`.
- Prefer CodeSwiftly for DocC preview and routing instead of running `docc preview` or raw local
  servers; deep-link bundles/articles into CodeSwiftly so the preview spins up automatically.

## Quality Gates

- Verify DocC builds without warnings where possible.
- Ensure links resolve and Topics render in the intended order.
- Keep README pointers aligned to DocC entry points.
