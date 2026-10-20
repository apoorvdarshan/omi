## What changed and why

Fixes #22776.

`get_workstream_detail` (`backend/database/workstreams.py`) filled `recent_events` from `list_workstream_events` with its defaults: `after_sequence=0`, `limit=100`, ascending by `sequence`. That always returns sequences 1..100, so a workstream past 100 journal events never showed its newest changes. The macOS task thread reads this projection as the thread's recent activity.

Every append sets the new event's `sequence` to `latest_event_sequence + 1` and updates `latest_event_sequence` in the same transaction, so the journal is contiguous. The detail now reads from `max(0, latest_event_sequence - 100)`, which returns the newest 100 events in the ascending order the response already promises, and reuses the existing query shape.

## Product invariants affected

none

## How it was verified

- Traced on current `origin/main` (`31a07230bb`): `get_workstream_detail` called `list_workstream_events(uid, workstream_id, firestore_client=client)` with no `after_sequence`, and `list_workstream_events` queries `sequence > after_sequence` ascending with `limit`. `append_workstream_event` assigns `sequence = workstream.latest_event_sequence + 1` inside the transaction that advances `latest_event_sequence`.
- No issue or open PR covers `get_workstream_detail`'s event window.
- `scripts/backend-python-format --check` and `python3 -m py_compile` on the changed files. The regression tests were written to fail without the fix and run in Omi CI with `ci:full`; they have not been run locally.

## Tests

`backend/tests/unit/test_workstream_detail_recent_events.py`, against an in-memory fake that honours `where`, `order_by` and `limit` the way `test_workstream_core.py`'s fake does:

- `test_workstream_detail_returns_the_newest_events_past_the_page`: seeds 105 contiguous events and asserts the detail returns sequences 6..105 in ascending order. On `main` it returns 1..100, so the test fails.
- `test_workstream_detail_returns_every_event_of_a_short_thread`: a 3-event thread still returns all of them.

## UI evidence

UI-Evidence: none -- backend projection fix with no UI

## Failure class (fixes)

Failure-Class: new

## Failure-class transition narrative

New class `FC-recent-window-reads-oldest-page`.

- Violated contract: a projection named for recent entries must read the tail of an append-only sequence, not its first page. `recent_events` served sequences 1..100 for every thread.
- Canonical guard: `test_workstream_detail_recent_events.py` seeds a journal longer than the page and asserts the newest sequences come back. The read starts at `latest_event_sequence - 100`, which is exact because appends assign `sequence = latest_event_sequence + 1` in the same transaction.
- Evidence: `get_workstream_detail` on `origin/main` before this change. `evidence_prs` is empty because this PR is the first instance.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
