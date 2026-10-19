## What changed and why

Fixes #22442.

On the web Memories page, `useMemories` keeps one `error` for the page, and only a fetch clears it, when the fetch starts. When the category filter changes to one whose list is cached and fresh, the category-change effect shows the cached list and returns without starting a fetch, so the error stays. An error from an earlier failure (another category's first page, a refresh, loading more) then sits above the valid list: `MemoriesPage` renders `error` as a banner above the memories. It stays until a later fetch starts (a category with no fresh cache, a refresh).

The effect now clears `error` when it shows a fresh cached list.

This is the bug my open #22396 fixes in `useConversations`, and the fix has the same shape. The only difference is where the clear sits: here it is in the fresh-cache branch only. In this hook, a stale cache's refresh can wait for another category's fetch to finish, and the effect runs again on every render until that refresh starts. The refresh clears the error itself when it starts (`loadForCategories`). Clearing on each of those runs would also wipe a failure message that arrives in the meantime, such as a failed delete.

## Product invariants affected

none

The changed paths fall only under INV-UI-1's whole-tree `web/**` glob, which needs no citation for routine changes. INV-MEM-1 covers `web/app/src/components/memories/**`, which this PR does not touch.

## How it was verified

- Traced on current `origin/main` (`70f9bace79`). In `useMemories`, `error` is cleared only when a fetch starts (`loadInitial`, `loadForCategories`, `refresh`) and on an owner or backend change. Failed fetches (including `loadMore`) and failed memory edits set it. The category-change effect's fresh-cache branch sets the list, `hasMore`, `truncated` and the paging refs, marks the category handled and returns. No fetch starts, so nothing clears `error`. `MemoriesPage` renders `error` as a banner above the list.
- I wrote the regression test to fail without the fix. I checked this by tracing the code, not by running it: on main the cached list comes back with `error` still `'Network error'`, so the last assertion fails.
- The test runs in Omi's CI (the `web-app-checks` lane in Hygiene: typecheck and vitest) with `ci:full`. I did not run it locally.
- prettier 2.8.8 (the version web/app pins) with web/app's config reports both changed files unchanged. `git diff --check` is clean.

## Tests

`web/app/src/hooks/useMemories.test.tsx`, `clears an earlier fetch error when a cached category is shown`. It uses the file's existing harness: the real hook, an in-memory cache and a mocked `getMemoriesPage`. The test loads the full list, then switches to the `manual` category, whose first page fails. Then it switches back to all memories. The cached list comes back without a new request, and `error` is `null`.

## UI evidence

UI-Evidence: none -- list state in a hook with no layout change; the hook test above covers the behaviour

## Failure class (fixes)

Failure-Class: new

## Failure-class transition narrative (only when needed)

New class `FC-fetch-error-outlives-cached-view-switch`. #22396 (open) adds it for the same bug in `useConversations`. It is not on `main` yet, so this PR adds a byte-identical copy of that file (blob `67fe3f2174`). Whichever of the two PRs merges second adds nothing new to it. If #22396 merges first, this PR's declaration becomes `Failure-Class: FC-fetch-error-outlives-cached-view-switch`.

- Violated contract: a view that switches to data it already holds must reset the request status that described the data it replaces. Here `error` was cleared only when a fetch started, and a category served from a fresh cache starts none.
- Canonical guard: clear request status on every path that replaces the displayed data, proven by a failed fetch followed by a switch to a view whose cached list is fresh. The test above does this for memories, as #22396's does for conversations.
- Evidence: issue #22442 and `useMemories.ts` on `origin/main`. `evidence_prs` is empty because neither PR has merged.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
