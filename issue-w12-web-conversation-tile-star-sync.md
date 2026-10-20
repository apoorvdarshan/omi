**Product impact**

- Primary loop layer (pick one): UX-Polish
- [ ] Involves data loss, failed capture, or broken sync/trust (call this out clearly below)

**Describe the bug**

In `web/app/src/components/conversations/ConversationTile.tsx`, `isStarred` is initialized once on mount via `useState(conversation.starred)` and never updates when `conversation.starred` changes via props.

Because `ConversationGallery` keys each `ConversationTile` by `conversation.id`, tiles remain mounted across list refetches, background cache refreshes, and polling. When a conversation's starred state changes outside the tile (for example on another client or tab) and a refetch delivers the updated `conversation.starred`, the mounted tile continues displaying its old star state while the Starred tab (which filters on `conversation.starred`) shows the updated state.

**To Reproduce**

1. Open Conversations in the web app (`All` tab) with an unstarred conversation rendered in the gallery.
2. Star that conversation from another client/tab and let the list refetch (or refresh the list).
3. Switch to the `Starred` tab and back to `All`: the tile on `All` still shows `"Star conversation"` (unstarred) even though `conversation.starred` is `true`.

**Current behavior**

`ConversationTile` only reads `conversation.starred` on initial mount and ignores subsequent updates to `conversation.starred`.

**Expected behavior**

`ConversationTile` syncs `isStarred` with `conversation.starred` whenever no star request is in flight for that tile (`!starRequestPending.current`).

**Screenshots**

Not applicable; covered by a component test rendering the real `ConversationGallery` and `ConversationTile`.

**user ID (can we access the user info to validate the bug?):**

Not applicable; reproduces from component props without account data.

**Smartphone + device (please complete the following information):**

- Device: desktop/mobile browser
- OS: any
- Browser: any
- App Version: `web/app` at `9e8a777c9f9f2706e1bebf835bb5b141ac061c52`

**Additional context**

Cause on current `main`: https://github.com/BasedHardware/omi/blob/9e8a777c9f9f2706e1bebf835bb5b141ac061c52/web/app/src/components/conversations/ConversationTile.tsx#L38-L42
