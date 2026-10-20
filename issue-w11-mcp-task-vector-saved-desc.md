**Product impact**

- Primary loop layer (pick one): Retrieval-Action
- [ ] Involves data loss, failed capture, or broken sync/trust (call this out clearly below)

**Describe the bug**

In `backend/utils/mcp_action_items.py`, `create_action_item` upserts the semantic-search vector (`upsert_action_item_vector(uid, item_id, text)`) using the incoming request `text` before reading the stored task (`item = action_items_db.get_action_item(uid, item_id)`).

When an open task created via MCP is later renamed, its stored `idempotency_key` in Firestore still matches the original normalized title (`content_idempotency_key(uid, text)`). Calling `create_action_item` again with that original title matches the existing open task and returns its saved, renamed description (and syncs its reminder from the saved row), but overwrites the task's semantic-search vector with the stale request title.

The REST create endpoint (`backend/routers/action_items.py`) was fixed in #19441 to index `response.description` from the loaded row; the MCP orchestration helper still indexed the raw request text before loading `item`.

**To Reproduce**

1. Create a task via MCP `create_action_item` with description `"Email Bob"`.
2. Rename that open task to `"Email Bob the signed contract"`.
3. Call MCP `create_action_item` again with description `"Email Bob"`.
4. The call matches the open task by `idempotency_key` and returns `"Email Bob the signed contract"`, but `upsert_action_item_vector` is called with `"Email Bob"`.

**Current behavior**

`create_action_item` calls `upsert_action_item_vector(uid, item_id, text)` before loading `item`, overwriting a renamed task's search vector with the request text on an idempotent hit.

**Expected behavior**

`create_action_item` loads the persisted task first and indexes `item.get("description") or text`, preserving the saved description in the vector index just as reminder reconciliation and the returned payload do.

**Screenshots**

Not applicable; this is backend MCP orchestration and vector indexing.

**user ID (can we access the user info to validate the bug?):**

Not applicable; reproduces deterministically in unit tests without user data.

**Smartphone + device (please complete the following information):**

- Device: server-side MCP / REST handler
- OS: any
- Browser: any
- App Version: `backend` at `5098bbc6eab52a955f0b043b5bedd013ea3c5851`

**Additional context**

Cause on current `main`: https://github.com/BasedHardware/omi/blob/5098bbc6eab52a955f0b043b5bedd013ea3c5851/backend/utils/mcp_action_items.py#L164-L179 — `upsert_action_item_vector(uid, item_id, text)` runs before `item = action_items_db.get_action_item(uid, item_id)`. Compare with https://github.com/BasedHardware/omi/blob/5098bbc6eab52a955f0b043b5bedd013ea3c5851/backend/routers/action_items.py#L384-L399 (`upsert_action_item_vector(uid, action_item_id, response.description)`).
