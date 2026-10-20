# w11-mcp-task-vector-saved-desc

- Issue: #22843 — MCP create_action_item overwrites a renamed task's search vector on idempotent hit
- PR: #22844 — fix(mcp): index the saved task description on idempotent create
- Branch: `fix/mcp-task-create-vector-saved-description` (fork `apoorvdarshan/omi`)
- Head: fd3f584ff9 (ci:full empty commit; fix commit 662052c1b0)
- Base: `origin/main` 5098bbc6eab52a955f0b043b5bedd013ea3c5851

What changed:
- `utils.mcp_action_items.create_action_item` loads the stored task `item` before calling
  `upsert_action_item_vector`, and indexes `item.get("description") or text` so an
  idempotent match on a renamed open task preserves its current search vector.
- Failure class: `FC-replay-idempotency-keyed-on-advancing-state` (existing).
- Regression test: `backend/tests/unit/test_mcp_action_item_writes.py`
  (`TestCreateOrchestration.test_create_idempotent_hit_indexes_saved_description`).

Verified: code reading plus `python3 -m py_compile`; not run locally (compute policy),
runs in Omi CI with `ci:full`. Watcher entry added to `watch.inbox`.
