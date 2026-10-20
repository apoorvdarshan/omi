## What changed and why

`utils.mcp_action_items.create_action_item` upserted the semantic-search vector using the incoming request `text` before loading the persisted task (`action_items_db.get_action_item(uid, item_id)`). When an open task created via MCP was later renamed, its stored `idempotency_key` still matched the original title (`content_idempotency_key(uid, text)`), so calling `create_action_item` with the original title returned the renamed task and reconciled its reminder from the saved row, but overwrote its Pinecone vector with the stale request text.

`create_action_item` now loads `item` first and passes `item.get("description") or text` to `upsert_action_item_vector`, matching the REST `POST /v1/action-items` handler (#19441).

Fixes #22843

## Product invariants affected

none

## How it was verified

- Read `backend/utils/mcp_action_items.py` and compared `create_action_item` with `backend/routers/action_items.py` (#19441).
- Added `test_create_idempotent_hit_indexes_saved_description` in `backend/tests/unit/test_mcp_action_item_writes.py`, which exercises `actions.create_action_item` when `action_items_db.get_action_item` returns a renamed open task and asserts `upsert_action_item_vector` receives the saved description (`'Email Bob the signed contract'`) instead of the request text (`'Email Bob'`).
- Ran `python3 -m py_compile backend/utils/mcp_action_items.py backend/tests/unit/test_mcp_action_item_writes.py`. Per the fix loop's compute policy, the backend unit suite was not run on this Mac; it runs in Omi CI with `ci:full`.

## Tests

`backend/tests/unit/test_mcp_action_item_writes.py` — `TestCreateOrchestration.test_create_idempotent_hit_indexes_saved_description` (written to fail without the fix and pass with it; runs in Omi CI).

## UI evidence

UI-Evidence: none -- backend MCP orchestration and vector indexing only; no UI change.

## Failure class (fixes)

Failure-Class: FC-replay-idempotency-keyed-on-advancing-state

🤖 Generated with [Claude Code](https://claude.com/claude-code)
