**Product impact**

- Primary loop layer (pick one): UX-Polish
- [ ] Involves data loss, failed capture, or broken sync/trust (call this out clearly below)

**Describe the bug**

On the web Tasks page, Select All (`Cmd/Ctrl+A` and the bulk bar's Select All button) decides whether every visible task is already selected by comparing the size of the whole selection with the number of pending tasks that match the search. If one selected task is hidden by the search — or by the day picked in the hub — and exactly one pending task is visible, the counts match, so Select All clears the selection instead of selecting the visible task. The bulk bar's toggle state makes the same size comparison, so it can show Select All as active while the visible task is unselected. Select All also ignores the hub's picked-day filter, so it selects pending tasks on other days.

**To Reproduce**

1. Open Tasks in the web app at a width below 1024px so the List view is shown.
2. Select "Buy milk" with the keyboard (`Down`, `Space`).
3. Search for "email": "Buy milk" is hidden and only "Email boss" is shown.
4. Press `Cmd/Ctrl+A`, then `Enter`.
5. Nothing is completed. `Cmd/Ctrl+A` cleared the selection instead of selecting the visible task.

With two visible pending tasks and one hidden selection, `Cmd/Ctrl+A` does select the visible tasks (1 != 2), so the bug depends on the counts matching.

**Current behavior**

Select All can clear the selection when a selected task is hidden by the search or the picked day, and the bulk bar can show Select All as active while visible tasks are unselected.

**Expected behavior**

Select All toggles exactly the pending tasks the current view shows, and its toggle state reflects whether those visible tasks are selected.

**Screenshots**

Not applicable; the selection state is covered by a component test.

**user ID (can we access the user info to validate the bug?):**

Not applicable; this reproduces from local component state and needs no account data.

**Smartphone + device (please complete the following information):**

- Device: desktop browser
- OS: any
- Browser: any
- App Version: `web/app` at `e660746cf2d92f6eca498a26627ca16c64dd5d46`

**Additional context**

Cause on current `main`:

- `handleSelectAll` filters only by the search text and compares `selectedIds.size` with the visible pending count: https://github.com/BasedHardware/omi/blob/e660746cf2d92f6eca498a26627ca16c64dd5d46/web/app/src/components/tasks/TaskHub.tsx#L157-L172
- The bulk bar's `allSelected` and `totalCount` use the same size comparison against the search-only list, not the day-filtered list the hub renders: https://github.com/BasedHardware/omi/blob/e660746cf2d92f6eca498a26627ca16c64dd5d46/web/app/src/components/tasks/TaskHub.tsx#L520-L528

The fix derives the selectable rows from the same filtered list the view renders and compares membership by task id.
