# Contributing to SkyLine

Thanks for your interest in **SkyLine**, a clean and professional mobile weather app for iOS and Android built with Flutter.

Please read the [README](README.md) first for a project overview, and keep in mind this repository follows strict engineering conventions: Clean Architecture, feature-driven layout, test-driven development, and a **zero-warning analysis policy**.

## Table of Contents

- [Development Environment](#development-environment)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Code Conventions](#code-conventions)
- [Testing](#testing)
- [Documentation](#documentation)
- [Continuous Integration](#continuous-integration)
- [Commit Conventions](#commit-conventions)
- [Pull Request Process](#pull-request-process)

## Development Environment

| Requirement | Version |
| ----------- | ------- |
| Flutter     | `>= 3.35.0` |
| Dart        | `^3.9.2` |

The CI pipeline pins Flutter `3.35.0` (stable). Local results are only trustworthy on a matching SDK.

## Getting Started

```bash
# 1. Fetch dependencies
flutter pub get

# 2. Generate ObjectBox code (required after any ObjectBox model change)
dart run build_runner build

# 3. Run the app
flutter run
```

## Development Workflow

Every change must pass, with zero issues:

```bash
# Static analysis — zero warnings and zero infos tolerated
flutter analyze --fatal-infos

# Full test suite
flutter test

# Formatting — the codebase is dart-format conformant
dart format .
```

Run only the tests relevant to your feature while developing:

```bash
flutter test test/path/to/test_file.dart
```

## Code Conventions

A machine-readable engineering contract lives in [AGENTS.md](AGENTS.md). The essentials:

- **Clean Architecture, feature-driven** — `core/` for cross-cutting concerns, `features/<feature>/` split into `data/`, `domain/`, `presentation/`.
- **English only** — code, identifiers, comments, and commit messages are written in English.
- **Immutability** — entities, models, BLoC events, and states extend `Equatable` with explicit `props`; `copyWith` is hand-written. `freezed` is not allowed.
- **Layer isolation** — models never leak into domain/presentation; dedicated static mappers (e.g. `WeatherMapper`) handle conversions.
- **BLoC pattern** — state changes always emit new immutable instances via `emit(state.copyWith(...))`; async work goes through an explicit loading state.
- **Strict error handling** — low-level exceptions are caught in the `data` layer and converted to typed `Failure` objects; presentation consumes them through `BlocListener` with user-facing localized messages. No debug strings in the UI.
- **Stateless UI** — presentation widgets stay stateless and contain no business rules. `BuildContext` never reaches use cases or repositories.

## Testing

Testing is **mandatory**. The project follows TDD with `flutter_test`, `mocktail`, and `bloc_test`:

- Unit tests for entities, models, and mappers
- BLoC tests for every event/state transition (`bloc_test`)
- Widget tests for screens and reusable widgets
- `mocktail` for repositories and data sources

Every feature ships with its tests. The CI suite must stay green.

## Documentation

All documentation is written in **English** and lives in [docs/](docs/README.md):

- Every change starts with a **design spec** (`docs/superpowers/specs/`) answering *what* and *why*.
- Each spec is followed by an **implementation plan** (`docs/superpowers/plans/`) answering *how*.

If your change introduces a new feature or a substantial behavior change, add or update the corresponding spec and plan. See [docs/superpowers/](docs/superpowers/README.md) for the workflow.

## Continuous Integration

A GitHub Actions workflow (`.github/workflows/ci.yml`) runs on every push and pull request targeting `main`:

1. `flutter pub get`
2. `flutter analyze --fatal-infos` (zero warnings, zero infos)
3. `flutter test`

The workflow pins Flutter `3.35.0`. A red CI run blocks the merge.

## Commit Conventions

Commits follow [Conventional Commits](https://www.conventionalcommits.org/), in English:

```
type(scope): short lowercase summary

body if needed
```

Common types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `style`, `perf`.

## Pull Request Process

1. Create a branch from `main` (or a dedicated git worktree) for your change.
2. Format your code and ensure `flutter analyze --fatal-infos` and `flutter test` pass locally.
3. Add (or update) the design spec and implementation plan when your change adds a feature or changes behavior.
4. Open the pull request; the CI pipeline must pass before review.
5. A maintainer will review, request changes if needed, and merge once approved.