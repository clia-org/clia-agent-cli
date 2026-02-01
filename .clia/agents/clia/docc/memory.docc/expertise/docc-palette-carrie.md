# DocC Palette - Carrie

@Metadata {
  @PageColor(blue)
  @PageImage(purpose: icon, source: "memory-icon-docc-style-kit", alt: "DocC visual style icon")
}

Generated CSS and JSON tokens for Carrie’s standardized DocC palette.

## CSS (DocC Profile)

```css
:root{
  /* Headings */
  --docc-heading-color: #E7EBF4;
  /* Links */
  --docc-link-color: #3D7CFF;
  --docc-link-hover-color: #B58CFF;
  /* Code */
  --docc-code-bg: #1E2533;
  --docc-inline-code-bg: #171C26;
  --docc-code-fg: #E7EBF4;
  --docc-code-border: #3E475C;
  /* Callouts */
  --docc-callout-note-bg: #171C26;
  --docc-callout-note-border: #3E475C;
  --docc-callout-tip-bg: #171C26;
  --docc-callout-tip-border: #3D7CFF;
  --docc-callout-important-bg: #171C26;
  --docc-callout-important-border: #B58CFF;
}
@media (prefers-color-scheme:light){:root{
  --docc-heading-color: #0C1016;
  --docc-link-color: #2F6BFF;
  --docc-link-hover-color: #9B7BFF;
  --docc-code-bg: #EEF2F7;
  --docc-inline-code-bg: #FFFFFF;
  --docc-code-fg: #0C1016;
  --docc-code-border: #D3DAE6;
  --docc-callout-note-bg: #FFFFFF;
  --docc-callout-note-border: #D3DAE6;
  --docc-callout-tip-bg: #FFFFFF;
  --docc-callout-tip-border: #2F6BFF;
  --docc-callout-important-bg: #FFFFFF;
  --docc-callout-important-border: #9B7BFF;
}}
/* Headings */
main h1, main h2, main h3, .topic-title { color: var(--docc-heading-color); }

/* Links */
main a { color: var(--docc-link-color); }
main a:hover { color: var(--docc-link-hover-color); }

/* Code blocks */
pre, pre code { background: var(--docc-code-bg); color: var(--docc-code-fg); border-color: var(--docc-code-border); }
code:not(pre code) { background: var(--docc-inline-code-bg); color: var(--docc-code-fg); }

/* Callouts */
aside.note { background: var(--docc-callout-note-bg); border-left: 3px solid var(--docc-callout-note-border); }
aside.tip { background: var(--docc-callout-tip-bg); border-left: 3px solid var(--docc-callout-tip-border); }
aside.important { background: var(--docc-callout-important-bg); border-left: 3px solid var(--docc-callout-important-border); }
```

## JSON Tokens

```json
{
  "palette": "carrie",
  "dark": {
    "bg": "#0F1218",
    "surface": "#171C26",
    "surfaceAlt": "#1E2533",
    "text": "#E7EBF4",
    "textSecondary": "#A7B1C6",
    "stroke": "#3E475C",
    "accent1": "#3D7CFF",
    "accent2": "#B58CFF",
    "grid": "rgba(61,124,255,.12)"
  },
  "light": {
    "bg": "#F6F7FA",
    "surface": "#FFFFFF",
    "surfaceAlt": "#EEF2F7",
    "text": "#0C1016",
    "textSecondary": "#4A5568",
    "stroke": "#D3DAE6",
    "accent1": "#2F6BFF",
    "accent2": "#9B7BFF",
    "grid": "rgba(47,107,255,.12)"
  }
}
```

## Usage Notes

- Apply the CSS through DocC theming (for example, `theme-settings.json` or a host pipeline).
- Use the JSON tokens to drive SVG diagrams or external theme tooling.

## Theme Settings (Catalog Wiring)

- Theme settings live at `.clia/agents/carrie/docc/expertise.docc/theme-settings.json`.
- The CSS file lives at `.clia/agents/carrie/docc/expertise.docc/Resources/memory-carrie.docc.css`.
- DocC preview reads `theme-settings.json` and maps values to CSS custom properties; static hosting
  still needs a CSS link injection or custom renderer to apply selector mappings.

## Renderer Pipeline (Docc-palette)

- `docc-palette` vendors Swift-DocC-Render at
  `code/spm/tools/docc-palette/Sources/docc-palette/Resources/docc-render`.
- `docc-palette docc convert` and `docc-palette docc preview` set `DOCC_HTML_DIR` to the vendored
  renderer unless you override it.
- The renderer includes `/css/carrie.docc.css` and links it in `index.html`, so previews apply the
  Carrie palette by default.
- Refresh by building `swift-docc-render` (Node 22.17 / npm 10.9) and copying `dist/*` plus
  `LICENSE.txt` and `NOTICE.txt` into the renderer folder.

## Verify

```bash
code/spm/tools/docc-palette/.build/release/docc-palette print \
  --format css \
  --profile docc \
  --palette carrie

code/spm/tools/docc-palette/.build/release/docc-palette print \
  --format json \
  --palette carrie
```
