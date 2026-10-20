# w12-web-conversations-uncached-filter

- Issue: #22914 — Web Conversations: switching to an uncached folder or date keeps showing the previous filter's conversations
- PR: #22915 — fix(web): clear the old conversations list when switching to an uncached filter
- Branch: `fix/web-conversations-clear-uncached-filter` (fork `apoorvdarshan/omi`)
- Head: f77316c730 (ci:full empty commit; fix commit fccfca9e5f)
- Base: `origin/main` 9e8a777c9f9f2706e1bebf835bb5b141ac061c52

What changed:
- `useConversations` clears `conversations` (`setConversations([])`) when switching to an
  uncached filter combination (`!cached`), so the previous filter's items do not stay rendered
  under the new folder/date while loading or after a failed fetch.
- Failure class: `FC-fetch-error-outlives-cached-view-switch` (existing).
- Regression test: `web/app/src/hooks/__tests__/useConversations.test.tsx`
  (`clears the previous filter's conversations when switching to an uncached filter`).

Verified: code reading plus hermetic hook test; not run locally (compute policy),
runs in Omi CI (`web-app-checks`) with `ci:full`. Watcher entry added to `watch.inbox`.

