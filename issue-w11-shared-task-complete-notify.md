**Product impact**

- Primary loop layer (pick one): Retrieval-Action
- [ ] Involves data loss, failed capture, or broken sync/trust (call this out clearly below)

**Describe the bug**

In `backend/routers/action_items.py`, `toggle_action_item_completion` (`PATCH /v1/action-items/{action_item_id}/completed`) sends the `"Task completed"` push notification to `shared_from.sender_uid` whenever `completed=True` and `existing_item.get('shared_from')` is present, without checking whether `existing_item.get('completed')` was already `True`.

Although #21532 updated `database/action_items.py` so re-completing an already-completed task preserves `completed_at` and treats the write as idempotent, any client retry, duplicate tap, or bulk-complete call that includes an already-completed shared task still sends another `"Task completed"` push notification to the sender.

**To Reproduce**

1. User A shares a task with User B, and User B accepts it (`shared_from.sender_uid == uid_alice`).
2. User B marks the task completed (`PATCH /v1/action-items/{id}/completed?completed=true`). User A receives `"Task completed"`.
3. A client retry, double-tap, or bulk complete sends `PATCH /v1/action-items/{id}/completed?completed=true` for that already-completed task.
4. User A receives a second `"Task completed"` notification for the same completion.

**Current behavior**

`toggle_action_item_completion` checks `if completed and existing_item.get('shared_from'):`, notifying the sender on every `completed=true` call even when the task was already completed.

**Expected behavior**

`toggle_action_item_completion` notifies the sender only when the task transitions from incomplete to completed (`if completed and not existing_item.get('completed') and existing_item.get('shared_from'):`).

**Screenshots**

Not applicable; this is a backend push-notification side effect.

**user ID (can we access the user info to validate the bug?):**

Not applicable; reproduces deterministically in unit tests without account data.

**Smartphone + device (please complete the following information):**

- Device: server-side API (`PATCH /v1/action-items/{action_item_id}/completed`)
- OS: any
- Browser: any
- App Version: `backend` at `5098bbc6eab52a955f0b043b5bedd013ea3c5851`

**Additional context**

Cause on current `main`: https://github.com/BasedHardware/omi/blob/5098bbc6eab52a955f0b043b5bedd013ea3c5851/backend/routers/action_items.py#L860-L873
