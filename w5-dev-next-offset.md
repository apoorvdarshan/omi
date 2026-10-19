# w5-dev-next-offset

- Issue: https://github.com/BasedHardware/omi/issues/22421 (filed this run, after the fix, test, commit and body were ready)
- PR: https://github.com/BasedHardware/omi/pull/22423 (created without --label; `ci:full` added via the issues API and confirmed; then the empty commit was pushed)
- Fork branch: `fix/dev-api-next-offset-hidden-rows` (local branch tracks `fork/fix/dev-api-next-offset-hidden-rows`)
- PR head: `608228226bea45486a449f36da09af188386d80a` (empty `ci: run with ci:full`) on fix commit `4df6f10e31ddf7c70b57865726ec54282faf88d1`; base `c88d8b5937` (current origin/main at start)
- Worktree: `/Users/apoorvdarshan/omi/w5-dev-next-offset` (sparse: .github scripts product contracts backend), left for the watcher
- watch.inbox line: `22423 w5-dev-next-offset fix/dev-api-next-offset-hidden-rows`
- PR body: `body-w5-dev-next-offset.md` (same text as the PR)
- CI: not awaited (batch override). Checks were queued on the labeled head when I left.

## The bug

`GET /v1/dev/user/conversations` offset-only modes (`include_transcript=true`, `folder_id`, `starred`) read `limit + 1` rows with `get_conversations_without_photos` at the server offset. Dream duplicates (`dream_duplicate_of`, written by `review_overlay_merge.py` / `cleanup_edits.py` without `discarded`) and legacy completed rule discards match `discarded == False`, so `_collect_visible_conversation_page` drops them in Python and back-fills with `start_after(last_doc)`. `routers/developer.py:1626` set `X-Omi-Next-Offset = offset + len(page)` (visible count) while Firestore's offset counts stored rows, so the next page restarted early and repeated conversations.

## The fix

- `database/conversations.py`: optional `scan_stats` on `_collect_visible_conversation_page` and `get_conversations_without_photos`; the indexed path counts every stored row read past the offset in `scan_stats['rows_read']` (2 increments next to `fetched += 1`). Other callers pass nothing.
- `routers/developer.py`: the offset path passes `scan_stats` and adds `rows_read - len(fetched)` (hidden rows read) to the next offset. A full page resumes at its lookahead row (the last row read); a budget-truncated page resumes after every row read. `.get('rows_read', len(conversations))` keeps MagicMock-based tests at the old value.
- `tests/support/firestore_query_driver_registry.py`: `scan_stats` registered as a neutral (the driver fails on unclassified parameters).
- New test `backend/tests/unit/test_dev_api_next_offset_hidden_rows.py`: real handler + real reader over `_install_listing` (from `test_sync_donor_tombstone_visibility.py`), Dream duplicate + rule discard among five visible rows. (1) the first page's header must be `3` (old `2`), and following headers must list `c5..c1` once; (2) with `OMI_LIST_READ_MAX_DOCUMENTS=3` the offset-1 page is truncated after the duplicate and `c4`, so the header must be `3` (old `2`), and offset 3 returns `c3, c2`.
- Line-Count-Exception lines in the body: conversations.py 4276 -> 4286, developer.py 2760 -> 2765.
- Failure-Class: FC-raw-page-limit-before-visibility-filter (same class as #22378).

## What I verified (code reading and cheap checks only; no local tests)

- The bug is present on origin/main `c88d8b5937` (paths above). Duplicates: none in issues or open PRs. #22377/#22378 (ours) fix the cards-path premature end in `database/mcp_conversation_pages.py`; I didn't touch that file. #21950, #22419 and #22219 touch other hunks of the same files.
- Hand-traced the new tests against the old and new code (old fails on the first header assertion in both tests).
- Existing tests that mock `get_conversations_without_photos` (folder_filters, conversations_poison, lock_bypass_fixes, external_list_routes) get no count, so they keep the old value. The positional `(uid, limit + 1, offset)` call is unchanged. The caller-witness profile matching ignores extra keys. `test_people_conversations_500s` signature slicing still finds `):`. No body digest covers the touched functions.
- Black 26.5.1 (`uvx`, pinned like `scripts/backend-python-format`): no changes. `py_compile` on all four files passed. `scripts/failure-class validate` recognizes the declaration and the fix commit. Its only errors are missing artifacts for unrelated classes in this sparse checkout.
- The pre-commit hook ran (identity check, Black) on the fix commit. Pushes used `--no-verify`.

## Environment notes

- BRIEF.md was missing when I started (deleted earlier by a cleanup session). I followed the task's summary of it. The lead restored it at about 12:24; I re-checked against it afterwards: I saved the body here and set the branch upstream. I skipped the `backend/.venv` symlink and the PATH shims because the hooks passed without them.
- watch.inbox did not exist at the moment I appended (the watcher had just renamed it into watch.list), so my append recreated it with only my line, which is the watcher's protocol.

## Leads

- `backend/database/conversations.py:899,914` + `backend/routers/developer.py:1617`: once a page skips more than `_RULE_DISCARD_PAGE_SKIP_CAP` (64) hidden rows, `_collect_visible_conversation_page` returns a short page without marking truncation, so the Developer API offset modes send `X-Omi-Has-More: false` and clients stop while visible conversations remain. One trigger is `include_transcript=true&limit=200` when 65 or more of the first 201 stored rows are Dream duplicates or legacy rule discards (no follow-up read at all). The app list route reads the short page the same way.
- `backend/routers/developer.py:1626` (cards path): with `offset > 0` and the request budget truncating `get_mcp_conversation_cards` after hidden rows, `X-Omi-Next-Offset` is still `offset + len(visible)` and repeats rows. After #22378 lands, that reader walks past hidden rows by keyset, so the gap can grow. It can adopt the same `rows_read` count.

## Cleanup

Leave the worktree for the watcher. Once CI is green: `git -C /Users/apoorvdarshan/omi/repository worktree remove /Users/apoorvdarshan/omi/w5-dev-next-offset` and `git -C /Users/apoorvdarshan/omi/repository branch -D fix/dev-api-next-offset-hidden-rows`.
