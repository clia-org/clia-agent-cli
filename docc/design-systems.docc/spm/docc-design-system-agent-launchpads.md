# Agent Launchpads

@Metadata {
  @PageImage(purpose: icon, source: "spm-docc-design-system-agent-launchpads-icon", alt: "Launchpad icon")
  @PageImage(purpose: card, source: "spm-docc-design-system-agent-launchpads-card", alt: "Launchpad hero")
}

@Image(source: "spm-docc-design-system-agent-launchpads-hero", alt: "Launchpad hero")

From throwaway scripts to verifiable software artifacts.

## Overview

The **Launchpad** pattern defines how agents and developers evolve logic within the repository. It mandates a transition from "throwaway" scripts (e.g., Python or standalone Swift files) into permanent, testable Swift libraries.

## The Lifecycle: Scratchpad to Core

Logic follows a strict promotion path to ensure maintainability and technical enforcement of design standards.

### 1. The Scratchpad (Exploration)
- **Location:** `.clia/agents/[agent]/spm/launchpad/scratchpad/`
- **Purpose:** Rapid prototyping of a new command or logic.
- **Form:** An executable target in the scratchpad package.
- **Rule:** Use the scratchpad to prove the value of a tool before committing to its architecture.
- **Retention:** Do not delete scratchpad code; accumulate experiments to surface common patterns.
- **Modes:** Cloud pads live in the repo scratchpad for hosted agents; local pads may start on a
  developer machine but should be ported into the repo scratchpad once useful.

### 2. The Library (Promotion)
- **Location:** `.clia/agents/[agent]/spm/launchpad/core/`
- **Purpose:** Hosting "Compiled Logic" that enforces standards.
- **Form:** A named library target (e.g., `DoccAuditNavigationLib`).
- **Rule:** If logic is valuable enough to persist, it MUST be extracted into a library.

### 3. The Test Suite (Enforcement)
- **Location:** `.clia/agents/[agent]/spm/launchpad/core/tests/`
- **Purpose:** Verifying the logic against edge cases and design regressions.
- **Rule:** No library is promoted to core without a corresponding Swift Testing suite.

## Why We Avoid Throwaway Scripts

| Attribute | Throwaway Scripts (Python/Bash) | SPM Launchpads (Swift Libraries) |
| :--- | :--- | :--- |
| **Verification** | Manual / Brittle | Automated / Compiled |
| **Reusability** | Copy-Paste | Module Import |
| **Discovery** | Hidden in `scripts/` | First-class in `launchpad/core` |
| **Typing** | Dynamic / Runtime errors | Static / Compile-time safety |

## Best Practices

- **Avoid Generic Scripts:** Instead of a `clean-docs.py`, build a `DoccCleanupLib` and a small CLI wrapper.
- **Path Dependencies:** Use relative path dependencies in `Package.swift` to link scratchpad tools to core libraries during development.
- **Module Safety:** Use `UpperCamelCase` for library targets to ensure they are valid Swift module names.
- **Test-First Evolution:** Use tests to capture the specific design system rules (like kebab-case or triple visual standards) so they are technically enforced.

## Example: DoccAuditNavigationLib

The `audit-navigation` tool evolved through this pattern:
1.  **Started** as a standalone Swift file in the Castor scratchpad.
2.  **Identified** the need for permanent enforcement of "Hierarchical Integrity."
3.  **Extracted** to `DoccAuditNavigationLib` in the core directory.
4.  **Tested** with a full suite capturing "Double Curation" and "Orphans."
