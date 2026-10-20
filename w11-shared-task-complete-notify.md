# w11-shared-task-complete-notify

- Issue: #22847 — Repeating completed=true on a shared task sends duplicate 'Task completed' notifications
- PR: #22848 — fix(action-items): notify the sharer only when a task first completes
- Branch: `fix/shared-task-repeat-completion-notification` (fork `apoorvdarshan/omi`)
- Head: ab117a4e1c (ci:full empty commit; fix commit 2832ab75d4)
- Base: `origin/main` 5098bbc6eab52a955f0b043b5bedd013ea3c5851

What changed:
- `toggle_action_item_completion` in `backend/routers/action_items.py` checks
  `not existing_item.get('completed')` before sending the shared-task `"Task completed"`
  notification, so a retry, duplicate tap, or bulk complete on an already-completed
  shared task does not notify the sender again.
- Failure class: `FC-replay-idempotency-keyed-on-advancing-state` (existing).
- Regression test: `backend/tests/unit/test_task_sharing.py`
  (`TestCompletionNotification.test_no_duplicate_notification_when_already_completed`).

Verified: code reading plus `python3 -m py_compile`; not run locally (compute policy),
runs in Omi CI with `ci:full`. Watcher entry added to `watch.inbox`.
