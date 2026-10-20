## What changed and why

`ConversationTile` initialized `isStarred` from `conversation.starred` on mount (`useState(conversation.starred)`) and never updated it when `conversation.starred` changed. Because `ConversationGallery` keys each tile by `conversation.id`, tiles remain mounted across refetches and cache refreshes; when a refetch returned a changed `conversation.starred` (for example after starring or unstarring on another client), the tile kept rendering its stale `isStarred` button state while the Starred tab filtered on the updated prop.

`ConversationTile` now syncs `isStarred` from `conversation.starred` in an effect whenever no star request is in flight for that tile (`!starRequestPending.current`).

Fixes #22916

## Product invariants affected

none

## How it was verified

- Read `web/app/src/components/conversations/ConversationTile.tsx` and `web/app/src/components/conversations/__tests__/ConversationSplitView.starToggle.test.tsx`.
- Added regression test `updates the tile star when a refetch changes conversation.starred` in `web/app/src/components/conversations/__tests__/ConversationSplitView.starToggle.test.tsx`, which renders an unstarred conversation, updates `conversation.starred` to `true` on rerender, and asserts the tile button updates to `'Unstar conversation'`.
- Per the fix loop's compute policy, the web test suite was not run on this Mac; it runs in Omi CI (`web-app-checks`) with `ci:full`.

## Tests

`web/app/src/components/conversations/__tests__/ConversationSplitView.starToggle.test.tsx` — `updates the tile star when a refetch changes conversation.starred` (written to fail without the fix and pass with it; runs in Omi CI).

## UI evidence

UI-Evidence: none -- no layout or visual design change; the component test asserts the tile's star button state after a prop update.

## Failure class (fixes)

Failure-Class: FC-control-shows-unconfirmed-write

🤖 Generated with [Claude Code](https://claude.com/claude-code)
