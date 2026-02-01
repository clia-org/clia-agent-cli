# clia-agent

Unified package for CLIA core libraries and the `clia` command-line tool.

Status: 0.1.0-draft (Swift 6.2+)

## Products

- `clia` (executable, target: `CLIAAgentTool`)
- `CLIAAgentCore` — write targets, journaling, mirrors, roster updates
- `CLIACore` — lineage discovery + merged triad views
- `CLIACoreModels` — agent/agenda/agency Codable models and `ExtensionValue`
- `CLIAAgentCoreCLICommands` — shared CLI subcommands
- `CLIAAgentAudit` — audit helpers for triads

Notes:

- note: canonical-triad-schemas-live-at
  `sources/core/clia-agent-core-cli-commands/resources/.clia/schemas/triads/`.
- note: .clia-is-the-symlink-target-for-submodule-installers-and-sub-submodule-installers.
- note: macos-case-insensitive-filesystems-may-require-temp-moves-for-case-only-renames.

## Build

```bash
swift build --package-path . -c release
```

## DocC catalogs

```bash
# Request system
xcrun docc preview \
  .clia/docc/clia-request-system.docc \
  --fallback-display-name "clia-request-system" \
  --fallback-bundle-identifier "com.example.clia.request-system" \
  --fallback-bundle-version "1.0.0" \
  --port 8085
# Open: http://localhost:8085/documentation/clia-request-system

# Design systems (includes SVG animation patterns)
xcrun docc preview \
  docc/design-systems.docc \
  --fallback-display-name "clia-design-systems" \
  --fallback-bundle-identifier "com.example.clia.design-systems" \
  --fallback-bundle-version "1.0.0" \
  --port 8087
# Open: http://localhost:8087/documentation/clia-design-systems
```

Notes:

- Avoid the generic `/documentation/documentation` route by ensuring Tech roots are named with a
  kebab-case slug (for example, `clia-request-system.md`), not `Documentation.md`.

## CLI usage

```bash
# Chat with shell passthrough (JSON output + metadata)
.build/release/clia \
  chat \
  --shell-output json \
  --shell-metadata

# List types (All-Contributors)
.build/release/clia \
  core types-list --format md

# Resolve agents by type/emoji/synonym
.build/release/clia \
  core roster-resolve --query "branding" --json
```

## Shell command execution (chat)

To make `!` commands run and stream output back into chat, use this flow:

1) Build and install the latest `clia` binary:

```bash
swift build --package-path . -c release
swift run --package-path ../tooling/swift-cli-installer \
  swift-cli-installer \
  --package-path . \
  --product clia \
  --configuration release \
  --force-reinstall
```

2) Start chat with shell streaming enabled:

```bash
clia chat --shell-output text
# Optional: structured output + metadata for tooling
clia chat --shell-output json --shell-metadata
# Optional: trace CommonProcess execution
clia chat --shell-trace
```

3) Run shell commands from chat by prefixing with `!`:

```
> !pwd
> !/bin/ls -la
```

Notes:

- Shell execution is streaming-only and uses CommonProcess runners.
- If output stops after `$ /bin/...`, re-run the installer and confirm you are
  using the rebuilt binary. Use `--shell-trace` to inspect CommonProcess
  lifecycle logs.

## Incident resolution (write paths)

Incident write paths live in `CLIAIncidentResolutionCommands`, wired into the
`clia core incidents` group. Read-only status stays in `CLIAIncidentCoreCommands`.

```bash
# Create a report file from the standard template
.build/release/clia \
  core incidents new \
  --title "Database pool saturation" \
  --owner patch \
  --severity S1 \
  --service database

# Activate an incident (write/replace `.clia/incidents/active.json`)
.build/release/clia \
  core incidents activate \
  --id 2025-09-30-db-pool \
  --title "Database pool saturation" \
  --severity S1 \
  --owner patch \
  --summary "DB pool saturated on peak hours" \
  --affected ./** \
  --block .wrkstrm/** \
  --blocked-tool normalize-schema.apply \
  --blocked-tool recovery.restore \
  --link "Runbook=https://example.com/runbooks/db-pool" \
  --link https://status.example.com/incidents/db-pool
```

