# SVG Color Wash Variants

@Metadata {
  @PageImage(purpose: icon, source: "svg-svg-color-wash-variants-icon", alt: "Icon")
  @PageImage(purpose: card, source: "svg-svg-color-wash-variants-card", alt: "Card")
}

@Image(source: "svg-svg-color-wash-variants-hero", alt: "Hero")


Color wash techniques for sketch-style SVGs. Each variant includes an image preview and the full
SVG source for reuse.

@Links(visualStyle: list) {
  - <doc:simple-vector-graphics>
  - <doc:svg-sketch-style>
}

## Bleed Wash

@Image(source: "svg-sketch-style-bleed-wash", alt: "Bleed wash animation")

```xml
<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="360" viewBox="0 0 1200 360">
  <title>Sketch color wash: bleed</title>
  <style>
    .wash { fill: #f25f5c; fill-opacity: 0.22; }
  </style>

  <rect width="1200" height="360" fill="#f9fafb"/>

  <path class="wash" d="M180 200 C320 80, 620 80, 880 190 C860 260, 560 280, 180 200 Z" fill-opacity="0">
    <animate attributeName="fill-opacity" values="0;0.22;0" dur="6s" begin="0s" repeatCount="indefinite"/>
  </path>
  <path class="wash" d="M200 210 C340 100, 640 100, 900 200 C870 270, 560 290, 200 210 Z" fill-opacity="0">
    <animate attributeName="fill-opacity" values="0;0.18;0" dur="6s" begin="6s" repeatCount="indefinite"/>
  </path>
</svg>
```

## Gradient Wash (Static)

@Image(source: "svg-sketch-style-gradient-wash-static", alt: "Gradient wash static")

```xml
<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="360" viewBox="0 0 1200 360">
  <title>Sketch color wash: gradient static</title>
  <defs>
    <linearGradient id="wash" x1="0" x2="1" y1="0" y2="1">
      <stop offset="0%" stop-color="#ffe066" stop-opacity="0.35"/>
      <stop offset="100%" stop-color="#247ba0" stop-opacity="0.25"/>
    </linearGradient>
  </defs>

  <rect width="1200" height="360" fill="#f9fafb"/>
  <path fill="url(#wash)" d="M160 190 C320 80, 620 80, 880 190 C860 260, 560 280, 160 190 Z"/>
</svg>
```

## Gradient Wash (Animated)

@Image(source: "svg-sketch-style-gradient-wash-animated", alt: "Gradient wash animated")

```xml
<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="360" viewBox="0 0 1200 360">
  <title>Sketch color wash: gradient animated</title>
  <defs>
    <linearGradient id="wash" x1="0" x2="1" y1="0" y2="1">
      <stop offset="0%" stop-color="#ffe066" stop-opacity="0.35"/>
      <stop offset="100%" stop-color="#247ba0" stop-opacity="0.25"/>
    </linearGradient>
  </defs>

  <rect width="1200" height="360" fill="#f9fafb"/>
  <path fill="url(#wash)" d="M160 190 C320 80, 620 80, 880 190 C860 260, 560 280, 160 190 Z" fill-opacity="0">
    <animate attributeName="fill-opacity" values="0;1;0" dur="8s" begin="0s" repeatCount="indefinite"/>
  </path>
</svg>
```

## Layered Wash (Static)

@Image(source: "svg-sketch-style-layered-wash-static", alt: "Layered wash static")

```xml
<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="360" viewBox="0 0 1200 360">
  <title>Sketch color wash: layered static</title>
  <style>
    .yellow { fill: #ffe066; fill-opacity: 0.35; }
    .blue { fill: #247ba0; fill-opacity: 0.25; }
    .red { fill: #f25f5c; fill-opacity: 0.28; }
  </style>

  <rect width="1200" height="360" fill="#f9fafb"/>
  <path class="yellow" d="M140 190 C300 90, 620 80, 840 180 C820 260, 520 270, 140 190 Z"/>
  <path class="blue" d="M200 175 C340 120, 640 110, 900 180 C860 240, 560 250, 200 175 Z"/>
  <path class="red" d="M320 120 C460 90, 700 110, 980 180 C940 220, 660 220, 320 120 Z"/>
</svg>
```

## Layered Wash (Voice Wave)

@Image(source: "svg-sketch-style-layered-wash-voice-wave", alt: "Layered wash voice wave animation")

```xml
<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="360" viewBox="0 0 1200 360">
  <title>Sketch color wash: layered voice wave</title>
  <style>
    .yellow { fill: #ffe066; fill-opacity: 0.35; }
    .blue { fill: #247ba0; fill-opacity: 0.25; }
    .red { fill: #f25f5c; fill-opacity: 0.28; }
  </style>

  <rect width="1200" height="360" fill="#f9fafb"/>

  <g>
    <path class="yellow" d="M140 190 C300 90, 620 80, 840 180 C820 260, 520 270, 140 190 Z"/>
    <animateTransform attributeName="transform" type="scale"
                      values="1 1; 1 0.92; 1 1.04; 1 0.95; 1 1"
                      dur="6s" repeatCount="indefinite"/>
  </g>
  <g>
    <path class="blue" d="M200 175 C340 120, 640 110, 900 180 C860 240, 560 250, 200 175 Z"/>
    <animateTransform attributeName="transform" type="scale"
                      values="1 1; 1 1.05; 1 0.9; 1 1.02; 1 1"
                      dur="6s" begin="0.4s" repeatCount="indefinite"/>
  </g>
  <g>
    <path class="red" d="M320 120 C460 90, 700 110, 980 180 C940 220, 660 220, 320 120 Z"/>
    <animateTransform attributeName="transform" type="scale"
                      values="1 1; 1 0.96; 1 1.06; 1 0.93; 1 1"
                      dur="6s" begin="0.8s" repeatCount="indefinite"/>
  </g>
</svg>
```

