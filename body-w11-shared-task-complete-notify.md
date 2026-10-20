## What changed and why

`toggle_action_item_completion` (`PATCH /v1/action-items/{action_item_id}/completed`) sent the `"Task completed"` push notification to `shared_from.sender_uid` whenever `completed=True` and `existing_item.get('shared_from')` was present, without checking whether `existing_item` was already completed. Even after #21532 made re-completing an already-completed task preserve `completed_at` in `database/action_items.py`, a client retry, duplicate tap, or bulk complete that included an already-completed shared task notified the sender again.

The route now checks `not existing_item.get('completed')` before sending the completion notification, so the sharer is notified only when the task transitions to completed.

Fixes #22847

## Product invariants affected

none

## How it was verified

- Read `backend/routers/action_items.py` (`toggle_action_item_completion`) and `backend/tests/unit/test_task_sharing.py` (`TestCompletionNotification`).
- Added `test_no_duplicate_notification_when_already_completed` in `backend/tests/unit/test_task_sharing.py`, which calls `toggle_action_item_completion("t1", completed=True, uid="uid_bob")` when `existing_item["completed"]` is already `True` and asserts `send_notification` is not called.
- Ran `python3 -m py_compile backend/routers/action_items.py backend/tests/unit/test_task_sharing.py`. Per the fix loop's compute policy, the backend unit suite was not run on this Mac; it runs in Omi CI with `ci:full`.

## Tests

`backend/tests/unit/test_task_sharing.py` — `TestCompletionNotification.test_no_duplicate_notification_when_already_completed` (written to fail without the fix and pass with it; runs in Omi CI).

## UI evidence

UI-Evidence: none -- backend push-notification guard only; no UI change.

## Failure class (fixes)

Failure-Class: FC-replay-idempotency-keyed-on-advancing-state

🤖 Generated with [Claude Code](https://claude.com/claude-code)
