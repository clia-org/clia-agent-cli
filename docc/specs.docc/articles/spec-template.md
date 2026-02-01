# Spec Template

Use this template for each CLIA command specification. Save with a kebab-case
filename under `specs.docc/articles/`.

## Template

```markdown
# Feature specification: <command>

**Created**: <YYYY-MM-DD>  
**Status**: Draft  
**Input**: <user prompt or command scope>

## User scenarios & testing

### User story 1 - <title> (Priority: P1)

<Plain-language user journey>

**Why this priority**: <value statement>

**Independent test**: <how to validate in isolation>

**Acceptance scenarios**:

1. **Given** <state>, **When** <action>, **Then** <outcome>
2. **Given** <state>, **When** <action>, **Then** <outcome>

### Edge cases

- What happens when <boundary condition>?
- How does the system handle <error case>?

## Requirements

### Functional requirements

- **FR-001**: System MUST <capability>
- **FR-002**: System MUST <capability>
- **FR-003**: Users MUST be able to <interaction>

## Success criteria

### Measurable outcomes

- **SC-001**: <metric>
- **SC-002**: <metric>
```
