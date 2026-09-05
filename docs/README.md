# SkyLine — Documentation

This folder gathers the engineering documentation of the **SkyLine** project: the complete history of feature choices and their implementation.

## Getting Started

1. **Read the project overview** in the repository root: [README.md](../README.md).
2. **Browse the design specs** — every change starts with a validated design ([index](superpowers/specs/README.md)).
3. **Browse the implementation plans** — detailed task-by-task steps derived from each spec ([index](superpowers/plans/README.md)).

## Documentation Map

| Section | What it contains | |
|---------|------------------|---|
| [Specs](superpowers/specs/README.md) | Validated design specs (what & why) indexed by feature | |
| [Plans](superpowers/plans/README.md) | Implementation plans (how) indexed by feature | |

## Repository Structure

```
docs/
├── README.md                        # This overview
└── superpowers/
    ├── README.md                    # Workflow & conventions
    ├── specs/                       # Design specs + index
    │   ├── README.md
    │   └── YYYY-MM-DD-<topic>-design.md
    └── plans/                       # Implementation plans + index
        ├── README.md
        └── YYYY-MM-DD-<topic>.md
```

## Style Guide

- All documentation is in **English**.
- Specs answer **what** and **why**; plans answer **how**.
- Titles: `# <Title> — Design Spec` / `# <Title> — Implementation Plan`.
- Index tables group documents by feature: `weather_forecast`, `location`, `settings`, `core`.