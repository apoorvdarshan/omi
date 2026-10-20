# w9-web-bulk-delete

- Issue: #22803 — Web Tasks: a partly failed bulk delete restores tasks the server already deleted
- PR: #22804 — fix(web): keep the tasks a failed bulk delete did not remove
- Branch: `fix/web-bulk-delete-partial-failure` (fork `apoorvdarshan/omi`)
- Head: 1bfd34eaab (ci:full empty commit; fix commit 8924fc16b4)
- Base: `origin/main` e660746cf2d92f6eca498a26627ca16c64dd5d46

What changed:
- `bulkDelete` uses `Promise.allSettled`; only ids whose DELETE rejected are restored,
  deduped by id, instead of re-adding the whole selection from the catch.
- Reports the first failure, as before.
- Failure class: `FC-batch-fault-domain-head-of-line-poison` (existing).
- Regression test: `web/app/src/hooks/__tests__/useActionItems.test.tsx`
  "puts back only the tasks a partly failed bulk delete kept".

Verified: code reading plus the hermetic hook test; not run locally (compute
policy), runs in Omi CI with `ci:full`. Watcher entry added to `watch.inbox`.
