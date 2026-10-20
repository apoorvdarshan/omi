## What changed and why

Fixes #22778.

`get_user_goals` (`backend/database/goals.py`) pushed `.limit(limit)` into an unordered query, `where is_active == True`. Firestore returns that page in document-id order, and the ended-goal filter and the oldest-first sort both run afterwards in Python. So a `limit=3` caller (Mentor notifications in `backend/utils/proactivity_producers.py`, deep daily recaps in `backend/utils/llm/external_integrations.py`) saw whichever three active goals had the lowest document ids, dropping the user's other goals, and an ended row inside that first page came back as a short page.

The query now reads up to 100 active rows, the widest bound an existing caller already passes (`get_user_goal`, chat context, goal advice), and slices to `limit` only after the ended-goal filter and the sort. The query shape is unchanged, so no new index is needed.

## Product invariants affected

none

## How it was verified

- Traced on current `origin/main` (`31a07230bb`): `get_user_goals` built `collection.where(is_active == True).limit(limit)`, then filtered `status not in {achieved, abandoned}`, then sorted by `_goal_created_at_sort_key`, then sliced `[:limit]`. Callers at `proactivity_producers.py:574` and `external_integrations.py:97` pass `limit=3`; `get_user_goal`, `utils/llm/chat.py` and `utils/llm/goals.py` pass `limit=100`.
- Checked the existing `get_user_goals` tests (`test_goals_sort_missing_created_at.py`, `test_goals_id_fallback.py`): their fakes return the whole stubbed stream, so the wider scan does not change their assertions.
- No issue or open PR covers this truncation.
- `scripts/backend-python-format --check` and `python3 -m py_compile` on the changed files. The regression tests were written to fail without the fix and run in Omi CI with `ci:full`; they have not been run locally.

## Tests

`backend/tests/unit/test_goal_context_all_active_goals.py`, against a fake that streams goals in document-id order and honours `.limit()`:

- `test_limit_three_keeps_the_oldest_active_goals_past_the_first_document_ids`: six active goals where the three oldest have the latest document ids. Asserts `limit=3` returns those three oldest. On `main` the query returns the three newest, so the test fails.
- `test_ended_rows_inside_the_first_page_do_not_shorten_the_result`: the first three document ids are achieved or abandoned. Asserts three active goals come back. On `main` the page is exactly those three ended rows and the result is empty, so the test fails.

## UI evidence

UI-Evidence: none -- backend query-bound fix with no UI

## Failure class (fixes)

Failure-Class: new

## Failure-class transition narrative

New class `FC-query-limit-before-python-filter`.

- Violated contract: a limit that the caller reads as "the first N after filtering and sorting" must be applied after that filtering and sorting when the query has no order. Pushing it into an unordered query returns an arbitrary page and drops rows the filter would have kept.
- Canonical guard: `test_goal_context_all_active_goals.py` drives `get_user_goals` through a fake that streams in document-id order and honours `.limit()`, with the wanted rows past the first page and with ended rows filling it.
- Evidence: `get_user_goals` on `origin/main` before this change. `evidence_prs` is empty because this PR is the first instance.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
