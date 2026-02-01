# Incident Resolution: Usage

@Metadata {
  @PageImage(purpose: icon, source: "incidents-incident-resolution-usage-icon", alt: "incidents-incident-resolution-usage icon")
  @PageImage(purpose: card, source: "incidents-incident-resolution-usage-card", alt: "incidents-incident-resolution-usage card")
}


@Image(source: "incidents-incident-resolution-usage-hero", alt: "Incident resolution: Usage hero")

## Build

```bash
swift build --package-path . -c release
```

## Create a Report (Markdown)

```bash
.build/release/clia \
  core incidents new \
  --title "Database pool saturation" \
  --owner patch \
  --severity S1 \
  --service database
```

## Activate An Incident (Banner JSON)

```bash
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

### Notes

- `--blocked-tool` adds a `blockedTools` array; repeatable.
- `--link` accepts `title=url` or a bare `url`; repeatable. Links are stored as
  objects `{ "title": ..., "url": ... }` (title optional).
- JSON is formatted for humans. Normalize with `swift-cli-kit json format`.

### Downstream Usage

- `Incident.bannerText` renders a standard header line, e.g.
  `[INCIDENT — S1 — Database pool saturation]`.
- `clia-agent` and `codex-agent-cli` use `bannerText` in headers.
