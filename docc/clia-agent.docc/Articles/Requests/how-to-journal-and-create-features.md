# How-To: Journal and Create Features

@Metadata {
  @PageImage(purpose: icon, source: "requests-how-to-journal-and-create-features-icon", alt: "requests-how-to-journal-and-create-features icon")
  @PageImage(purpose: card, source: "requests-how-to-journal-and-create-features-card", alt: "requests-how-to-journal-and-create-features card")
}


This guide helps agents journal progress and create feature requests using CLIA tools and directives.
@Image(source: "requests-how-to-journal-and-create-features-hero", alt: "How-To: Journal and Create Features hero")


## Journaling (Agency Log)

- Directive (chat): `$jrnl` -> JOURNAL
  - Maps to: `clia agency-log`
- CLI example (append a log entry to an agent's Agency JSON):

  ```bash
  # Append a summary (creates the agency file if missing)
  swift run -c release --package-path . \
    clia agency-log \
    --agent codex \
    --summary "Investigated DocC preview integration" \
    --details "Settled on in-process API; spiked pins." \
    --create-if-missing
  ```

- Notes
  - Writes to `<dirTag>.<slug>.agency.triad.json` resolved via lineage.
  - Respects guardrails; refuses during recovery locks/incidents where applicable.

## Daily Notes (Good Morning Day Winddown)

- Rituals support journaling alongside Agency logs:
  - `$wu` -> `clia wind up` (starts heartbeat; ensures today's note)
  - `$wc` -> `clia wind check-in` (prints heartbeat; optional Agency append)
  - `$wd` -> `clia wind down` (winddown; Agency banner)

## Creating Feature Requests

- Directive (chat): `$fr` -> REQUEST-SCAFFOLD
  - Maps to: `docc-requests scaffold`
- Layout (project-centered)
  - `.clia/requests/<project-slug>/request.json` - canonical metadata (schema `request.v1`)
  - `.clia/requests/<project-slug>/README.md` - project overview and links
  - `.clia/requests/<project-slug>/roadmap/<roadmap>.docc/<roadmap>.md`
  - `.clia/requests/<project-slug>/epics/<epic>.docc/<epic>.md`
  - `.clia/requests/<project-slug>/epics/<epic>.docc/features/<feature>.docc/<feature>.md`
  - `.clia/requests/<project-slug>/features/<feature>.docc/<feature>.md`
  - `.clia/requests/<project-slug>/archive/epics/<epic>.docc/<epic>.md`
  - `.clia/requests/<project-slug>/archive/features/<feature>.docc/<feature>.md`
  - `.clia/requests/<project-slug>/archive/roadmap/<roadmap>.docc/<roadmap>.md`
  - DocC roots use `<slug>.md` with `@TechnologyRoot` for clean URLs.
  - Move `completed`/`archived`/`sunset` items into `archive/` to keep active work visible.
  - `.clia/submodule-patch-requests/` is explicitly excluded from feature requests.
- Scaffold a new project request:

  ```bash
  swift build --package-path ../clis/docc-requests-cli -c release
  ../clis/docc-requests-cli/.build/release/docc-requests scaffold \
    --slug code-swiftly-app \
    --title "CodeSwiftly App" \
    --owner alphabeta/code-swiftly \
    --labels code-swiftly app \
    --story-points 3
  ```

- Add an epic and features:

  ```bash
  ../clis/docc-requests-cli/.build/release/docc-requests scaffold-epic \
    --project code-swiftly-app \
    --slug code-swiftly-app-epic \
    --features code-swiftly-onboarding code-swiftly-ui-design

  ../clis/docc-requests-cli/.build/release/docc-requests scaffold-feature \
    --project code-swiftly-app \
    --slug automate-code-swiftly-asset-generation \
    --epic code-swiftly-app-epic
  ```

- Add a project-level feature (no epic):

  ```bash
  ../clis/docc-requests-cli/.build/release/docc-requests scaffold-feature \
    --project code-swiftly-app \
    --slug code-swiftly-quickstart
  ```

- Validate current requests:

  ```bash
  ../clis/docc-requests-cli/.build/release/docc-requests validate --root . --format text
  ```

## Workspace Directives (Examples)

Add entries to `.clia/workspace.clia.json` (schemaVersion `0.4.0`) under `directives`:

```json
{
  "schemaVersion": "0.4.0",
  "directives": {
    "jrnl": {
      "capability": "JOURNAL",
      "cli": "clia agency-log",
      "checklist": [
        {"level":"required","text":"Resolve agent slug lineage; locate agency.triad.json"},
        {"level":"required","text":"Append summary/details with timestamp"},
        {"level":"optional","text":"Create agency file when missing"}
      ]
    },
    "fr": {
      "capability": "REQUEST-SCAFFOLD",
      "cli": "docc-requests scaffold",
      "checklist": [
        {"level":"required","text":"Validate slug (kebab-case)"},
        {"level":"required","text":"Create request.json and README.md"},
        {"level":"optional","text":"Create epic and feature DocC bundles"},
        {"level":"optional","text":"Run docc-requests validate"}
      ]
    }
  }
}
```

## See Also

- Repo: `.clia/requests/README.md` (dual-file model)
