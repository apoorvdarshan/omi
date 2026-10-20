# w9-web-tasks-select-all

- Issue: #22799 — Web Tasks: Select All clears the selection when a filter hides a selected task
- PR: #22800 — fix(web): make Tasks Select All use the rows the view shows
- Branch: `fix/web-tasks-select-all-visible` (fork `apoorvdarshan/omi`)
- Head: 7e0aa84b8f (ci:full empty commit; fix commit 23cb635d05)
- Base: `origin/main` e660746cf2d92f6eca498a26627ca16c64dd5d46

What changed:
- `handleSelectAll` now derives its rows from the same filtered list the view renders
  (`filteredFlatList` in list view, the picked-day groups in the hub) and checks
  membership by task id instead of comparing `selectedIds.size` with the visible count.
- The bulk bar's `allSelected` and `totalCount` use the same selectable set.
- `getVisibleGroups`/`filteredView` became a memo above the keyboard hook so the
  selectable set can be computed from it.
- New failure class `FC-filtered-selection-gated-on-count`.
- Regression test: `web/app/src/components/tasks/__tests__/TaskHub.test.tsx`
  "selects the search results when another selected task is hidden".

Verified: code reading plus the hermetic component test; not run locally (compute
policy), runs in Omi CI with `ci:full`. Watcher entry added to `watch.inbox`.
