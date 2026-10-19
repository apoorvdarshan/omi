# w7-web-memories-error

- Issue: https://github.com/BasedHardware/omi/issues/22442 (filed after the fix, test, commit and body were ready)
- PR: https://github.com/BasedHardware/omi/pull/22443 (created without --label; `ci:full` added via the issues API and confirmed; then the empty commit was pushed)
- Fork branch: `fix/web-memories-stale-error` (local branch tracks `fork/fix/web-memories-stale-error`)
- PR head: `60245f194f9779bf0c2be987a28b44f933d090f8` (empty `ci: run with ci:full`) on fix commit `16125ea0b6864831ac171b69a25f977763c06654`; base `70f9bace79` (origin/main when the worktree was made, and when the bug was verified)
- Worktree: `/Users/apoorvdarshan/omi/w7-web-memories-error` (sparse: .github scripts product contracts backend web/app), left for the watcher
- watch.inbox line: `22443 w7-web-memories-error fix/web-memories-stale-error`
- PR body: `body-w7-web-memories-error.md` (same text as the PR)
- CI: not awaited (batch override). No checks had registered on the labeled head when I left.

## The bug

`useMemories` (web/app/src/hooks/useMemories.ts) keeps one `error` for the Memories page. Only a starting fetch clears it (`loadInitial`, `loadForCategories`, `refresh`), plus an owner or backend change. The category-change effect's cached branch (L384-396 on main) sets the list, `hasMore`, `truncated` and the paging refs. When the cache is fresh (5-minute `CACHE_TTL.MEDIUM`), it marks the query handled and returns, so no fetch starts and nothing clears `error`. An error from a failed category fetch, refresh or load-more stays as `MemoriesPage`'s red banner (L562-567) above the valid cached list. It is the same bug as our #22396 (useConversations, issue #22394).

## The fix

- `useMemories.ts`: `setError(null)` in the fresh-cache branch, with a one-line comment (2 added lines). #22396 put its clear in the shared cached block. Here it is in the fresh branch only, because a stale cache's refresh can be blocked by another query's `fetchingRef` lock. The effect then re-runs on every render: its deps include `memoryCacheScope`, a new object each render. A clear there would wipe any failure message, such as a failed delete, that arrives while the refresh waits. `loadForCategories` clears the error itself when it starts. The PR body explains this.
- Test: `web/app/src/hooks/useMemories.test.tsx`, `clears an earlier fetch error when a cached category is shown`, appended to the existing describe and using that file's harness (mocked `getMemoriesPage`, `getCache`/`setCache` backed by `mocks.cacheEntries`, IndexedDB mocked to null). The test loads All (call 1), switches to `['manual']` with a one-time rejection `Network error` (call 2), waits for `error`, then switches back to `[]`. It asserts the cached list, exactly 2 calls, and `error` null.
- Failure-Class: `new`, with a byte-identical copy of #22396's `.github/failure-classes/FC-fetch-error-outlives-cached-view-switch.json` (blob `67fe3f2174`, taken from the #22396 head `37e8d52314`). This follows the precedent of #22301/#22347/#22387, which share `FC-readiness-gate-swallows-terminal-close` the same way. The validator uses three-dot ranges, so `new` stays valid in either merge order unless the branch is updated from main after #22396 merges. In that case, switch the declaration to the FC id.
- No changelog (web/app has none). Invariants: none (only INV-UI-1's `web/**`, which opts out; INV-MEM-1 covers `web/app/src/components/memories/**`, not touched). The line-count ratchet doesn't apply to .ts.

## What I verified (code reading and cheap checks only; no local tests)

- The bug is present on origin/main `70f9bace79`. Duplicates: none found in an issue search (useMemories, memories error/category/filter, error banner cached and similar) or a PR search. I also scanned the files of all 917 open PRs: only #20472 (Spanish strings) touches `components/memories/*`, and none touches `hooks/useMemories*`. I checked the PRs with more than 100 files through the REST file list.
- Hand-traced the test against React 19 and RTL semantics, with no StrictMode in vitest.setup. Without the fix, nothing clears `error` after the final `act`, so `toBeNull()` fails. With the fix, the fresh branch clears it. `waitFor(loading false)` guarantees `fetchingRef` was released, because `finally` sets both synchronously. The mock key for `[]` is `memories:owner-a|https://backend-a:all`, which matches between `setToCache` and `getFromCache`.
- prettier 2.8.8 (the pre-existing binary in `repair-tools/firmware-pr-formatters`, run with `--no-plugin-search` and web/app's `.prettierrc.js`, output only to the scratchpad) reports both changed files unchanged; main's versions were clean too. `git diff --check` is clean. Committed with `OMI_SKIP_WEB_FORMAT=1`; the identity check ran. Pushes used `--no-verify`.
- `scripts/failure-class validate --base origin/main --head HEAD`: the `new` declaration validates, with no `new_definition_required` and no `scope_hint` errors. The only errors are 305 `missing_canonical_prevention_artifact` for other classes, because their artifacts are outside the sparse set; all 287 of those paths exist on origin/main.
- I confirmed that #22396's Hygiene job ran `web-app-checks` (typecheck and vitest) and passed with its harness test. The same lane is selected for `web/app/src/**`, so my test runs there.

## Leads

- `web/app/src/components/memories/MemoryList.tsx:56-77` + `web/app/src/hooks/useMemories.ts:508-518`: a failed load-more leaves `hasMore` true and resets `loading`/`loadingMore`. The infinite-scroll effect re-runs on those deps and calls `onLoadMore` again at once, so a next page that keeps failing (offline, a 5xx on that cursor) is retried in a tight loop with no backoff while the list sits near its end.
- `web/app/src/hooks/useMemories.ts:466-507`: `loadMore` never clears `error`, neither when it starts nor when it succeeds. After one failed load-more ("Failed to load more memories" / "Failed to fetch"), later successful pages append under the same red banner until a category fetch or refresh runs.
- `web/app/src/hooks/useMemories.ts:629-631` (and the catch blocks at 655, 676, 711, 735, 759, 780): the memory-edit catch blocks call `setError` without the `isCurrentRequest()` fence that their success paths use. A request from the previous owner that fails after sign-out and sign-in as another account puts "Failed to delete memory" (etc.) on the new account's Memories page.
