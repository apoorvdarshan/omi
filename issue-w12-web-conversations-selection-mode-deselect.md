**Product impact**

- Primary loop layer (pick one): UX-Polish
- [ ] Involves data loss, failed capture, or broken sync/trust (call this out clearly below)

**Describe the bug**

In `web/app/src/components/conversations/ConversationSplitView.tsx`, `enterSelectionMode` and `enterSelectionModeWithId` call `setSelection(null); // Deselect any viewed tile` to close the detail pane when entering selection mode.

However, neither sets `preventAutoSelect.current = true` nor does the auto-select `useEffect` check `isSelectionMode`. On the very next render after `setSelection(null)`, the auto-select `useEffect` sees `selection === null` with `preventAutoSelect.current === false` and immediately selects `dayGroups[0]?.items[0]` again:

- On desktop (`>=lg`), clicking **Select** (or double-clicking a conversation card to enter selection mode) never closes the detail pane, and if the user was viewing a lower conversation, the detail pane jumps to the newest item.
- Below `lg` widths, where the gallery uses `selection ? 'hidden lg:flex' : 'flex'`, clicking **Select** while viewing a conversation immediately re-selects the first item and keeps the gallery hidden in selection mode.

**To Reproduce**

1. Open Conversations in the web app (`All` tab) so the newest conversation is auto-selected in the detail pane.
2. Click **Select** in the toolbar (or double-click a conversation card).
3. `enterSelectionMode` calls `setSelection(null)`, and the auto-select effect immediately re-selects the newest item, keeping the detail pane open.

**Current behavior**

Entering selection mode clears `selection`, and the auto-select effect immediately populates `selection` again on the next render.

**Expected behavior**

Entering selection mode closes the detail pane (`selection` stays `null`) and suppresses auto-select while selection mode is entered.

**Screenshots**

Not applicable; covered by a component test on `ConversationSplitView`.

**user ID (can we access the user info to validate the bug?):**

Not applicable; reproduces from client component state without account data.

**Smartphone + device (please complete the following information):**

- Device: desktop/mobile browser
- OS: any
- Browser: any
- App Version: `web/app` at `9e8a777c9f9f2706e1bebf835bb5b141ac061c52`

**Additional context**

Cause on current `main`:
- Auto-select effect: https://github.com/BasedHardware/omi/blob/9e8a777c9f9f2706e1bebf835bb5b141ac061c52/web/app/src/components/conversations/ConversationSplitView.tsx#L310-L336
- Selection mode handlers: https://github.com/BasedHardware/omi/blob/9e8a777c9f9f2706e1bebf835bb5b141ac061c52/web/app/src/components/conversations/ConversationSplitView.tsx#L463-L475
