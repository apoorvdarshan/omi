# w12-web-conversation-tile-star-sync

- Issue: #22916 — Web Conversations: ConversationTile keeps showing a stale star state after a refetch
- PR: #22917 — fix(web): sync a conversation tile's star when the list updates
- Branch: `fix/web-conversation-tile-star-prop-sync` (fork `apoorvdarshan/omi`)
- Head: 2cbb41fead (ci:full empty commit; fix commit 9d255cb767)
- Base: `origin/main` 9e8a777c9f9f2706e1bebf835bb5b141ac061c52

What changed:
- `ConversationTile` syncs `isStarred` from `conversation.starred` in an effect whenever
  `!starRequestPending.current`, so refetches and prop updates update the tile's star button.
- Failure class: `FC-control-shows-unconfirmed-write` (existing).
- Regression test: `web/app/src/components/conversations/__tests__/ConversationSplitView.starToggle.test.tsx`
  (`updates the tile star when a refetch changes conversation.starred`).

Verified: code reading plus component test; not run locally (compute policy),
runs in Omi CI (`web-app-checks`) with `ci:full`. Watcher entry added to `watch.inbox`.

