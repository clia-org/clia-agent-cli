# CommonProcess CommandSpec Adoption and CI Stabilization

@Metadata {
  @PageColor(orange)
  @PageImage(purpose: icon, source: "memory-icon-tooling-specs", alt: "icon tooling specs icon")
}

## Summary

- Completed CommandInvocation → CommandSpec rename across CommonProcess and
  downstream shells; removed legacy mentions in docs/diagrams.
- Stabilized CI on ubuntu‑latest using the Swift 6.1 container; removed
  setup‑swift incompatibility with Ubuntu 24.04; avoided macOS runners.
- Fixed Linux build by adding swift‑system (SystemPackage) and import guards.
- Cleaned swift‑format warnings (no force unwraps; comment style); trimmed
  README; added “Why more than Subprocess” and light emoji.
- DocC guidance: write static export to `.clia/tmp/docc/<bundle>` and ignore
  `_site/` in source control.

## Why it Matters

- “Specs, not strings”: CommandSpec makes process runs explicit, reviewable,
  and testable; the rename cements the surface.
- CI determinism: containerized Swift toolchain avoids runner drift and cost.
- Portability: swift‑system import guards keep Linux builds reliable.
- Hygiene: smaller READMEs, fewer foot‑guns; DocC outputs stay out of the repo.

## Links

- CI container PR: common‑process/ci/container‑swift
- Linux fix PR: common‑process/fix/linux‑system‑dep
- README tidy PR: common‑process/docs/readme‑quickstart
- Journal: <doc:Journal 2025-10-28>
