# DocC Design System Examples

@Metadata {
  @PageImage(purpose: icon, source: "docc-docc-design-system-examples-icon", alt: "Icon")
  @PageImage(purpose: card, source: "docc-docc-design-system-examples-card", alt: "Card")
}

@Image(source: "docc-docc-design-system-examples-hero", alt: "Hero")

Examples of good DocC

## UI Examples

- <doc:docc-ui-light-dark-examples>

## Example: Technology Root

```md
# Documentation

@Metadata {
  @TechnologyRoot
  @PageColor(blue)
  @PageImage(purpose: card, source: "hero-expertise-banner", alt: "Hero banner")
}

Summary paragraph.

@Image(source: "hero-expertise-banner", alt: "Hero banner")

## Topics

### Start here

- <doc:docc-design-system>
```

## Example: Hub Hero + Call to Action

```md
# Request system

@Metadata {
  @TechnologyRoot
  @PageColor(blue)
  @TitleHeading("Requests: file-based Kanban + DocC")
  @PageImage(purpose: icon, source: "icon-request-system", alt: "Requests icon")
  @PageImage(purpose: card, source: "hero-request-system", alt: "Requests hero banner")
  @CallToAction(url: "/documentation/clia-request-system/directory-layout", label: "Start here")
}

@Options {
  @TopicsVisualStyle(detailedGrid)
  @AutomaticSeeAlso(disabled)
}

Summary paragraph.

@Image(source: "hero-request-system", alt: "Requests hero banner")
```

## Example: Options and Layout

```md
@Options {
  @TopicsVisualStyle(detailedGrid)
}

@Row {
  @Column {
    @Image(source: "icon-docc-style-kit", alt: "DocC style")
    DocC style guide
  }
}
```

## Example: Categorized Hub Grid

```md
## Topics

### Linear

- <doc:pattern-prefix-sum>
- <doc:pattern-two-pointers>

### Graph

- <doc:pattern-bfs>
- <doc:pattern-dfs>
```

## Example: Tutorial Skeleton

```swift
@Tutorial(time: 20) {
  @Intro(title: "Example tutorial") {
    Summarize the outcome in one or two sentences.
  }

  @Section(title: "First concept") {
    @ContentAndMedia {
      Explain what you will build or demonstrate in this section.
    }
    @Steps {
      @Step {
        Describe the first concrete action.
      }
    }
  }
}
```

## Example: Link Syntax

- Symbol link example (only for real symbols): `MyModule/MyType/myFunc(_:)`
- Doc link: `<doc:docc-design-system>`
