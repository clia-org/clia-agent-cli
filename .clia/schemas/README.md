# JSON Schemas

- Draft: 2020-12
- Location: `schemas/cli/`
- Naming: `<slug>.v<major>.schema.json`
- `$id` pattern: `https://local.schemas/cli/<slug>.v<major>.schema.json`

Use these to validate CLI JSON outputs. Tools may also copy a schema next to
runtime artifacts (e.g., `.wrkstrm/tmp/task-heartbeat.schema.json`) for local consumers.
