# Holo-Philographics: Concepts & Moods

@Metadata {
  @PageImage(purpose: icon, source: "docc-docc-design-system-philographics-castor-concepts-icon.castor", alt: "Icon")
  @PageImage(purpose: card, source: "docc-docc-design-system-philographics-castor-concepts-card.castor", alt: "Card")
}
@Image(source: "docc-docc-design-system-philographics-castor-concepts-hero.castor", alt: "Hero")


> "Atmospheres, not just tiles." — Castor

@Image(source: "hero-castor-concepts.castor", alt: "Hero: Castor Concepts Spectrum")

This collection expands the Castor Holo-Philographic design system to general documentation concepts. Unlike standard philographics which rely on static geometry, these tiles use **motion, depth, and luminosity** to evoke specific mental states for the reader.

## The Collection

These assets are available in the `resources/` directory with the `castor-take-` prefix.

### Core States

@Row {
  @Column {
    @Image(source: "castor-take-calm.castor", alt: "Calm: The Aurora")
    **Calm**

    *Drifting Tranquility.*
    
    A slow-moving aurora borealis. The gradient shifts gently, inducing a state of flow. Best for onboarding and "getting started" guides.
  }
  @Column {
    @Image(source: "castor-take-focus.castor", alt: "Focus: The Reticle")
    **Focus**

    *Precision Targeting.*
    
    Concentric rings that tighten and breathe. It signals "pay attention" and narrows the context window. Use for deep dives and technical specs.
  }
  @Column {
    @Image(source: "castor-take-clarity.castor", alt: "Clarity: The Prism")
    **Clarity**

    *Internal Structure.*
    
    A crystalline form refracting light. It reveals the internal geometry of a concept. Use for architecture diagrams and definition pages.
  }
}

### Exploration & Growth

@Row {
  @Column {
    @Image(source: "castor-take-curious.castor", alt: "Curious: The Seeker")
    **Curious**

    *Active Search.*
    
    An orbital probe scanning its environment. It represents the act of seeking answers. Use for experiments, research notes, and "try it yourself" sections.
  }
  @Column {
    @Image(source: "castor-take-growth.castor", alt: "Growth: The Ascent")
    **Growth**

    *Rising Momentum.*
    
    Vertical bars rising in sequence. It visualizes progress, scaling, and improvement. Use for roadmaps and migration guides.
  }
  @Column {
    @Image(source: "castor-take-celebrate.castor", alt: "Celebrate: The Spark")
    **Celebrate**

    *Joyful Release.*
    
    A particle system burst. It marks a win, a shipment, or a completed milestone. Use for release notes and "What's New".
  }
}

### System Health

@Row {
  @Column {
    @Image(source: "castor-take-balance.castor", alt: "Balance: The Gyro")
    **Balance**

    *Dynamic Equilibrium.*
    
    A seesaw mechanism in constant adjustment. It acknowledges trade-offs. Use for comparison pages and decision records.
  }
  @Column {
    @Image(source: "castor-take-stability.castor", alt: "Stability: The Monolith")
    **Stability**

    *Unshakable Foundation.*
    
    A heavy, anchored geometric form. It resists entropy. Use for invariants, contracts, and core library documentation.
  }
  @Column {
    @Image(source: "castor-take-danger.castor", alt: "Danger: The Glitch")
    **Danger**

    *Critical Failure.*
    
    A pulsing red core with glitch artifacts. It signals risk and breakage. Use for deprecations, breaking changes, and incident reports.
  }
}

## Implementation Details

All tiles use pure SVG + CSS animations (no JS). They support `prefers-reduced-motion` (via CSS media queries within the SVG) by defaulting to a static, high-fidelity frame.

To use:

```swift
@PageImage(purpose: card, source: "castor-take-calm.castor", alt: "Calm")
```

See also:

- <doc:docc-design-system-philographics-castor-reimagined> (Agent Identities)
