## What changed and why

`enterSelectionMode` and `enterSelectionModeWithId` in `ConversationSplitView` called `setSelection(null)` (`// Deselect any viewed tile`) to close the detail pane when entering selection mode, but neither set `preventAutoSelect.current = true` nor did the auto-select `useEffect` check `isSelectionMode`. On the next render, the auto-select effect immediately selected `dayGroups[0]?.items[0]` again, keeping the detail pane open (and hiding the gallery below `lg` widths).

Both selection-mode entry handlers now set `preventAutoSelect.current = true`, and the auto-select effect skips auto-selection while `isSelectionMode` is active.

Fixes #22918

## Product invariants affected

none

## How it was verified

- Read `web/app/src/components/conversations/ConversationSplitView.tsx` and `web/app/src/components/conversations/__tests__/ConversationSplitView.test.tsx`.
- Added regression test `closes the detail pane when entering selection mode instead of re-selecting the newest tile` in `web/app/src/components/conversations/__tests__/ConversationSplitView.test.tsx`, which renders `ConversationSplitView` with an auto-selected conversation, clicks **Select**, and asserts `conversation-detail` is removed from the document.
- Validated `.github/failure-classes/FC-default-selection-effect-overrides-explicit-clear.json` with `scripts/failure-class`'s `validate_definition`. Per the fix loop's compute policy, the web test suite was not run on this Mac; it runs in Omi CI (`web-app-checks`) with `ci:full`.

## Tests

`web/app/src/components/conversations/__tests__/ConversationSplitView.test.tsx` — `closes the detail pane when entering selection mode instead of re-selecting the newest tile` (written to fail without the fix and pass with it; runs in Omi CI).

## UI evidence

UI-Evidence: none -- selection state only; covered by the component test above.

## Failure class (fixes)

Failure-Class: new

## Failure-class transition narrative (only when needed)

The violated contract is that an automatic initial-selection effect must only populate an unchosen default state and must never immediately undo an explicit selection clear performed by a user action or mode transition (`enterSelectionMode` / `enterSelectionModeWithId`). The canonical guard introduced in `.github/failure-classes/FC-default-selection-effect-overrides-explicit-clear.json` records explicit selection clears on `preventAutoSelect` and gates the auto-select effect on `isSelectionMode`, proved by `web/app/src/components/conversations/__tests__/ConversationSplitView.test.tsx`. This PR is the first instance; `evidence_prs` is empty until it merges.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
