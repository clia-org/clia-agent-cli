# DocC Renderer Pipeline (2025-12-21)

@Metadata {
  @PageColor(blue)
  @PageImage(purpose: icon, source: "memory-icon-docc-style-kit", alt: "DocC visual style icon")
}

Vendored Swift-DocC-Render into docc-palette, injected the Carrie palette CSS, fixed the
preview navigator index aliasing, and renamed the technology root file for a cleaner URL.

## Problem

- Preview root reported: "Carrie - Expertise: There was an error fetching the data."
- Browser error: `Failed to load resource: /index/documentation/index.json (404)`.
- Palette CSS was not applied, leaving an overly blue and heavy background.

## Solution

- Vendor Swift-DocC-Render under `code/spm/tools/docc-palette/Sources/docc-palette/Resources/docc-render`.
- Set `DOCC_HTML_DIR` via docc-palette so preview uses the vendored renderer by default.
- Inject `/css/carrie.docc.css` into `index.html` and `index-template.html` for default theming.
- Mirror `/index/index.json` to `/index/documentation/index.json` and `/index/<module>/index.json`
  during preview so navigation loads.
- Rename the root article to `carrie-expertise.md` so the URL is
  `/documentation/carrie-expertise` instead of `/documentation/documentation`.
- Soften the Carrie palette to a neutral base and regenerate the DocC CSS/JSON tokens.

## Verify

```bash
code/spm/tools/docc-palette/.build/release/docc-palette docc preview \
  .clia/agents/carrie/docc/expertise.docc \
  --allow-arbitrary-catalog-directories \
  --fallback-display-name "Carrie Expertise" \
  --fallback-bundle-identifier "me.rismay.clia.carrie.expertise" \
  --fallback-bundle-version "1.0.0" \
  --port 8097
```

- Open: `http://localhost:8097/documentation/carrie-expertise`
- Check: `http://localhost:8097/index/documentation/index.json` returns 200.
- Check: `http://localhost:8097/css/carrie.docc.css` returns CSS.