## Edge Spill (Animated)

@Image(source: "svg-sketch-style-edge-spill", alt: "Edge spill animation")

```xml
<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="360" viewBox="0 0 1200 360">
  <title>Sketch color wash: edge spill</title>
  <style>
    .wash { fill: #247ba0; fill-opacity: 0.25; }
  </style>

  <rect width="1200" height="360" fill="#f9fafb"/>

  <defs>
    <clipPath id="spill">
      <rect x="0" y="0" width="0" height="360">
        <animate attributeName="width" values="0;1200;0" dur="12s" begin="0s" repeatCount="indefinite"/>
      </rect>
    </clipPath>
  </defs>

  <g clip-path="url(#spill)">
    <path class="wash" d="M120 200 C300 70, 620 70, 900 190 C880 280, 560 300, 120 200 Z" fill-opacity="0">
      <animate attributeName="fill-opacity" values="0;0.25;0" dur="6s" begin="0s" repeatCount="indefinite"/>
    </path>
    <path class="wash" d="M100 220 C280 90, 640 90, 920 210 C900 300, 560 320, 100 220 Z" fill-opacity="0">
      <animate attributeName="fill-opacity" values="0;0.2;0" dur="6s" begin="6s" repeatCount="indefinite"/>
    </path>
  </g>
</svg>
```

## Edge Spill (Angled)

@Image(source: "svg-sketch-style-edge-spill-angled", alt: "Edge spill animation with angled fill")

```xml
<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="360" viewBox="0 0 1200 360">
  <title>Sketch color wash: edge spill (angled)</title>
  <style>
    .wash { fill: #247ba0; fill-opacity: 0.25; }
  </style>

  <rect width="1200" height="360" fill="#f9fafb"/>

  <defs>
    <clipPath id="spill-angled-1">
      <rect x="-80" y="0" width="0" height="360" transform="skewX(-12)">
        <animate attributeName="width" values="0;1400;1400;0"
                 keyTimes="0;0.43;0.85;1" dur="14s" repeatCount="indefinite"/>
      </rect>
    </clipPath>
    <clipPath id="spill-angled-2">
      <rect x="-80" y="0" width="0" height="360" transform="skewX(-12)">
        <animate attributeName="width" values="0;0;1400;1400;0"
                 keyTimes="0;0.5;0.93;0.95;1" dur="14s" repeatCount="indefinite"/>
      </rect>
    </clipPath>
  </defs>

  <g clip-path="url(#spill-angled-1)">
    <path class="wash" d="M120 200 C300 70, 620 70, 900 190 C880 280, 560 300, 120 200 Z" fill-opacity="0.25"/>
  </g>
  <g clip-path="url(#spill-angled-2)">
    <path class="wash" d="M100 220 C280 90, 640 90, 920 210 C900 300, 560 320, 100 220 Z" fill-opacity="0.2"/>
  </g>
</svg>
```

## Edge Spill (Angled, with Line)

@Image(source: "svg-sketch-style-edge-spill-angled-with-line", alt: "Edge spill with line drawing first")

```xml
<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="360" viewBox="0 0 1200 360">
  <title>Sketch color wash: edge spill (angled) with line</title>
  <style>
    .wash { fill: #247ba0; fill-opacity: 0.25; }
    .ink { stroke: #1f2328; stroke-width: 3; stroke-linecap: round; stroke-linejoin: round; fill: none; }
  </style>

  <rect width="1200" height="360" fill="#f9fafb"/>

  <path class="ink" d="M160 190 C330 95, 660 95, 860 190 C830 250, 520 260, 160 190 Z"
        pathLength="100" stroke-dasharray="100 100" stroke-dashoffset="100">
    <animate id="lineDraw" attributeName="stroke-dashoffset" values="100;0" dur="3s"
             begin="0s" fill="freeze"/>
  </path>

  <defs>
    <clipPath id="spill-angled-1">
      <rect x="-80" y="0" width="0" height="360" transform="skewX(-12)">
        <animate attributeName="width" values="0;1400;1400;0"
                 keyTimes="0;0.42;0.92;1" dur="12s" begin="lineDraw.end+0.2s" repeatCount="indefinite"/>
      </rect>
    </clipPath>
    <clipPath id="spill-angled-2">
      <rect x="-80" y="0" width="0" height="360" transform="skewX(-12)">
        <animate attributeName="width" values="0;0;1400;1400;0"
                 keyTimes="0;0.48;0.95;0.98;1" dur="12s" begin="lineDraw.end+0.2s" repeatCount="indefinite"/>
      </rect>
    </clipPath>
  </defs>

  <g clip-path="url(#spill-angled-1)">
    <path class="wash" d="M120 200 C300 70, 620 70, 900 190 C880 280, 560 300, 120 200 Z" fill-opacity="0.25"/>
  </g>
  <g clip-path="url(#spill-angled-2)">
    <path class="wash" d="M100 220 C280 90, 640 90, 920 210 C900 300, 560 320, 100 220 Z" fill-opacity="0.2"/>
  </g>
</svg>
```
