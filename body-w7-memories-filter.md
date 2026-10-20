## What changed and why

Fixes #22791.

The Memories filter sheet shows All as checked only when the selected category set is empty. With no `memories_filter_categories` saved, `_loadFilter` seeded all four categories, so All was unchecked and System, Interesting and Manual were ticked. Tapping one of them then removed it and kept the rest, so "filter to Manual" hid every manual memory instead.

Now:

- No saved filter loads as the empty (All) selection.
- Selecting every category collapses back to All and removes the saved key, so it stays All next time.
- A saved category name this build does not know is dropped instead of silently checking System.

The behavior of the All view itself is unchanged: an empty set already matched every category.

## Product invariants affected

none

`app/lib/providers/memories_provider.dart` is not in any invariant's path globs; `scripts/pr-preflight --suggest` reports none. This change does not alter memory authority or the loaded set, only a local UI filter.

## How it was verified

- Traced on current `origin/main` (`31a07230bb`): `_loadFilter` sets all four categories when the key is missing; `memory_management_sheet.dart` computes All from `selectedCategories.isEmpty`; `toggleCategoryFilter` flips only the tapped category.
- No open issue or PR covers the missing-key All state.
- `dart format --language-version=3.0 --line-length 120` on the changed Dart files. The regression tests run in Omi CI (`flutter test`) with `ci:full`. They have not been run locally.

## Tests

`app/test/providers/memories_filter_selection_test.dart`, all against the production provider:

- a first visit (no saved key) has an empty selection, so All is checked;
- a saved list naming every category also loads as All;
- a saved unknown name does not check System;
- tapping Manual from All yields `{manual}` and `filteredMemories` keeps only the manual row;
- ticking every category returns to All and clears the saved key.

On `main` the first test sees all four categories and the Manual test sees `{system, interesting, workflow}`, so both fail.

## UI evidence

UI-Evidence: none -- provider state fix; the tests assert the selection the filter sheet renders from. The running app was not exercised locally.

## Failure class (fixes)

Failure-Class: new

## Failure-class transition narrative

New class `FC-all-filter-persisted-as-every-category`.

- Violated contract: All and a selection of every category are the same view and must both render as All; a missing saved filter must not turn one tap into a removal.
- Canonical guard: `normalizeCategorySelection` collapses a full selection to empty, `_loadFilter` maps a missing key to empty, and the regression tests assert both.
- Evidence: `_loadFilter` seeding all four categories on `origin/main`. `evidence_prs` is empty because this PR is the first instance.

🤖 Generated with [Claude Code](https://claude.com/claude-code)