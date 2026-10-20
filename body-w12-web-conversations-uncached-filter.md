## What changed and why

When `useConversations` switched to a folder or date filter with no cache entry (`!cached`), it reset `offset` and `hasMore` and called `fetchConversations(0, false)` without clearing `conversations`. Because `ConversationSplitView` renders `ConversationGallery` whenever `dayGroups.length > 0` (and only renders `ConversationGallerySkeleton` when `isLoading && dayGroups.length === 0`), the previous filter's conversations stayed on screen under the new folder or date while the request was in flight, and remained there next to the error banner if that first fetch failed.

`useConversations` now calls `setConversations([])` before starting the fetch for an uncached filter.

Fixes #22914

## Product invariants affected

none

## How it was verified

- Read `web/app/src/hooks/useConversations.ts` and `web/app/src/components/conversations/ConversationSplitView.tsx`.
- Added regression test `clears the previous filter's conversations when switching to an uncached filter` in `web/app/src/hooks/__tests__/useConversations.test.tsx`, which loads the `home` folder, switches to an uncached `work` folder whose request is pending (asserting `conversations` is `[]` while `loading` is `true`), and rejects the request (asserting `conversations` remains `[]` with `error` set).
- Per the fix loop's compute policy, the web test suite was not run on this Mac; it runs in Omi CI (`web-app-checks`) with `ci:full`.

## Tests

`web/app/src/hooks/__tests__/useConversations.test.tsx` — `clears the previous filter's conversations when switching to an uncached filter` (written to fail without the fix and pass with it; runs in Omi CI).

## UI evidence

UI-Evidence: none -- hook state only; no layout or visual change.

## Failure class (fixes)

Failure-Class: FC-fetch-error-outlives-cached-view-switch

🤖 Generated with [Claude Code](https://claude.com/claude-code)
