# w11-cli-screen-search-empty

- Issue: #22849 — omi --json local search-screen omits results: [] when screenshots are not indexed yet
- PR: #22850 — fix(cli): structure unindexed and stats-error empty screen searches
- Branch: `fix/cli-screen-search-empty-messages` (fork `apoorvdarshan/omi`)
- Head: c7dac848a9 (ci:full empty commit; fix commit b8644c1b83)
- Base: `origin/main` 5098bbc6eab52a955f0b043b5bedd013ea3c5851

What changed:
- `_normalize_screen_search` in `sdks/python-cli/omi_cli/commands/local.py` recognizes all four
  empty-result messages from `ChatToolExecutor.emptySemanticSearchMessage`, including
  unindexed screenshots (`"Omi has <N> screenshot(s), but they are not ready to search yet..."`)
  and failed stats reads (`"No screenshots found matching ..."`).
- Failure class: `FC-mirrored-model-omits-new-member` (existing).
- Regression test: `sdks/python-cli/tests/test_local.py`
  (`test_search_screen_unindexed_and_stats_error_empty_messages_are_structured_in_json`).

Verified: code reading plus `python3 -m py_compile`; not run locally (compute policy),
runs in Omi CI (`python-cli-ci.yml`) with `ci:full`. Watcher entry added to `watch.inbox`.
