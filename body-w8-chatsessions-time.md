## What changed and why

Fixes #22795.

`useChatSessions` memoized `groupSessionsByDate(filteredSessions)` on the filtered list alone, so `Date.now()` inside the grouper froze at the last list/search change. A chat-history popover left open across midnight kept yesterday's chats under **Today** until the list changed.

Now:

- grouping runs at render time with a fresh clock;
- `now?: () => number` is injectable for tests.

## Product invariants affected

none

`desktop/windows/src/renderer/src/hooks/useChatSessions.ts` is not in any invariant's path globs. This only refreshes display buckets; session identity and CRUD are unchanged.

## How it was verified

- Traced on current `origin/main` (`e660746cf2d92f6eca498a26627ca16c64dd5d46`): the `useMemo` dependency array is only `[filteredSessions]`; `groupSessionsByDate` already takes `now`.
- No open issue or PR covers frozen Today/Yesterday labels for this hook.
- Regression test written to fail without the fix (memoized clock) and pass with render-time `now()`. Tests run in Omi CI (`pnpm test` via desktop-windows CI) with `ci:full`. They have not been run locally.

## Tests

`desktop/windows/src/renderer/src/hooks/useChatSessions.test.ts`:

- loads sessions, groups them under **Today** with a pre-midnight `now`;
- advances `now` past local midnight without changing the list;
- rerenders and asserts the same row moves to **Yesterday**.

## UI evidence

UI-Evidence: none -- hook/unit behavior only; no visual chrome change.

## Failure class

Failure-Class: new

## Failure-class transition narrative

New class `FC-date-buckets-frozen-at-memo-clock`.

- Violated contract: date buckets derived from wall-clock calendar days must re-evaluate their clock on each render (or on an explicit midnight tick). Memoizing on the row list alone freezes `Date.now` at the last list change.
- Canonical guard: call `groupSessionsByDate(rows, now())` at render time; inject `now` in tests and cover a midnight-crossing rerender with an unchanged list.
- Evidence: `useMemo(() => groupSessionsByDate(filteredSessions), [filteredSessions])` on `origin/main` before this change. `evidence_prs` is empty because this PR is the first instance.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