Notes:

- `--blocked-tool` adds a `blockedTools` array; repeatable.
- `--link` accepts `title=url` or a bare `url`; repeatable.
- Keys are omitted when values are not provided.

## Library quickstart

Add as a local dependency in Package.swift:

```swift
.package(name: "clia-agent", path: "../../universal/clia/clia-agent")
```

Import and use:

```swift
import CLIAAgentCore

// Resolve repo root and agent dir
let target = try WriteTargetResolver.resolve(for: "dot", startingAt: URL(fileURLWithPath: "."))
print(target.agentDir.path)

// Append a journal entry (auto-sign from triad extensions)
let out = try JournalWriter.append(
  slug: "dot",
  workingDirectory: URL(fileURLWithPath: "."),
  highlights: ["DocC index fixed"],
  dirsTouched: ["docc/.wrkstrm", "docs/"]
)
print("journal: \(out.path)")

// Update AGENTS.md roster row
let roster = try RosterUpdater.update(
  startingAt: URL(fileURLWithPath: "."),
  title: "Dot",
  slug: "dot",
  summary: "Docs infra steward; keeps DocC and pipelines healthy."
)
print("roster: \(roster.path)")

// Render mirrors for a single agents root
let written = try MirrorRenderer.mirrorAgents(at: target.agentsRoot)
print(written.map(\.path).joined(separator: "\n"))
```

Merged views (optional):

```swift
import CLIACore
import CLIACoreModels

let merged = Merger.mergeAgent(slug: "dot", under: URL(fileURLWithPath: "."))
print(merged.title)
```

## CLI subcommands (CLIAAgentCoreCLICommands)

Register the standard set in your CLI to get read-only inspection and safe writes:

```swift
import ArgumentParser
import CLIAAgentCoreCLICommands

@main
struct App: ParsableCommand {
  static let configuration: CommandConfiguration = .init(
    commandName: "my-cli",
    abstract: "Agent utilities",
    subcommands: AgentCoreCommands.standard
  )
}
```

Usage examples:

```bash
# Print merged triads (includes root directives via top-level `inherits`)
my-cli profile --slug codex --kind agent --root-chain --json

# Lint lineage/inheritance determinism (read-only)
my-cli lineage-lint --json --strict

# Append an agency entry using lineage write target (submodule-aware)
my-cli agency-log --agent cadence \
  --kind decision \
  --summary "Adopt typed timestamps via cli-kit time now" \
  --participants codex,cadence,example

# Previews (read-only):
my-cli doctor --slug cadence --json
my-cli triads render --kind agenda --slug cadence
my-cli triads aggregate --kind agenda --format md
my-cli mirrors --dry-run
```

### Normalization safety

The `normalize-schema` command is non-destructive by default. It performs only safe shape upgrades
(schemaVersion, notes unwrap/typing, role fallback). If a future run ever detects structural change
risk (e.g., sections/checklists type/content changes) or you pass a non-preserve merge mode, it will:

- Refuse to write unless you acknowledge explicitly with `--i-understand-data-loss`.
- Print a clear DATA LOSS RISK banner describing why it’s blocked.

Recommended: keep `--merge-mode preserve` (default) for normal use. Always run without `--apply`
first to see the planned changes.

## Notes

- All-Contributors mapping file:
  `./sources/core/clia-agent-core-cli-commands/resources/all-contributors-types.v1.json`
  (override by providing `.clia/specs/all-contributors-types.v1.json`).

### Synonyms (common)

```
- projectManagement: pjm, project manager, project-manager
- promotion: branding, media, marketing, PR, outreach, social-media
- maintenance: incident, postmortem, retro, runbook
- infra: incident-response, oncall, ops, SRE, platform-engineering
- doc: docc, readme, docs, documentation
```
