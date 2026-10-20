## What changed and why

Fixes #22774.

`people_stats_scan` (`backend/database/conversation_scan.py`) reads conversations through a field mask, `PEOPLE_STATS_FIELD_PATHS`, and then hides rows with `is_visible_conversation`. A Dream duplicate capture stays `discarded == False` (Dream's `merge_conversations` cleanup only writes `dream_duplicate_of`), so the indexed `discarded == False` filter still returns it and only `dream_duplicate_of` hides it. The mask never selected that field. A field a mask drops comes back absent, and `is_visible_conversation` reads an absent hide flag as visible, so People stats counted both captures of a Dream merge.

This is the same defect #22419 fixed for the MCP and Developer API card reads (`MCP_CONVERSATION_CARD_FIELD_PATHS`).

The mask now selects `dream_duplicate_of`.

## Product invariants affected

none

## How it was verified

- Traced on current `origin/main` (`31a07230bb`): `people_stats_scan` calls `iter_conversations` with `field_paths=PEOPLE_STATS_FIELD_PATHS` (`backend/database/conversation_scan.py`), and `iter_conversations` drops any row `is_visible_conversation` rejects. That predicate (`backend/database/conversations.py`) returns false for a row whose `dream_duplicate_of` is set, while the mask ended at `manual_speaker_assignments_compressed`.
- Confirmed #22419 (merged) fixed the same omission for `MCP_CONVERSATION_CARD_FIELD_PATHS` and left `conversation_scan.py` untouched.
- `scripts/backend-python-format --check` and `python3 -m py_compile` on the changed files. The regression test was written to fail without the fix and runs in Omi CI with `ci:full`; it has not been run locally.

## Tests

`backend/tests/unit/test_conversation_scan.py`, `test_people_stats_scan_hides_dream_duplicate_captures`: scans one kept conversation and one Dream duplicate (`dream_duplicate_of` set, `discarded` false) through the real `iter_conversations` with `PEOPLE_STATS_FIELD_PATHS`, against the file's masking `_StrictClient`. It asserts only the kept conversation comes back and that the query's projection selects `dream_duplicate_of`. On `main` the mask drops the field, the fake returns it absent, and the duplicate is yielded, so the test fails.

## UI evidence

UI-Evidence: none -- backend read-projection fix with no UI

## Failure class (fixes)

Failure-Class: FC-read-projection-omits-visibility-field

🤖 Generated with [Claude Code](https://claude.com/claude-code)
