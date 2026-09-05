# Superpowers — Project Documentation

This directory contains the full engineering history of **SkyLine**: every feature was designed and validated **before** being implemented, and implemented **plan-first**.

## Workflow

```
Feature idea
    ↓
1. Design Spec   docs/superpowers/specs/   — what & why (problem, approach, architecture, errors, tests)
    ↓
2. Implementation Plan   docs/superpowers/plans/   — how & when (task-by-task TDD steps)
    ↓
3. Implementation        lib/ + test/       — driven by the plan, one task at a time
```

- A **spec** is written first, reviewed, and only then turned into a **plan**.
- A **plan** is executed by an agentic worker using the subagent-driven-development or executing-plans workflow.
- The current status of a change is tracked in the `Status` metadata of each doc.

## Contents

| Section | Purpose |
|---------|---------|
| [Specs](specs/README.md) | Validated design documents, indexed by feature |
| [Plans](plans/README.md) | Implementation plans, indexed by feature |

## Conventions

- All documentation is written in **English**.
- File naming: `YYYY-MM-DD-<topic>.md` for plans, `YYYY-MM-DD-<topic>-design.md` for specs.
- Every document carries a normalized metadata block: `Date`, `Feature` (or `Goal`), and `Status`.
- Titles follow the format `# <Title> — Design Spec` / `# <Title> — Implementation Plan`.

See the repository root [README](../../README.md) for the project overview.