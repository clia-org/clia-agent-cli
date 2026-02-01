# DocC Package Usage Map

@Metadata {
  @PageImage(purpose: icon, source: "docc-docc-design-system-docc-packages-usage-map-icon", alt: "Icon")
  @PageImage(purpose: card, source: "docc-docc-design-system-docc-packages-usage-map-card", alt: "Card")
}
@Image(source: "docc-docc-design-system-docc-packages-usage-map-hero", alt: "Hero")


This page maps DocC-related features to their source packages so ownership stays explicit.
Use it when wiring new tooling or splitting the DocC stack into separate books.

## CodeSwiftly App (DocC UI)

The app is filesystem-first. It indexes bundles directly and uses DocC output only as an
optional mapping layer.

- Browses filesystem bundles and files via `DocC.BundleScanner` and `DocC.BundleFile`.
- Resolves optional preview URLs via `DocC.NavigationState` and a cached archive index.
- Renders Mermaid previews locally for `.mmd` files (via `DocC.MermaidRenderer` + `npm exec`).

## DocC Preview CLI

The CLI hosts rendered output and provides asset tooling; it does not render DocC itself.

- Serves rendered output via `WrkstrmDocCPreviewCore.DocCPreviewService`.
- Generates Mermaid SVGs and DocC assets with CommonCLI/CommonShell tooling.

## WrkstrmDocCPreviewCore

This package is a lightweight server for already-rendered DocC output.

- Only serves existing DocC output; it does not render DocC and does not import SwiftDocC.

## SwiftDocC SwiftPM DocC Plugin

The renderer and its build orchestrator live outside the app UI surface.

- Renderer and build orchestration used outside the app (via SwiftPM or CLI).
- Provides canonical DocC data models and archive formats consumed by preview tooling.

## Feature-to-package Map

Use DocC Markdown tables, not raw HTML. Keep column content as plain text.

| Feature | SPM package(s) | Notes |
| --- | --- | --- |
| DocC bundle browsing + file tree | CodeSwiftly app (shared code) | Filesystem-first via DocC.BundleScanner and DocC.BundleFile. |
| DocC preview URL mapping | CodeSwiftly app (shared code) | Best-effort mapping; falls back to raw content. |
| DocC preview server (serve rendered output) | WrkstrmDocCPreviewCore | Used by docc-wrkstrm-cli and optional app preview flows. |
| DocC rendering orchestration | DoccRenderHost + swift-docc-plugin | SwiftPM plugin drives generate-documentation. |
| Markdown rendering | MarkdownUI, Ink, swift-markdown | Multiple renderers for comparison and fallback. |
| Swift parsing + syntax highlighting | swift-syntax | Uses SwiftParser and SwiftSyntax for parsing and highlighting. |
| UI components | CodeSwiftlyAppKit, WrkstrmKit | Shared UI primitives and platform helpers. |
| Networking + logging | CodeSwiftlyAppLib, WrkstrmFoundation, CommonLog | Core app services and diagnostics. |
| Mermaid SVG rendering | CommonShell, CommonCLI | Runs npm exec for .mmd previews. |
