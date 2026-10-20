## What changed and why

`_normalize_screen_search` in `sdks/python-cli/omi_cli/commands/local.py` only recognized two of macOS Desktop's four empty-result strings from `ChatToolExecutor.emptySemanticSearchMessage`: `"No matching screen-history results..."` and `"No screen history is available..."`. When Desktop returned either of its other two empty messages — `"Omi has <N> screenshot(s), but they are not ready to search yet..."` (`stats.indexed == 0`) or `"No screenshots found matching \"<query>\" in the last <days> day(s). Local status could not be read: ..."` (when `getStats()` fails) — `omi --json local search-screen` fell through the hit parser and returned `{"text": result, ...}` without `"results": []`, `"reason"`, or `"suggestions"`.

`_normalize_screen_search` now recognizes all four empty-result messages from `ChatToolExecutor.emptySemanticSearchMessage`.

Fixes #22849

## Product invariants affected

none

## How it was verified

- Read `ChatToolExecutor.emptySemanticSearchMessage` in `desktop/macos/Desktop/Sources/Providers/ChatToolExecutor.swift` and `_normalize_screen_search` in `sdks/python-cli/omi_cli/commands/local.py`.
- Added parameterized test `test_search_screen_unindexed_and_stats_error_empty_messages_are_structured_in_json` in `sdks/python-cli/tests/test_local.py`, covering both previously missed empty messages and asserting `payload["results"] == []`, `payload["reason"] == response`, `payload["suggestions"]`, and `"text" not in payload`.
- Ran `python3 -m py_compile sdks/python-cli/omi_cli/commands/local.py sdks/python-cli/tests/test_local.py`. Per the fix loop's compute policy, pytest was not run locally; it runs in Omi CI (`python-cli-ci.yml`) with `ci:full`.

## Tests

`sdks/python-cli/tests/test_local.py` — `test_search_screen_unindexed_and_stats_error_empty_messages_are_structured_in_json` (written to fail without the fix and pass with it; runs in Omi CI).

## UI evidence

UI-Evidence: none -- CLI `--json` output only; no UI change.

## Failure class (fixes)

Failure-Class: FC-mirrored-model-omits-new-member

🤖 Generated with [Claude Code](https://claude.com/claude-code)
