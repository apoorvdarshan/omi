## What changed and why

Fixes #22421.

`GET /v1/dev/user/conversations` pages its offset-only modes (`include_transcript=true`, `folder_id` or `starred`) with `X-Omi-Next-Offset`. Those modes read `limit + 1` rows through `get_conversations_without_photos`, which applies the server `offset` to the indexed `discarded == False` query. Dream duplicates and legacy completed rule discards still match that filter, so `_collect_visible_conversation_page` drops them in Python and keeps reading past them to fill the page. The route set the header to `offset + len(page)`, which counts only visible rows, but Firestore's offset counts stored rows. After a page that read past hidden rows, the next request started too early and returned conversations the client already had.

The page reader now counts the stored rows it reads past the offset in an optional `scan_stats['rows_read']` (indexed path only), and the route adds the hidden ones to the next offset:
- a full page resumes at its lookahead row, which is always the last row read;
- a budget-truncated page resumes after every row it read.

`offset` still counts stored rows, as the Firestore skip does. A page without hidden rows gets the same header as before. Other callers of the reader don't pass `scan_stats` and are unchanged.

Related: our #22378 fixes the default list's offset pages in `database/mcp_conversation_pages.py`. This PR doesn't touch that file. The default list only emits `X-Omi-Next-Offset` when the request budget truncates an offset page, and that header still uses the visible count. It can adopt the same count once #22378 settles its reader.

## Product invariants affected

none

## How it was verified

- Traced the bug on `origin/main` (`c88d8b5937`): `routers/developer.py` computes `offset + len(conversations)`, and the indexed path of `_collect_visible_conversation_page` reads past hidden rows with `start_after(last_doc)`. Dream's merge cleanup (`database/review_overlay_merge.py`, `utils/agent_capabilities/cleanup_edits.py`) writes `dream_duplicate_of` without `discarded`, and legacy rule discards keep `discarded == False` (`utils/conversations/fragment_visibility.py`), so both stay in the indexed window.
- Traced the regression scenario through the old and new code by hand. Old: page 1 is `c5, c4` with next offset 2, and page 2 starts at `c4` again. New: next offset 3, then pages `c3, c2` and `c1`.
- Checked the existing tests that replace `get_conversations_without_photos` with a `MagicMock` or a `**kwargs` fake (`test_dev_api_folder_filters.py`, `test_dev_api_conversations_poison.py`, `test_lock_bypass_fixes.py`, `test_external_list_routes.py`). They report no count, so the route falls back to the visible count as before. The positional `(uid, limit + 1, offset)` call they assert is unchanged.
- Registered `scan_stats` as a neutral in `tests/support/firestore_query_driver_registry.py`, because the driver fails on unclassified parameters. The caller-witness profiles match only their listed keys, so the extra keyword still fits the `developer-list` profile.
- Local checks only (compute policy on this machine): `scripts/backend-python-format` (Black 26.5.1, no changes) and `python -m py_compile` on the four files. I didn't run pytest locally. The new tests are written to fail without the fix; they and the full backend suites run in Omi's CI (`ci:full`).

## Tests

`backend/tests/unit/test_dev_api_next_offset_hidden_rows.py` calls the real Developer API list handler with `include_transcript=true`, over the real `get_conversations_without_photos` reader and the ordered listing fake from `test_sync_donor_tombstone_visibility.py` (filters, `limit`, `offset`, `start_after`). The stored rows hold a Dream duplicate and a legacy rule discard among five visible conversations.
- `test_next_offset_skips_hidden_rows_so_pages_never_repeat`: the first page (`limit=2`) must return `X-Omi-Next-Offset: 3`, and following the header must list every visible conversation exactly once. Before the fix the header was `2` and the second page repeated `c4`.
- `test_truncated_page_resumes_after_every_row_it_read`: with a three-document budget, the page at offset 1 reads the Dream duplicate and `c4`, then truncates. Its next offset must be `3` (before the fix: `2`, which repeats `c4`), and offset 3 returns `c3, c2`.

## UI evidence

UI-Evidence: none -- backend-only change; the regression tests cover the Developer API pages.

## Line-count exceptions

Line-Count-Exception: backend/database/conversations.py | 4276 -> 4286 | the page reader reports the stored rows it read so offset callers can step over hidden rows
Line-Count-Exception: backend/routers/developer.py | 2760 -> 2765 | the next offset adds the hidden rows the page read

## Failure class (fixes)

Failure-Class: FC-raw-page-limit-before-visibility-filter

🤖 Generated with [Claude Code](https://claude.com/claude-code)
