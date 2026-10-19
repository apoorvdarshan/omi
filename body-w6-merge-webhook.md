## What changed and why

Fixes #22413.

`perform_merge_async` processes the merged conversation before it moves the correction anchors (`review_overlay_merge.transfer`) and deletes the sources. `MERGE` is not a reprocess, so `process_conversation` submits the developer `conversation_created` webhook during that processing.

If `transfer` then raises a `ReviewConflict`, the merge is still in `BEFORE_SOURCE_DELETION`. `_handle_merge_failure` deletes the merged conversation and puts the sources back. `transfer` raises when a source was deleted, locked or edited while the merge was processing, or when another merge already moved the anchors. On current `main` it also raises for sources that overlap in time so their lines interleave (#22319). By then the webhook is already on the postprocess pool and nothing recalls it. Developer endpoints get a conversation that no longer exists, next to the sources they already had.

The fix:
- `process_conversation` takes an optional keyword `created_webhook_observer`. When it is set, the created webhook's send goes to the observer instead of being submitted. Every other caller passes nothing and sends as before.
- `perform_merge_async` collects that send and releases it right after `transfer` returns. From that point failure handling keeps the merged conversation (`SOURCE_DELETION_STARTED`). A failed send is logged and does not fail the merge.
- A merge that goes through still sends exactly one webhook for the merged conversation. It now goes out after the transfer transaction, before the sources are deleted.

## Product invariants affected

- INV-MEM-4
- INV-TASK-2

`process_conversation.py` is under both path globs. The change only moves when the developer webhook is sent for a merge. Memory promotion and task capture are untouched.

## How it was verified

- Traced the merge on current `origin/main` (`64b082e9b2`; same merge and processing code as this branch's base `501f906eac`). Processing submits `conversation_created_webhook` to `postprocess_executor` in `_emit_derived_effects` (`not is_reprocess`). `transfer` can then raise while `failure_phase` is still `BEFORE_SOURCE_DELETION`, and `_handle_merge_failure` calls `_cleanup_merged_target_after_failure`, which deletes the merged conversation. Nothing cancels the submitted webhook.
- Local checks only (compute policy on this machine): `scripts/backend-python-format --check` on the changed files (no changes) and a compile check of the changed Python files.
- The background-task ratchet (`tests/unit/test_background_task_ratchet.py`) counts un-awaited `submit_with_context` sites per enclosing function. The created-webhook submit now sits in two mutually exclusive branches of `_emit_derived_effects` (submit now, or hand the send to the observer), so `tests/unit/fixtures/background_task_baseline.json` allows 5 sites there instead of 4. Its `why` says the extra one is the same webhook, still submitted at most once per run. I checked the new count by running the ratchet's site visitor on `process_conversation.py` alone (not pytest); the ratchet itself runs in CI.
- I didn't run pytest locally. The regression tests are written to fail without the fix. They and the full backend suites run in Omi's CI (`ci:full`).

## Tests

- `backend/tests/unit/test_merge_created_webhook.py` runs the real `perform_merge_async` with its storage edges stubbed and records what happens, in order.
  - `test_transfer_rollback_never_announces_the_merged_conversation_it_deletes`: `transfer` raises `ReviewConflict` and the rollback runs with `BEFORE_SOURCE_DELETION` for the merged conversation. No webhook was sent. On `main` it went out before `transfer`.
  - `test_committed_merge_announces_the_merged_conversation_once_transfer_succeeds`: the order is transfer, webhook, source deletes, merge-completed notification. On `main` the webhook comes first.
- `backend/tests/unit/test_process_conversation_usage_context.py` runs the real `process_conversation` with the `MERGE` trigger and every submitted job run inline.
  - `test_created_webhook_observer_holds_the_webhook_until_the_caller_sends_it`: with the observer, nothing is delivered during processing and exactly one send is handed over. Calling it delivers the webhook for the processed conversation.
  - `test_created_webhook_is_sent_during_processing_without_an_observer`: without one, the webhook is still delivered during processing, as before.

## UI evidence

UI-Evidence: none -- backend-only change; the merge-level tests cover the behaviour.

## Failure class (fixes)

Failure-Class: new

## Failure-class transition narrative

New class `FC-announcement-precedes-rollback-boundary`.

- Violated contract: an operation that can still roll back (delete) the record it is building must not send an irreversible external announcement of that record before the point after which its failure handling keeps it.
- Canonical guard: `backend/tests/unit/test_merge_created_webhook.py`, which drives the real merge through the rolled-back and the committed path and checks when the webhook goes out.
- Evidence: the issue above and the merge path on `origin/main` before this change. `evidence_prs` is empty because this PR is the first instance.

Line-Count-Exception: backend/utils/conversations/process_conversation.py | 3204 -> 3210 | created-webhook observer: one keyword-only parameter and the branch that hands the send to it

Related: #22320 (mine) and #21845 also change `merge_conversations.py`. This PR stays off their lines (the `transfer(...)` call, the imports, `_delete_conversation_and_related_data` and the rollback cleanup).

🤖 Generated with [Claude Code](https://claude.com/claude-code)
