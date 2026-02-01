# SVG Stroke Styles

@Metadata {
  @PageImage(purpose: icon, source: "svg-svg-stroke-styles-icon", alt: "Icon")
  @PageImage(purpose: card, source: "svg-svg-stroke-styles-card", alt: "Card")
}

@Image(source: "svg-svg-stroke-styles-hero", alt: "Hero")


Use these stroke styles as the shared vocabulary for lines, connectors, and outlines in SVGs.
The goal is to keep diagrams legible while supporting different visual moods without rewriting
each asset.

@Image(source: "svg-stroke-styles-examples", alt: "SVG stroke examples")

@Links(visualStyle: list) {
  - <doc:simple-vector-graphics>
  - <doc:docc-design-system-assets>
  - <doc:svg-color-wash-variants>
  - <doc:svg-line-endings>
}

## Core Styles

- Solid: default stroke for structure and flow. Rounded caps and joins.
- Hairline: low-emphasis separators or grid hints. Keep opacity low.
- Dashed: secondary emphasis or “optional” flows.
- Dotted: annotations or rhythm guides.
- Dash-dot: mixed emphasis for layered systems or phased states.
- Double-line: outlines or containers that need extra weight without increasing fill density.
- Marker: bold, confident strokes for highlights or callouts.
- Brush: expressive strokes for conceptual or exploratory diagrams.
- Pencil: sketch-style strokes for early-stage or exploratory work.

## Examples

The examples above show one line per style so you can compare weights, caps, and dash patterns.

## Core Style Examples

### Solid

@Image(source: "svg-stroke-solid-static", alt: "Solid stroke static")
@Image(source: "svg-stroke-solid-animated", alt: "Solid stroke animated")

### Hairline

@Image(source: "svg-stroke-hairline-static", alt: "Hairline stroke static")
@Image(source: "svg-stroke-hairline-animated", alt: "Hairline stroke animated")

### Dashed

@Image(source: "svg-stroke-dashed-static", alt: "Dashed stroke static")
@Image(source: "svg-stroke-dashed-animated", alt: "Dashed stroke animated")

### Dotted

@Image(source: "svg-stroke-dotted-static", alt: "Dotted stroke static")
@Image(source: "svg-stroke-dotted-animated", alt: "Dotted stroke animated")

### Dash-dot

@Image(source: "svg-stroke-dash-dot-static", alt: "Dash-dot stroke static")
@Image(source: "svg-stroke-dash-dot-animated", alt: "Dash-dot stroke animated")

### Double-line

@Image(source: "svg-stroke-double-static", alt: "Double-line stroke static")
@Image(source: "svg-stroke-double-animated", alt: "Double-line stroke animated")

### Marker

@Image(source: "svg-stroke-marker-static", alt: "Marker stroke static")
@Image(source: "svg-stroke-marker-animated", alt: "Marker stroke animated")

### Brush

@Image(source: "svg-stroke-brush-static", alt: "Brush stroke static")
@Image(source: "svg-stroke-brush-animated", alt: "Brush stroke animated")

## Border Families

Use these borders to give cards and containers a little personality without sacrificing clarity.

@Image(source: "svg-border-styles-examples", alt: "SVG border examples")

- Soft: rounded corners, single stroke, minimal contrast.
- Double: secondary outline for emphasis without heavy fills.
- Dashed: layered systems or optional groupings.
- Dotted: annotations or secondary groupings.
- Offset: subtle shadow line offset for depth.
- Sketch: multi-pass stroke for hand-drawn warmth.
- Scalloped: playful edge rhythm for friendly sections.
- Notched: clipped corners to suggest technical or mechanical systems.
- Ribbon: layered banner-like frame for emphasis.
- Inset glow: soft inner line for focus without a heavy border.

## Pencil Strokes

Pencil strokes are built from 2 to 3 parallel paths with slight offsets and low opacity. Avoid
filters or masks so the SVG stays DocC-friendly.

### Pencil Strokes: Static

@Image(source: "svg-pencil-basic-example", alt: "Basic pencil stroke example")

### Pencil Strokes: Animated

@Image(source: "svg-pencil-hello-animate", alt: "Pencil stroke animation writing hello")

## Suggested Tokens (CSS)

```css
.stroke-solid {
  stroke-width: 3.5;
  stroke-linecap: round;
  stroke-linejoin: round;
}

.stroke-hairline {
  stroke-width: 1.5;
  stroke-opacity: 0.45;
  stroke-linecap: round;
  stroke-linejoin: round;
}

.stroke-dashed {
  stroke-width: 3;
  stroke-dasharray: 10 8;
  stroke-linecap: round;
}

.stroke-dotted {
  stroke-width: 3;
  stroke-dasharray: 2 10;
  stroke-linecap: round;
}

.stroke-dash-dot {
  stroke-width: 3;
  stroke-dasharray: 10 8 3 8;
  stroke-linecap: round;
}

.stroke-double {
  stroke-width: 5;
  stroke-linecap: round;
  stroke-linejoin: round;
}

.stroke-marker {
  stroke-width: 6;
  stroke-linecap: round;
  stroke-linejoin: round;
}

.stroke-brush {
  stroke-width: 4;
  stroke-linecap: round;
  stroke-linejoin: round;
  stroke-opacity: 0.8;
}

.stroke-pencil {
  stroke-width: 3;
  stroke-linecap: round;
  stroke-linejoin: round;
  stroke-opacity: 0.6;
}
```

## Usage Notes

- Keep a consistent stroke style per diagram family.
- Prefer rounded caps for readability at small sizes.
- Avoid filters and masks unless a specific asset requires them.
